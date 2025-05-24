import os
from flask import Flask, render_template, request, send_from_directory
from werkzeug.utils import secure_filename

from PIL import Image
import torch
from transformers import BlipProcessor, BlipForConditionalGeneration

# ——— Flask setup ———
app = Flask(__name__)
UPLOAD_FOLDER = os.path.join('static', 'uploads')
ALLOWED_IMG = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Add profile storage
profile = None
entries = []

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

# ——— Routes ———
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.route('/profile', methods=['GET', 'POST'])
def profile_page():
    global profile
    if request.method == 'POST':
        profile = {
            'age': request.form.get('age'),
            'sex': request.form.get('sex'),
            'diet': request.form.get('diet'),
            'conditions': request.form.get('conditions'),
            'allergies': request.form.get('allergies'),
            'medications': request.form.get('medications')
        }
        return render_template('profile.html', profile=profile, saved=True)
    return render_template('profile.html', profile=profile)

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        entry = {
            'food': request.form.get('food'),
            'pain': request.form.get('pain'),
            'symptoms': request.form.get('symptoms'),
            'mood': request.form.get('mood'),
            'energy': request.form.get('energy'),
            'supplements': request.form.get('supplements'),
            'voice': request.form.get('voice_input'),
            'image': None,
            'caption': None
        }

        # Handle image upload
        file = request.files.get('image')
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(save_path)
            entry['image'] = filename
            entry['caption'] = analyze_image(save_path)

        entries.append(entry)
        return render_template('thanks.html', entry=entry)

    return render_template('index.html', entries=entries)

if __name__ == '__main__':
    app.run(debug=True, use_reloader=False)