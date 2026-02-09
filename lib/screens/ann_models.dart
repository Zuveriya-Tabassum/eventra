// lib/screens/ann_models.dart

import 'package:flutter/material.dart';

enum AnnouncementCategory {
  notice,
  meeting,
  workshop,
  hackathon,
  club, event,
}

class Announcement {
  String id;
  String title;
  String description;
  String venue;
  DateTime date;
  TimeOfDay time;
  AnnouncementCategory category;
  bool isImportant;
  bool isPinned;
  String? targetType; // hackathon / workshop / club / etc
  String? targetId;

  // meta info
  String? createdByName;
  String? updatedByName;
  DateTime? createdAt;
  DateTime? updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.date,
    required this.time,
    required this.category,
    this.isImportant = false,
    this.isPinned = false,
    this.targetType,
    this.targetId,
    this.createdByName,
    this.updatedByName,
    this.createdAt,
    this.updatedAt,
  });
}
