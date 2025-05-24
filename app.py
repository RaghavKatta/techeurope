import os
import requests  # Make sure this import is at the top
from flask import Flask, render_template, request, redirect, url_for, send_from_directory, jsonify
from werkzeug.utils import secure_filename

from PIL import Image
import torch
from transformers import BlipProcessor, BlipForConditionalGeneration
from openai import OpenAI
import json
from dotenv import load_dotenv
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
    global profile
    # (DEBUG) print to console so you can see the value
    print("🔍 profile at start of index():", profile, flush=True)

    if request.method == 'POST':
        # If they forgot to set a profile, send them there first
        if profile is None:
            return redirect(url_for('profile_page'))

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

        # Handle image upload + caption
        file = request.files.get('image')
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(save_path)
            entry['image'] = filename
            entry['caption'] = analyze_image(save_path)

        entries.append(entry)

        # Pass the already‐set profile into the thanks page
        return render_template(
            'thanks.html',
            entry=entry,
            profile=profile
        )

    # On GET, just show the logger and any past entries
    return render_template(
        'index.html',
        entries=entries,
        profile=profile
    )

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
        return render_template('recommendations.html', entry=None, recommendations="No logs yet!")

    latest_entry = entries[-1]
    
    # Construct prompt for OpenAI
    prompt = f"""
    Based on this person's profile and daily log, suggest healthy food recommendations:
    
    Profile:
    - Age: {profile['age'] if profile else 'Not provided'}
    - Diet: {profile['diet'] if profile else 'Not provided'}
    - Medical Conditions: {profile['conditions'] if profile else 'None'}
    - Allergies: {profile['allergies'] if profile else 'None'}
    
    Current Status:
    - Energy Level: {latest_entry['energy']}
    - Symptoms: {latest_entry['symptoms']}
    - Mood: {latest_entry['mood']}
    
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
    
    return render_template('recommendations.html', entry=latest_entry, recommendations=recommendations)

if __name__ == '__main__':
    # debug=True ensures you see the print(...) output
    app.run(debug=True, use_reloader=False)
