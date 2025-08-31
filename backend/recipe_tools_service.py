# backend/recipe_tools_service.py
from . import prompts
from . import gemini_service

def handle_find_similar(request_json, model):
    """
    Orchestrates the recipe similarity comparison process.
    1. Extracts primary and candidate recipes from the request.
    2. Builds the prompt using the prompts module.
    3. Calls the Gemini service to get the result.
    """
    find_similar_request = request_json['find_similar_request']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data
    primary_recipe = find_similar_request.get('primary_recipe', {})
    candidate_recipes = find_similar_request.get('candidate_recipes', [])

    # 2. Build the prompt
    prompt_parts = prompts.build_find_similar_prompt(primary_recipe, candidate_recipes)
    
    # 3. Call the central Gemini service
    response_data = gemini_service.call_gemini(model, prompt_parts, developer_mode)
    
    # The result from Gemini will be in response_data['result']
    return response_data