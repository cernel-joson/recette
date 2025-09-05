import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';

import '../../mocks/mock_job_repository.mocks.dart';
import '../../mocks/mock_job_worker.mocks.dart';
import '../../mocks/mock_job_controller.mocks.dart';

void main() {
  late JobManager jobManager;
  late MockJobRepository mockJobRepository;
  late MockJobController mockJobController;
  late MockJobWorker mockJobWorker;

  setUp(() {
    mockJobRepository = MockJobRepository();
    mockJobController = MockJobController();
    mockJobWorker = MockJobWorker();

    // --- THIS IS THE FIX ---
    // Provide a default stub for the loadJobs method. This will be used by all
    // tests unless a specific test overrides it. This prevents the MissingStubError.
    when(mockJobController.loadJobs()).thenAnswer((_) async {});
    when(mockJobRepository.updateJobStatus(any, any)).thenAnswer((_) async {});
    when(mockJobRepository.completeJob(any, any)).thenAnswer((_) async {});

    jobManager = JobManager(
      jobRepository: mockJobRepository,
      jobController: mockJobController,
      workers: {
        'test_job': mockJobWorker,
      },
    );
  });

  group('JobManager', () {
    final testJob = Job(
      id: 1,
      jobType: 'test_job',
      requestPayload: '{}',
      createdAt: DateTime.now(),
    );

    test('submitJob creates a job, adds it to the queue, and notifies the controller', () async {
      // Arrange
      // Define all stubs at the top level of the test block, before the action.
      when(mockJobRepository.createJob(
        jobType: anyNamed('jobType'),
        requestPayload: anyNamed('requestPayload'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => testJob);

      // The mock worker's execute method now returns a JobResult.
      final jobResult = JobResult(responsePayload: '{"result":"success"}');
      when(mockJobWorker.execute(any)).thenAnswer((_) async => jobResult);

      // Act
      await jobManager.submitJob(jobType: 'test_job', requestPayload: '{}');

      // Assert
      verify(mockJobRepository.createJob(jobType: 'test_job', requestPayload: '{}')).called(1);
      verify(mockJobController.loadJobs()).called(1);
    });

    test('_processQueue executes a job and updates its status correctly', () async {
      // Arrange
      when(mockJobRepository.createJob(
        jobType: anyNamed('jobType'),
        requestPayload: anyNamed('requestPayload'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => testJob);
      
      final jobResult = JobResult(responsePayload: '{"result":"success"}');
      when(mockJobWorker.execute(any)).thenAnswer((_) async => jobResult);

      // Act
      await jobManager.submitJob(jobType: 'test_job', requestPayload: '{}');
      // Wait until the final step of the process has been called.
      await untilCalled(mockJobRepository.completeJob(any, any));

      // --- THIS IS THE FIX ---
      // Add a micro-delay to allow the async 'finally' block in the
      // JobManager to execute before we run our final verification.
      await Future.delayed(Duration.zero);

      // Assert
      verifyInOrder([
        mockJobRepository.updateJobStatus(1, JobStatus.inProgress),
        mockJobRepository.completeJob(1, jobResult),
      ]);
      // The controller is notified 3 times: on submit, on start, and on complete.
      verify(mockJobController.loadJobs()).called(3);
    });

    test('_processQueue handles worker execution failure', () async {
      // Arrange
      when(mockJobRepository.createJob(
        jobType: anyNamed('jobType'),
        requestPayload: anyNamed('requestPayload'),
        priority: anyNamed('priority'),
      )).thenAnswer((_) async => testJob);

      when(mockJobWorker.execute(any)).thenThrow(Exception('Execution failed'));

      // Act
      await jobManager.submitJob(jobType: 'test_job', requestPayload: '{}');
      // Wait until the job is marked as failed.
      await untilCalled(mockJobRepository.updateJobStatus(any, JobStatus.failed));
      
      // Assert
      verify(mockJobRepository.updateJobStatus(1, JobStatus.failed)).called(1);
      verifyNever(mockJobRepository.completeJob(any, any));
    });
  });
}