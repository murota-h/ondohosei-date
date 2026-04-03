import 'package:flutter/material.dart';
import '../widgets/numeric_keypad.dart';
import '../services/database_helper.dart';
import '../services/app_localizations.dart';

class CalculationScreen extends StatefulWidget {
  const CalculationScreen({super.key});
  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _sizeController = TextEditingController();
  final _masterTempController = TextEditingController();
  final _workTempController = TextEditingController();
  double _correctionValue = 0.0, _finalResult = 0.0, _currentSize = 0.0, _currentDiff = 0.0;
  final double alpha = 0.0000115;
  late AppLocalizations _tr;

  late TextEditingController _activeController;
  int _activeIndex = 0;
  bool _showKeypad = true;
  bool _needsCalculation = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _activeController = _sizeController;
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    for (final c in [_sizeController, _masterTempController, _workTempController]) {
      c.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    for (final c in [_sizeController, _masterTempController, _workTempController]) {
      c.removeListener(_onInputChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onInputChanged() {
    if (!_needsCalculation) setState(() => _needsCalculation = true);
  }

  void _setActive(int index) {
    setState(() {
      _activeIndex = index;
      _activeController = [_sizeController, _masterTempController, _workTempController][index];
      _showKeypad = true;
    });
  }

  void _nextField() {
    _setActive((_activeIndex + 1) % 3);
  }

  Future<void> _calculate() async {
    final size = double.tryParse(_sizeController.text) ?? 0;
    final masterTemp = double.tryParse(_masterTempController.text) ?? 0;
    final workTemp = double.tryParse(_workTempController.text) ?? 0;
    final tempDiff = workTemp - masterTemp;

    // 温度差10度以上は確認ダイアログ
    if (tempDiff.abs() >= 10) {
      final sign = tempDiff > 0 ? '+' : '';
      final tr = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(tr('dialogConfirm')),
          ]),
          content: Text(
            tr('dialogTempWarn').replaceAll('{diff}', '$sign${tempDiff.toStringAsFixed(1)}'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('dialogCancel'))),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('dialogExec'))),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) return;
    }

    final correctionValue = size * alpha * tempDiff;
    final finalResult = size - correctionValue;

    setState(() {
      _currentSize = size;
      _currentDiff = tempDiff;
      _correctionValue = correctionValue;
      _finalResult = finalResult;
      _showKeypad = false;
      _needsCalculation = false;
    });

    // DBに保存（寸法が入力されている場合のみ）
    if (size > 0) {
      await DatabaseHelper.instance.insert(TemperatureRecord(
        dateTime: DateTime.now(),
        productSize: size,
        masterTemp: masterTemp,
        workTemp: workTemp,
        tempDiff: tempDiff,
        correctionValue: correctionValue,
        isAbnormal: tempDiff.abs() >= 10,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _tr = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? _buildLandscape() : _buildPortrait();
  }

  // ── 縦向きレイアウト ───────────────────────

  Widget _buildPortrait() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _buildFieldSelector(),
        const SizedBox(height: 20),
        _buildCalculateButton(),
        _buildKeypad(),
        if (_currentSize > 0) ...[
          const SizedBox(height: 20),
          _buildResultDisplay(),
          const SizedBox(height: 25),
          _buildReferenceTable(),
        ],
      ]),
    );
  }

  // ── 横向きレイアウト ───────────────────────

  Widget _buildLandscape() {
    final showRight = _showKeypad || _currentSize > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左：入力フィールド + ボタン（flex:2）
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _buildFieldSelector(),
              const SizedBox(height: 12),
              _buildCalculateButton(),
            ]),
          ),
        ),
        // 右：テンキー or 計算結果（flex:3）
        if (showRight) ...[
          VerticalDivider(width: 1, color: Colors.grey[300]),
          Expanded(
            flex: 3,
            child: _showKeypad
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: NumericKeypad(
                          controller: _activeController,
                          onConfirm: _nextField,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _buildResultDisplay(),
                      const SizedBox(height: 20),
                      _buildReferenceTable(),
                    ]),
                  ),
          ),
        ],
      ],
    );
  }

  // ── 共通ウィジェット ──────────────────────

  Widget _buildCalculateButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        final glow = _needsCalculation ? _glowAnim.value : 0.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withAlpha((160 * glow).toInt()),
                blurRadius: 18 * glow,
                spreadRadius: 2 * glow,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: () => _calculate(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[800],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
        ),
        child: Text(_tr('calcBtn'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKeypad() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showKeypad
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: NumericKeypad(
                  controller: _activeController,
                  onConfirm: _nextField,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFieldSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFieldTile(index: 0, label: _tr('fieldSize'), controller: _sizeController)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildFieldTile(index: 1, label: _tr('fieldMasterTemp'), controller: _masterTempController)),
            const SizedBox(width: 10),
            Expanded(child: _buildFieldTile(index: 2, label: _tr('fieldWorkTemp'), controller: _workTempController)),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldTile({
    required int index,
    required String label,
    required TextEditingController controller,
  }) {
    final isActive = _activeIndex == index;
    return GestureDetector(
      onTap: () => _setActive(index),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, _, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.blueGrey[50] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? Colors.blueGrey[700]! : Colors.grey[400]!,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.blueGrey[700] : Colors.grey[600],
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.text.isEmpty ? '　' : controller.text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.blueGrey[900] : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultDisplay() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.blueGrey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blueGrey[200]!),
    ),
    child: Column(children: [
      Text(_tr('resultCorrection'), style: const TextStyle(fontSize: 13)),
      Text(
        '${_correctionValue >= 0 ? "+" : ""}${_correctionValue.toStringAsFixed(4)} mm',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _correctionValue >= 0 ? Colors.red : Colors.blue),
      ),
      const Divider(height: 15),
      Text(_tr('resultConverted'), style: const TextStyle(fontSize: 13)),
      Text('${_finalResult.toStringAsFixed(4)} mm', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _buildReferenceTable() {
    List<double> diffList = [];
    double base = (_currentDiff * 2).round() / 2.0;
    for (int i = -3; i <= 3; i++) { diffList.add(base + (i * 0.5)); }
    diffList.add(double.parse(_currentDiff.toStringAsFixed(1)));
    diffList = diffList.toSet().toList();
    diffList.sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('refTableTitle'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(_tr('refTableTempDiff'), textAlign: TextAlign.center)),
                Padding(padding: const EdgeInsets.all(8), child: Text(_tr('refTableCorrection'), textAlign: TextAlign.center)),
              ],
            ),
            ...diffList.map((diff) => _buildTableRow(diff)),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableRow(double diff) {
    double val = _currentSize * alpha * diff;
    bool isCurrent = (diff - _currentDiff).abs() < 0.05;
    return TableRow(
      decoration: BoxDecoration(color: isCurrent ? Colors.yellow[50] : Colors.white),
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text('${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} ℃', textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(8), child: Text(
          '${val >= 0 ? "+" : ""}${val.toStringAsFixed(4)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: val >= 0 ? Colors.red : Colors.blue, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
        )),
      ],
    );
  }
}
