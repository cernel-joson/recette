// test/mocks/mock_database_helper.dart

// This file is necessary for mockito to generate the mock classes.
// Create a file at this path and add the following content.
// Then, in your terminal, run:
// flutter pub run build_runner build

import 'package:mockito/annotations.dart';
import 'package:recette/core/data/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

@GenerateMocks([DatabaseHelper, Database])
void main() {}
