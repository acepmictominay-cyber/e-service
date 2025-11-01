import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TierInfo {
  final String label;
  final BoxDecoration decoration;
  final Color textColor;
  TierInfo(this.label, this.decoration, this.textColor);
}

TierInfo getTierInfo(int points) {
  if (points >= 1500) {
    return TierInfo(
      'Sultan',
      BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/image/sultan_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      Colors.white,
    );
  } else if (points >= 500) {
    return TierInfo(
      'Crazy Rich',
      BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3C72).withOpacity(0.9),
            const Color(0xFF2A5298).withOpacity(0.95),
            const Color(0xFF7E22CE).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E22CE).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      Colors.white,
    );
  } else if (points >= 1) {
    return TierInfo(
      'Cuanners',
      BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF42A5F5).withOpacity(0.85),
            const Color(0xFF64B5F6).withOpacity(0.9),
            const Color(0xFF90CAF9).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      Colors.white,
    );
  } else {
    return TierInfo(
      '',
      BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      Colors.black,
    );
  }
}

Widget buildTierIcon(String label) {
  switch (label) {
    case 'Cuanners':
      return const Icon(
        Icons.stars_rounded,
        color: Colors.white,
        size: 16,
      );
    case 'Crazy Rich':
      return const Icon(
        Icons.diamond_rounded,
        color: Colors.white,
        size: 16,
      );
    case 'Sultan':
      return const FaIcon(
        FontAwesomeIcons.crown,
        color: Color(0xFFFFEB3B),
        size: 16,
      );
    default:
      return const SizedBox.shrink();
  }
}
