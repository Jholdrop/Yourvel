class Validation {
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : 'Informe um email válido.';
  }

  static String? name(String? value) => length(value, 2, 100, 'O local');
  static String? memory(String? value) => length(value, 1, 1000, 'A memória');
  static String? length(String? value, int min, int max, String field) {
    final count = (value ?? '').trim().length;
    return count >= min && count <= max
        ? null
        : '$field deve ter entre $min e $max caracteres.';
  }
}
