import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/core/presentation/controllers/job_controller.dart';
import 'package:recette/core/jobs/job_model.dart';

import '../../mocks/mock_job_repository.mocks.dart';

void main() {
  late MockJobRepository mockJobRepository;
  late JobController jobController;

  setUp(() {
    mockJobRepository = MockJobRepository();

    // --- THIS IS THE FIX ---
    // Provide a default stub for the getAllJobs method before creating the controller.
    // This handles the automatic call made in the controller's constructor.
    when(mockJobRepository.getAllJobs()).thenAnswer((_) async => []);

    // Now, when the JobController is created, it can successfully call getAllJobs.
    jobController = JobController(jobRepository: mockJobRepository);
  });

  group('JobController', () {
    test('initial state after load is correct', () async {
      // Arrange
      // We need to wait for the async work in the constructor to finish.
      // A short delay allows the async `loadJobs` to complete.
      await Future.delayed(Duration.zero);

      // Assert
      // --- THIS IS THE FIX ---
      // After the initial load in the constructor, isLoading should be false.
      expect(jobController.isLoading, isFalse);
      expect(jobController.jobs, isEmpty);
    });

    test('loadJobs fetches jobs from the repository and updates state', () async {
      // Arrange
      final mockJobs = [
        Job(id: 1, jobType: 'test', requestPayload: '{}', createdAt: DateTime.now()),
      ];
      when(mockJobRepository.getAllJobs()).thenAnswer((_) async => mockJobs);

      // Act
      await jobController.loadJobs();

      // Assert
      expect(jobController.isLoading, isFalse);
      expect(jobController.jobs.length, 1);
      expect(jobController.jobs.first.id, 1);
    });

    test('hasActiveJobs returns true when a job is queued', () async {
      // Arrange
      final mockJobs = [
        Job(id: 1, jobType: 'test', requestPayload: '{}', createdAt: DateTime.now(), status: JobStatus.queued),
        Job(id: 2, jobType: 'test2', requestPayload: '{}', createdAt: DateTime.now(), status: JobStatus.complete),
      ];
      when(mockJobRepository.getAllJobs()).thenAnswer((_) async => mockJobs);

      // Act
      await jobController.loadJobs();

      // Assert
      expect(jobController.hasActiveJobs, isTrue);
    });

    test('hasActiveJobs returns true when a job is in progress', () async {
      // Arrange
      final mockJobs = [
        Job(id: 1, jobType: 'test', requestPayload: '{}', createdAt: DateTime.now(), status: JobStatus.inProgress),
      ];
      when(mockJobRepository.getAllJobs()).thenAnswer((_) async => mockJobs);
      
      // Act
      await jobController.loadJobs();
      
      // Assert
      expect(jobController.hasActiveJobs, isTrue);
    });

    test('hasActiveJobs returns false when all jobs are complete or failed', () async {
      // Arrange
      final mockJobs = [
        Job(id: 1, jobType: 'test', requestPayload: '{}', createdAt: DateTime.now(), status: JobStatus.complete),
        Job(id: 2, jobType: 'test2', requestPayload: '{}', createdAt: DateTime.now(), status: JobStatus.failed),
      ];
      when(mockJobRepository.getAllJobs()).thenAnswer((_) async => mockJobs);
      
      // Act
      await jobController.loadJobs();
      
      // Assert
      expect(jobController.hasActiveJobs, isFalse);
    });
  });
}