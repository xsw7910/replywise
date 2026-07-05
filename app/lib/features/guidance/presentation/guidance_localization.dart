import 'package:flutter/widgets.dart';

import '../../../core/localization/localization_extensions.dart';
import '../domain/guidance_template.dart';

String localizedGuidanceCategory(
  BuildContext context,
  GuidanceCategory category,
) => switch (category) {
  GuidanceCategory.general => context.l10n.general,
  GuidanceCategory.professional => context.l10n.professional,
  GuidanceCategory.friendly => context.l10n.friendly,
  GuidanceCategory.decline => context.l10n.decline,
  GuidanceCategory.thanks => context.l10n.thanks,
  GuidanceCategory.followUp => context.l10n.followUp,
  GuidanceCategory.custom => context.l10n.custom,
};

String localizedGuidanceTitle(
  BuildContext context,
  GuidanceTemplate template,
) => switch (template.id) {
  'builtin_be_polite' => context.l10n.bePolite,
  'builtin_keep_short' => context.l10n.keepItShort,
  'builtin_professional' => context.l10n.makeProfessional,
  'builtin_friendly' => context.l10n.makeFriendly,
  'builtin_decline' => context.l10n.declinePolitely,
  'builtin_thanks' => context.l10n.sayThankYou,
  'builtin_more_time' => context.l10n.askMoreTime,
  'builtin_confident' => context.l10n.soundConfident,
  _ => template.title,
};

String localizedGuidanceContent(
  BuildContext context,
  GuidanceTemplate template,
) => switch (template.id) {
  'builtin_be_polite' => context.l10n.guidancePoliteContent,
  'builtin_keep_short' => context.l10n.guidanceShortContent,
  'builtin_professional' => context.l10n.guidanceProfessionalContent,
  'builtin_friendly' => context.l10n.guidanceFriendlyContent,
  'builtin_decline' => context.l10n.guidanceDeclineContent,
  'builtin_thanks' => context.l10n.guidanceThanksContent,
  'builtin_more_time' => context.l10n.guidanceMoreTimeContent,
  'builtin_confident' => context.l10n.guidanceConfidentContent,
  _ => template.content,
};
