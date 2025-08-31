from . import prompts
from . import gemini_service

def handle_inventory_import(request_json, model):
    """
    Orchestrates the inventory import process:
    1. Extracts data from the request.
    2. Builds the prompt using the prompts module.
    3. Calls the Gemini service to get the result.
    """
    inventory_import_request = request_json['inventory_import_request']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data
    inventory_text = inventory_import_request.get('inventory_import_request', {}).get('text', '')
    locations = inventory_import_request.get('locations', [])

    # 2. Build the prompt
    prompt_parts = prompts.get_inventory_parse_prompt(inventory_text, locations)
    
    # 3. Call the central Gemini service
    response_data = gemini_service.call_gemini(model, prompt_parts, developer_mode)

    return response_data

def handle_meal_suggestion(request_json, model):
    """
    Orchestrates the meal suggestion process:
    1. Extracts data from the request.
    2. Builds the prompt using the prompts module.
    3. Calls the Gemini service to get the result.
    """
    meal_suggestion_request = request_json['meal_suggestion_request']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data
    inventory = meal_suggestion_request.get('inventory', [])
    profile = meal_suggestion_request.get('dietary_profile', 'No profile provided.')
    intent = meal_suggestion_request.get('user_intent', 'No specific situation provided.')

    # 2. Build the prompt
    prompt_parts = prompts.get_meal_ideas_prompt(inventory, profile, intent)
    
    # 3. Call the central Gemini service
    response_data = gemini_service.call_gemini(model, prompt_parts, developer_mode)

    return response_data