import openai
import os
import json

def analyze_food_from_caption(caption, api_key=None):
    """
    Simple function to analyze food from caption using OpenAI
    
    Args:
        caption: The image caption describing the food
        api_key: OpenAI API key (optional, will use environment variable if not provided)
    
    Returns:
        Dictionary with ingredients and basic analysis
    """
    
    # Get API key
    if not api_key:
        api_key = os.getenv('OPENAI_API_KEY')
    
    if not api_key:
        return {"error": "OpenAI API key not found"}
    
    # Create OpenAI client
    client = openai.OpenAI(api_key=api_key)
    
    # Simple prompt
    prompt = f"""
    Analyze this food description and extract the ingredients with estimated quantities:
    
    Food: "{caption}"
    
    Please respond in JSON format:
    {{
        "detected_food": "name of the main dish",
        "ingredients": [
            {{"name": "ingredient1", "quantity_grams": 100}},
            {{"name": "ingredient2", "quantity_grams": 50}}
        ],
        "total_calories": 400,
        "inflammation_level": "low/medium/high"
    }}
    
    Keep it simple - just the main ingredients and rough estimates.
    """
    
    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=500
        )
        
        content = response.choices[0].message.content.strip()
        
        # Try to parse JSON
        try:
            # Find JSON in the response
            start = content.find('{')
            end = content.rfind('}') + 1
            if start != -1 and end != 0:
                json_str = content[start:end]
                result = json.loads(json_str)
                return result
            else:
                return {"error": "Could not parse JSON from response", "raw_response": content}
        except json.JSONDecodeError:
            return {"error": "Invalid JSON in response", "raw_response": content}
            
    except Exception as e:
        return {"error": f"OpenAI API error: {str(e)}"}

# Simple integration for your app.py
def add_to_app(entry, caption):
    """
    Simple function to add food analysis to your entry
    """
    if caption:
        analysis = analyze_food_from_caption(caption)
        entry['food_analysis'] = analysis
        
        # Add simple inflammation score to entry
        if 'inflammation_level' in analysis:
            entry['inflammation_level'] = analysis['inflammation_level']
    
    return entry 