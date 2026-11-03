// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get fileMenu => 'Archivo';

  @override
  String get newImage => 'Nuevo';

  @override
  String get openImage => 'Abrir';

  @override
  String get save => 'Guardar';

  @override
  String get saveAs => 'Guardar como';

  @override
  String saveAsFormat(String format) {
    return 'Guardar como $format';
  }

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del sistema';

  @override
  String get minimize => 'Minimizar';

  @override
  String get maximize => 'Maximizar';

  @override
  String get restore => 'Restaurar';

  @override
  String get close => 'Cerrar';

  @override
  String get untitled => 'Sin título';

  @override
  String get undo => 'Deshacer';

  @override
  String get redo => 'Rehacer';

  @override
  String get copy => 'Copiar';

  @override
  String get cut => 'Cortar';

  @override
  String get paste => 'Pegar';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get deleteSelection => 'Borrar selección';

  @override
  String get crop => 'Recortar';

  @override
  String get resize => 'Cambiar tamaño';

  @override
  String get rotateLeft => 'Girar a la izquierda';

  @override
  String get rotateRight => 'Girar a la derecha';

  @override
  String get flipHorizontal => 'Voltear horizontalmente';

  @override
  String get flipVertical => 'Voltear verticalmente';

  @override
  String get clipboardGroup => 'Portapapeles';

  @override
  String get imageGroup => 'Imagen';

  @override
  String get toolsGroup => 'Herramientas';

  @override
  String get shapesGroup => 'Formas';

  @override
  String get sizeGroup => 'Tamaño';

  @override
  String get colorsGroup => 'Colores';

  @override
  String get toolSelect => 'Seleccionar';

  @override
  String get toolPencil => 'Lápiz';

  @override
  String get toolBrush => 'Pincel';

  @override
  String get toolEraser => 'Borrador';

  @override
  String get toolFill => 'Relleno con color';

  @override
  String get toolPicker => 'Selector de color';

  @override
  String get toolLine => 'Línea';

  @override
  String get toolRectangle => 'Rectángulo';

  @override
  String get toolEllipse => 'Elipse';

  @override
  String get shapeOutline => 'Contorno';

  @override
  String get shapeFilled => 'Rellena';

  @override
  String get color1 => 'Color 1';

  @override
  String get color2 => 'Color 2';

  @override
  String get color1Hint => 'Color 1: el clic izquierdo pinta con él';

  @override
  String get color2Hint =>
      'Color 2: el clic derecho y el borrador pintan con él';

  @override
  String get swapColors => 'Intercambiar colores';

  @override
  String get editColors => 'Editar colores';

  @override
  String get editColorTitle => 'Editar color';

  @override
  String get red => 'Rojo';

  @override
  String get green => 'Verde';

  @override
  String get blue => 'Azul';

  @override
  String get hexColor => 'Hex';

  @override
  String sizePixels(int size) {
    return '$size px';
  }

  @override
  String get brushSize =>
      'Tamaño del lápiz, el pincel, el borrador y las formas';

  @override
  String get newImageTitle => 'Nueva imagen';

  @override
  String get width => 'Ancho';

  @override
  String get height => 'Alto';

  @override
  String get pixelsUnit => 'px';

  @override
  String get create => 'Crear';

  @override
  String get resizeTitle => 'Cambiar tamaño de la imagen';

  @override
  String get keepProportions => 'Mantener las proporciones';

  @override
  String get stretchDrawing => 'Estirar el dibujo';

  @override
  String get stretchDrawingHint =>
      'Desactivado: solo el lienzo crece o se reduce, y el dibujo queda del mismo tamaño.';

  @override
  String sizeLimit(int max) {
    return 'Entre 1 y $max px.';
  }

  @override
  String get apply => 'Aplicar';

  @override
  String get ok => 'Aceptar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get saveChangesTitle => '¿Guardar los cambios?';

  @override
  String saveChangesMessage(String name) {
    return '¿Quieres guardar los cambios en \"$name\"?';
  }

  @override
  String get dontSave => 'No guardar';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get openImageTitle => 'Abrir imagen';

  @override
  String get saveImageTitle => 'Guardar imagen';

  @override
  String get openFailed => 'No se pudo abrir este archivo como imagen.';

  @override
  String get saveFailed => 'No se pudo guardar la imagen.';

  @override
  String imageTooLarge(int max) {
    return 'Esta imagen es demasiado grande. El límite es $max px por lado.';
  }

  @override
  String get nothingToPaste => 'No hay ninguna imagen para pegar.';

  @override
  String get copyFailed => 'No se pudo copiar la imagen.';

  @override
  String flattenedWarning(String format) {
    return '$format no tiene transparencia: las partes transparentes se guardaron en blanco.';
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
    return 'Selección: $width × $height px';
  }

  @override
  String get zoom => 'Zoom';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get fitToWindow => 'Ajustar a la ventana';
}
