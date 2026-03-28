import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onConfirm;

  const NumericKeypad({super.key, required this.controller, this.onConfirm});

  void _onKey(String key) {
    final text = controller.text;
    switch (key) {
      case '⌫':
        if (text.isNotEmpty) controller.text = text.substring(0, text.length - 1);
      case 'C':
        controller.text = '';
      case '+':
        if (text.startsWith('-')) controller.text = text.substring(1);
      case '-':
        if (!text.startsWith('-') && text.isNotEmpty) controller.text = '-$text';
      case '.':
        if (!text.contains('.')) controller.text = '$text.';
      default:
        controller.text = text + key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // [label, flex, style]
    // styles: 'num', 'action', 'confirm', 'sign'
    final rows = [
      [('7', 1, 'num'), ('8', 1, 'num'), ('9', 1, 'num'), ('⌫', 1, 'action')],
      [('4', 1, 'num'), ('5', 1, 'num'), ('6', 1, 'num'), ('C', 1, 'action')],
      [('1', 1, 'num'), ('2', 1, 'num'), ('3', 1, 'num'), ('確定', 1, 'confirm')],
      [('+', 1, 'sign'), ('-', 1, 'sign'), ('0', 1, 'num'), ('.', 1, 'num')],
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C2833),
        border: Border(top: BorderSide(color: Color(0xFF2E3F4F), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: row.map<Widget>((cell) {
                final (label, _, style) = cell;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _KeyButton(
                      label: label,
                      style: style,
                      onTap: label == '確定' ? onConfirm : () => _onKey(label),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final String style;
  final VoidCallback? onTap;

  const _KeyButton({required this.label, required this.style, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, fontSize) = switch (style) {
      'action'  => (const Color(0xFF3D5166), Colors.redAccent[100]!, 20.0),
      'confirm' => (Colors.orangeAccent[700]!, Colors.white, 15.0),
      'sign'    => (const Color(0xFF2C4A60), const Color(0xFF90CAF9), 20.0),
      _         => (const Color(0xFF2E3F4F), Colors.white, 22.0),
    };

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        splashColor: Colors.white24,
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fgColor,
              letterSpacing: label == '確定' ? 2 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
