import json
from prompts import get_enhancement_prompt

def handle_enhancement(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'enhancement_request' in request_json:
        enhancement_data = request_json['enhancement_request']
        tasks = enhancement_data.get('tasks', [])
        
        # This is now the primary way to call the prompt builder
        prompt = get_enhancement_prompt(tasks)
        prompt_parts.append(prompt)

        if 'findSimilar' in tasks:
            new_recipe = enhancement_data['recipe_data'][0]
            candidates = enhancement_data.get('candidate_recipes', [])
            prompt_parts.append("\n--- PRIMARY RECIPE ---")
            prompt_parts.append(json.dumps(new_recipe))
            prompt_parts.append("\n--- CANDIDATE RECIPES ---")
            prompt_parts.append(json.dumps(candidates))
        else:
            recipe = enhancement_data['recipe_data'][0]
            dietary_profile = enhancement_data.get('dietary_profile', '')
            prompt_parts.append("\n--- PRIMARY RECIPE ---")
            prompt_parts.append(json.dumps(recipe))
            if dietary_profile and 'healthCheck' in tasks:
                prompt_parts.append("\n--- DIETARY PROFILE ---")
                prompt_parts.append(dietary_profile)
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)