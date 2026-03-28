import 'dart:io';
import 'dart:math' show max, min;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';
import 'web_download_stub.dart'
    if (dart.library.js_interop) 'web_download_web.dart';

class CsvExporter {
  static Future<List<String>?> export(List<TemperatureRecord> records) async {
    if (kIsWeb) {
      return _exportWeb(records);
    } else {
      return _exportMobile(records);
    }
  }

  // ── Web: ブラウザダウンロード ─────────────────────

  static Future<List<String>?> _exportWeb(
      List<TemperatureRecord> records) async {
    final stamp = _stamp();

    await downloadBytesOnWeb(
      _bom + _dataListCsv(records).codeUnits,
      'ondohosei_データ一覧_$stamp.csv',
    );
    await downloadBytesOnWeb(
      _bom +
          _summaryCsv(
            title: '月別　温度差集計',
            records: records,
            keyOf: (r) => '${r.dateTime.year}/${_p(r.dateTime.month)}',
            labelOf: (k) => k,
          ).codeUnits,
      'ondohosei_月別集計_$stamp.csv',
    );
    await downloadBytesOnWeb(
      _bom +
          _summaryCsv(
            title: '製品寸法別　温度差集計',
            records: records,
            keyOf: (r) => r.productSize.toStringAsFixed(0),
            labelOf: (k) => '${k}mm',
          ).codeUnits,
      'ondohosei_寸法別集計_$stamp.csv',
    );
    await downloadBytesOnWeb(
      _bom +
          _summaryCsv(
            title: '50mmグループ別　温度差集計',
            records: records,
            keyOf: (r) {
              final lower = (r.productSize / 50).floor() * 50;
              return '$lower';
            },
            labelOf: (k) => '$k〜${int.parse(k) + 50}mm',
          ).codeUnits,
      'ondohosei_50mmグループ集計_$stamp.csv',
    );
    return ['(ブラウザのダウンロードフォルダに保存されました)'];
  }

  // ── Mobile: ファイル保存 ──────────────────────────

  static Future<List<String>?> _exportMobile(
      List<TemperatureRecord> records) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = _stamp();
    final saved = <String>[];

    Future<void> write(String name, String content) async {
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(_bom + content.codeUnits);
      saved.add(file.path);
    }

    await write('ondohosei_データ一覧_$stamp.csv', _dataListCsv(records));
    await write(
        'ondohosei_月別集計_$stamp.csv',
        _summaryCsv(
          title: '月別　温度差集計',
          records: records,
          keyOf: (r) => '${r.dateTime.year}/${_p(r.dateTime.month)}',
          labelOf: (k) => k,
        ));
    await write(
        'ondohosei_寸法別集計_$stamp.csv',
        _summaryCsv(
          title: '製品寸法別　温度差集計',
          records: records,
          keyOf: (r) => r.productSize.toStringAsFixed(0),
          labelOf: (k) => '${k}mm',
        ));
    await write(
        'ondohosei_50mmグループ集計_$stamp.csv',
        _summaryCsv(
          title: '50mmグループ別　温度差集計',
          records: records,
          keyOf: (r) {
            final lower = (r.productSize / 50).floor() * 50;
            return '$lower';
          },
          labelOf: (k) => '$k〜${int.parse(k) + 50}mm',
        ));
    return saved;
  }

  // ── 共通ユーティリティ ────────────────────────────

  static final List<int> _bom = [0xEF, 0xBB, 0xBF];

  static String _stamp() {
    final now = DateTime.now();
    return '${now.year}${_p(now.month)}${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
  }

  static String _p(int n) => n.toString().padLeft(2, '0');

  static String _q(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

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
