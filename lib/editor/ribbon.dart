import 'package:flutter/material.dart';

import '../canvas/image_ops.dart';
import '../canvas/paint_controller.dart';
import '../canvas/tool_settings.dart';
import '../l10n/l10n.dart';
import '../shell/platform.dart';
import '../shell/ribbon_controls.dart';
import '../shell/ribbon_style.dart';

class RibbonActions {
  const RibbonActions({
    required this.copy,
    required this.cut,
    required this.paste,
    required this.resize,
    required this.editColor,
  });

  final VoidCallback copy;
  final VoidCallback cut;
  final VoidCallback paste;
  final VoidCallback resize;

  /// Edits color 1, or color 2 when true.
  final ValueChanged<bool> editColor;
}

/// The single row of tools, as in classic paint programs.
class Ribbon extends StatelessWidget {
  const Ribbon({required this.controller, required this.actions, super.key});

  final PaintController controller;
  final RibbonActions actions;

  ToolSettings get settings => controller.settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          color: RibbonColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RibbonColors.panelBorder),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RibbonGroup(label: l10n.clipboardGroup, child: _clipboard(l10n)),
              const RibbonGroupDivider(),
              RibbonGroup(label: l10n.imageGroup, child: _image(l10n)),
              const RibbonGroupDivider(),
              RibbonGroup(label: l10n.toolsGroup, child: _tools(l10n)),
              const RibbonGroupDivider(),
              RibbonGroup(label: l10n.shapesGroup, child: _shapes(l10n)),
              const RibbonGroupDivider(),
              RibbonGroup(label: l10n.sizeGroup, child: _size(l10n)),
              const RibbonGroupDivider(),
              RibbonGroup(label: l10n.colorsGroup, child: _colors(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clipboard(AppLocalizations l10n) {
    final selected = controller.hasSelection;
    return Row(
      children: [
        RibbonBigButton(
          icon: Icons.content_paste,
          label: l10n.paste,
          tooltip: '${l10n.paste} (${shortcutLabel('V')})',
          onPressed: actions.paste,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RibbonIconButton(
              icon: Icons.content_cut,
              tooltip: '${l10n.cut} (${shortcutLabel('X')})',
              onPressed: selected ? actions.cut : null,
            ),
            RibbonIconButton(
              icon: Icons.content_copy,
              tooltip: '${l10n.copy} (${shortcutLabel('C')})',
              onPressed: actions.copy,
            ),
          ],
        ),
      ],
    );
  }

  Widget _image(AppLocalizations l10n) {
    final selectTool = settings.tool == PaintTool.select;
    return Row(
      children: [
        RibbonBigButton(
          icon: Icons.highlight_alt,
          label: l10n.toolSelect,
          selected: selectTool,
          onPressed: () => settings.tool = PaintTool.select,
        ),
        _grid([
          RibbonIconButton(
            icon: Icons.select_all,
            tooltip: '${l10n.selectAll} (${shortcutLabel('A')})',
            onPressed: controller.selectAll,
          ),
          RibbonIconButton(
            icon: Icons.crop,
            tooltip: l10n.crop,
            onPressed: controller.hasSelection ? controller.crop : null,
          ),
          RibbonIconButton(
            icon: Icons.rotate_left,
            tooltip: l10n.rotateLeft,
            onPressed: () => controller.turn(Turn.left),
          ),
          RibbonIconButton(
            icon: Icons.rotate_right,
            tooltip: l10n.rotateRight,
            onPressed: () => controller.turn(Turn.right),
          ),
          RibbonIconButton(
            icon: Icons.photo_size_select_large,
            tooltip: l10n.resize,
            onPressed: actions.resize,
          ),
          RibbonIconButton(
            icon: Icons.flip,
            tooltip: l10n.flipHorizontal,
            onPressed: () => controller.turn(Turn.flipHorizontal),
          ),
          RibbonIconButton(
            icon: Icons.flip,
            tooltip: l10n.flipVertical,
            onPressed: () => controller.turn(Turn.flipVertical),
            child: const RotatedBox(quarterTurns: 1, child: Icon(Icons.flip)),
          ),
        ], columns: 4),
      ],
    );
  }

  Widget _tools(AppLocalizations l10n) => _grid([
    _tool(PaintTool.pencil, Icons.edit, l10n.toolPencil),
    _tool(PaintTool.brush, Icons.brush, l10n.toolBrush),
    _tool(
      PaintTool.eraser,
      Icons.rectangle_outlined,
      l10n.toolEraser,
      child: const _EraserIcon(),
    ),
    _tool(PaintTool.fill, Icons.format_color_fill, l10n.toolFill),
    _tool(PaintTool.picker, Icons.colorize, l10n.toolPicker),
  ], columns: 3);

  Widget _shapes(AppLocalizations l10n) => _grid([
    _tool(PaintTool.line, Icons.horizontal_rule, l10n.toolLine),
    _tool(PaintTool.rectangle, Icons.crop_square, l10n.toolRectangle),
    _tool(PaintTool.ellipse, Icons.circle_outlined, l10n.toolEllipse),
    RibbonIconButton(
      icon: Icons.check_box_outline_blank,
      tooltip: l10n.shapeOutline,
      selected: !settings.filled,
      onPressed: () => settings.filled = false,
    ),
    RibbonIconButton(
      icon: Icons.square,
      tooltip: l10n.shapeFilled,
      selected: settings.filled,
      onPressed: () => settings.filled = true,
    ),
  ], columns: 3);

  Widget _size(AppLocalizations l10n) => Tooltip(
    message: l10n.brushSize,
    child: MenuAnchor(
      style: ribbonMenuStyle(),
      menuChildren: [
        for (final size in brushSizes)
          MenuItemButton(
            style: ribbonMenuItemStyle(),
            onPressed: () => settings.size = size,
            leadingIcon: Icon(
              Icons.check,
              size: 16,
              color: size == settings.size
                  ? RibbonColors.text
                  : Colors.transparent,
            ),
            trailingIcon: SizedBox(
              width: 60,
              height: 24,
              child: Center(
                child: Container(
                  width: 56,
                  height: size.clamp(1, 20).toDouble(),
                  decoration: BoxDecoration(
                    color: RibbonColors.text,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            child: Text(l10n.sizePixels(size), style: RibbonText.control),
          ),
      ],
      builder: (context, menu, _) => RibbonBigButton(
        icon: Icons.line_weight,
        label: l10n.sizePixels(settings.size),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    ),
  );

  Widget _colors(AppLocalizations l10n) => Row(
    children: [
      _ColorSlot(
        label: l10n.color1,
        tooltip: l10n.color1Hint,
        color: settings.color1,
        big: true,
        onTap: () => actions.editColor(false),
      ),
      const SizedBox(width: 6),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorSlot(
            label: l10n.color2,
            tooltip: l10n.color2Hint,
            color: settings.color2,
            onTap: () => actions.editColor(true),
          ),
          RibbonIconButton(
            icon: Icons.swap_horiz,
            tooltip: l10n.swapColors,
            onPressed: settings.swapColors,
          ),
        ],
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 10 * 22,
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (final color in paletteColors)
              _Swatch(
                color: color,
                onPrimary: () => settings.color1 = color,
                onSecondary: () => settings.color2 = color,
              ),
          ],
        ),
      ),
      const SizedBox(width: 4),
      RibbonIconButton(
        icon: Icons.palette_outlined,
        tooltip: l10n.editColors,
        onPressed: () => actions.editColor(false),
      ),
    ],
  );

  Widget _tool(PaintTool tool, IconData icon, String label, {Widget? child}) =>
      RibbonIconButton(
        icon: icon,
        tooltip: label,
        selected: settings.tool == tool,
        onPressed: () => settings.tool = tool,
        child: child,
      );

  Widget _grid(List<Widget> buttons, {required int columns}) => SizedBox(
    width: columns * 34.0,
    child: Wrap(spacing: 2, runSpacing: 2, children: buttons),
  );
}

class _ColorSlot extends StatelessWidget {
  const _ColorSlot({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.big = false,
  });

  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final side = big ? 40.0 : 26.0;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: RibbonColors.text, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Left click sets color 1, right click color 2.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.onPrimary,
    required this.onSecondary,
  });

  final Color color;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPrimary,
      onSecondaryTap: onSecondary,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: RibbonColors.divider),
          ),
        ),
      ),
    );
  }
}

/// Material Icons has no eraser: a tilted block, its tip filled.
class _EraserIcon extends StatelessWidget {
  const _EraserIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? RibbonColors.text;
    return Transform.rotate(
      angle: -0.6,
      child: Container(
        width: 18,
        height: 10,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.6),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(children: [Container(width: 6, color: color)]),
      ),
    );
  }
}
