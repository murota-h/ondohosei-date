import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'stats_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});
  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _slideUp = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2E3C), Color(0xFF0D1B2A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 背景グリッドライン
            CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
            // メインコンテンツ
            isLandscape ? _buildLandscape(context) : _buildPortrait(context),
            // バージョン・開発者情報
            const Positioned(
              bottom: 12, left: 0, right: 0,
              child: Column(children: [
                Text('Ver 1.0', style: TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 2)),
                SizedBox(height: 2),
                Text('Developer: H.Murota', style: TextStyle(fontSize: 12, color: Colors.white54)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _fadeIn.value,
          child: Transform.translate(
            offset: Offset(0, _slideUp.value),
            child: child,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 16),
            _buildSubtitle(),
            const SizedBox(height: 12),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildDividerLine(),
            const SizedBox(height: 60),
            _buildStartButton(context),
            const SizedBox(height: 16),
            _buildStatsButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscape(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeIn.value,
        child: Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: child,
        ),
      ),
      child: Row(
        children: [
          // 左：アイコン＋タイトル
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 12),
                  _buildSubtitle(),
                  const SizedBox(height: 8),
                  _buildTitle(),
                  const SizedBox(height: 6),
                  _buildDividerLine(),
                ],
              ),
            ),
          ),
          // 縦の区切り
          Container(
            width: 1,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.orangeAccent.withAlpha(120), Colors.transparent],
              ),
            ),
          ),
          // 右：ボタン群
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStartButton(context),
                  const SizedBox(height: 16),
                  _buildStatsButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _iconScale,
      builder: (context, _) => Transform.scale(
        scale: _iconScale.value,
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E3A4F),
            border: Border.all(color: Colors.orangeAccent.withAlpha(180), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.orangeAccent.withAlpha(100), blurRadius: 30, spreadRadius: 5),
              BoxShadow(color: Colors.orangeAccent.withAlpha(50), blurRadius: 60, spreadRadius: 10),
            ],
          ),
          child: const Icon(Icons.precision_manufacturing, size: 50, color: Colors.orangeAccent),
        ),
      ),
    );
  }

  Widget _buildSubtitle() => Text(
    '一体型仕上げ組',
    style: TextStyle(fontSize: 13, letterSpacing: 6, color: Colors.orangeAccent.withAlpha(200), fontWeight: FontWeight.w400),
  );

  Widget _buildTitle() => const Text(
    '温度補正システム',
    style: TextStyle(
      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
      letterSpacing: 4.0,
      shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 20)],
    ),
  );

  Widget _buildDividerLine() => Container(
    width: 200, height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.transparent, Colors.orangeAccent.withAlpha(200), Colors.transparent]),
    ),
  );

  Widget _buildStartButton(BuildContext context) => _StartButton(onPressed: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
  });

  Widget _buildStatsButton(BuildContext context) => _StatsButton(onPressed: () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen()));
  });
}

class _StartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _StartButton({required this.onPressed});
  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: Colors.orangeAccent.withAlpha((100 * _pulse.value).toInt()), blurRadius: 20 * _pulse.value, spreadRadius: 2 * _pulse.value),
          ],
        ),
        child: child,
      ),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40), side: const BorderSide(color: Colors.orangeAccent, width: 1.5)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('START', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 6, color: Colors.orangeAccent)),
          SizedBox(width: 10),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orangeAccent),
        ]),
      ),
    );
  }
}

class _StatsButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _StatsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
          side: const BorderSide(color: Color(0xFF4FC3F7), width: 1.5),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bar_chart, size: 18, color: Color(0xFF4FC3F7)),
        SizedBox(width: 10),
        Text('統計・データ',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
                color: Color(0xFF4FC3F7))),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A4F).withAlpha(120)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
