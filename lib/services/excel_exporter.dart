import 'dart:io';
import 'dart:math' show max, min;
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

class ExcelExporter {
  // ヘッダー行のスタイル
  static CellStyle _headerStyle(String bgHex) => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(bgHex),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle _subHeaderStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D9E1F2'),
        horizontalAlign: HorizontalAlign.Center,
      );

  static Future<String?> export(List<TemperatureRecord> records) async {
    // Android 9 以下はストレージ権限が必要
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) return null;
    }

    final excel = Excel.createExcel();
    // デフォルトシートを削除
    excel.delete('Sheet1');

    _buildDataSheet(excel, records);
    _buildMonthlySheet(excel, records);
    _buildSizeSheet(excel, records);
    _buildGroupSheet(excel, records);

    final bytes = excel.encode();
    if (bytes == null) return null;

    // ダウンロードフォルダに保存
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    final now = DateTime.now();
    final stamp =
        '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
    final file = File('${downloadsDir.path}/ondohosei_$stamp.xlsx');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static String _p(int n) => n.toString().padLeft(2, '0');

  // ── Sheet1: データ一覧 ───────────────────────────

  static void _buildDataSheet(Excel excel, List<TemperatureRecord> records) {
    final sheet = excel['データ一覧'];
    const headers = [
      'No', '日時', '製品寸法(mm)', '模範温度(°C)',
      '製品温度(°C)', '温度差(°C)', '補正量(mm)', '異常',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = _headerStyle('#2E5DA8');
    }

    final sorted = [...records]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final row = i + 1;
      _setCell(sheet, 0, row, IntCellValue(i + 1));
      _setCell(
          sheet,
          1,
          row,
          TextCellValue(
              '${r.dateTime.year}/${_p(r.dateTime.month)}/${_p(r.dateTime.day)} '
              '${_p(r.dateTime.hour)}:${_p(r.dateTime.minute)}'));
      _setCell(sheet, 2, row, DoubleCellValue(r.productSize));
      _setCell(sheet, 3, row, DoubleCellValue(r.masterTemp));
      _setCell(sheet, 4, row, DoubleCellValue(r.workTemp));
      _setCell(sheet, 5, row, DoubleCellValue(r.tempDiff));
      _setCell(sheet, 6, row, DoubleCellValue(r.correctionValue));
      _setCell(sheet, 7, row,
          TextCellValue(r.isAbnormal ? '⚠ 要確認' : ''));
    }
  }

  // ── Sheet2: 月別集計 ─────────────────────────────

  static void _buildMonthlySheet(
      Excel excel, List<TemperatureRecord> records) {
    final sheet = excel['月別集計'];
    _writeSummary(
      sheet,
      title: '月別　温度差集計',
      headerColor: '#1D6B2E',
      records: records,
      keyOf: (r) =>
          '${r.dateTime.year}/${_p(r.dateTime.month)}',
      labelOf: (k) => k,
    );
  }

  // ── Sheet3: 寸法別集計 ───────────────────────────

  static void _buildSizeSheet(Excel excel, List<TemperatureRecord> records) {
    final sheet = excel['寸法別集計'];
    _writeSummary(
      sheet,
      title: '製品寸法別　温度差集計',
      headerColor: '#7B3F00',
      records: records,
      keyOf: (r) => r.productSize.toStringAsFixed(0),
      labelOf: (k) => '${k}mm',
    );
  }

  // ── Sheet4: 50mmグループ集計 ─────────────────────

  static void _buildGroupSheet(Excel excel, List<TemperatureRecord> records) {
    final sheet = excel['50mmグループ集計'];
    _writeSummary(
      sheet,
      title: '50mmグループ別　温度差集計',
      headerColor: '#6A1A6A',
      records: records,
      keyOf: (r) {
        final lower = (r.productSize / 50).floor() * 50;
        return '$lower';
      },
      labelOf: (k) => '$k〜${int.parse(k) + 50}mm',
    );
  }

  // ── 共通：集計シート書き込み ─────────────────────

  static void _writeSummary(
    Sheet sheet, {
    required String title,
    required String headerColor,
    required List<TemperatureRecord> records,
    required String Function(TemperatureRecord) keyOf,
    required String Function(String) labelOf,
  }) {
    // タイトル行
    final titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(title);
    titleCell.cellStyle = CellStyle(
        bold: true, fontSize: 13, fontColorHex: ExcelColor.fromHexString('#2E3A4B'));

    // ヘッダー行
    const headers = ['区分', '件数', '平均 温度差(°C)', '最大(°C)', '最小(°C)', '標準偏差'];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = _subHeaderStyle();
    }

    // 集計
    final Map<String, List<double>> grouped = {};
    for (final r in records) {
      grouped.putIfAbsent(keyOf(r), () => []).add(r.tempDiff);
    }
    final keys = grouped.keys.toList()..sort();

    for (var i = 0; i < keys.length; i++) {
      final k = keys[i];
      final diffs = grouped[k]!;
      final avg = diffs.reduce((a, b) => a + b) / diffs.length;
      final maxVal = diffs.fold(diffs[0], (m, v) => max(m, v));
      final minVal = diffs.fold(diffs[0], (m, v) => min(m, v));
      final variance =
          diffs.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
              diffs.length;
      final stdDev = variance == 0 ? 0.0 : variance;
      // sqrt を避けるため dart:math は import 済み
      final sd = _sqrt(stdDev);

      final row = i + 2;
      _setCell(sheet, 0, row, TextCellValue(labelOf(k)));
      _setCell(sheet, 1, row, IntCellValue(diffs.length));
      _setCell(sheet, 2, row,
          DoubleCellValue(double.parse(avg.toStringAsFixed(4))));
      _setCell(sheet, 3, row,
          DoubleCellValue(double.parse(maxVal.toStringAsFixed(4))));
      _setCell(sheet, 4, row,
          DoubleCellValue(double.parse(minVal.toStringAsFixed(4))));
      _setCell(sheet, 5, row,
          DoubleCellValue(double.parse(sd.toStringAsFixed(4))));
    }
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) {
      r = (r + x / r) / 2;
    }
    return r;
  }

  static void _setCell(Sheet sheet, int col, int row, CellValue value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = value;
  }
}
