import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 🇮🇳 +91 prefix shown inside phone-number fields.
class IndiaPhonePrefix extends StatelessWidget {
  const IndiaPhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇮🇳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text('+91',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 8),
          Container(width: 1, height: 22, color: context.semantic.border),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
