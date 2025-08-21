import json
from prompts import get_profile_review_prompt

def handle_profile_review(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'review_text' in request_json:
        prompt = get_profile_review_prompt(request_json['review_text'])
        prompt_parts = [prompt] # Assign to prompt_parts
    else:
        raise Exception("Invalid parsing request.", 400)

    # Store the full prompt text before making the call.
    full_prompt_text = "".join([p for p in prompt_parts if isinstance(p, str)])

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    ai_result = json.loads(json_string)
    
    return {
        "prompt_text": full_prompt_text,
        "result": ai_result
    }