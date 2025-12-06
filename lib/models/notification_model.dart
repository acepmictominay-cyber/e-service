import 'package:flutter/material.dart';

class NotificationModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textColor;
  final DateTime timestamp;

  NotificationModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.timestamp,
  });

  // Convert to Map for SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon.codePoint, // Store icon as codePoint
      'color': color.value, // Store color as int
      'textColor': textColor.value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      title: map['title'],
      subtitle: map['subtitle'],
      icon: const IconData(0xe3e1, fontFamily: 'MaterialIcons'), // Use constant icon
      color: Color(map['color']),
      textColor: Color(map['textColor']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
