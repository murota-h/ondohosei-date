import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle('温度補正の計算式'),
        _buildContentBox('補正値 = 寸法 × 線膨張係数 × 温度差\n\n・線膨張係数：11.5 × 10⁻⁶ (鉄鋼)\n・温度差：製品温度 － 模範温度'),
        const SizedBox(height: 20),
        _buildSectionTitle('補正の考え方'),
        _buildContentBox('【製品が模範より熱い場合 (+)】\n製品が膨張しているため、マイクロの読み値は本来より大きくなります。真の寸法を得るには補正値を「引き」ます。\n\n【製品が模範より冷たい場合 (-)】\n製品が収縮しているため、読み値は小さくなります。補正値を「足し」ます。'),
        const SizedBox(height: 30),
        const Center(child: Text('一体型仕上げ組 温度補正システム v1.0', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)));
  Widget _buildContentBox(String text) => Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)), child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5)));
}
