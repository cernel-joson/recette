import json
from prompts import get_inventory_parse_prompt

def handle_inventory_import(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'inventory_import_request' in request_json:
        inventory_text = request_json['inventory_import_request']['text']
        prompt = get_inventory_parse_prompt(inventory_text)
        prompt_parts = [prompt]
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)