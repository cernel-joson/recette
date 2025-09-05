# backend/gemini_service.py
import json
from vertexai.generative_models import GenerativeModel

def call_gemini(model: GenerativeModel, prompt_parts: list, developer_mode: bool = False):
    """
    Handles the interaction with the Gemini model, including prompt execution,
    response parsing, and error handling.
    """
    full_prompt_text = "".join([p for p in prompt_parts if isinstance(p, str)])

    if developer_mode:
        return {"prompt_text": full_prompt_text, "raw_response_text": None, "result": None, "error": None}

    try:
        response = model.generate_content(prompt_parts)

        # --- THIS IS THE FIX ---
        # The 'response.text' property can be unreliable. The robust way to get the
        # full text content is to iterate through the response 'parts' and join them.
        # This handles all cases and ensures a string is always produced.
        raw_response_text = "".join([part.text for part in response.parts]) if hasattr(response, 'parts') and response.parts else response.text

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