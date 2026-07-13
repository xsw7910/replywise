import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

Future<void> pasteIntoController(
  TextEditingController controller, {
  int? maxLength,
}) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  var pasteText = data?.text ?? '';
  if (pasteText.isEmpty) return;

  final value = controller.value;
  final text = value.text;
  final selection = value.selection;
  final rawStart = selection.isValid ? selection.start : text.length;
  final rawEnd = selection.isValid ? selection.end : text.length;
  final safeStart = rawStart.clamp(0, text.length);
  final safeEnd = rawEnd.clamp(0, text.length);
  final replaceStart = safeStart < safeEnd ? safeStart : safeEnd;
  final replaceEnd = safeStart < safeEnd ? safeEnd : safeStart;

  if (maxLength != null) {
    final remaining = maxLength - (text.length - (replaceEnd - replaceStart));
    if (remaining <= 0) return;
    if (pasteText.length > remaining) {
      pasteText = pasteText.substring(0, remaining);
    }
  }

  final newText = text.replaceRange(replaceStart, replaceEnd, pasteText);
  final newOffset = replaceStart + pasteText.length;
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newOffset),
    composing: TextRange.empty,
  );
}
