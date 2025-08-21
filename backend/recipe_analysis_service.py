import json
from .prompts import get_recipe_analysis_prompt # Use the new unified prompt
from .utils import scrape_text_from_url
import base64
from vertexai.generative_models import Part

def handle_recipe_analysis(request_json, model):
    analysis_request = request_json['recipe_analysis_request']
    
    tasks = analysis_request.get('tasks', [])
    recipe_data = analysis_request.get('recipe_data', {})
    dietary_profile = analysis_request.get('dietary_profile', '')
    has_image = 'image' in recipe_data

    prompt_text = get_recipe_analysis_prompt(tasks, has_image=has_image)
    prompt_parts = [prompt_text]

    # --- THIS IS THE FIX ---
    # Add the correct context based on whether we are parsing or just analyzing.
    if 'parse' in tasks:
        if 'url' in recipe_data:
            scraped_text = scrape_text_from_url(recipe_data['url'])
            prompt_parts.extend(["\n--- RECIPE URL CONTENT ---\n", scraped_text])
        elif 'text' in recipe_data:
            pasted_text = recipe_data['text']
            prompt_parts.extend(["\n--- RECIPE TEXT ---\n", pasted_text])
        elif has_image:
            image_data = recipe_data['image']
            image_part = Part.from_data(data=base64.b64decode(image_data), mime_type="image/jpeg")
            prompt_parts = [image_part, prompt_text] # Image must come first
    else:
        # If not parsing, the recipe data itself is the context.
        prompt_parts.append(f"\n--- RECIPE JSON TO ANALYZE ---\n{json.dumps(recipe_data)}")

    if "healthCheck" in tasks and dietary_profile:
        prompt_parts.extend(["\n--- DIETARY PROFILE FOR HEALTH CHECK ---\n", dietary_profile])
    
    full_prompt_text = "".join([p for p in prompt_parts if isinstance(p, str)])

    if request_json.get("developer_mode", False):
        return {"prompt_text": full_prompt_text, "has_image": has_image}

    # --- THIS IS THE FIX: Capture and return the raw response ---
    response = model.generate_content(prompt_parts)
    raw_response_text = response.text
    ai_result = None
    error_message = None

    try:
        # Attempt to parse the JSON
        json_string = raw_response_text.strip().replace("```json", "").replace("```", "").strip()
        ai_result = json.loads(json_string)
    except json.JSONDecodeError as e:
        # If parsing fails, capture the error message
        error_message = f"Failed to parse AI response as JSON: {e}"

    # Return a standardized object with all debug information
    return {
        "prompt_text": full_prompt_text,
        "raw_response_text": raw_response_text,
        "result": ai_result,
        "error": error_message
    }