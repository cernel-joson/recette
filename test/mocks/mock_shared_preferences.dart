// test/mocks/mock_shared_preferences.dart

// This file is necessary for mockito to generate the mock classes.
// Create a file at this path and add the following content.
// Then, in your terminal, run:
// flutter pub run build_runner build --delete-conflicting-outputs

import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([SharedPreferences])
void main() {}
