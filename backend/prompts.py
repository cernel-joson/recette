import json
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
        "quantity_display": "The quantity exactly as it is written in the text (e.g., '2 or 3', '1/2', 'a splash'). THIS MUST BE A STRING.",
        "quantity_numeric": "The numeric value of the quantity, if possible. For '2 or 3', use 2.5. For '1/2', use 0.5. For non-numeric quantities like 'a splash', return null.",
        "unit": "The unit of measurement (e.g., 'cup', 'tbsp', 'clove')",
        "name": "The core name of the ingredient",
        "notes": "Any additional commentary, brand suggestions, or preparation notes (e.g., 'finely chopped', '(see note)')"
    }
  ],
  "instructions": [
        "A list of strings, with each string being a single step in the recipe."
  ],
  "other_timings": [
    {
        "label": "The name of any other time (e.g., 'Rest Time', 'Marinate Time')",
        "duration": "The duration for that time (e.g., '10 mins')"
    }
  ],
  "tags": [
      "A list of relevant tags like cuisine (e.g., 'Italian', 'Mexican'), meal type (e.g., 'Dinner', 'Dessert'), or key ingredients (e.g., 'Chicken', 'Pasta')."
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

def get_profile_review_prompt(profile_text):
    """Creates the prompt for reviewing a user's dietary profile text."""
    return f"""
    You are an expert dietary assistant. A user has provided text for their health rules and their personal preferences.
    Your task is to analyze this text and refine it into two distinct, well-structured summaries.

    1.  **Health Rules & Allergies:** This section should only contain clear, actionable medical directives and allergies. Extract these from the user's text.
    2.  **Likes, Dislikes & Preferences:** This section should contain subjective tastes, cuisine preferences, and other non-critical information.

    Return a single, clean JSON object with the following structure:
    {{
        "suggested_rules": "Your refined summary of the user's health rules and allergies.",
        "suggested_preferences": "Your refined summary of the user's likes, dislikes, and preferences."
    }}

    Do not include any text or formatting before or after the JSON object.

    Here is the user's text to analyze:
    ---
    {profile_text}
    ---
    """

def get_health_check_prompt(profile_text, recipe_data):
    """NEW: Creates the prompt for analyzing a recipe against a dietary profile."""
    return f"""
    You are an expert nutritional analyst. Your task is to analyze a recipe against a user's specific dietary guidelines.

    Here are the user's dietary guidelines:
    ---
    {profile_text}
    ---

    Here is the recipe data you need to analyze:
    ---
    {recipe_data}
    ---

    Your Task:
    1. Assign a `health_rating` of `GREEN`, `YELLOW`, or `RED`.
       - `GREEN` means it aligns perfectly with the user's goals.
       - `YELLOW` means it's acceptable in moderation but has some minor issues.
       - `RED` means it significantly violates one or more core health rules.
    2. Write a brief, one or two-sentence `summary` of your findings.
    3. Provide a bulleted list of specific, actionable `suggestions` for improvement.

    Return your response as a single, clean JSON object with the following structure:
    {{
      "health_rating": "...",
      "summary": "...",
      "suggestions": [ "..." ]
    }}
    """
    
# --- REVISED PROMPT WITH NUANCED ANALYSIS ---
def get_nutritional_estimation_prompt(recipe_text):
    """Creates the prompt for estimating nutritional information from text."""
    return f"""
    You are a meticulous nutritional analyst. Your task is to analyze the provided recipe text and calculate the estimated nutritional information PER SERVING.

    Follow these steps to arrive at your answer:
    1.  First, identify the total number of servings for the recipe. If not specified, assume 4 servings.
    2.  Scan the ingredient list for keywords that modify nutritional content, such as "low-sodium", "unsalted", "reduced-sugar", or "light". You MUST adjust your calculations based on these modifiers. For example, "low-sodium chicken stock" has significantly less sodium than regular stock.
    3.  For standard ingredients, use the following conversion factors as a baseline:
        - 1 teaspoon of table salt = 2300mg sodium
        - 1 tablespoon of table salt = 6900mg sodium
        - 1 tablespoon of soy sauce = 900mg sodium
        - 1 cup of REGULAR chicken/beef/vegetable stock = 800mg sodium
        - 1 teaspoon of sugar = 4g sugar
        - 1 tablespoon of sugar = 12g sugar
        - 1 tablespoon of honey/maple syrup = 17g sugar
    4.  For any ingredients not listed, use your general nutritional knowledge to estimate their values.
    5.  Sum the totals for all relevant nutrients.
    6.  Divide the total amount of each nutrient by the number of servings to get the per-serving value.
    7.  Finally, format your per-serving calculations into the required JSON object.

    You MUST return a single, clean JSON object with the EXACT following structure. Do not add, remove, or change any of the keys.

    {{
      "calories": "...",
      "protein_grams": "...",
      "carbohydrates_grams": "...",
      "sugar_grams": "...",
      "fat_grams": "...",
      "saturated_fat_grams": "...",
      "sodium_milligrams": "...",
      "fiber_grams": "...",
      "cholesterol_milligrams": "..."
    }}

    - All values must be returned as strings, rounded to the nearest whole number.
    - If a specific value cannot be determined, you MUST return "N/A" for that key.
    - Do not include any text, notes, or formatting before or after the JSON object.

    Here is the recipe text to analyze:
    ---
    {recipe_text}
    ---
    """

def get_inventory_parse_prompt(inventory_text, locations):
    """Creates the prompt for parsing a block of inventory text, now with location awareness."""
    return f"""
    You are an expert inventory parsing API. Your job is to analyze the raw text, which contains a list of food items, potentially grouped under location headings.

    First, here are the valid locations available: {locations}

    Analyze the text and extract each item into a structured format. If an item appears under a heading (e.g., '--- FRIDGE ---' or 'In the Pantry:'), associate it with the corresponding location from the provided list. If no heading is present, the location_name should be null.

    Please return a single, clean JSON array of objects with the following structure:
    [
      {{
        "name": "The core name of the ingredient",
        "quantity": "The quantity, if available (e.g., '2', '1/2', 'a splash')",
        "unit": "The unit of measurement, if available (e.g., 'cup', 'tbsp', 'gallon')",
        "location_name": "The name of the location from the valid list, or null if not specified"
      }}
    ]

    - Do not include any text or formatting before or after the JSON array.
    - If the input text is empty or contains no items, return an empty array [].

    Here is the raw text to analyze:
    ---
    {inventory_text}
    ---
    """

def get_meal_ideas_prompt(inventory_list, dietary_profile, user_intent):
    """Creates a sophisticated prompt for generating context-aware meal ideas."""
    return f"""
    You are an empathetic and expert kitchen assistant. Your goal is to help the user decide what to make by providing simple, actionable, and relevant meal ideas.

    Analyze the complete context provided below.

    **CONTEXT:**
    - **User's Dietary Profile:** {dietary_profile}
    - **Current Inventory:** {inventory_list}
    - **User's Immediate Situation:** {user_intent}

    **YOUR TASK:**
    Based on all of the provided context, suggest 3 to 5 simple meal ideas. For each idea, provide a title and a brief, one-sentence description explaining why it's a good fit for the user's situation.

    Return a single, clean JSON array of objects with the following structure:
    [
      {{
        "title": "...",
        "description": "..."
      }}
    ]

    - Do not include any text or formatting before or after the JSON array.
    """

# --- NEW: A more robust prompt function for the enhancement service ---
def get_enhancement_prompt(tasks):
    """Dynamically builds a more robust prompt for AI enhancement tasks."""

    # --- 1. Define the complete JSON structure we expect ---
    json_template = {
        "results": [
            {
                "tags": "...",
                "health_analysis": {
                    "health_rating": "...",
                    "summary": "...",
                    "suggestions": ["..."]
                }
            }
        ]
    }

    # --- 2. Build the instruction list dynamically ---
    prompt_parts = [
        "You are an expert recipe and nutritional analysis API. Your job is to perform a set of tasks on the provided recipe data and return a single, clean JSON object. Your response MUST strictly follow the structure defined in the 'JSON_RESPONSE_TEMPLATE'.",
    ]

    task_descriptions = []
    if "generateTags" in tasks:
        task_descriptions.append("- **generateTags**: Analyze the recipe's title and ingredients to generate a JSON array of 5-7 relevant tags (e.g., cuisine, meal type, key ingredient). Populate the 'tags' field in the template with this array.")
    
    if "healthCheck" in tasks:
        task_descriptions.append("- **healthCheck**: Analyze the recipe against the user's dietary profile. Populate the 'health_analysis' object in the template with a 'health_rating' ('GREEN', 'YELLOW', or 'RED'), a one-sentence 'summary', and a list of 'suggestions'.")
    
    if "findSimilar" in tasks:
        # Handling findSimilar separately as it has a different output structure
        return """
          You are an expert recipe analyst. Compare the 'PRIMARY RECIPE' to the 'CANDIDATE RECIPES'.
          Based on title and ingredients, identify which candidates are semantically very similar (a variation of the same core dish).
          Return a single JSON object with ONE key: 'similar_recipe_ids', containing a list of the integer IDs of ONLY the similar recipes.
        """

    # --- 3. Assemble the final prompt ---
    prompt_parts.append("\n**TASKS TO PERFORM:**")
    prompt_parts.extend(task_descriptions)
    
    prompt_parts.append("\n**JSON_RESPONSE_TEMPLATE:**")
    prompt_parts.append("```json")
    prompt_parts.append(json.dumps(json_template, indent=2))
    prompt_parts.append("```")
    prompt_parts.append("IMPORTANT: If a requested task cannot be completed or is not applicable, return the corresponding key with a default value (e.g., an empty list `[]` or an empty object `{}`), but always include the key to maintain the structure.")

    return "\n".join(prompt_parts)