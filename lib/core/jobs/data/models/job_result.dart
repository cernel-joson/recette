/// A simple data class to hold the results of a completed job worker.
class JobResult {
  final String responsePayload;
  final String? title;
  final String? promptText; // <-- NEW FIELD
  final String? rawAiResponse; // <-- NEW FIELD

  JobResult({
    required this.responsePayload,
    this.title,
    this.promptText, // <-- NEW
    this.rawAiResponse, // <-- NEW
  });
}