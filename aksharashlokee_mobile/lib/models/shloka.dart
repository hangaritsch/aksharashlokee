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
}
