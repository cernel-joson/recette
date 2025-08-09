import json
from prompts import get_nutritional_estimation_prompt

def handle_nutritional_estimation(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'nutritional_estimation_request' in request_json:
        recipe_text = request_json['nutritional_estimation_request']['text']
        prompt = get_nutritional_estimation_prompt(recipe_text)
        prompt_parts = [prompt]
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)