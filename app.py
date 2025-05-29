import os
import requests  # Make sure this import is at the top
from flask import Flask, render_template, request, redirect, url_for, send_from_directory, jsonify, session
from werkzeug.utils import secure_filename
import openai
from PIL import Image
import torch
from transformers import BlipProcessor, BlipForConditionalGeneration
from openai import OpenAI
import json
from dotenv import load_dotenv
from simple_openai_helper import analyze_food_from_caption
load_dotenv()

# ——— Flask setup ———
app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'change-me')

UPLOAD_FOLDER = os.path.join('static', 'uploads')
ALLOWED_IMG = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Simple data structures instead of database
entries = []
profile = None

# Helper: allow images
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_IMG

# ——— BLIP setup ———
processor = BlipProcessor.from_pretrained(
    "Salesforce/blip-image-captioning-base",
    use_fast=True
)
caption_model = BlipForConditionalGeneration.from_pretrained(
    "Salesforce/blip-image-captioning-base",
    device_map="auto"
)
try:
    caption_model = torch.compile(caption_model)
except Exception:
    pass
model_device = next(caption_model.parameters()).device

def analyze_image(path):
    image = Image.open(path).convert("RGB")
    inputs = processor(images=image, return_tensors="pt")
    inputs['pixel_values'] = inputs['pixel_values'].to(model_device)
    out = caption_model.generate(**inputs, max_length=50)
    caption = processor.decode(out[0], skip_special_tokens=True)
    return caption

# Initialize OpenAI client
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

GOOGLE_KEY = os.getenv('GOOGLE_PLACES_API_KEY')

# ——— Routes ———
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/api/nearby', methods=['POST'])
def api_nearby():
    data = request.get_json()
    lat, lng = data.get('lat'), data.get('lng')
    print(f"🔍 Received coords: {lat}, {lng}", flush=True)
    print(f"🔑 Using key: {GOOGLE_KEY}", flush=True)

    resp_raw = requests.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        params={
            'key':      GOOGLE_KEY,
            'location': f'{lat},{lng}',
            'radius':   2000,
            'type':     'supermarket'
        }
    )
    print("📡 HTTP status:", resp_raw.status_code, flush=True)
    resp = resp_raw.json()
    print("⚙️ Full Google response:\n", json.dumps(resp, indent=2), flush=True)

    status = resp.get('status')
    if status != 'OK':
        return jsonify(error=status, message=resp.get('error_message')), 500

    stores = [{
        'name':    p['name'],
        'address': p.get('vicinity'),
    } for p in resp.get('results', [])[:5]]
    print("🏬 Parsed stores:", stores, flush=True)

    return jsonify(stores=stores)


@app.route('/profile', methods=['GET', 'POST'])
def profile_page():
    global profile
    if request.method == 'POST':
        # 1) Save into the module‐level global
        profile = {
            'age':        request.form.get('age'),
            'sex':        request.form.get('sex'),
            'diet':       request.form.get('diet'),
            'conditions': request.form.get('conditions'),
            'allergies':  request.form.get('allergies'),
            'medications':request.form.get('medications')
        }
        # 2) Redirect to the logger so profile is guaranteed set on the next request
        return redirect(url_for('index'))
    # GET just renders the form with whatever profile exists
    return render_template('profile.html', profile=profile)

@app.route('/', methods=['GET', 'POST'])
def index():
    print("DEBUG: Entering index function", flush=True)
    global profile
    # (DEBUG) print to console so you can see the value
    print("🔍 profile at start of index():", profile, flush=True)

    if request.method == 'POST':
        print("DEBUG: Request method is POST", flush=True)
        # If they forgot to set a profile, send them there first
        if profile is None:
            print("DEBUG: Profile is None, redirecting to profile_page", flush=True)
            return redirect(url_for('profile_page'))
        print("DEBUG: Profile is set.", flush=True)

        # Build the new entry
        entry = {
            'id':        len(entries),
            'food':      request.form.get('food'),
            'pain':      request.form.get('pain'),
            'symptoms':  request.form.get('symptoms'),
            'mood':      request.form.get('mood'),
            'energy':    request.form.get('energy'),
            'supplements': request.form.get('supplements'),
            'voice':     request.form.get('voice_input'),
            'image':     None,
            'caption':   None
        }
        print(f"DEBUG: Built new entry: {entry}", flush=True)

        # Handle image upload + caption
        file = request.files.get('image')
        if file and allowed_file(file.filename):
            print("DEBUG: Image file found.", flush=True)
            filename = secure_filename(file.filename)
            save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(save_path)
            entry['image'] = filename
            entry['caption'] = analyze_image(save_path)
            print(f"DEBUG: Image saved to {save_path}, caption: {entry['caption']}", flush=True)

        entries.append(entry)
        print(f"DEBUG: Appended entry to entries. Current entries count: {len(entries)}", flush=True)

        # Simple OpenAI food analysis
        last_entry = entries[-1]
        if last_entry.get('caption'):
            print(f"🤖 Analyzing food from caption: {last_entry['caption']}")
            food_analysis = analyze_food_from_caption(last_entry['caption'])
            last_entry['food_analysis'] = food_analysis
            print(f"✅ Food analysis complete: {food_analysis}")

        # Pass the already‐set profile into the thanks page
        print("DEBUG: Rendering thanks.html", flush=True)
        return render_template(
            'thanks.html',
            entry=entry,
            profile=profile
        )

    # On GET, just show the logger and any past entries
    print("DEBUG: Request method is GET, rendering index.html", flush=True)
    return render_template(
        'index.html',
        entries=entries,
        profile=profile
    )
    
def analyze_food_from_caption(caption, api_key=None):
    """
    Analyze food from caption using OpenAI and return structured info.

    Args:
        caption (str): The image caption describing the food
        api_key (str): OpenAI API key (optional)

    Returns:
        dict: Contains food analysis including health_score
    """
    
    if not api_key:
        api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        return {"error": "OpenAI API key not found"}

    client = openai.OpenAI(api_key=api_key)

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
        "inflammation_level": "low/medium/high",
        "health_score": 3  # -3 (very unhealthy) to +3 (very healthy)
    }}

    Give a rough estimate based on ingredient quality, calories, and inflammation potential.
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

        try:
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
   
@app.route('/camera', methods=['POST'])
def camera():
    # print("DEBUG: Entering /camera route", flush=True)
    # Check if the post request has the file part
    if 'image' not in request.files:
        # print("DEBUG: No 'image' file part in request", flush=True)
        return jsonify({'error': 'No file part in the request'}), 400

    file = request.files['image']

    # If the user does not select a file, the browser submits an empty file without a filename.
    if file.filename == '':
        # print("DEBUG: No selected file", flush=True)
        return jsonify({'error': 'No selected file'}), 400

    if file and allowed_file(file.filename):
        # print(f"DEBUG: File found and allowed: {file.filename}", flush=True)
        filename = secure_filename(file.filename)
        save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        try:
            file.save(save_path)
            # print(f"DEBUG: File saved successfully to {save_path}", flush=True)
            caption = analyze_image(save_path)
            # print(f"DEBUG: Image analyzed, caption: {caption}", flush=True)
            caption = analyze_food_from_caption(caption)
            return jsonify({'caption': caption})
        except Exception as e:
            # print(f"DEBUG: Error saving file or analyzing image: {e}", flush=True)
            return jsonify({'error': str(e)}), 500
    else:
        # print("DEBUG: File not allowed or no file provided", flush=True)
        return jsonify({'error': 'File type not allowed'}), 400

@app.route('/recommendations/<int:entry_id>')
def recommendations(entry_id):
    if entry_id >= len(entries):
        return "Entry not found", 404
        
    entry = entries[entry_id]
    
    # Construct prompt for OpenAI
    prompt = f"""
    Based on this person's profile and daily log, suggest healthy food recommendations:
    
    Profile:
    - Age: {profile['age'] if profile else 'Not provided'}
    - Diet: {profile['diet'] if profile else 'Not provided'}
    - Medical Conditions: {profile['conditions'] if profile else 'None'}
    - Allergies: {profile['allergies'] if profile else 'None'}
    
    Current Status:
    - Energy Level: {entry['energy']}
    - Symptoms: {entry['symptoms']}
    - Mood: {entry['mood']}
    
    Please provide specific food recommendations considering their dietary restrictions and current symptoms.
    """
    
    # Call OpenAI API
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a nutritionist providing specific food recommendations."},
            {"role": "user", "content": prompt}
        ]
    )
    
    recommendations = response.choices[0].message.content
    
    return render_template('recommendations.html', entry=entry, recommendations=recommendations)

@app.route('/recommendations')
def latest_recommendations():
    if not entries:
        return render_template(
            'recommendations.html',
            entry=None,
            recommendations="No logs yet!",
            stores=[]
        )

    latest_entry = entries[-1]

    # —— 1) Food recommendations via GPT-3.5 —— #
    prompt_nutri = f"""
    Based on this person's profile and daily log, suggest healthy food recommendations:

    Profile:
    - Age: {profile.get('age', 'Not provided')}
    - Diet: {profile.get('diet', 'Not provided')}
    - Medical Conditions: {profile.get('conditions', 'None')}
    - Allergies: {profile.get('allergies', 'None')}

    Current Status:
    - Energy Level: {latest_entry['energy']}
    - Symptoms: {latest_entry['symptoms']}
    - Mood: {latest_entry['mood']}

    Please provide specific food recommendations considering their dietary restrictions and current symptoms.
    """
    resp1 = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a nutritionist providing specific food recommendations."},
            {"role": "user",   "content": prompt_nutri}
        ]
    )
    recommendations = resp1.choices[0].message.content.strip()

    # —— 2) Nearby grocery stores via GPT-4.1 —— #
    lat = session.get('latitude')
    lon = session.get('longitude')
    loc_str = f"{lat}, {lon}" if lat and lon else "unknown location"
    prompt_stores = f"""
    Based on the user's location ({loc_str}), list nearby grocery stores in Paris.
    Return ONLY a Python list assigned to a variable called stores.
    Each dict must have these keys:
      name, address, price, healthiness_score

    Example:
    stores = [
      {{'name': 'Franprix', 'address': '27 Rue…', 'price': '€€', 'healthiness_score': 60}},
      …
    ]
    """
    resp2 = client.chat.completions.create(
        model="gpt-4.1",
        messages=[
            {"role": "system", "content": "You are a location-based nutrition assistant."},
            {"role": "user",   "content": prompt_stores}
        ],
        temperature=0
    )
    text2 = resp2.choices[0].message.content.strip()
    # Safely exec the list literal
    namespace = {}
    try:
        exec(text2, {}, namespace)
        stores = namespace.get('stores', [])
    except Exception:
        stores = []

    # —— Render both into the template —— #
    return render_template(
        'recommendations.html',
        entry=latest_entry,
        recommendations=recommendations,
        stores=stores
    )


@app.route('/recommendations/location', methods=['POST'])
def save_location():
    data = request.get_json()
    print("📍 Received location data:", data, flush=True)
    session['latitude'] = data.get('latitude')
    session['longitude'] = data.get('longitude')
    return '', 204          # empty body, HTTP 204 No Content

#connected
@app.route('/locations', methods=['GET'])
def get_nearby_stores():
    print("DEBUG: Entering get_nearby_stores function", flush=True)
    # —— 2) Nearby grocery stores via GPT-4.1 —— #
    lat = session.get('latitude')
    lon = session.get('longitude')
    print(f"DEBUG: Retrieved lat: {lat}, lon: {lon} from session", flush=True)
    loc_str = f"{lat}, {lon}" if lat and lon else "unknown location"
    print(f"DEBUG: Constructed loc_str: {loc_str}", flush=True)
    prompt_stores = f"""
Based on the user's location ({loc_str}), list nearby grocery stores in Paris.
Return ONLY a Python list assigned to a variable called stores.
Each dict must have these keys:
  name, address, price, healthiness_score

Example:
stores = [
  {{'name': 'Franprix', 'address': '27 Rue…', 'price': '€€', 'healthiness_score': 60}},
]
"""

    print("DEBUG: Calling OpenAI API for stores...", flush=True)
    resp = client.chat.completions.create(
        model="gpt-4.1",
        messages=[
            {"role": "system", "content": "You are a location-based nutrition assistant."},
            {"role": "user",   "content": prompt_stores}
        ],
        temperature=0
    )
    text = resp.choices[0].message.content.strip()
    print(f"DEBUG: Received text from OpenAI: {text}", flush=True)
    # Safely exec the list literal
    namespace = {}
    try:
        print("DEBUG: Attempting to exec OpenAI response...", flush=True)
        exec(text, {}, namespace)
        stores = namespace.get('stores', [])
        print(f"DEBUG: Successfully parsed stores from exec. Stores: {stores}", flush=True)
    except Exception as e:
        print(f"DEBUG: Failed to exec OpenAI response: {e}", flush=True)
        stores = []
        print("DEBUG: stores list is empty due to error.", flush=True)

    print("DEBUG: Returning jsonify(stores)", flush=True)
    return jsonify(stores)


if __name__ == '__main__':
    # debug=True ensures you see the print(...) output
    app.run(debug=True, use_reloader=False, host='0.0.0.0', port=8000)
