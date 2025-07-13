# This is the implementation for the Google Cloud function
# It runs on the back-end to accept requests for AI analysis

import functions_framework
from flask import jsonify
import requests
from bs4 import BeautifulSoup
import vertexai
from vertexai.generative_models import GenerativeModel, Part
import json

# --- Initialization ---
PROJECT_ID = "winged-oath-465602-i5"
GCP_REGION = "us-central1"
MODEL_NAME = "gemini-2.5-pro"

vertexai.init(project=PROJECT_ID, location=GCP_REGION)
model = GenerativeModel(MODEL_NAME)

# --- Refactored Prompts for DRY Principle ---

# Define the common JSON structure as a constant.
JSON_STRUCTURE_PROMPT = """
Please return a single, clean JSON object with the following structure:
{
  "title": "The name of the recipe",
  "description": "A short, one-sentence description of the dish",
  "prep_time": "The preparation time, if available (e.g., '20 minutes')",
  "cook_time": "The cooking time, if available (e.g., '45 minutes')",
  "total_time": "The total time, if available (e.g., '1 hour 5 minutes')",
  "servings": "The number of servings, if available (e.g., '4-6 people')",
  "ingredients": [
    { 
      "quantity": "...", 
      "unit": "...", 
      "name": "...",
      "notes": "..."
    }
  ],
  "instructions": [ "..." ],
  "other_timings": [
    {
        "label": "The name of any other time (e.g., 'Rest Time', 'Marinate Time')",
        "duration": "The duration for that time (e.g., '10 mins')"
    }
  ]
}

IMPORTANT: Extract "Prep Time", "Cook Time", and "Total Time" into their specific fields. If you find any OTHER labeled timings, put them in the "other_timings" list.

If an ingredient line contains a reference like "(see note)", search the entire document for the corresponding note text and place that text in the "notes" field.

If a field is not available, return an empty string "" or an empty list [].
Do not include any text or formatting before or after the JSON object.
"""

def get_text_prompt(scraped_text):
    """Creates the prompt for analyzing raw text."""
    return f"""
    You are an expert recipe parsing API. Your job is to analyze the raw text content, find the recipe, and extract its key components.
    The text may contain blog posts, comments, and other noise. You must ignore it and only focus on the recipe itself.

    {JSON_STRUCTURE_PROMPT}

    Here is the raw text to analyze:
    ---
    {scraped_text}
    ---
    """

def get_image_prompt():
    """Creates the prompt for analyzing an image."""
    return f"""
    You are a recipe parsing expert. Look at this image of a cookbook page or recipe card.
    Ignore any photos, page numbers, or decorative elements.
    Find the recipe text, extract its key components, and return it as a clean JSON object.

    {JSON_STRUCTURE_PROMPT}
    """

# --- Helper Function for Scraping ---
def scrape_text_from_url(url):
    """Scrapes all text from a URL and returns it as a string."""
    try:
        http_headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'}
        page = requests.get(url, headers=http_headers, timeout=10)
        page.raise_for_status() # Raises an exception for bad status codes
        soup = BeautifulSoup(page.content, 'html.parser')
        return soup.get_text(separator=' ', strip=True)
    except requests.exceptions.RequestException as e:
        raise Exception(f'Failed to fetch or scrape URL: {e}')


# --- Main Cloud Function ---
@functions_framework.http
def recipe_analyzer_api(request):
    """
    An HTTP-triggered Cloud Function that analyzes a recipe from a URL,
    raw text, or an image.
    """
    # Set CORS headers for preflight requests
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    # Set CORS headers for the main request
    headers = {
        'Access-Control-Allow-Origin': '*'
    }

    try:
        request_json = request.get_json(silent=True)
        if not request_json:
            raise Exception("Invalid request. JSON body is required.", 400)

        request_content = None

        # --- Refactored Logic to Prepare the AI Request ---
        if 'image' in request_json:
            image_data = request_json['image']
            prompt = get_image_prompt()
            image_part = Part.from_data(data=image_data, mime_type="image/jpeg")
            request_content = [image_part, prompt]

        elif 'text' in request_json:
            pasted_text = request_json['text']
            if not pasted_text or len(pasted_text) < 20:
                raise Exception("Insufficient text provided for analysis.", 400)
            prompt = get_text_prompt(pasted_text)
            request_content = [prompt] # For text-only, content is a list with one item

        elif 'url' in request_json:
            scraped_text = scrape_text_from_url(request_json['url'])
            if not scraped_text or len(scraped_text) < 20:
                raise Exception("Insufficient text scraped from URL for analysis.", 400)
            prompt = get_text_prompt(scraped_text)
            request_content = [prompt]

        else:
            raise Exception("Invalid request. 'image', 'text', or 'url' key is required.", 400)

        # --- Consolidated AI Call and Response Handling ---
        response = model.generate_content(request_content)
        
        # Clean up the response text to get pure JSON
        json_string = response.text.strip().replace("```json", "").replace("```", "").strip()
        
        # Validate that the response is valid JSON before returning
        parsed_json = json.loads(json_string)

        return (json.dumps(parsed_json), 200, headers)

    except Exception as e:
        # Centralized error handling
        status_code = 500
        # Check if a specific status code was passed with the exception
        if len(e.args) > 1 and isinstance(e.args[1], int):
            status_code = e.args[1]
        
        error_message = str(e.args[0])
        print(f"An error occurred: {error_message}")
        return (jsonify({"error": error_message}), status_code, headers)