import 'package:firebase_core/firebase_core.dart';

String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'email-already-in-use' => 'Este email já está em uso.',
      'weak-password' => 'Escolha uma senha mais forte.',
      'invalid-email' => 'Informe um email válido.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Não foi possível entrar. Confira email e senha.',
      'network-request-failed' ||
      'unavailable' => 'Sem conexão com o serviço. Tente novamente.',
      'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
      'permission-denied' ||
      'unauthorized' => 'Você não tem permissão para esta operação.',
      'unauthenticated' =>
        'Sua sessão expirou. Entre novamente para continuar.',
      'deadline-exceeded' =>
        'O serviço demorou para responder. Tente novamente.',
      _ => 'Não foi possível concluir. Tente novamente.',
    };
  }
  return 'Não foi possível concluir. Verifique a conexão e tente novamente.';
}

class AppException implements Exception {
  const AppException(this.message);
  final String message;
}
