import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/core/jobs/job_controller.dart';
import 'package:recette/core/jobs/job_manager.dart';
import 'package:recette/core/jobs/job_model.dart';

import '../../mocks/mock_job_repository.mocks.dart';
import '../../mocks/mock_job_worker.mocks.dart';

// We can create a mock for JobController as well for verification
class MockJobController extends Mock implements JobController {}

void main() {
  late JobManager jobManager;
  late MockJobRepository mockJobRepository;
  late MockJobController mockJobController;
  late MockJobWorker mockJobWorker;

  setUp(() {
    mockJobRepository = MockJobRepository();
    mockJobController = MockJobController();
    mockJobWorker = MockJobWorker();

    jobManager = JobManager(
      jobRepository: mockJobRepository,
      jobController: mockJobController,
      workers: {
        'test_job': mockJobWorker, // Register our mock worker for 'test_job' type
      },
    );
  });

  group('JobManager', () {
    test('submitJob creates a job, adds it to the queue, and notifies the controller', () async {
      // Arrange
      final now = DateTime.now();
      final createdJob = Job(
        id: 1,
        jobType: 'test_job',
        requestPayload: '{}',
        createdAt: now,
      );
      when(mockJobRepository.createJob(
        jobType: anyNamed('jobType'),
        requestPayload: anyNamed('requestPayload'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => createdJob);
      
      // Mock the worker's execution to avoid errors in the processing loop
      when(mockJobWorker.execute(any)).thenAnswer((_) async => '{"status":"ok"}');

      // Act
      await jobManager.submitJob(jobType: 'test_job', requestPayload: '{}');

      // Assert
      // Verify the job was created in the repository.
      verify(mockJobRepository.createJob(jobType: 'test_job', requestPayload: '{}')).called(1);
      // Verify the controller was notified to reload its state.
      verify(mockJobController.loadJobs()).called(1);
    });

    test('_processQueue executes a job and updates its status correctly', () async {
      // Arrange
      final now = DateTime.now();
      final createdJob = Job(id: 1, jobType: 'test_job', requestPayload: '{}', createdAt: now);

      when(mockJobRepository.createJob(
        jobType: anyNamed('jobType'),
        requestPayload: anyNamed('requestPayload'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => createdJob);
      
      when(mockJobWorker.execute(any)).thenAnswer((_) async => '{"result":"success"}');

      // Act
      await jobManager.submitJob(jobType: 'test_job', requestPayload: '{}');
      
      // We need to wait for the async processing to complete.
      await untilCalled(mockJobRepository.completeJob(any, any));

      // Assert
      verifyInOrder([
        mockJobRepository.updateJobStatus(1, JobStatus.inProgress),
        mockJobRepository.completeJob(1, '{"result":"success"}'),
      ]);

      // --- THIS IS THE FIX ---
      // Verify that the controller was notified exactly 3 times during the process.
      verify(mockJobController.loadJobs()).called(3);
    });

    test('_processQueue handles worker execution failure', () async {
      // Arrange
      final now = DateTime.now();
      final createdJob = Job(id: 1, jobType: 'test_job', requestPayload: '{}', createdAt: now);
      
      when(mockJobRepository.createJob(
        jobType: anyNamed('jobType'),
        requestPayload: anyNamed('requestPayload'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => createdJob);

      // Make the worker throw an error when executed.
      when(mockJobWorker.execute(any)).thenThrow(Exception('Execution failed'));

      // Act
      await jobManager.submitJob(jobType: 'test_job', requestPayload: '{}');
      
      await untilCalled(mockJobRepository.updateJobStatus(any, JobStatus.failed));
      
      // Assert
      // Verify that the job status was correctly updated to 'failed'.
      verify(mockJobRepository.updateJobStatus(1, JobStatus.failed)).called(1);
      // Verify that `completeJob` was never called.
      verifyNever(mockJobRepository.completeJob(any, any));
    });
  });
}