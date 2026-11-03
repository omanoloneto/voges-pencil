# Voges Pencil

A simple paint program for the desktop, in the spirit of the classic Paint: draw, fill, cut and paste, and save as PNG, JPEG or BMP. Part of the Voges suite, next to [Voges Word](https://github.com/omanoloneto/voges-word). Built with Flutter for macOS, Windows and Linux.

## What it does

- **Tools:** pencil (hard pixels), brush (soft round edges), eraser, fill with color, color picker, line, rectangle and ellipse. Shapes can be outlined or filled; holding Shift keeps lines at multiples of 45° and makes rectangles and ellipses square and round.
- **Sizes:** 1 to 48 px for the pencil, brush, eraser and shapes.
- **Two colors:** the left click paints with color 1, the right click with color 2, and the eraser paints color 2. A palette of 20 colors (left click sets color 1, right click color 2), a swap button and an editor with red, green and blue sliders and a hex field.
- **Selection:** select an area, drag it to move it (the place it leaves gets color 2), delete it, crop the image to it, or select everything.
- **Clipboard:** copy and cut the selection (or the whole image) and paste images from other apps. A pasted image bigger than the canvas grows the canvas. On Linux, copying only reaches Voges Pencil itself; pasting from other apps works.
- **Image:** rotate left and right, flip horizontally and vertically, and resize, either stretching the drawing or only changing the canvas.
- **Files:** opens PNG, JPEG, BMP, GIF, WebP, TIFF, ICO and TGA; saves PNG (with transparency), JPEG and BMP. JPEG and BMP have no transparency, so transparent parts are saved as white, and the app says so. GIF, WebP and the other formats it can't write are saved as a new PNG, never over the original.
- Undo and redo for every change, zoom from 5% to 3200% (Ctrl or ⌘ with the mouse wheel, a pinch on the trackpad, or the status bar), with sharp pixels from 100% up.
- The status bar shows the pixel under the mouse, the image size and the selection size.
- Warns before closing or opening another file with unsaved changes.
- macOS "Open with" for every format it opens, without becoming the default app. A file path can also be passed on the command line.
- Interface in English, Portuguese and Spanish. It follows the system language, and you can pick another one in the File menu.

## Shortcuts

Ctrl on Windows and Linux, ⌘ on the Mac.

| Keys | Action |
| --- | --- |
| Ctrl+N, Ctrl+O, Ctrl+S, Ctrl+Shift+S | New, open, save, save as |
| Ctrl+Z, Ctrl+Y (or Ctrl+Shift+Z) | Undo, redo |
| Ctrl+C, Ctrl+X, Ctrl+V | Copy, cut, paste |
| Ctrl+A | Select all |
| Delete or Backspace | Delete the selection |
| Esc | Drop the selection |
| Ctrl+=, Ctrl+-, Ctrl+0 | Zoom in, zoom out, 100% |

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

- `lib/painting/` is plain Dart with no Flutter: the pixel buffer, the flood fill and the file formats.
- `lib/canvas/` holds the image and its history (`PaintDocument`), the tools (`PaintController`, which works in image pixels) and the widget that turns pointer events into tool calls (`CanvasView`).
- `lib/editor/` is the screen: ribbon, status bar, File panel and dialogs. `lib/shell/` has the window chrome shared in look with Voges Word.
- Strings live in `lib/l10n/app_*.arb`.
