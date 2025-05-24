import csv
import random

# Read ingredients from the CSV
with open('ingredients.csv', 'r', encoding='utf-8') as infile:
    reader = csv.reader(infile)
    ingredients = [row[0] for row in reader if row]

# Remove header if present
if ingredients[0].strip().lower() == 'ingredient description':
    ingredients = ingredients[1:]

# Prepare output data
output_rows = []
for ingredient in ingredients:
    general_score = round(random.uniform(-1, 1), 3)
    sam_score = round(random.uniform(-1, 1), 3) if random.choice([True, False]) else ''
    andrea_score = round(random.uniform(-1, 1), 3) if random.choice([True, False]) else ''
    output_rows.append([
        ingredient,
        general_score,
        sam_score,
        andrea_score
    ])

# Write to new CSV
with open('ingredients_with_inflammation.csv', 'w', newline='', encoding='utf-8') as outfile:
    writer = csv.writer(outfile)
    writer.writerow([
        'ingredient',
        'general people inflammation',
        'Sam inflammation',
        'Andrea inflammation'
    ])
    writer.writerows(output_rows) 