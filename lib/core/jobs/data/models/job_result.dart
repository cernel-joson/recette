/// A simple data class to hold the results of a completed job worker.
class JobResult {
  final String responsePayload;
  final String? title;

  JobResult({required this.responsePayload, this.title});
}