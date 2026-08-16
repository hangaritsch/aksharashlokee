class Shloka {
  final String id;
  final String akshara;
  final String content;
  final String reference;
  final String? createdAt;
  final String? updatedAt;

  Shloka({
    required this.id,
    required this.akshara,
    required this.content,
    required this.reference,
    this.createdAt,
    this.updatedAt,
  });

  factory Shloka.fromJson(Map<String, dynamic> json) {
    return Shloka(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      akshara: json['akshara'] as String? ?? '',
      content: json['content'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'akshara': akshara,
      'content': content,
      'reference': reference,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Extracts the main work/grantha name without chapter or verse numbers
  String get mainGrantha {
    if (reference.trim().isEmpty) return 'सामान्यम्';
    final ref = reference.trim();
    // Split by comma or slash to isolate main work name
    final commaIndex = ref.indexOf(',');
    if (commaIndex != -1) {
      return ref.substring(0, commaIndex).trim();
    }
    // Remove numbers, slashes, and verse indicators
    return ref.split(RegExp(r'[\d\/,॥\.]')).first.trim();
  }
}

