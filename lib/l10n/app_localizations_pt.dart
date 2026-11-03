// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get fileMenu => 'Arquivo';

  @override
  String get newImage => 'Novo';

  @override
  String get openImage => 'Abrir';

  @override
  String get save => 'Salvar';

  @override
  String get saveAs => 'Salvar como';

  @override
  String saveAsFormat(String format) {
    return 'Salvar como $format';
  }

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma do sistema';

  @override
  String get minimize => 'Minimizar';

  @override
  String get maximize => 'Maximizar';

  @override
  String get restore => 'Restaurar';

  @override
  String get close => 'Fechar';

  @override
  String get untitled => 'Sem título';

  @override
  String get undo => 'Desfazer';

  @override
  String get redo => 'Refazer';

  @override
  String get copy => 'Copiar';

  @override
  String get cut => 'Recortar';

  @override
  String get paste => 'Colar';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get deleteSelection => 'Apagar seleção';

  @override
  String get crop => 'Cortar';

  @override
  String get resize => 'Redimensionar';

  @override
  String get rotateLeft => 'Girar para a esquerda';

  @override
  String get rotateRight => 'Girar para a direita';

  @override
  String get flipHorizontal => 'Espelhar na horizontal';

  @override
  String get flipVertical => 'Espelhar na vertical';

  @override
  String get clipboardGroup => 'Área de transferência';

  @override
  String get imageGroup => 'Imagem';

  @override
  String get toolsGroup => 'Ferramentas';

  @override
  String get shapesGroup => 'Formas';

  @override
  String get sizeGroup => 'Tamanho';

  @override
  String get colorsGroup => 'Cores';

  @override
  String get toolSelect => 'Selecionar';

  @override
  String get toolPencil => 'Lápis';

  @override
  String get toolBrush => 'Pincel';

  @override
  String get toolEraser => 'Borracha';

  @override
  String get toolFill => 'Balde de tinta';

  @override
  String get toolPicker => 'Conta-gotas';

  @override
  String get toolLine => 'Linha';

  @override
  String get toolRectangle => 'Retângulo';

  @override
  String get toolEllipse => 'Elipse';

  @override
  String get shapeOutline => 'Contorno';

  @override
  String get shapeFilled => 'Preenchida';

  @override
  String get color1 => 'Cor 1';

  @override
  String get color2 => 'Cor 2';

  @override
  String get color1Hint => 'Cor 1: o clique esquerdo pinta com ela';

  @override
  String get color2Hint =>
      'Cor 2: o clique direito e a borracha pintam com ela';

  @override
  String get swapColors => 'Trocar as cores';

  @override
  String get editColors => 'Editar cores';

  @override
  String get editColorTitle => 'Editar cor';

  @override
  String get red => 'Vermelho';

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
      'Tamanho do lápis, do pincel, da borracha e das formas';

  @override
  String get newImageTitle => 'Nova imagem';

  @override
  String get width => 'Largura';

  @override
  String get height => 'Altura';

  @override
  String get pixelsUnit => 'px';

  @override
  String get create => 'Criar';

  @override
  String get resizeTitle => 'Redimensionar imagem';

  @override
  String get keepProportions => 'Manter as proporções';

  @override
  String get stretchDrawing => 'Esticar o desenho';

  @override
  String get stretchDrawingHint =>
      'Desligado: só a tela cresce ou diminui, e o desenho fica do mesmo tamanho.';

  @override
  String sizeLimit(int max) {
    return 'Entre 1 e $max px.';
  }

  @override
  String get apply => 'Aplicar';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get saveChangesTitle => 'Salvar as alterações?';

  @override
  String saveChangesMessage(String name) {
    return 'Quer salvar as alterações em \"$name\"?';
  }

  @override
  String get dontSave => 'Não salvar';

  @override
  String get unsavedChanges => 'Alterações não salvas';

  @override
  String get openImageTitle => 'Abrir imagem';

  @override
  String get saveImageTitle => 'Salvar imagem';

  @override
  String get openFailed => 'Não foi possível abrir este arquivo como imagem.';

  @override
  String get saveFailed => 'Não foi possível salvar a imagem.';

  @override
  String imageTooLarge(int max) {
    return 'Esta imagem é grande demais. O limite é $max px por lado.';
  }

  @override
  String get nothingToPaste => 'Não há imagem para colar.';

  @override
  String get copyFailed => 'Não foi possível copiar a imagem.';

  @override
  String flattenedWarning(String format) {
    return '$format não tem transparência: as partes transparentes foram salvas em branco.';
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
    return 'Seleção: $width × $height px';
  }

  @override
  String get zoom => 'Zoom';

  @override
  String get zoomIn => 'Aumentar o zoom';

  @override
  String get zoomOut => 'Diminuir o zoom';

  @override
  String get fitToWindow => 'Ajustar à janela';
}
