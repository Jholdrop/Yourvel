import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../core/errors.dart';
import '../../../core/validation.dart';
import '../data/places_repository.dart';
import '../data/location_service.dart';
import '../data/travel_repository.dart';
import '../domain/models.dart';

class EntryFormPage extends StatefulWidget {
  const EntryFormPage({super.key, required this.repository});
  final TravelRepository repository;
  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final _form = GlobalKey<FormState>();
  final _query = TextEditingController();
  final _name = TextEditingController();
  final _memory = TextEditingController();
  final _client = http.Client();
  late final _places = PlacesRepository(_client);
  late final _id = widget.repository.newId();
  List<Place> _results = [];
  Place? _selected;
  Uint8List? _bytes;
  var _searching = false;
  var _picking = false;
  var _locating = false;
  var _saving = false;
  var _searched = false;
  var _lockedAfterAttempt = false;
  var _allowExit = false;
  var _confirmingExit = false;
  double? _progress = 0;
  String? _error;

  Future<void> _exit() async {
    if (_confirmingExit || _saving || _picking || _locating) return;
    _confirmingExit = true;
    final dirty =
        _name.text.isNotEmpty || _memory.text.isNotEmpty || _bytes != null;
    final discard =
        !dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Descartar esta memória?'),
                content: Text(
                  _lockedAfterAttempt
                      ? 'A cópia local da foto e qualquer registro confirmado desta tentativa serão removidos. Seus campos serão descartados.'
                      : 'Os campos preenchidos e a foto selecionada serão descartados.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Continuar editando'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Descartar'),
                  ),
                ],
              ),
            ) ==
            true;
    if (!mounted) return;
    if (!discard) {
      _confirmingExit = false;
      return;
    }
    if (_lockedAfterAttempt) {
      setState(() => _saving = true);
      try {
        await widget.repository.discard(_id);
      } catch (error) {
        if (mounted) {
          setState(() {
            _saving = false;
            _error =
                'Não foi possível descartar a memória. Verifique sua conexão e tente novamente.';
          });
        }
        _confirmingExit = false;
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _allowExit = true;
      _saving = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final place = await LocationService().current();
      if (mounted) {
        setState(() {
          _selected = place;
          if (_name.text.isEmpty) _name.text = place.name;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _name.dispose();
    _memory.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await _places.search(_query.text);
      if (mounted) {
        setState(() {
          _results = results;
          _searched = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (await file.length() > 5242880) {
        throw const AppException('A foto deve ter até 5 MiB.');
      }
      final bytes = await file.readAsBytes();
      TravelRepository.imageType(bytes);
      if (mounted) setState(() => _bytes = bytes);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _picking || _searching || _locating) return;
    if (!_form.currentState!.validate()) return;
    if (_selected == null || _bytes == null) {
      setState(
        () => _error = 'Selecione um lugar na busca e uma foto para continuar.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _lockedAfterAttempt = true;
      _error = null;
      _progress = 0;
    });
    try {
      await widget.repository.save(
        id: _id,
        name: _name.text,
        memory: _memory.text,
        place: _selected!,
        bytes: _bytes!,
        progress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _allowExit = true;
        });
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = friendlyError(error);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowExit,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Nova memória')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Onde essa história aconteceu?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Encontre um lugar, escolha sua foto e conte o que fez esse momento especial.',
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _query,
                  enabled: !_saving && !_lockedAfterAttempt,
                  decoration: const InputDecoration(
                    labelText: 'Buscar cidade',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _searching || _saving || _lockedAfterAttempt
                      ? null
                      : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.travel_explore),
                  label: const Text('Buscar lugares'),
                ),
                const Text(
                  'Cidades: Open-Meteo / GeoNames (CC BY 4.0). A busca usa o centro da cidade; para maior precisão, use sua posição atual.',
                  style: TextStyle(fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: _saving || _locating || _lockedAfterAttempt
                      ? null
                      : _locate,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _locating
                        ? 'Obtendo localização…'
                        : 'Usar minha localização atual',
                  ),
                ),
                if (_searched && _results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Nenhum lugar encontrado. Tente outro nome.'),
                  ),
                if (!_lockedAfterAttempt)
                  ..._results.map(
                    (place) => Card(
                      child: ListTile(
                        title: Text(place.name),
                        trailing: _selected == place
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.add_location_alt_outlined),
                        onTap: _saving
                            ? null
                            : () => setState(() {
                                _selected = place;
                                _name.text = place.name.length > 100
                                    ? place.name.substring(0, 100)
                                    : place.name;
                              }),
                      ),
                    ),
                  ),
                if (_selected != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Localização: ${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  enabled: !_saving && !_lockedAfterAttempt,
                  validator: Validation.name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Nome do local'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _memory,
                  enabled: !_saving && !_lockedAfterAttempt,
                  validator: Validation.memory,
                  maxLength: 1000,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Sua memória',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (_bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _bytes!,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text('Não foi possível abrir a prévia.'),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving || _picking || _lockedAfterAttempt
                      ? null
                      : _pick,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _picking
                        ? 'Abrindo galeria…'
                        : _bytes == null
                        ? 'Selecionar foto'
                        : 'Trocar foto',
                  ),
                ),
                const Text(
                  'Uma foto JPEG ou PNG, até 5 MiB. A foto fica apenas neste dispositivo.',
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_lockedAfterAttempt && !_saving)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Os campos foram preservados para repetir o salvamento com segurança.',
                    ),
                  ),
                if (_saving) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(
                    _progress == null
                        ? 'Salvando registro…'
                        : 'Guardando foto no dispositivo…',
                  ),
                  const Text('Aguarde a conclusão antes de sair.'),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving || _picking || _searching || _locating
                      ? null
                      : _save,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _saving
                          ? 'Guardando memória…'
                          : _lockedAfterAttempt
                          ? 'Tentar salvar novamente'
                          : 'Guardar memória',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
