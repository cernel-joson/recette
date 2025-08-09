# This is the implementation for the Google Cloud function
# It runs on the back-end to accept requests for AI analysis

import functions_framework
from flask import jsonify
import requests
import vertexai
from vertexai.generative_models import GenerativeModel
import json
import recipe_parser
import enhancement_service
import inventory_service
import nutrition_service
import health_check_service
import profile_service

# --- Initialization ---
PROJECT_ID = "winged-oath-465602-i5"
GCP_REGION = "us-central1"

vertexai.init(project=PROJECT_ID, location=GCP_REGION)

models = {
    "pro": GenerativeModel("gemini-2.5-pro"),
    "flash": GenerativeModel("gemini-2.5-flash")
}

# --- Main Cloud Function ---
@functions_framework.http
def recipe_analyzer_api(request):
    """
    HTTP Cloud Function to analyze recipe data from a URL, text, or image.
    It now intelligently selects the Gemini model based on the request.
    """
    # --- 1. Set CORS headers for preflight requests ---
    if request.method == "OPTIONS":
        headers = {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Max-Age": "3600",
        }
        return ("", 204, headers)

    # --- 2. Set CORS headers for the main request ---
    headers = {"Access-Control-Allow-Origin": "*"}

    try:
        # --- 3. Parse Request and Select Model ---
        request_json = request.get_json(silent=True)

        if not request_json:
            raise Exception("Invalid request. JSON body is required.", 400)

        model_choice_key = request_json.get("model_choice", "gemini-2.5-pro")
        model = models.get("flash" if "flash" in model_choice_key else "pro")

        response_data = {}

        # --- THE ROUTER ---
        # This is now a clean, simple block that delegates work.
        if 'url' in request_json or 'text' in request_json or 'image' in request_json:
            response_data = recipe_parser.handle_recipe_parsing(request_json, model)
        elif 'enhancement_request' in request_json:
            response_data = enhancement_service.handle_enhancement(request_json, model)
        elif 'inventory_import_request' in request_json:
            response_data = inventory_service.handle_inventory_import(request_json, model)
        elif 'nutritional_estimation_request' in request_json:
            response_data = nutrition_service.handle_nutritional_estimation(request_json, model)
        elif 'health_check' in request_json:
            response_data = health_check_service.handle_health_check(request_json, model)
        elif 'review_text' in request_json:
            response_data = profile_service.handle_profile_review(request_json, model)
        else:
            raise Exception("Invalid request. Could not determine the correct handler.", 400)

        return (json.dumps(response_data), 200, headers)
    
    except Exception as e:
        status_code = 500
        if len(e.args) > 1 and isinstance(e.args[1], int):
            status_code = e.args[1]
        error_message = str(e.args[0])
        return (jsonify({"error": error_message}), status_code, headers)