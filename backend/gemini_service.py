# backend/gemini_service.py
import json
from vertexai.generative_models import GenerativeModel

def call_gemini(model: GenerativeModel, prompt_parts: list, developer_mode: bool = False):
    """
    Handles the interaction with the Gemini model, including prompt execution,
    response parsing, and error handling.

    Args:
        model: The initialized GenerativeModel instance.
        prompt_parts: A list of parts that make up the complete prompt.
        developer_mode: If True, returns the prompt text instead of calling the AI.

    Returns:
        A dictionary containing the prompt text, raw response, parsed result, and any errors.
    """
    # Join only the string parts of the prompt for the text version.
    full_prompt_text = "".join([p for p in prompt_parts if isinstance(p, str)])

    if developer_mode:
        return {"prompt_text": full_prompt_text, "raw_response_text": None, "result": None, "error": None}

    try:
        response = model.generate_content(prompt_parts)
        raw_response_text = response.text

        # Standardize the JSON cleaning process
        json_string = raw_response_text.strip().replace("```json", "").replace("```", "").strip()
        ai_result = json.loads(json_string)
        error_message = None

    except json.JSONDecodeError as e:
        ai_result = None
        error_message = f"Failed to parse AI response as JSON: {e}. Raw response: {raw_response_text}"
    except Exception as e:
        ai_result = None
        error_message = f"An unexpected error occurred: {e}"

    return {
        "prompt_text": full_prompt_text,
        "raw_response_text": raw_response_text,
        "result": ai_result,
        "error": error_message
    }