import json
from prompts import get_health_check_prompt

def handle_health_check(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'health_check' in request_json:
        profile = request_json.get('dietary_profile')
        recipe = request_json.get('recipe_data')
        if not profile or not recipe:
            raise Exception("Health check requires 'dietary_profile' and 'recipe_data'.", 400)
        prompt = get_health_check_prompt(json.dumps(profile), json.dumps(recipe))
        prompt_parts = [prompt] # Assign to prompt_parts
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)