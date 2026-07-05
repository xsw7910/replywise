import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// The kind of activity a [RecentItem] represents.
enum RecentType { reply, polish, explain }

extension RecentTypeInfo on RecentType {
  /// English label shown in the UI (also used as the type pill text).
  String get displayLabel => switch (this) {
    RecentType.reply => 'Reply',
    RecentType.polish => 'Polish',
    RecentType.explain => 'Explain',
  };

  IconData get icon => switch (this) {
    RecentType.reply => Icons.chat_bubble_outline_rounded,
    RecentType.polish => Icons.auto_fix_high_rounded,
    RecentType.explain => Icons.psychology_alt_rounded,
  };

  Color get accentColor => switch (this) {
    RecentType.reply => AppColors.replyColor,
    RecentType.polish => AppColors.polishColor,
    RecentType.explain => AppColors.explainColor,
  };

  /// Router path for the screen that produced this item.
  String get routePath => switch (this) {
    RecentType.reply => AppRoutes.reply,
    RecentType.polish => AppRoutes.polish,
    RecentType.explain => AppRoutes.explain,
  };
}

/// A single locally-stored recent activity item. Purely local; never synced.
class RecentItem {
  const RecentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.inputText,
    required this.outputText,
    required this.createdAt,
    this.guidance,
    this.tone,
    this.channel,
    this.length,
  });

  final String id;
  final RecentType type;
  final String title;
  final String inputText;
  final String outputText;
  final DateTime createdAt;

  // Optional context captured at generation time (handy for a future detail
  // view). Absent values are omitted from JSON to keep storage compact.
  final String? guidance;
  final String? tone;
  final String? channel;
  final String? length;

  /// Builds a new item with a fresh id, `createdAt = now`, and a locally
  /// generated [title]. Used by the generation screens on success.
  factory RecentItem.create({
    required RecentType type,
    required String inputText,
    required String outputText,
    String? guidance,
    String? tone,
    String? channel,
    String? length,
  }) => RecentItem(
    id: const Uuid().v4(),
    type: type,
    title: buildRecentTitle(type, inputText),
    inputText: inputText,
    outputText: outputText,
    createdAt: DateTime.now(),
    guidance: guidance,
    tone: tone,
    channel: channel,
    length: length,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'inputText': inputText,
    'outputText': outputText,
    'createdAt': createdAt.toIso8601String(),
    if (guidance != null) 'guidance': guidance,
    if (tone != null) 'tone': tone,
    if (channel != null) 'channel': channel,
    if (length != null) 'length': length,
  };

  /// Throws if a required field is missing or a value is malformed. The
  /// repository catches this so a single bad row never crashes the app.
  factory RecentItem.fromJson(Map<String, dynamic> json) => RecentItem(
    id: json['id'] as String,
    type: RecentType.values.byName(json['type'] as String),
    title: json['title'] as String,
    inputText: json['inputText'] as String? ?? '',
    outputText: json['outputText'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    guidance: json['guidance'] as String?,
    tone: json['tone'] as String?,
    channel: json['channel'] as String?,
    length: json['length'] as String?,
  );
}

/// Builds a human-readable title locally — no AI call.
///
/// Format: `Reply to: {preview}` / `Polish: {preview}` / `Explain: {preview}`,
/// where the preview is the trimmed, whitespace-collapsed input capped at 36
/// characters (with a trailing `...` when longer).
String buildRecentTitle(RecentType type, String input) {
  final preview = _previewOf(input);
  final label = switch (type) {
    RecentType.reply => 'Reply to:',
    RecentType.polish => 'Polish:',
    RecentType.explain => 'Explain:',
  };
  return preview.isEmpty ? label : '$label $preview';
}

String _previewOf(String input) {
  final collapsed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.length <= 36) return collapsed;
  return '${collapsed.substring(0, 36)}...';
}
