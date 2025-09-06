import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/core/jobs/job_model.dart';
import 'package:recette/core/jobs/job_repository.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../mocks/mock_database_helper.mocks.dart';
void main() {
  // Set up sqflite_common_ffi for testing on desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late MockDatabaseHelper mockDatabaseHelper;
  late JobRepository jobRepository;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    jobRepository = JobRepository(dbHelper: mockDatabaseHelper);
    mockDatabase = MockDatabase();

    // Whenever the repository asks for the database, return our mock instance.
    when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
  });

  group('JobRepository', () {
    test('createJob inserts a new job and returns it with an ID', () async {
      // Arrange
      // When the mock's insert method is called, we tell it to return a dummy ID of 99.
      when(mockDatabase.insert(any, any)).thenAnswer((_) async => 99);

      // Act
      final newJob = await jobRepository.createJob(
        jobType: 'test_type',
        requestPayload: '{"data":"test"}',
      );

      // Assert
      // Verify that the insert method was called exactly once on our mock database.
      verify(mockDatabase.insert('job_history', any)).called(1);
      // Check that the returned Job object has the correct ID and status.
      expect(newJob.id, 99);
      expect(newJob.status, JobStatus.queued);
    });

    test('updateJobStatus calls the database update method with the correct status', () async {
      // Arrange
      when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);

      // Act
      await jobRepository.updateJobStatus(1, JobStatus.inProgress);

      // Assert
      verify(mockDatabase.update(
        'job_history',
        {'status': 'inProgress'},
        where: 'id = ?',
        whereArgs: [1],
      )).called(1);
    });

    test('completeJob calls the database update method with the correct data', () async {
      // Arrange
      when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);
      
      // Create a JobResult object to pass to the method.
      final jobResult = JobResult(responsePayload: '{"result":"done"}', title: 'Test Title');

      // Act
      await jobRepository.completeJob(1, jobResult);

      // Assert
      // We use `argThat` to check that the map contains the correct keys, since the timestamp will be different each time.
      verify(mockDatabase.update(
        'job_history',
        argThat(allOf(
          containsPair('status', 'complete'),
          containsPair('response_payload', '{"result":"done"}'),
          contains('completed_at'),
        )),
        where: 'id = ?',
        whereArgs: [1],
      )).called(1);
    });

    test('getAllJobs returns a list of jobs from the database', () async {
      // Arrange
      final mockDbResponse = [
        Job(id: 1, jobType: 'a', requestPayload: '', createdAt: DateTime.now()).toMap(),
        Job(id: 2, jobType: 'b', requestPayload: '', createdAt: DateTime.now()).toMap(),
      ];
      when(mockDatabase.query(any, orderBy: anyNamed('orderBy'))).thenAnswer((_) async => mockDbResponse);

      // Act
      final jobs = await jobRepository.getAllJobs();

      // Assert
      expect(jobs.length, 2);
      expect(jobs.first.jobType, 'a');
    });
  });
}