import json
from prompts import get_unified_recipe_analysis_prompt # <-- Use the new prompt
from prompts import get_text_prompt, get_image_prompt
from utils import scrape_text_from_url
import base64
from vertexai.generative_models import Part

def handle_recipe_parsing(request_json, model):
    """
    Handles all new recipe additions and performs all requested analysis
    tasks in a single, unified AI call.
    """
    # Extract the list of tasks from the request, default to just parsing.
    tasks = request_json.get('tasks', [])
    prompt_text = get_unified_recipe_analysis_prompt(tasks)
    prompt_parts = [prompt_text]

    # Add the recipe data (text, url, or image) to the prompt
    if 'url' in request_json:
        scraped_text = scrape_text_from_url(request_json['url'])
        prompt_parts.append(f"\n--- RECIPE URL CONTENT ---\n{scraped_text}")
    elif 'text' in request_json:
        pasted_text = request_json['text']
        prompt_parts.append(f"\n--- RECIPE TEXT ---\n{pasted_text}")
    elif 'image' in request_json:
        image_data = request_json['image']
        image_part = Part.from_data(data=base64.b64decode(image_data), mime_type="image/jpeg")
        # For images, the instructions go first, then the image
        prompt_parts = [image_part, prompt_text]
    else:
        raise Exception("Invalid parsing request.", 400)

    # Developer mode still returns the prompt for debugging
    if request_json.get("developer_mode", False):
        return {"prompt_text": prompt_parts[-1]} # Return the main text part of the prompt

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)