# backend/recipe_tools_service.py
import json
from .prompts import get_find_similar_prompt

def handle_find_similar(request_json, model):
    """Handles the specific task of finding similar recipes."""
    find_similar_request = request_json['find_similar_request']
    primary_recipe = find_similar_request['primary_recipe']
    candidate_recipes = find_similar_request['candidate_recipes']

    prompt_text = get_find_similar_prompt()
    prompt_parts = [
        prompt_text,
        "\n--- PRIMARY RECIPE ---\n", json.dumps(primary_recipe),
        "\n--- CANDIDATE RECIPES ---\n", json.dumps(candidate_recipes)
    ]

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    # if request_json.get("developer_mode", False):
    #    return {"prompt_text": prompt_parts[0]}
    
    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)

