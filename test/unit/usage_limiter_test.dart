// test/unit/usage_limiter_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/core/utils/usage_limiter.dart';

// Use a mock for SharedPreferences to isolate the limiter's logic.
import '../mocks/mock_shared_preferences.mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late UsageLimiter usageLimiter;

  setUp(() {
    // Before each test, create new mock instances.
    mockPrefs = MockSharedPreferences();
    usageLimiter = UsageLimiter.internal(mockPrefs);
  });

  group('UsageLimiter', () {
    const featureKey = 'test_feature';

    test('isAllowed returns true for a feature that has never been used',
        () async {
      // Arrange: When the limiter asks for the usage history, return null.
      when(mockPrefs.getStringList(any)).thenReturn(null);

      // Act
      final isAllowed = await usageLimiter.isAllowed(featureKey);

      // Assert
      expect(isAllowed, isTrue);
    });

    test(
        'isAllowed returns false if used more than maxUsages within the duration',
        () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      // Simulate that the feature has already been used once.
      when(mockPrefs.getStringList(featureKey))
          .thenReturn([now.toString()]);
      // We expect the limiter to try and save the new usage time.
      when(mockPrefs.setStringList(any, any))
          .thenAnswer((_) async => true);

      // Act
      await usageLimiter.recordUsage(featureKey); // Record the first usage
      final isAllowed = await usageLimiter.isAllowed(featureKey,
          maxUsages: 1); // Check if a second usage is allowed

      // Assert
      expect(isAllowed, isFalse);
    });

    test('isAllowed returns true if usage history is outside the duration',
        () async {
      // Arrange
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));
      // Simulate a usage that happened 5 minutes ago.
      when(mockPrefs.getStringList(featureKey))
          .thenReturn([fiveMinutesAgo.millisecondsSinceEpoch.toString()]);

      // Act
      // Check if usage is allowed with a 4-minute window.
      final isAllowed = await usageLimiter.isAllowed(featureKey,
          duration: const Duration(minutes: 4));

      // Assert
      expect(isAllowed, isTrue);
    });

    test('isAllowed correctly handles multiple usages', () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      // Simulate two previous usages.
       when(mockPrefs.getStringList(featureKey))
          .thenReturn([now.toString(), now.toString()]);
      when(mockPrefs.setStringList(any, any))
          .thenAnswer((_) async => true);

      // Act & Assert
      // Check with maxUsages: 3. Should be allowed.
      final isAllowed1 = await usageLimiter.isAllowed(featureKey, maxUsages: 3);
      expect(isAllowed1, isTrue);
      
      await usageLimiter.recordUsage(featureKey);

      // After recording the third usage, it should now be disallowed.
       when(mockPrefs.getStringList(featureKey))
          .thenReturn([now.toString(), now.toString(), now.toString()]);
      final isAllowed2 = await usageLimiter.isAllowed(featureKey, maxUsages: 3);
      expect(isAllowed2, isFalse);
    });
  });
}