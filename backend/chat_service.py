# backend/chat_service.py
from . import prompts
from . import gemini_service

def handle_chat_request(request_json, model):
    """
    Orchestrates the conversational chat process.
    """
    chat_request = request_json['chat_request']
    developer_mode = request_json.get("developer_mode", False)

    # 1. Extract data from the request
    user_message = chat_request.get('user_message', '')
    profile_text = chat_request.get('profile_text', '')
    inventory_text = chat_request.get('inventory_text', '')
    chat_history = chat_request.get('chat_history', [])

    # 2. Build the prompt using the prompts module
    prompt_parts = prompts.build_chat_prompt(
        user_message,
        profile_text,
        inventory_text,
        chat_history
    )
    
    # 3. Call the central Gemini service
    # Note: Chat responses are not expected to be JSON, so we handle them differently.
    # We can enhance gemini_service later if needed, but for now, a direct call is fine.
    
    if developer_mode:
        return {"prompt_text": "".join(prompt_parts)}

    response = model.generate_content(prompt_parts)
    
    # For chat, we often want the direct text response
    return {
        "prompt_text": "".join(prompt_parts),
        "result": response.text, # Return the raw text response
        "error": None
    }