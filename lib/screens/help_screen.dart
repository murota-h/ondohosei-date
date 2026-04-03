import 'package:flutter/material.dart';
import '../services/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle(tr('helpCalcFormula')),
        _buildContentBox(tr('helpCalcFormulaContent')),
        const SizedBox(height: 20),
        _buildSectionTitle(tr('helpCorrectionIdea')),
        _buildContentBox(tr('helpCorrectionContent')),
        const SizedBox(height: 30),
        Center(child: Text(tr('helpFooter'), style: const TextStyle(color: Colors.grey, fontSize: 12))),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _buildContentBox(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)),
  );
}
