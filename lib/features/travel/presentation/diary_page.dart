import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/errors.dart';
import '../../auth/auth_repository.dart';
import '../data/travel_repository.dart';
import '../domain/models.dart';
import 'entry_form_page.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key, required this.auth, required this.repository});
  final AuthRepository auth;
  final TravelRepository repository;
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late Stream<List<TravelEntry>> _stream = widget.repository.watch();
  var _leaving = false;

  Future<void> _logout() async {
    setState(() => _leaving = true);
    try {
      await widget.auth.logout();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Future<void> _newEntry() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(repository: widget.repository),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memória guardada no seu diário.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Yourvel'),
      actions: [
        TextButton.icon(
          onPressed: _leaving ? null : _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _newEntry,
      icon: const Icon(Icons.add),
      label: const Text('Nova memória'),
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: StreamBuilder<List<TravelEntry>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Não foi possível carregar o diário. Confira sua conexão e tente novamente.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () =>
                            setState(() => _stream = widget.repository.watch()),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seu mundo, em memórias.',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${entries.length} ${entries.length == 1 ? 'história guardada' : 'histórias guardadas'} • Diário pessoal',
                        ),
                      ],
                    ),
                  ),
                ),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.landscape_outlined,
                              size: 80,
                              color: Color(0xFF206453),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sua próxima lembrança começa aqui.',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Registre um lugar especial com uma foto e sua história.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _newEntry,
                              child: const Text('Criar primeira memória'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntryDetailPage(
                                entry: entry,
                                repository: widget.repository,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EntryImage(
                                key: ValueKey(entry.id),
                                repository: widget.repository,
                                path: entry.imagePath,
                                height: 230,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.memory,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _date(entry.createdAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

String _date(DateTime? date) => date == null
    ? 'Sincronizando data…'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class EntryImage extends StatefulWidget {
  const EntryImage({
    super.key,
    required this.repository,
    required this.path,
    required this.height,
  });
  final TravelRepository repository;
  final String path;
  final double height;
  @override
  State<EntryImage> createState() => _EntryImageState();
}

class _EntryImageState extends State<EntryImage> {
  late Future<Uint8List?> _image = widget.repository.image(widget.path);
  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: FutureBuilder<Uint8List?>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Foto indisponível'),
                TextButton(
                  onPressed: () => setState(
                    () => _image = widget.repository.image(widget.path),
                  ),
                  child: const Text('Carregar novamente'),
                ),
              ],
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          semanticLabel: 'Foto pessoal do local visitado',
          errorBuilder: (_, _, _) =>
              const Center(child: Text('Não foi possível abrir a foto.')),
        );
      },
    ),
  );
}

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({
    super.key,
    required this.entry,
    required this.repository,
  });
  final TravelEntry entry;
  final TravelRepository repository;
  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  var _deleting = false;
  String? _error;
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir esta memória?'),
        content: const Text(
          'A foto e o registro serão removidos. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.repository.delete(widget.entry);
      if (mounted) {
        setState(() => _deleting = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error =
              'A exclusão não foi concluída. A foto pode já ter sido removida. Tente excluir novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: Scaffold(
      appBar: AppBar(title: const Text('Sua memória')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: EntryImage(
                  repository: widget.repository,
                  path: widget.entry.imagePath,
                  height: 300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.entry.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(_date(widget.entry.createdAt)),
              const SizedBox(height: 24),
              Text(
                widget.entry.memory,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Coordenadas: ${widget.entry.coordinates.latitude.toStringAsFixed(5)}, ${widget.entry.coordinates.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 32),
              if (_error != null) Text(_error!),
              OutlinedButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(_deleting ? 'Excluindo…' : 'Excluir memória'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
