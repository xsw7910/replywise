import 'dart:convert';

enum GuidanceCategory {
  general,
  professional,
  friendly,
  decline,
  thanks,
  followUp,
  custom;

  String get label => switch (this) {
    GuidanceCategory.general => 'General',
    GuidanceCategory.professional => 'Professional',
    GuidanceCategory.friendly => 'Friendly',
    GuidanceCategory.decline => 'Decline',
    GuidanceCategory.thanks => 'Thanks',
    GuidanceCategory.followUp => 'Follow-up',
    GuidanceCategory.custom => 'Custom',
  };
}

class GuidanceTemplate {
  const GuidanceTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isBuiltIn,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final GuidanceCategory category;
  final bool isBuiltIn;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  GuidanceTemplate copyWith({
    String? title,
    String? content,
    GuidanceCategory? category,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return GuidanceTemplate(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isBuiltIn: isBuiltIn,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category.name,
    'isBuiltIn': isBuiltIn,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory GuidanceTemplate.fromJson(Map<String, dynamic> json) {
    return GuidanceTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: GuidanceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => GuidanceCategory.custom,
      ),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static GuidanceTemplate fromJsonString(String s) =>
      GuidanceTemplate.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}

// Built-in templates — IDs are stable; never change them.
final List<GuidanceTemplate> kBuiltInTemplates = List.unmodifiable([
  _builtin(
    'builtin_be_polite',
    'Be polite',
    'Make the reply polite and respectful.',
    GuidanceCategory.general,
  ),
  _builtin(
    'builtin_keep_short',
    'Keep it short',
    'Keep the reply short and clear.',
    GuidanceCategory.general,
  ),
  _builtin(
    'builtin_professional',
    'Make it professional',
    'Make the reply sound professional and appropriate for work.',
    GuidanceCategory.professional,
  ),
  _builtin(
    'builtin_friendly',
    'Make it friendly',
    'Make the reply warm and friendly.',
    GuidanceCategory.friendly,
  ),
  _builtin(
    'builtin_decline',
    'Decline politely',
    'Politely decline the request without sounding rude.',
    GuidanceCategory.decline,
  ),
  _builtin(
    'builtin_thanks',
    'Say thank you',
    'Add appreciation and a polite thank-you.',
    GuidanceCategory.thanks,
  ),
  _builtin(
    'builtin_more_time',
    'Ask for more time',
    'Ask for more time while sounding responsible and polite.',
    GuidanceCategory.followUp,
  ),
  _builtin(
    'builtin_confident',
    'Sound confident',
    'Make the reply sound confident but not aggressive.',
    GuidanceCategory.general,
  ),
]);

GuidanceTemplate _builtin(
  String id,
  String title,
  String content,
  GuidanceCategory category,
) {
  final t = DateTime.utc(2024);
  return GuidanceTemplate(
    id: id,
    title: title,
    content: content,
    category: category,
    isBuiltIn: true,
    isFavorite: false,
    createdAt: t,
    updatedAt: t,
  );
}
