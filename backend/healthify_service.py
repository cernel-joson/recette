# backend/healthify_service.py
from . import prompts
from . import gemini_service

def handle_healthify_recipe(request_json, model):
    """
    Orchestrates the "healthify recipe" process:
    1. Extracts the original recipe and profile from the request.
    2. Builds the specific prompt for this task.
    3. Calls the Gemini service to generate the new, healthier recipe.
    """
    healthify_request = request_json['healthify_recipe_request']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data
    recipe_data = healthify_request.get('recipe_data', {})
    dietary_profile = healthify_request.get('dietary_profile', '')

    # 2. Build the prompt using the new prompt function
    prompt_parts = prompts.build_healthify_recipe_prompt(recipe_data, dietary_profile)
    
    # 3. Call the central Gemini service
    response_data = gemini_service.call_gemini(model, prompt_parts, developer_mode)

    return response_data
