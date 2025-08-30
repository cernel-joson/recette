import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/logic/job_broadcast_service.dart';

class JobRepository {
  // --- This is the list of essential columns for job processing ---
  static const _lightweightColumns = [
    'id',
    'job_type',
    'title',
    'status',
    'priority',
    'request_fingerprint',
    'request_payload',
    'response_payload',
    'created_at',
    'completed_at',
    'error_message'
  ];

  /// Creates a new job in the database and returns it with its new ID.
  Future<Job> createJob({
    required String jobType,
    required String requestPayload,
    JobPriority priority = JobPriority.normal,
    String? requestFingerprint,
    String? promptText,
  }) async {
    final now = DateTime.now();
    final job = Job(
      jobType: jobType,
      requestPayload: requestPayload,
      createdAt: now,
      priority: priority,
      requestFingerprint: requestFingerprint,
      promptText: promptText,
      status: JobStatus.queued,
    );
    
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('job_history', job.toMap());
    JobBroadcastService.instance.broadcastJobDataChanged();

    // Return a new Job object that includes the database-assigned ID.
    return Job.fromMap({...job.toMap(), 'id': id});
  }

  /// Retrieves all jobs from the database, ordered by creation date.
  Future<List<Job>> getAllJobs() async {
    
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'job_history',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Job.fromMap(maps[i]));
  }

  /// Fetches the oldest job that is still in the 'queued' state.
  Future<Job?> getNextQueuedJob() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'job_history',
      columns: _lightweightColumns,
      where: 'status = ?',
      whereArgs: [JobStatus.queued.name],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Job.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves a single job by its ID.
  Future<Job?> getJobById(int jobId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'job_history',
      where: 'id = ?',
      whereArgs: [jobId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Job.fromMap(maps.first);
    }
    return null;
  }
  
  /// Updates the status of an existing job.
  Future<void> updateJobStatus(int jobId, JobStatus status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'job_history',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [jobId],
    );
    JobBroadcastService.instance.broadcastJobDataChanged();
  }

  /// --- NEW: Deletes all jobs that are in a 'complete' or 'failed' state. ---
  /* Future<void> deleteCompleted() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('job_history',
        where: 'status = ? OR status = ?',
        whereArgs: [JobStatus.complete.name, JobStatus.failed.name]);
  } */
  
  
  /// Marks a job as complete, saving the final response and completion time.
  Future<void> completeJob(int jobId, JobResult result) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'job_history',
      {
        'status': JobStatus.complete.name,
        'response_payload': result.responsePayload,
        'title': result.title,
        'prompt_text': result.promptText,
        'raw_ai_response': result.rawAiResponse,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [jobId],
    );
    JobBroadcastService.instance.broadcastJobDataChanged();
  }
  
  /// Marks a job as failed, saving the error message.
  Future<void> failJob(int jobId, String errorMessage) async {
    
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'job_history',
      {
        'status': JobStatus.failed.name,
        'error_message': errorMessage, // Save the specific error
      },
      where: 'id = ?',
      whereArgs: [jobId],
    );
    JobBroadcastService.instance.broadcastJobDataChanged();
  }
}