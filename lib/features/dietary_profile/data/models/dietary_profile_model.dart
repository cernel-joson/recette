import 'package:intelligent_nutrition_app/core/utils/utils.dart';

/// A model to represent the user's dietary profile.
///
/// By implementing [Fingerprintable], we can use our generic helper
/// to generate a consistent hash of its content.
class DietaryProfile implements Fingerprintable {
  final String rules;
  final String preferences;

  DietaryProfile({this.rules = '', this.preferences = ''});

  /// A computed property that combines the rules and preferences
  /// into a single string for AI analysis.
  String get fullProfileText => '$rules\n\n$preferences'.trim();

  @override
  String get fingerprintableString => fullProfileText;
}