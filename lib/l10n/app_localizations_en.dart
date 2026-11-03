// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get fileMenu => 'File';

  @override
  String get newImage => 'New';

  @override
  String get openImage => 'Open';

  @override
  String get save => 'Save';

  @override
  String get saveAs => 'Save as';

  @override
  String saveAsFormat(String format) {
    return 'Save as $format';
  }

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get minimize => 'Minimize';

  @override
  String get maximize => 'Maximize';

  @override
  String get restore => 'Restore';

  @override
  String get close => 'Close';

  @override
  String get untitled => 'Untitled';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get copy => 'Copy';

  @override
  String get cut => 'Cut';

  @override
  String get paste => 'Paste';

  @override
  String get selectAll => 'Select all';

  @override
  String get deleteSelection => 'Delete selection';

  @override
  String get crop => 'Crop';

  @override
  String get resize => 'Resize';

  @override
  String get rotateLeft => 'Rotate left';

  @override
  String get rotateRight => 'Rotate right';

  @override
  String get flipHorizontal => 'Flip horizontally';

  @override
  String get flipVertical => 'Flip vertically';

  @override
  String get clipboardGroup => 'Clipboard';

  @override
  String get imageGroup => 'Image';

  @override
  String get toolsGroup => 'Tools';

  @override
  String get shapesGroup => 'Shapes';

  @override
  String get sizeGroup => 'Size';

  @override
  String get colorsGroup => 'Colors';

  @override
  String get toolSelect => 'Select';

  @override
  String get toolPencil => 'Pencil';

  @override
  String get toolBrush => 'Brush';

  @override
  String get toolEraser => 'Eraser';

  @override
  String get toolFill => 'Fill with color';

  @override
  String get toolPicker => 'Color picker';

  @override
  String get toolLine => 'Line';

  @override
  String get toolRectangle => 'Rectangle';

  @override
  String get toolEllipse => 'Ellipse';

  @override
  String get shapeOutline => 'Outline';

  @override
  String get shapeFilled => 'Filled';

  @override
  String get color1 => 'Color 1';

  @override
  String get color2 => 'Color 2';

  @override
  String get color1Hint => 'Color 1: the left click paints with it';

  @override
  String get color2Hint =>
      'Color 2: the right click and the eraser paint with it';

  @override
  String get swapColors => 'Swap colors';

  @override
  String get editColors => 'Edit colors';

  @override
  String get editColorTitle => 'Edit color';

  @override
  String get red => 'Red';

  @override
  String get green => 'Green';

  @override
  String get blue => 'Blue';

  @override
  String get hexColor => 'Hex';

  @override
  String sizePixels(int size) {
    return '$size px';
  }

  @override
  String get brushSize => 'Size of the pencil, brush, eraser and shapes';

  @override
  String get newImageTitle => 'New image';

  @override
  String get width => 'Width';

  @override
  String get height => 'Height';

  @override
  String get pixelsUnit => 'px';

  @override
  String get create => 'Create';

  @override
  String get resizeTitle => 'Resize image';

  @override
  String get keepProportions => 'Keep proportions';

  @override
  String get stretchDrawing => 'Stretch the drawing';

  @override
  String get stretchDrawingHint =>
      'Off: only the canvas grows or shrinks, and the drawing stays the same size.';

  @override
  String sizeLimit(int max) {
    return 'Between 1 and $max px.';
  }

  @override
  String get apply => 'Apply';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveChangesTitle => 'Save changes?';

  @override
  String saveChangesMessage(String name) {
    return 'Do you want to save the changes to \"$name\"?';
  }

  @override
  String get dontSave => 'Don\'t save';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get openImageTitle => 'Open image';

  @override
  String get saveImageTitle => 'Save image';

  @override
  String get openFailed => 'This file could not be opened as an image.';

  @override
  String get saveFailed => 'The image could not be saved.';

  @override
  String imageTooLarge(int max) {
    return 'This image is too large. The limit is $max px per side.';
  }

  @override
  String get nothingToPaste => 'There is no image to paste.';

  @override
  String get copyFailed => 'The image could not be copied.';

  @override
  String flattenedWarning(String format) {
    return '$format has no transparency: the transparent parts were saved as white.';
  }

  @override
  String cursorPosition(int x, int y) {
    return '$x, $y px';
  }

  @override
  String imageSize(int width, int height) {
    return '$width × $height px';
  }

  @override
  String selectionSize(int width, int height) {
    return 'Selection: $width × $height px';
  }

  @override
  String get zoom => 'Zoom';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get fitToWindow => 'Fit to window';
}
