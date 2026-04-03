import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_helper.dart';
import '../services/csv_exporter.dart';
import '../services/excel_exporter.dart';
import '../services/app_localizations.dart';
import '../widgets/numeric_keypad.dart';

// ══════════════════════════════════════════
//  StatsScreen
// ══════════════════════════════════════════

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // データ変更を両タブへ通知するノーティファイア
  final _refreshNotifier = ValueNotifier<int>(0);

  void _onDataChanged() => _refreshNotifier.value++;

  void _showHelp(BuildContext context) {
    final tr = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.help_outline, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(tr('helpStatsTitle'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),

            _helpSection(tr('helpGraphSection'), Icons.bar_chart, [
              _helpItem(tr('helpGraphMode'), tr('helpGraphModeDesc')),
              _helpItem(tr('helpGraphColor'), tr('helpGraphColorDesc')),
              _helpItem(tr('helpGraphTap'), tr('helpGraphTapDesc')),
              _helpItem(tr('helpGraphTable'), tr('helpGraphTableDesc')),
              _helpItem(tr('helpGraphAvg'), tr('helpGraphAvgDesc')),
              _helpItem(tr('helpGraphSort'), tr('helpGraphSortDesc')),
            ]),
            const SizedBox(height: 16),

            _helpSection(tr('helpDataSection'), Icons.list_alt, [
              _helpItem(tr('helpDataAbnormal'), tr('helpDataAbnormalDesc')),
              _helpItem(tr('helpDataEdit'), tr('helpDataEditDesc')),
              _helpItem(tr('helpDataDelete'), tr('helpDataDeleteDesc')),
            ]),
            const SizedBox(height: 16),

            _helpSection(tr('helpCategorySection'), Icons.playlist_remove, [
              _helpItem(tr('helpGraphMode'), tr('helpCategoryDesc')),
              _helpItem(tr('helpCategoryNote'), tr('helpCategoryNoteDesc')),
            ]),
            const SizedBox(height: 16),

            _helpSection(tr('helpDeleteAllSection'), Icons.delete_sweep, [
              _helpItem(tr('helpGraphMode'), tr('helpDeleteAllDesc')),
              _helpItem(tr('helpDeleteAllNote'), tr('helpDeleteAllNoteDesc')),
            ]),
            const SizedBox(height: 16),

            _helpSection(tr('helpExportSection'), Icons.file_download_outlined, [
              _helpItem(tr('helpGraphMode'), tr('helpExportDesc')),
              _helpItem(tr('helpExportCsv'), tr('helpExportCsvDesc')),
              _helpItem(tr('helpExportExcel'), tr('helpExportExcelDesc')),
              _helpItem(tr('helpExportSave'), tr('helpExportSaveDesc')),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _helpSection(String title, IconData icon, List<Widget> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: Colors.blueGrey[400]!, width: 3)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.blueGrey[600]),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800])),
        ]),
      ),
      const SizedBox(height: 8),
      ...items,
      const SizedBox(height: 4),
    ]);
  }

  Widget _helpItem(String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('・ ', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(description,
                style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5)),
          ]),
        ),
      ]),
    );
  }

  Future<void> _exportToExcel(BuildContext context) async {
    final tr = AppLocalizations.of(context);
    final records = await DatabaseHelper.instance.getAll();
    if (!context.mounted) return;

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('noData'))),
      );
      return;
    }

    final format = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.file_download_outlined, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(tr('exportTitle')),
        ]),
        content: Text(tr('exportDesc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('dialogCancel')),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.grid_on, size: 18),
            label: Text(tr('csvLabel')),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, 'csv'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.table_chart, size: 18),
            label: Text(tr('excelLabel')),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, 'xlsx'),
          ),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 12),
          Text(format == 'csv' ? tr('creatingCsv') : tr('creatingExcel')),
        ]),
        duration: const Duration(seconds: 15),
      ),
    );

    String? resultMessage;
    bool success = false;

    if (format == 'csv') {
      final paths = await CsvExporter.export(records);
      success = paths != null;
      if (paths != null) resultMessage = tr('exportSuccess').replaceAll('{n}', '${paths.length}');
    } else {
      final path = await ExcelExporter.export(records);
      success = path != null;
      if (path != null) resultMessage = path.split('/').last;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? resultMessage! : tr('exportFail')),
        backgroundColor: success ? Colors.green[700] : Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _confirmResetAll(BuildContext context) async {
    final tr = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Text(tr('deleteAllTitle')),
        ]),
        content: Text(tr('deleteAllMsg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('dialogCancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('deleteBtn')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteAll();
      _onDataChanged();
    }
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('statsTitle'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: tr('howToUse'),
              onPressed: () => _showHelp(context),
            ),
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: tr('export'),
              onPressed: () => _exportToExcel(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: tr('deleteAllBtn'),
              onPressed: () => _confirmResetAll(context),
            ),
          ],
          bottom: TabBar(
            tabAlignment: TabAlignment.fill,
            indicatorWeight: 2,
            labelPadding: const EdgeInsets.symmetric(vertical: 6),
            tabs: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bar_chart, size: 16),
                const SizedBox(width: 4),
                Text(tr('tabGraph'), style: const TextStyle(fontSize: 12)),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.list_alt, size: 16),
                const SizedBox(width: 4),
                Text(tr('tabData'), style: const TextStyle(fontSize: 12)),
              ]),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GraphTab(refreshNotifier: _refreshNotifier),
            _DataListTab(onDataChanged: _onDataChanged, refreshNotifier: _refreshNotifier),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  グラフタブ
// ══════════════════════════════════════════

class _GraphTab extends StatefulWidget {
  final ValueNotifier<int> refreshNotifier;
  const _GraphTab({required this.refreshNotifier});
  @override
  State<_GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<_GraphTab>
    with AutomaticKeepAliveClientMixin {
  List<TemperatureRecord> _records = [];
  bool _loading = true;
  int _mode = 0; // 0:月別  1:寸法別  2:50mmグループ
  int _sortCol = 0;   // 0:区分  1:件数  2:平均  3:最大  4:最小
  bool _sortAsc = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records = await DatabaseHelper.instance.getAll();
    if (mounted) {
      setState(() {
        _records = records;
        _loading = false;
      });
    }
  }

  // ── 集計 ───────────────────────────────

  List<_ChartData> _buildChartData() {
    if (_records.isEmpty) return [];
    return switch (_mode) {
      0 => _buildMonthlyData(),
      1 => _buildSizeData(),
      _ => _buildGroupData(),
    };
  }

  List<_ChartData> _buildMonthlyData() {
    final Map<String, List<double>> grouped = {};
    for (final r in _records) {
      final key =
          '${r.dateTime.year}-${r.dateTime.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r.tempDiff);
    }
    final keys = grouped.keys.toList()..sort();
    final recent = keys.length > 12 ? keys.sublist(keys.length - 12) : keys;
    return recent.map((k) {
      final parts = k.split('-');
      return _ChartData.from(
          '${parts[0]}/${int.parse(parts[1])}', k, grouped[k]!);
    }).toList();
  }

  List<_ChartData> _buildSizeData() {
    final Map<double, List<double>> grouped = {};
    for (final r in _records) {
      grouped.putIfAbsent(r.productSize, () => []).add(r.tempDiff);
    }
    final keys = grouped.keys.toList()..sort();
    return keys
        .map((k) => _ChartData.from(k.toStringAsFixed(0), k.toStringAsFixed(0), grouped[k]!))
        .toList();
  }

  List<_ChartData> _buildGroupData() {
    final Map<int, List<double>> grouped = {};
    for (final r in _records) {
      final lower = (r.productSize / 50).floor() * 50;
      grouped.putIfAbsent(lower, () => []).add(r.tempDiff);
    }
    final keys = grouped.keys.toList()..sort();
    return keys
        .map((k) => _ChartData.from('$k〜\n${k + 50}', '$k', grouped[k]!))
        .toList();
  }

  // ── 区分削除 ───────────────────────────

  String _keyForRecord(TemperatureRecord r) {
    return switch (_mode) {
      0 => '${r.dateTime.year}-${r.dateTime.month.toString().padLeft(2, '0')}',
      1 => r.productSize.toStringAsFixed(0),
      _ => '${(r.productSize / 50).floor() * 50}',
    };
  }

  void _showCategoryDeleteSheet() {
    final data = _buildChartData();
    if (data.isEmpty) return;
    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> deleteSelected() async {
            final ids = _records
                .where((r) => selected.contains(_keyForRecord(r)))
                .map((r) => r.id!)
                .toList();
            await DatabaseHelper.instance.deleteByIds(ids);
            if (ctx.mounted) Navigator.pop(ctx);
            _loadData();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Builder(builder: (ctx2) {
                final tr = AppLocalizations.of(ctx2);
                return Row(children: [
                  Text(tr('selectCategory'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(tr('selectedCount').replaceAll('{n}', '${selected.length}'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]);
              }),
              const Divider(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: ListView(
                  shrinkWrap: true,
                  children: data.map((d) {
                    final isSelected = selected.contains(d.key);
                    return CheckboxListTile(
                      value: isSelected,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.red,
                      onChanged: (v) => setSheet(() {
                        if (v == true) { selected.add(d.key); }
                        else { selected.remove(d.key); }
                      }),
                      title: Text(d.label.replaceAll('\n', ' '),
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(
                          '${d.count}  ${AppLocalizations.of(context)('colAvg')} ${d.avg.toStringAsFixed(2)}°C',
                          style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Builder(builder: (c) => Text(AppLocalizations.of(c)('cancel2'))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(builder: (c) {
                    final tr = AppLocalizations.of(c);
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      onPressed: selected.isEmpty ? null : deleteSelected,
                      child: Text(selected.isEmpty
                          ? tr('selectFirst')
                          : tr('deleteCategoryBtn').replaceAll('{n}', '${selected.length}')),
                    );
                  }),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── UI ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_records.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)('noData'),
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('計算を実行するとデータが記録されます',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      );
    }

    final data = _buildChartData();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? _buildLandscape(data)
        : _buildPortrait(data);
  }

  Widget _buildModeSelector() {
    final tr = AppLocalizations.of(context);
    return Row(children: [
      Expanded(
        child: SegmentedButton<int>(
          style: SegmentedButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          ),
          segments: [
            ButtonSegment(value: 0, label: Text(tr('modeMonthly'), style: const TextStyle(fontSize: 11))),
            ButtonSegment(value: 1, label: Text(tr('modeSize'), style: const TextStyle(fontSize: 11))),
            ButtonSegment(value: 2, label: Text(tr('modeGroup'), style: const TextStyle(fontSize: 10))),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.playlist_remove, size: 20),
        color: Colors.red[400],
        tooltip: tr('helpCategorySection'),
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        onPressed: _showCategoryDeleteSheet,
      ),
    ]);
  }

  Widget _buildLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 14, height: 14, color: Colors.red[300]),
      const SizedBox(width: 4),
      const Text('製品が高い (+)', style: TextStyle(fontSize: 11)),
      const SizedBox(width: 20),
      Container(width: 14, height: 14, color: Colors.blue[300]),
      const SizedBox(width: 4),
      const Text('製品が低い (−)', style: TextStyle(fontSize: 11)),
    ]);
  }

  Widget _buildPortrait(List<_ChartData> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildModeSelector(),
        const SizedBox(height: 10),
        _buildLegend(),
        const SizedBox(height: 8),
        _buildChart(data),
        const SizedBox(height: 24),
        _buildSummaryTable(data),
      ]),
    );
  }

  Widget _buildLandscape(List<_ChartData> data) {
    return Row(
      children: [
        // 左：モード切替 + 凡例 + グラフ（画面高さいっぱいに）
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModeSelector(),
                const SizedBox(height: 6),
                _buildLegend(),
                const SizedBox(height: 6),
                Expanded(child: _buildChart(data, flexible: true)),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: Colors.grey[300]),
        // 右：集計テーブル
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildSummaryTable(data),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<_ChartData> data, {bool flexible = false}) {
    if (data.isEmpty) {
      return SizedBox(
          height: 220, child: Center(child: Text(AppLocalizations.of(context)('noData'))));
    }
    final positiveMax =
        data.where((d) => d.avg >= 0).fold(0.0, (m, d) => max(m, d.avg));
    final negativeMin =
        data.where((d) => d.avg < 0).fold(0.0, (m, d) => min(m, d.avg));
    final absMax = max(positiveMax, negativeMin.abs());
    final chartMax = absMax < 1 ? 5.0 : absMax * 1.3;

    final barChart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        minY: negativeMin < 0 ? -chartMax : 0,
        barGroups: data.asMap().entries.map((e) {
          final avg = e.value.avg;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                fromY: avg < 0 ? avg : 0,
                toY: avg >= 0 ? avg : 0,
                color: avg >= 0 ? Colors.red[300]! : Colors.blue[300]!,
                width: _barWidth(data.length),
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (val, meta) {
                if (val == meta.max || val == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text('${val.toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: 9));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, meta) {
                final i = val.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(data[i].label,
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[400]!, width: 1),
            left: BorderSide(color: Colors.grey[400]!, width: 1),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[group.x];
              return BarTooltipItem(
                '${d.label.replaceAll('\n', ' ')}\n'
                '平均: ${d.avg.toStringAsFixed(2)}°C  ${d.count}件',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
      ),
    );

    if (flexible) return barChart;
    return SizedBox(height: 250, child: barChart);
  }

  double _barWidth(int count) {
    if (count <= 3) return 40;
    if (count <= 6) return 30;
    if (count <= 9) return 22;
    return 16;
  }

  void _onSortTap(int col) {
    setState(() {
      if (_sortCol == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col;
        _sortAsc = col == 0; // 区分は昇順デフォルト、数値列は降順デフォルト
        if (col != 0) _sortAsc = false;
      }
    });
  }

  List<_ChartData> _sortedData(List<_ChartData> data) {
    final sorted = [...data];
    sorted.sort((a, b) {
      int cmp;
      switch (_sortCol) {
        case 1: cmp = a.count.compareTo(b.count); break;
        case 2: cmp = a.avg.compareTo(b.avg); break;
        case 3: cmp = a.maxVal.compareTo(b.maxVal); break;
        case 4: cmp = a.minVal.compareTo(b.minVal); break;
        default: cmp = a.label.compareTo(b.label);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return sorted;
  }

  Widget _buildSummaryTable(List<_ChartData> data) {
    if (data.isEmpty) return const SizedBox();
    final tr = AppLocalizations.of(context);
    final modeLabel = [tr('modeMonthly'), tr('modeSize'), tr('modeGroup')][_mode];
    final sorted = _sortedData(data);

    Widget headerCell(String label, int col, {bool isAvg = false}) {
      final active = _sortCol == col;
      final icon = active
          ? (_sortAsc ? Icons.arrow_upward : Icons.arrow_downward)
          : Icons.unfold_more;
      return GestureDetector(
        onTap: () => _onSortTap(col),
        child: Container(
          color: active
              ? (isAvg ? Colors.amber[200] : Colors.blueGrey[200])
              : (isAvg ? Colors.amber[100] : Colors.blueGrey[100]),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.blueGrey[900] : Colors.blueGrey[700])),
              ),
              Icon(icon,
                  size: 11,
                  color: active ? Colors.blueGrey[800] : Colors.grey[400]),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$modeLabel　集計',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
          },
          children: [
            TableRow(children: [
              headerCell(tr('colCategory'), 0),
              headerCell(tr('colCount'), 1),
              headerCell('${tr('colAvg')}(°C)', 2, isAvg: true),
              headerCell('${tr('colMax')}(°C)', 3),
              headerCell('${tr('colMin')}(°C)', 4),
            ]),
            ...sorted.map((d) => TableRow(children: [
                  _Cell(d.label.replaceAll('\n', ' ')),
                  _Cell('${d.count}'),
                  _Cell(d.avg.toStringAsFixed(2), isAvg: true),
                  _Cell(d.maxVal.toStringAsFixed(2)),
                  _Cell(d.minVal.toStringAsFixed(2)),
                ])),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════
//  データ一覧タブ
// ══════════════════════════════════════════

class _DataListTab extends StatefulWidget {
  final VoidCallback onDataChanged;
  final ValueNotifier<int> refreshNotifier;
  const _DataListTab({required this.onDataChanged, required this.refreshNotifier});
  @override
  State<_DataListTab> createState() => _DataListTabState();
}

class _DataListTabState extends State<_DataListTab> {
  List<TemperatureRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records = await DatabaseHelper.instance.getAll();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  Future<bool> _confirmDelete() async {
    final tr = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('deleteTitle')),
        content: Text(tr('deleteMsg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('dialogCancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('deleteBtn')),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── 編集シート（テンキー付き） ──────────────

  void _showEditSheet(TemperatureRecord record) {
    final ctrls = [
      TextEditingController(text: record.productSize.toStringAsFixed(1)),
      TextEditingController(text: record.masterTemp.toStringAsFixed(1)),
      TextEditingController(text: record.workTemp.toStringAsFixed(1)),
    ];
    final tr = AppLocalizations.of(context);
    final labels = [tr('fieldSize'), tr('fieldMasterTemp'), tr('fieldWorkTemp')];
    int activeIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          void nextField() =>
              setSheet(() => activeIndex = (activeIndex + 1) % 3);

          Future<void> save() async {
            const alpha = 0.0000115;
            final size =
                double.tryParse(ctrls[0].text) ?? record.productSize;
            final master =
                double.tryParse(ctrls[1].text) ?? record.masterTemp;
            final work =
                double.tryParse(ctrls[2].text) ?? record.workTemp;
            final diff = work - master;
            await DatabaseHelper.instance.update(record.copyWith(
              productSize: size,
              masterTemp: master,
              workTemp: work,
              tempDiff: diff,
              correctionValue: size * alpha * diff,
              isAbnormal: diff.abs() >= 10,
            ));
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            _loadData();
            widget.onDataChanged(); // グラフへ即時反映
          }

          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ハンドル
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              // タイトル
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text(tr('editTitle'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_formatDate(record.dateTime),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ]),
              ),
              const SizedBox(height: 12),
              // フィールド
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _buildEditTile(
                      label: labels[0],
                      ctrl: ctrls[0],
                      isActive: activeIndex == 0,
                      onTap: () => setSheet(() => activeIndex = 0),
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _buildEditTile(
                      label: labels[1],
                      ctrl: ctrls[1],
                      isActive: activeIndex == 1,
                      onTap: () => setSheet(() => activeIndex = 1),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildEditTile(
                      label: labels[2],
                      ctrl: ctrls[2],
                      isActive: activeIndex == 2,
                      onTap: () => setSheet(() => activeIndex = 2),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              // 保存・キャンセルボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: Text(tr('cancel2')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          foregroundColor: Colors.white),
                      child: Text(tr('save')),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              // テンキー
              NumericKeypad(
                controller: ctrls[activeIndex],
                onConfirm: nextField,
              ),
            ]),
          );
        },
      ),
    ).then((_) {
      for (final c in ctrls) { c.dispose(); }
    });
  }

  Widget _buildEditTile({
    required String label,
    required TextEditingController ctrl,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder(
        valueListenable: ctrl,
        builder: (_, __, ___) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.blueGrey[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? Colors.blueGrey[700]! : Colors.grey[400]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: isActive
                        ? Colors.blueGrey[700]
                        : Colors.grey[600])),
            const SizedBox(height: 2),
            Text(
              ctrl.text.isEmpty ? '　' : ctrl.text,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_records.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)('noData'),
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ]),
      );
    }

    return ListView.builder(
      itemCount: _records.length,
      itemBuilder: (ctx, i) {
        final r = _records[i];
        return Dismissible(
          key: ValueKey(r.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red[400],
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white),
                Text('削除',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
          confirmDismiss: (_) => _confirmDelete(),
          onDismissed: (_) async {
            final record = _records[i];
            setState(() => _records.removeAt(i));
            await DatabaseHelper.instance.delete(record.id!);
            widget.onDataChanged(); // グラフへ即時反映
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: r.isAbnormal
                  ? const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 28)
                  : Icon(Icons.check_circle_outline,
                      color: Colors.green[400], size: 28),
              title: Row(children: [
                Text('${r.productSize.toStringAsFixed(0)} mm',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Text(
                  '温度差: ${r.tempDiff >= 0 ? "+" : ""}${r.tempDiff.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: r.tempDiff >= 0
                        ? Colors.red[400]
                        : Colors.blue[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
              subtitle: Text(
                '${_formatDate(r.dateTime)}　'
                '模範:${r.masterTemp.toStringAsFixed(1)}° / 製品:${r.workTemp.toStringAsFixed(1)}°',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
              onTap: () => _showEditSheet(r),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════
//  ヘルパー
// ══════════════════════════════════════════

class _ChartData {
  final String label;
  final String key;
  final double avg;
  final int count;
  final double maxVal;
  final double minVal;

  const _ChartData({
    required this.label,
    required this.key,
    required this.avg,
    required this.count,
    required this.maxVal,
    required this.minVal,
  });

  factory _ChartData.from(String label, String key, List<double> values) {
    final avg = values.reduce((a, b) => a + b) / values.length;
    return _ChartData(
      label: label,
      key: key,
      avg: avg,
      count: values.length,
      maxVal: values.reduce(max),
      minVal: values.reduce(min),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isAvg;
  const _Cell(this.text, {this.isAvg = false});

  @override
  Widget build(BuildContext context) {
    if (isAvg) {
      // 平均列：値の正負で色分け＋太字＋大きめ
      final val = double.tryParse(text);
      final color = val == null
          ? Colors.black87
          : val > 0
              ? Colors.red[700]!
              : val < 0
                  ? Colors.blue[700]!
                  : Colors.black87;
      return Container(
        color: Colors.yellow[50],
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11)),
    );
  }
}
