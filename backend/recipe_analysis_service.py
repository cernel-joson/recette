# backend/recipe_analysis_service.py
from . import prompts
from . import gemini_service

def handle_recipe_analysis(request_json, model):
    """
    Orchestrates the recipe analysis process:
    1. Extracts data from the request.
    2. Builds the prompt using the prompts module.
    3. Calls the Gemini service to get the result.
    """
    analysis_request = request_json['recipe_analysis_request']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data
    tasks = analysis_request.get('tasks', [])
    recipe_data = analysis_request.get('recipe_data', {})
    dietary_profile = analysis_request.get('dietary_profile', '')

    # 2. Build the prompt
    prompt_parts = prompts.build_recipe_analysis_prompt(tasks, recipe_data, dietary_profile)
    
    # 3. Call the central Gemini service
    response_data = gemini_service.call_gemini(model, prompt_parts, developer_mode)

    return response_data