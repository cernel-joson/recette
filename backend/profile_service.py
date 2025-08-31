from . import prompts
from . import gemini_service

def handle_profile_review(request_json, model):
    """
    Orchestrates the profile review process:
    1. Extracts data from the request.
    2. Builds the prompt using the prompts module.
    3. Calls the Gemini service to get the result.
    """
    review_text = request_json['review_text']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data

    # 2. Build the prompt
    prompt_parts = prompts.get_profile_review_prompt(review_text)
    
    # 3. Call the central Gemini service
    response_data = gemini_service.call_gemini(model, prompt_parts, developer_mode)

    return response_data