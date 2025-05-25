# GutTrack 🥗  
**Stop guessing. Start healing.**

---

## Why This Matters

Chronic inflammation is a silent epidemic. It drives pain, fatigue, gut issues, and long-term diseases—and it costs the healthcare system **billions** every year.

But for people actually living with it? The cost is even higher.

Our teammate **Andrea** knows this firsthand. For years, he dealt with unexplained inflammation—his knees would swell so badly he couldn’t walk, let alone go to work. It took **four years** of trial and error to figure out the culprit was food-related. Four years of frustration, specialists, tests, and lost days.

He’s not alone.

Millions of people are suffering, and the tools they have—if any—aren’t built to connect the dots between what they eat and how they feel.

That’s why we built **GutTrack**.

![image](https://github.com/user-attachments/assets/4797268a-da83-4175-a24f-e0fb75afe307)

---

## What It Does

GutTrack is a mobile app that lets users **log their meals and track pain**, then uses AI and science to uncover what foods are making things worse.

### Under the Hood:
- 🖼️ **Local image captioning model** identifies what’s on your plate
- 📃 **Ingredients are extracted and quantified**
- 📚 **Inflammation scores** are assigned based on clinical research  
   (source: [Reumatología Clínica, 2024](https://www.reumatologiaclinica.org/es-the-relationship-between-dietary-inflammatory-articulo-S1699258X24000147))
- 📊 A **cumulative inflammation score** is calculated for each meal
- ✍️ You log your pain—GutTrack learns from it
- 🛒 We suggest **nearby grocery stores** for better ingredient choices (manual links for now)

Over time, GutTrack adapts to you. It gets smarter with every meal and every pain log—learning what your body tolerates and what it doesn’t.

![image](https://github.com/user-attachments/assets/1003fa0b-df47-409c-837c-0dab2cc7d8ef)
<img width="690" alt="Screenshot 2025-05-25 at 11 39 42 AM" src="https://github.com/user-attachments/assets/41cdf416-ee87-40f7-ac3f-297d349c6709" />
---

## How It Works

1. **Log a meal** – Snap a photo or type in what you ate.
2. **AI figures out what’s on your plate** – Run locally on your phone.
3. **Score it** – We pull inflammation values from scientific tables to give your meal a personalized score.
4. **Log how you feel** – Bloating, fatigue, pain—we track it all.
5. **GutTrack learns** – Future meals are scored based on your data.
6. **Store suggestions** – Want better ingredients? We surface stores near you where you can shop smarter.

---

## What Makes It Different

Unlike calorie or macro trackers, **we don’t just track what goes in**—we connect it to how you feel.

- Built entirely in **SwiftUI**  
- Uses a **local model for food image captioning** (no cloud dependency)  
- Fine-tunes food scoring based on **your unique pain response**  
- References real **clinical inflammation data**  
- Makes it actionable with **location-based store suggestions**



---
![image](https://github.com/user-attachments/assets/9ce9eddb-7885-493c-b318-c2d88af425f0)


## Example

**Meal**: Chicken tikka masala with white rice and naan  
**Score**: Inflammation +2.3  
**Pain Logged**: 7/10  
**Response**: “You’ve had consistent flare-ups after dairy-heavy meals. Consider trying a tomato-based chicken dish without cream next time.”

![image](https://github.com/user-attachments/assets/d7b7f633-043b-4e6a-a003-0a86e34ed526)

---

## Built At

A 36-hour hackathon—but born out of years of lived experience, frustration, and a desire to build something better for ourselves and others like us.

> This isn’t just a tracker. It’s a tool for healing.
