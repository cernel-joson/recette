# This is the implementation for the Google Cloud function
# It runs on the back-end to accept requests for AI analysis# main.py

import functions_framework
from flask import jsonify
import vertexai
from vertexai.generative_models import GenerativeModel
import json

from . import recipe_analysis_service
from . import recipe_tools_service
from . import inventory_service
from . import profile_service
from prompts import get_conversational_chat_prompt

# --- Initialization ---
PROJECT_ID = "recette-fdf64"
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

        # --- THE REFACTORED ROUTER ---
        if 'recipe_analysis_request' in request_json:
            # All recipe-related tasks now go to this single handler.
            response_data = recipe_analysis_service.handle_recipe_analysis(request_json, model)
        elif 'find_similar_request' in request_json:
            response_data = recipe_tools_service.handle_find_similar(request_json, model)
        elif 'meal_suggestion_request' in request_json:
            response_data = inventory_service.handle_meal_suggestion(request_json, models.get("pro"))
        elif 'inventory_import_request' in request_json:
            response_data = inventory_service.handle_inventory_import(request_json, model)
        elif 'review_text' in request_json:
            response_data = profile_service.handle_profile_review(request_json, model)
        elif 'chat_request' in request_json:
            # 1. Get data from the app's request
            user_message = request_json.get('user_message', '')
            profile_text = request_json.get('profile_text', '')
            inventory_text = request_json.get('inventory_text', '')
            chat_history = request_json.get('chat_history', []) # Expects a list of {'role': 'user'/'model', 'text': '...'}

            # 2. Create the prompt
            prompt = get_conversational_chat_prompt(user_message, profile_text, inventory_text, chat_history)

            # 3. Call Gemini
            response = model.generate_content(prompt)
            json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
            ai_result = json.loads(json_string)
            
            return {
                "prompt_text": prompt,
                "result": ai_result
            }

            # 4. Return the plain text response
            return response.text
        else:
            raise Exception("Invalid request. Could not determine the correct handler.", 400)

        return (json.dumps(response_data), 200, headers)
    
    except Exception as e:
        status_code = 500
        if len(e.args) > 1 and isinstance(e.args[1], int):
            status_code = e.args[1]
        error_message = str(e.args[0])
        return (jsonify({"error": error_message}), status_code, headers)