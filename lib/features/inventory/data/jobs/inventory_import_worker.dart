// lib/features/inventory/data/jobs/inventory_import_worker.dart
import 'dart:convert';
import 'package:recette/core/core.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';

class InventoryImportWorker implements JobWorker {
  @override
  Future<JobResult> execute(Job job) async {
    final requestData = json.decode(job.requestPayload);
    final inventoryText = requestData['text'];
    final locations = List<String>.from(requestData['locations'] ?? []);

    final requestBody = {
      'inventory_import_request': {
        'text': inventoryText,
        'locations': locations,
      }
    };

    final responseBody = await ApiHelper.analyzeRaw(requestBody, model: AiModel.flash);
    final aiResult = responseBody['result'];
    final promptText = responseBody['prompt_text'];
    final rawAiResponse = responseBody['raw_response_text'];


    return JobResult(
      responsePayload: json.encode(aiResult), // The AI result is a list of items
      promptText: promptText,
      rawAiResponse: rawAiResponse,
      title: 'Parsed Inventory List',
    );
  }

  @override
  Future<void> onComplete(Job job) async {
    if (job.responsePayload == null || job.responsePayload!.isEmpty) return;

    // 1. Instantiate the services we need.
    final inventoryService = InventoryService();
    final jobRepo = JobRepository();

    // 2. Decode the job's payload.
    final parsedItems = json.decode(job.responsePayload!) as List<dynamic>;

    // 3. Delegate the entire import and replacement logic to the service.
    await inventoryService.replaceInventoryFromImport(parsedItems);

    // 4. Archive the job now that its work is complete.
    await jobRepo.updateJobStatus(job.id!, JobStatus.archived);
  }
}