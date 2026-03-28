import 'package:flutter/material.dart';

class QuickReferenceTable extends StatefulWidget {
  const QuickReferenceTable({super.key});
  @override
  State<QuickReferenceTable> createState() => _QuickReferenceTableState();
}

class _QuickReferenceTableState extends State<QuickReferenceTable> with AutomaticKeepAliveClientMixin {
  final double alpha = 0.0000115;
  final List<double> sizes = const [290, 300, 310, 340, 350, 400, 415, 420, 450, 480];
  final List<double> tempDiffs = const [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0];
  double _selectedSize = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InteractiveViewer(
      constrained: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(75),
          border: TableBorder.all(color: Colors.grey[400]!),
          children: [
            // ヘッダー行
            TableRow(decoration: BoxDecoration(color: Colors.blueGrey[100]), children: [
              const TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('寸法\\差', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
              ...tempDiffs.map((d) => TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('+$d', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))))),
            ]),
            // データ行
            ...sizes.map((s) {
              bool isRowSelected = s == _selectedSize;
              return TableRow(
                decoration: BoxDecoration(
                  color: isRowSelected ? Colors.blue[50] : Colors.transparent,
                ),
                children: [
                  // 寸法セル（タップで行選択）
                  TableCell(child: GestureDetector(
                    onTap: () => setState(() => _selectedSize = s),
                    child: Container(color: Colors.grey[100], padding: const EdgeInsets.all(8), child: Text('${s.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  )),
                  // 各補正値セル（タップで行選択）
                  ...List.generate(tempDiffs.length, (index) {
                    return TableCell(child: GestureDetector(
                      onTap: () => setState(() => _selectedSize = s),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Center(child: Text((s * alpha * tempDiffs[index]).toStringAsFixed(4), style: const TextStyle(fontSize: 11))),
                      ),
                    ));
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
