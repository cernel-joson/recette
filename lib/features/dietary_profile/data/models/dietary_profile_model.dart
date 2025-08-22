// lib/features/dietary_profile/data/models/dietary_profile_model.dart
import 'package:recette/core/utils/utils.dart';

class DietaryProfile implements Fingerprintable {
  final String markdownText;

  DietaryProfile({this.markdownText = ''});

  // The fullProfileText is now just the markdownText.
  String get fullProfileText => markdownText.trim();

  @override
  String get fingerprintableString => fullProfileText;
}