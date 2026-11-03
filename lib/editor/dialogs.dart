import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../painting/rgba_image.dart';

enum UnsavedChoice { save, discard, cancel }

Future<UnsavedChoice> askToSave(BuildContext context, String name) async {
  final choice = await showDialog<UnsavedChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.saveChangesTitle),
      content: Text(context.l10n.saveChangesMessage(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, UnsavedChoice.cancel),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, UnsavedChoice.discard),
          child: Text(context.l10n.dontSave),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, UnsavedChoice.save),
          child: Text(context.l10n.save),
        ),
      ],
    ),
  );
  return choice ?? UnsavedChoice.cancel;
}

class SizeRequest {
  const SizeRequest(this.width, this.height, {this.stretch = true});

  final int width;
  final int height;
  final bool stretch;
}

Future<SizeRequest?> askNewImageSize(BuildContext context, Size initial) =>
    showDialog<SizeRequest>(
      context: context,
      builder: (context) => _SizeDialog(
        title: context.l10n.newImageTitle,
        action: context.l10n.create,
        initial: initial,
        offersStretch: false,
      ),
    );

Future<SizeRequest?> askResize(BuildContext context, Size current) =>
    showDialog<SizeRequest>(
      context: context,
      builder: (context) => _SizeDialog(
        title: context.l10n.resizeTitle,
        action: context.l10n.apply,
        initial: current,
        offersStretch: true,
      ),
    );

class _SizeDialog extends StatefulWidget {
  const _SizeDialog({
    required this.title,
    required this.action,
    required this.initial,
    required this.offersStretch,
  });

  final String title;
  final String action;
  final Size initial;
  final bool offersStretch;

  @override
  State<_SizeDialog> createState() => _SizeDialogState();
}

class _SizeDialogState extends State<_SizeDialog> {
  late final _width = TextEditingController(
    text: '${widget.initial.width.round()}',
  );
  late final _height = TextEditingController(
    text: '${widget.initial.height.round()}',
  );
  var _keepProportions = true;
  var _stretch = true;

  double get _ratio => widget.initial.width / widget.initial.height;

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  int? _valid(TextEditingController field) {
    final value = int.tryParse(field.text);
    return value != null && value >= 1 && value <= maxImageSide ? value : null;
  }

  void _follow(TextEditingController changed) {
    if (!_keepProportions) return setState(() {});
    final value = int.tryParse(changed.text);
    if (value == null) return setState(() {});
    final other = identical(changed, _width) ? _height : _width;
    final linked = identical(changed, _width) ? value / _ratio : value * _ratio;
    other.text = '${linked.round().clamp(1, maxImageSide)}';
    setState(() {});
  }

  void _submit() {
    final width = _valid(_width), height = _valid(_height);
    if (width == null || height == null) return;
    Navigator.pop(context, SizeRequest(width, height, stretch: _stretch));
  }

  Widget _field(String label, TextEditingController controller) {
    return SizedBox(
      width: 130,
      child: TextField(
        controller: controller,
        autofocus: identical(controller, _width),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          suffixText: context.l10n.pixelsUnit,
          errorText: _valid(controller) == null ? '' : null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
        onChanged: (_) => _follow(controller),
        onSubmitted: (_) => _submit(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _valid(_width) != null && _valid(_height) != null;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _field(l10n.width, _width),
                const SizedBox(width: 16),
                _field(l10n.height, _height),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sizeLimit(maxImageSide),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _keepProportions,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.keepProportions),
              onChanged: (value) {
                setState(() => _keepProportions = value ?? true);
                if (_keepProportions) _follow(_width);
              },
            ),
            if (widget.offersStretch)
              CheckboxListTile(
                value: _stretch,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.stretchDrawing),
                subtitle: _stretch ? null : Text(l10n.stretchDrawingHint),
                onChanged: (value) => setState(() => _stretch = value ?? true),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: valid ? _submit : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
