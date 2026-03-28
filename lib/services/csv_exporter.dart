import 'dart:io';
import 'dart:math' show max, min;
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

class CsvExporter {
  static Future<List<String>?> export(List<TemperatureRecord> records) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) return null;
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    final now = DateTime.now();
    final stamp =
        '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';

    final saved = <String>[];

    // ① データ一覧
    final dataFile = File('${downloadsDir.path}/ondohosei_データ一覧_$stamp.csv');
    await dataFile.writeAsBytes(_bom + _dataListCsv(records).codeUnits);
    saved.add(dataFile.path);

    // ② 月別集計
    final monthFile = File('${downloadsDir.path}/ondohosei_月別集計_$stamp.csv');
    await monthFile.writeAsBytes(_bom +
        _summaryCsv(
          title: '月別　温度差集計',
          records: records,
          keyOf: (r) =>
              '${r.dateTime.year}/${_p(r.dateTime.month)}',
          labelOf: (k) => k,
        ).codeUnits);
    saved.add(monthFile.path);

    // ③ 寸法別集計
    final sizeFile =
        File('${downloadsDir.path}/ondohosei_寸法別集計_$stamp.csv');
    await sizeFile.writeAsBytes(_bom +
        _summaryCsv(
          title: '製品寸法別　温度差集計',
          records: records,
          keyOf: (r) => r.productSize.toStringAsFixed(0),
          labelOf: (k) => '${k}mm',
        ).codeUnits);
    saved.add(sizeFile.path);

    // ④ 50mmグループ集計
    final groupFile =
        File('${downloadsDir.path}/ondohosei_50mmグループ集計_$stamp.csv');
    await groupFile.writeAsBytes(_bom +
        _summaryCsv(
          title: '50mmグループ別　温度差集計',
          records: records,
          keyOf: (r) {
            final lower = (r.productSize / 50).floor() * 50;
            return '$lower';
          },
          labelOf: (k) => '$k〜${int.parse(k) + 50}mm',
        ).codeUnits);
    saved.add(groupFile.path);

    return saved;
  }

  // UTF-8 BOM（Excelで文字化けしないように）
  static final List<int> _bom = [0xEF, 0xBB, 0xBF];

  static String _p(int n) => n.toString().padLeft(2, '0');

  static String _q(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ── データ一覧CSV ────────────────────────────────

  static String _dataListCsv(List<TemperatureRecord> records) {
    final buf = StringBuffer();
    buf.writeln('No,日時,製品寸法(mm),模範温度(°C),製品温度(°C),温度差(°C),補正量(mm),異常');

    final sorted = [...records]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    for (var i = 0; i < sorted.length; i++) {
      final r = sorted[i];
      final dt =
          '${r.dateTime.year}/${_p(r.dateTime.month)}/${_p(r.dateTime.day)} '
          '${_p(r.dateTime.hour)}:${_p(r.dateTime.minute)}';
      buf.writeln([
        '${i + 1}',
        _q(dt),
        r.productSize.toStringAsFixed(2),
        r.masterTemp.toStringAsFixed(2),
        r.workTemp.toStringAsFixed(2),
        r.tempDiff.toStringAsFixed(4),
        r.correctionValue.toStringAsFixed(4),
        r.isAbnormal ? '要確認' : '',
      ].join(','));
    }
    return buf.toString();
  }

  // ── 集計CSV ─────────────────────────────────────

  static String _summaryCsv({
    required String title,
    required List<TemperatureRecord> records,
    required String Function(TemperatureRecord) keyOf,
    required String Function(String) labelOf,
  }) {
    final buf = StringBuffer();
    buf.writeln(_q(title));
    buf.writeln('区分,件数,平均 温度差(°C),最大(°C),最小(°C),標準偏差');

    final Map<String, List<double>> grouped = {};
    for (final r in records) {
      grouped.putIfAbsent(keyOf(r), () => []).add(r.tempDiff);
    }
    final keys = grouped.keys.toList()..sort();

    for (final k in keys) {
      final diffs = grouped[k]!;
      final avg = diffs.reduce((a, b) => a + b) / diffs.length;
      final maxVal = diffs.fold(diffs[0], (m, v) => max(m, v));
      final minVal = diffs.fold(diffs[0], (m, v) => min(m, v));
      final variance =
          diffs.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
              diffs.length;
      final sd = _sqrt(variance);

      buf.writeln([
        _q(labelOf(k)),
        '${diffs.length}',
        avg.toStringAsFixed(4),
        maxVal.toStringAsFixed(4),
        minVal.toStringAsFixed(4),
        sd.toStringAsFixed(4),
      ].join(','));
    }
    return buf.toString();
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) {
      r = (r + x / r) / 2;
    }
    return r;
  }
}
