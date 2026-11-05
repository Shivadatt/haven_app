import 'package:flutter/material.dart';

/// One activity event rendered in the Parent Dashboard's recent activity timeline.
final class DashboardActivityItem {
  const DashboardActivityItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.timeAgo,
    required this.icon,
    this.isDemo = false,
  });

  final String id;
  final String title;
  final String detail;
  final String timeAgo;
  final IconData icon;
  final bool isDemo;
}
