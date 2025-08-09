import json
from prompts import get_text_prompt, get_image_prompt
from utils import scrape_text_from_url
import base64
from vertexai.generative_models import Part

def handle_recipe_parsing(request_json, model):
    """Handles all requests related to parsing a new recipe."""
    prompt_parts = []
    
    if 'url' in request_json:
        scraped_text = scrape_text_from_url(request_json['url'])
        if not scraped_text or len(scraped_text) < 20:
            raise Exception("Insufficient text scraped from URL.", 400)
        prompt = get_text_prompt(scraped_text)
        prompt_parts = [prompt]
    elif 'text' in request_json:
        pasted_text = request_json['text']
        if not pasted_text or len(pasted_text) < 20:
            raise Exception("Insufficient text provided for analysis.", 400)
        prompt = get_text_prompt(pasted_text)
        prompt_parts = [prompt]
    elif 'image' in request_json:
        image_data = request_json['image']
        prompt = get_image_prompt()
        image_part = Part.from_data(data=base64.b64decode(image_data), mime_type="image/jpeg")
        prompt_parts = [image_part, prompt]
    else:
        raise Exception("Invalid parsing request.", 400)

    # In developer mode, we return the prompt itself. Otherwise, we call the model.
    if request_json.get("developer_mode", False):
        # We need to handle the image part for display
        if isinstance(prompt_parts[0], Part):
             return {"prompt_text": prompt_parts[1], "has_image": True}
        return {"prompt_text": prompt_parts[0]}

    response = model.generate_content(prompt_parts)
    json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
    return json.loads(json_string)