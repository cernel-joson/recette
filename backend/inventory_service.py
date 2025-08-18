import json
from prompts import get_inventory_parse_prompt, get_meal_ideas_prompt

def handle_inventory_import(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'inventory_import_request' in request_json:
        inventory_text = request_json['inventory_import_request']['text']
        # NEW: Get locations from the request to pass to the prompt
        locations = request_json['inventory_import_request'].get('locations', [])
        prompt = get_inventory_parse_prompt(inventory_text, locations)
        prompt_parts = [prompt]
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)

def handle_meal_suggestion(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'meal_suggestion_request' in request_json:        
        data = request_json['meal_suggestion_request']
        inventory = data.get('inventory', [])
        profile = data.get('dietary_profile', 'No profile provided.')
        intent = data.get('user_intent', 'No specific situation provided.')
        
        prompt = get_meal_ideas_prompt(inventory, profile, intent)
        prompt_parts = [prompt]
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)