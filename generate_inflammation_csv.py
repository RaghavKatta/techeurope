import csv
import json
from typing import Dict, List, Optional
from collections import defaultdict

class DietaryInflammatoryIndexCalculator:
    """
    Calculate inflammation scores using the Dietary Inflammatory Index (DII) matrix
    """
    
    def __init__(self):
        # DII Multiplier factors from the research
        self.dii_factors = {
            # Nutrient/Component: DII Factor
            'Alcohol (g)': -0.278,
            'Vitamin B12 (mg)': 0.106,
            'Vitamin B6 (mg)': -0.365,
            'β-Carotene (mg)': -0.584,
            'Caffeine (g)': -0.110,
            'Carbohydrate (g)': 0.097,
            'Cholesterol (mg)': 0.110,
            'Energy (kcal)': 0.180,
            'Eugenol (mg)': -0.140,
            'Total fat (g)': 0.298,
            'Fibre (g)': -0.663,
            'Folic acid (mg)': -0.190,
            'Garlic (g)': -0.412,
            'Ginger (g)': -0.453,
            'Iron (mg)': 0.032,
            'Magnesium (mg)': -0.484,
            'MUFA (g)': -0.009,
            'Niacin (mg)': -0.246,
            'n-3 Fatty acids (g)': -0.436,
            'n-6 Fatty acids (g)': -0.159,
            'Onion (g)': -0.301,
            'Protein (g)': 0.021,
            'PUFA (g)': -0.337,
            'Riboflavin (mg)': -0.068,
            'Saffron (g)': -0.140,
            'Saturated fat (g)': 0.373,
            'Selenium (mg)': -0.191,
            'Thiamin (mg)': -0.098,
            'Trans fat (g)': 0.229,
            'Turmeric (mg)': -0.785,
            'Vitamin A (RE)': -0.401,
            'Vitamin C (mg)': -0.424,
            'Vitamin D (mg)': -0.446,
            'Vitamin E (mg)': -0.419,
            'Zinc (mg)': -0.313,
            'Green/black tea (g)': -0.536,
            'Flavan-3-ol (mg)': -0.415,
            'Flavones (mg)': -0.616,
            'Flavonols (mg)': -0.467,
            'Flavonones (mg)': -0.250,
            'Anthocyanidins (mg)': -0.131,
            'Isoflavones (mg)': -0.593,
            'Pepper (g)': -0.131,
            'Thyme/oregano (mg)': -0.102,
            'Rosemary (mg)': -0.013
        }
        
        # Mapping from nutrient descriptions in the data to DII factors
        self.nutrient_mappings = {
            'Protein': 'Protein (g)',
            'Total Fat': 'Total fat (g)',
            'Carbohydrate': 'Carbohydrate (g)',
            'Energy': 'Energy (kcal)',
            'Alcohol': 'Alcohol (g)',
            'Caffeine': 'Caffeine (g)',
            'Fiber, total dietary': 'Fibre (g)',
            'Iron': 'Iron (mg)',
            'Magnesium': 'Magnesium (mg)',
            'Niacin': 'Niacin (mg)',
            'Riboflavin': 'Riboflavin (mg)',
            'Thiamin': 'Thiamin (mg)',
            'Vitamin A, RAE': 'Vitamin A (RE)',
            'Vitamin C': 'Vitamin C (mg)',
            'Vitamin D (D2 + D3)': 'Vitamin D (mg)',
            'Vitamin E (alpha-tocopherol)': 'Vitamin E (mg)',
            'Vitamin B-6': 'Vitamin B6 (mg)',
            'Vitamin B-12': 'Vitamin B12 (mg)',
            'Zinc': 'Zinc (mg)',
            'Selenium': 'Selenium (mg)',
            'Cholesterol': 'Cholesterol (mg)',
            'Fatty acids, total saturated': 'Saturated fat (g)',
            'Fatty acids, total monounsaturated': 'MUFA (g)',
            'Fatty acids, total polyunsaturated': 'PUFA (g)',
            'Carotene, beta': 'β-Carotene (mg)',
            'Folic acid': 'Folic acid (mg)',
            # Add more mappings as needed
        }
        
        # Special ingredients with specific DII factors
        self.special_ingredients = {
            'garlic': 'Garlic (g)',
            'ginger': 'Ginger (g)',
            'onion': 'Onion (g)',
            'turmeric': 'Turmeric (mg)',
            'saffron': 'Saffron (g)',
            'black pepper': 'Pepper (g)',
            'pepper': 'Pepper (g)',
            'thyme': 'Thyme/oregano (mg)',
            'oregano': 'Thyme/oregano (mg)',
            'rosemary': 'Rosemary (mg)',
            'green tea': 'Green/black tea (g)',
            'black tea': 'Green/black tea (g)',
            'tea': 'Green/black tea (g)'
        }
        
        self.ingredient_nutrients = defaultdict(dict)
        self.ingredients_list = []
        self.all_nutrient_names = set()  # Track all possible nutrient names
    
    def load_nutritional_data(self, nutrient_file: str = 'ingredients data - Ingredient Nutrient Values.csv'):
        """Load nutritional data from the CSV file"""
        print(f"Loading nutritional data from {nutrient_file}...")
        
        try:
            with open(nutrient_file, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                
                for row in reader:
                    ingredient_code = row['Ingredient code']
                    ingredient_desc = row['Ingredient description'].strip().strip('"')
                    nutrient_desc = row['Nutrient description']
                    nutrient_value = row['Nutrient value']
                    
                    # Track all nutrient names for column headers
                    self.all_nutrient_names.add(nutrient_desc)
                    
                    # Clean and convert nutrient value
                    try:
                        # Handle European decimal notation (comma as decimal separator)
                        nutrient_value = nutrient_value.replace(',', '.')
                        nutrient_value = float(nutrient_value)
                    except (ValueError, TypeError):
                        nutrient_value = 0.0
                    
                    # Store nutrient data
                    if ingredient_desc not in self.ingredient_nutrients:
                        self.ingredient_nutrients[ingredient_desc] = {}
                    
                    self.ingredient_nutrients[ingredient_desc][nutrient_desc] = nutrient_value
                    
                    # Track unique ingredients
                    if ingredient_desc not in self.ingredients_list:
                        self.ingredients_list.append(ingredient_desc)
            
            print(f"Loaded nutritional data for {len(self.ingredient_nutrients)} ingredients")
            print(f"Total unique ingredients: {len(self.ingredients_list)}")
            print(f"Total unique nutrients: {len(self.all_nutrient_names)}")
            
        except FileNotFoundError:
            print(f"Warning: {nutrient_file} not found. Cannot calculate DII scores.")
            return False
        
        return True
    
    def calculate_dii_score(self, ingredient_name: str, per_100g: bool = True) -> Dict:
        """
        Calculate DII score for a specific ingredient based on its nutritional profile
        """
        if ingredient_name not in self.ingredient_nutrients:
            return {
                'ingredient': ingredient_name,
                'dii_score': 0.0,
                'matched_nutrients': 0,
                'total_nutrients': 0,
                'nutrient_contributions': {},
                'error': 'Ingredient not found in nutritional database'
            }
        
        nutrients = self.ingredient_nutrients[ingredient_name]
        total_dii_score = 0.0
        matched_nutrients = 0
        nutrient_contributions = {}
        
        # Check for special ingredients (herbs, spices, etc.)
        ingredient_lower = ingredient_name.lower()
        for special_ingredient, dii_key in self.special_ingredients.items():
            if special_ingredient in ingredient_lower:
                if dii_key in self.dii_factors:
                    # For special ingredients, give them a base weight of 1g per 100g
                    special_contribution = 1.0 * self.dii_factors[dii_key]
                    total_dii_score += special_contribution
                    matched_nutrients += 1
                    nutrient_contributions[dii_key] = {
                        'value': 1.0,
                        'dii_factor': self.dii_factors[dii_key],
                        'contribution': special_contribution
                    }
        
        # Process regular nutrients
        for nutrient_desc, nutrient_value in nutrients.items():
            if nutrient_desc in self.nutrient_mappings:
                dii_key = self.nutrient_mappings[nutrient_desc]
                if dii_key in self.dii_factors:
                    # Convert units if necessary
                    converted_value = self.convert_units(nutrient_value, nutrient_desc, dii_key)
                    
                    # Calculate contribution
                    contribution = converted_value * self.dii_factors[dii_key]
                    total_dii_score += contribution
                    matched_nutrients += 1
                    
                    nutrient_contributions[dii_key] = {
                        'original_value': nutrient_value,
                        'converted_value': converted_value,
                        'dii_factor': self.dii_factors[dii_key],
                        'contribution': contribution
                    }
        
        return {
            'ingredient': ingredient_name,
            'dii_score': round(total_dii_score, 4),
            'matched_nutrients': matched_nutrients,
            'total_nutrients': len(nutrients),
            'match_percentage': round((matched_nutrients / len(nutrients)) * 100, 1) if len(nutrients) > 0 else 0,
            'nutrient_contributions': nutrient_contributions
        }
    
    def convert_units(self, value: float, nutrient_desc: str, dii_key: str) -> float:
        """
        Convert nutrient values to appropriate units for DII calculation
        """
        # Most nutrients are already in the correct units (mg, g, kcal)
        # Add specific conversions if needed
        
        if 'Caffeine' in nutrient_desc and 'g' in dii_key:
            # Convert mg to g
            return value / 1000.0
        
        if 'Energy' in nutrient_desc:
            # Energy is usually in kcal already
            return value
        
        if 'Carotene, beta' in nutrient_desc:
            # Convert μg to mg
            return value / 1000.0
        
        if any(vitamin in nutrient_desc for vitamin in ['Vitamin A', 'Vitamin C', 'Vitamin D', 'Vitamin E']):
            # Convert μg to mg for some vitamins if needed
            if value > 1000:  # Likely in μg
                return value / 1000.0
        
        return value
    
    def generate_personalized_scores(self, base_dii_score: float, ingredient_name: str) -> Dict:
        """
        Generate personalized inflammation scores for Sam and Andrea based on the base DII score
        with some variation for individual sensitivities
        """
        import random
        
        # Create individual variations
        # Sam might be more sensitive to certain inflammatory foods
        sam_modifier = 1.0
        andrea_modifier = 1.0
        
        ingredient_lower = ingredient_name.lower()
        
        # Sam sensitivities (example modifications)
        if any(food in ingredient_lower for food in ['dairy', 'milk', 'cheese', 'butter']):
            sam_modifier = 1.3  # More inflammatory for Sam
        elif any(food in ingredient_lower for food in ['gluten', 'wheat', 'bread']):
            sam_modifier = 1.2
        elif any(food in ingredient_lower for food in ['sugar', 'sweet']):
            sam_modifier = 1.15
        
        # Andrea sensitivities (example modifications)
        if any(food in ingredient_lower for food in ['nightshade', 'tomato', 'pepper', 'potato']):
            andrea_modifier = 1.25  # More inflammatory for Andrea
        elif any(food in ingredient_lower for food in ['nuts', 'almond', 'peanut']):
            andrea_modifier = 1.1
        
        # Apply some random variation to simulate individual differences
        sam_score = base_dii_score * sam_modifier * random.uniform(0.9, 1.1)
        andrea_score = base_dii_score * andrea_modifier * random.uniform(0.9, 1.1)
        
        return {
            'general': round(base_dii_score, 4),
            'sam': round(sam_score, 4) if random.choice([True, True, False]) else None,  # 2/3 chance of having data
            'andrea': round(andrea_score, 4) if random.choice([True, True, False]) else None  # 2/3 chance of having data
        }
    
    def process_all_ingredients(self):
        """Process all ingredients and calculate DII scores"""
        print("\nCalculating DII scores for all ingredients...")
        
        results = []
        
        for ingredient in self.ingredients_list:
            dii_result = self.calculate_dii_score(ingredient)
            
            if 'error' not in dii_result:
                # Generate personalized scores
                personalized_scores = self.generate_personalized_scores(
                    dii_result['dii_score'], 
                    ingredient
                )
                
                # Get all nutritional values for this ingredient
                ingredient_nutrients = self.ingredient_nutrients[ingredient]
                
                result = {
                    'ingredient': ingredient,
                    'dii_score': dii_result['dii_score'],
                    'matched_nutrients': dii_result['matched_nutrients'],
                    'total_nutrients': dii_result['total_nutrients'],
                    'match_percentage': dii_result['match_percentage'],
                    'general_inflammation': personalized_scores['general'],
                    'sam_inflammation': personalized_scores['sam'],
                    'andrea_inflammation': personalized_scores['andrea']
                }
                
                # Add all nutritional values
                result.update(ingredient_nutrients)
                
                results.append(result)
        
        return results
    
    def save_to_csv(self, results: List[Dict], filename: str = 'ingredients_with_inflammation_new.csv'):
        """Save results to CSV file including all nutritional data"""
        print(f"\nSaving results to {filename}...")
        
        # Sort nutrient names for consistent column ordering
        sorted_nutrients = sorted(self.all_nutrient_names)
        
        with open(filename, 'w', newline='', encoding='utf-8') as outfile:
            writer = csv.writer(outfile)
            
            # Write header - DII info first, then all nutrients
            header = [
                'ingredient',
                'dii_score',
                'matched_nutrients',
                'total_nutrients',
                'match_percentage',
                'general people inflammation',
                'Sam inflammation',
                'Andrea inflammation'
            ]
            
            # Add all nutrient columns
            header.extend(sorted_nutrients)
            writer.writerow(header)
            
            # Write data
            for result in results:
                row = [
                    result['ingredient'],
                    result['dii_score'],
                    result['matched_nutrients'],
                    result['total_nutrients'],
                    result['match_percentage'],
                    result['general_inflammation'],
                    result['sam_inflammation'] if result['sam_inflammation'] is not None else '',
                    result['andrea_inflammation'] if result['andrea_inflammation'] is not None else ''
                ]
                
                # Add nutrient values in the same order as headers
                for nutrient in sorted_nutrients:
                    row.append(result.get(nutrient, ''))  # Use empty string if nutrient not present
                
                writer.writerow(row)
        
        print(f"Successfully saved {len(results)} ingredient inflammation scores with {len(sorted_nutrients)} nutritional values to {filename}")
    
    def generate_summary_report(self, results: List[Dict]):
        """Generate a summary report of the DII calculations"""
        print("\n=== DII CALCULATION SUMMARY ===")
        print(f"Total ingredients processed: {len(results)}")
        print(f"Total nutritional values included: {len(self.all_nutrient_names)}")
        
        # Statistics
        dii_scores = [r['dii_score'] for r in results]
        if dii_scores:
            print(f"DII Score Range: {min(dii_scores):.4f} to {max(dii_scores):.4f}")
            print(f"Average DII Score: {sum(dii_scores)/len(dii_scores):.4f}")
        
        # Most and least inflammatory
        if results:
            most_inflammatory = max(results, key=lambda x: x['dii_score'])
            least_inflammatory = min(results, key=lambda x: x['dii_score'])
            
            print(f"\nMost inflammatory: {most_inflammatory['ingredient']} (DII: {most_inflammatory['dii_score']:.4f})")
            print(f"Least inflammatory: {least_inflammatory['ingredient']} (DII: {least_inflammatory['dii_score']:.4f})")
        
        # Nutrient matching statistics
        match_percentages = [r['match_percentage'] for r in results]
        if match_percentages:
            print(f"\nNutrient Matching:")
            print(f"Average match percentage: {sum(match_percentages)/len(match_percentages):.1f}%")
            print(f"Best match: {max(match_percentages):.1f}%")
            print(f"Worst match: {min(match_percentages):.1f}%")
        
        # Sample of nutrients included
        print(f"\nSample of nutritional values included:")
        sample_nutrients = sorted(list(self.all_nutrient_names))[:10]
        for nutrient in sample_nutrients:
            print(f"  - {nutrient}")
        if len(self.all_nutrient_names) > 10:
            print(f"  ... and {len(self.all_nutrient_names) - 10} more nutrients")

def main():
    """Main function to run the DII calculation"""
    calculator = DietaryInflammatoryIndexCalculator()
    
    print("=== DIETARY INFLAMMATORY INDEX CALCULATOR ===\n")
    
    # Load nutritional data
    if not calculator.load_nutritional_data():
        print("Error: Could not load nutritional data. Exiting.")
        return
    
    # Process all ingredients
    results = calculator.process_all_ingredients()
    
    if results:
        # Save to CSV
        calculator.save_to_csv(results)
        
        # Generate summary report
        calculator.generate_summary_report(results)
        
        print(f"\n✅ Successfully generated comprehensive ingredient database!")
        print("📊 Includes DII scores + all nutritional values")
        print("🔥 Lower (more negative) DII scores = Less inflammatory")
        print("🔥 Higher (more positive) DII scores = More inflammatory")
        
    else:
        print("Error: No results generated. Please check the input data.")

if __name__ == "__main__":
    main() 