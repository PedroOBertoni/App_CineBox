import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CineBoxLogo extends StatelessWidget {
  final double size;

  const CineBoxLogo({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'CB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.38,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
