import 'package:flutter/material.dart';
import '../../core/errors.dart';
import '../../core/validation.dart';
import 'auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.auth});
  final AuthRepository auth;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  var _mode = 0;
  var _busy = false;
  var _hidden = true;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_mode == 0) {
        await widget.auth.login(_email.text, _password.text);
      } else if (_mode == 1) {
        await widget.auth.register(_email.text, _password.text);
      } else {
        await widget.auth.recover(_email.text);
        if (mounted) {
          setState(
            () => _message =
                'Se houver uma conta para este email, você receberá instruções para redefinir a senha.',
          );
        }
      }
    } catch (error) {
      if (mounted) setState(() => _message = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeMode(int mode) {
    setState(() {
      _mode = mode;
      _message = null;
      _password.clear();
      _confirmation.clear();
      _form.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.explore_outlined,
                      size: 56,
                      color: Color(0xFF206453),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Yourvel',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(switch (_mode) {
                    1 => 'Comece a colecionar memórias.',
                    2 => 'Recupere o acesso ao seu diário.',
                    _ => 'Cada lugar tem uma história sua.',
                  }, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    validator: Validation.email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (_mode != 2) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _hidden,
                      validator: (value) => (value ?? '').length < 6
                          ? 'Use pelo menos 6 caracteres.'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => _hidden = !_hidden),
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_mode == 1) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: true,
                      validator: (value) => value != _password.text
                          ? 'As senhas precisam ser iguais.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Confirme a senha',
                      ),
                    ),
                  ],
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_message!),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(switch (_mode) {
                              1 => 'Criar conta',
                              2 => 'Enviar instruções',
                              _ => 'Entrar',
                            }),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _changeMode(_mode == 0 ? 1 : 0),
                    child: Text(
                      _mode == 0
                          ? 'Ainda não tem conta? Cadastre-se'
                          : 'Voltar para entrar',
                    ),
                  ),
                  if (_mode == 0)
                    TextButton(
                      onPressed: _busy ? null : () => _changeMode(2),
                      child: const Text('Esqueci minha senha'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
