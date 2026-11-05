# Voges Pencil

A simple paint program for the desktop, in the spirit of the classic Paint: draw, fill, cut and paste, and save as PNG, JPEG or BMP. Part of the Voges suite, next to [Voges Word](https://github.com/omanoloneto/voges-word). Built with Flutter for macOS, Windows and Linux.

## Install

The installers are in the [latest release](https://github.com/omanoloneto/voges-pencil/releases/latest) and on the [omanoloneto.pro/voges/pencil](https://omanoloneto.pro/voges/pencil/) page.

- **macOS** 10.15 or newer, Apple Silicon and Intel: [`VogesPencil-macos.dmg`](https://github.com/omanoloneto/voges-pencil/releases/latest/download/VogesPencil-macos.dmg). Open it and drag Voges Pencil to Applications. The app is not notarized by Apple; the first time, allow it in System Settings → Privacy & Security → Open Anyway.
- **Windows** 10 or 11, 64-bit: [`VogesPencil-windows-setup.exe`](https://github.com/omanoloneto/voges-pencil/releases/latest/download/VogesPencil-windows-setup.exe). It installs without administrator rights and shows up in "Open with" for every format it opens (`.png`, `.jpg`, `.jpeg`, `.bmp`, `.gif`, `.webp`, `.tif`, `.tiff`, `.ico` and `.tga`), without becoming the default program. If SmartScreen warns you, click "More info" and then "Run anyway".
- **Linux** (Ubuntu 22.04, Debian 12 or newer and derivatives, 64-bit): [`voges-pencil-linux-amd64.deb`](https://github.com/omanoloneto/voges-pencil/releases/latest/download/voges-pencil-linux-amd64.deb), then `sudo apt install ./voges-pencil-linux-amd64.deb`.

`SHA256SUMS.txt` in each release lists the SHA-256 of every installer, and `SHA256SUMS.txt.sig` is its signature.

### Updates

Voges Pencil checks for a new version every time it opens and says in the status bar whether it is up to date. When there is an update, clicking it asks about unsaved changes, closes the app and opens **Voges Updater**, which lists every installed app of the Voges suite that has an update; update all of them or only some. When it finishes, Voges Pencil opens again.

- The check reads the number of the latest release from github.com; nothing about you or your images is sent.
- Every update is verified before it is installed: its files must match the `SHA256SUMS.txt` of the release, and that file must carry the Ed25519 signature of the project's key, which is built into the app. A download that doesn't match is never installed.
- **macOS:** the updater replaces the app in its folder; if your account can't write to it, it puts the verified `.dmg` in Downloads for you to install. Voges Pencil stays sandboxed: the updater is a separate app inside it (`Contents/Helpers/Voges Updater.app`).
- **Windows:** the installer runs silently; installs for all users ask for administrator permission.
- **Linux:** the update is installed with `apt`, after the system asks for your password (polkit). Without a password window, the updater shows the command to run in a terminal.

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
- The system's "Open with" for every format it opens, on macOS and, through the installers, Windows and Linux, without becoming the default app. A file path can also be passed on the command line.
- Updates itself on macOS, Windows and Linux: the status bar shows when a new version exists (see [Updates](#updates)).
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
- Updates come from the `voges_updater` package of [Voges Word](https://github.com/omanoloneto/voges-word/tree/main/packages/voges_updater), a git dependency pinned to a commit in `pubspec.yaml` and `pubspec.lock`; get the packages with `flutter pub get --enforce-lockfile` to use the locked commit.

## Releases

1. Set the new `version` in `pubspec.yaml` and write `packaging/release-notes.md`.
2. Push a `vX.Y.Z` tag with the same version. `.github/workflows/release.yml` builds the three installers (the macOS one with Voges Updater embedded) and creates a draft release with them and `SHA256SUMS.txt`.
3. Sign and publish the draft on the owner's Mac, from a Voges Word checkout:

   ```sh
   cd packages/voges_updater
   dart run tool/release_signing.dart publish omanoloneto/voges-pencil vX.Y.Z --clone <path to the voges-pencil clone>
   ```

Release builds pass `--dart-define=VOGES_VERSION=<version>`; without it, as in `flutter run`, the update indicator stays hidden.
