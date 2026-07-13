import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:replywise/core/text/paste_into_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setClipboardText(String text) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': text};
          }
          return null;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('empty field paste inserts clipboard text', () async {
    await setClipboardText('Hello');
    final controller = TextEditingController();

    await pasteIntoController(controller);

    expect(controller.text, 'Hello');
    expect(controller.selection.baseOffset, 5);
  });

  test('existing text paste inserts at the current cursor', () async {
    await setClipboardText('beautiful ');
    final controller = TextEditingController(text: 'Hello world')
      ..selection = const TextSelection.collapsed(offset: 6);

    await pasteIntoController(controller);

    expect(controller.text, 'Hello beautiful world');
    expect(controller.selection.baseOffset, 'Hello beautiful '.length);
  });

  test('selected text paste replaces only the selected text', () async {
    await setClipboardText('brave');
    final controller = TextEditingController(text: 'Hello old world')
      ..selection = const TextSelection(baseOffset: 6, extentOffset: 9);

    await pasteIntoController(controller);

    expect(controller.text, 'Hello brave world');
    expect(controller.selection.baseOffset, 'Hello brave'.length);
  });

  test('paste does not clear existing surrounding text', () async {
    await setClipboardText('X');
    final controller = TextEditingController(text: 'abc')
      ..selection = const TextSelection.collapsed(offset: 1);

    await pasteIntoController(controller);

    expect(controller.text, 'aXbc');
  });

  test('paste moves cursor to the end of inserted text', () async {
    await setClipboardText('XYZ');
    final controller = TextEditingController(text: 'ab')
      ..selection = const TextSelection.collapsed(offset: 1);

    await pasteIntoController(controller);

    expect(controller.text, 'aXYZb');
    expect(controller.selection, const TextSelection.collapsed(offset: 4));
  });
}
