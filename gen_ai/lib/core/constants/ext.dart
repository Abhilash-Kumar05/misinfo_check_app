import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/news_service.dart';

extension RatingTypeColors on RatingType {
  Color get color {
    switch (this) {
      case RatingType.true_:
        return Colors.green;
      case RatingType.mostlyTrue:
        return Colors.lightGreen;
      case RatingType.mixed:
        return Colors.orange;
      case RatingType.mostlyFalse:
        return Colors.redAccent;
      case RatingType.false_:
        return Colors.red;
      case RatingType.unknown:
        return Colors.grey;
    }
  }

  String get label {
    switch (this) {
      case RatingType.true_:
        return "TRUE";
      case RatingType.mostlyTrue:
        return "MOSTLY TRUE";
      case RatingType.mixed:
        return "MIXED";
      case RatingType.mostlyFalse:
        return "MOSTLY FALSE";
      case RatingType.false_:
        return "FALSE";
      case RatingType.unknown:
        return "UNRATED";
    }
  }
}