import 'package:flutter/material.dart';

class TierInfo {
  final String label;
  final BoxDecoration decoration;
  final Color textColor;
  TierInfo(this.label, this.decoration, this.textColor);
}

TierInfo getTierInfo(int points) {
  if (points >= 2000) {
    return TierInfo(
      'Diamond',
      BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/image/diamond.jpeg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      Colors.white,
    );
  } else if (points >= 1000) {
    return TierInfo(
      'Gold',
      BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/image/gold.jpeg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      Colors.white,
    );
  } else if (points >= 500) {
    return TierInfo(
      'Silver',
      BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/image/silver.jpeg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      Colors.white,
    );
  } else if (points >= 100) {
    return TierInfo(
      'Bronze',
      BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/image/bronze.jpeg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
        color: const Color(0xFF0041c3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      Colors.white,
    );
  }
}

Widget buildTierIcon(String label) {
  switch (label) {
    case 'Bronze':
      return const Icon(Icons.brightness_5, color: Colors.white, size: 16);
    case 'Silver':
      return const Icon(Icons.brightness_6, color: Colors.white, size: 16);
    case 'Gold':
      return const Icon(Icons.star, color: Colors.amber, size: 16);
    case 'Diamond':
      return const Icon(Icons.diamond, color: Colors.white, size: 16);
    default:
      return const SizedBox.shrink();
  }
}
