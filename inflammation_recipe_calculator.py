import csv
import json
import random
from typing import Dict, List, Optional

class InflammationRecipeCalculator:
    """
    Calculate inflammation scores for recipes and create personalized weekly menus
    """
    
    def __init__(self, ingredients_csv_path: str = 'ingredients_with_inflammation.csv', 
                 recipes_json_path: str = 'popular_recipes_database.json'):
        self.ingredients_inflammation = {}
        self.recipes = []
        self.load_ingredient_inflammation(ingredients_csv_path)
        self.load_recipes(recipes_json_path)
    
    def load_ingredient_inflammation(self, csv_path: str):
        """Load ingredient inflammation scores from CSV file"""
        try:
            with open(csv_path, 'r', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    ingredient = row['ingredient'].lower().strip()
                    self.ingredients_inflammation[ingredient] = {
                        'general': float(row['general people inflammation']) if row['general people inflammation'] else None,
                        'sam': float(row['Sam inflammation']) if row['Sam inflammation'] else None,
                        'andrea': float(row['Andrea inflammation']) if row['Andrea inflammation'] else None
                    }
            print(f"Loaded inflammation data for {len(self.ingredients_inflammation)} ingredients")
        except FileNotFoundError:
            print(f"Warning: {csv_path} not found. Creating sample data...")
            self.create_sample_inflammation_data()
    
    def create_sample_inflammation_data(self):
        """Create sample inflammation data if the CSV file doesn't exist"""
        common_ingredients = [
            'spaghetti', 'ground beef', 'onion', 'carrot', 'celery', 'garlic', 'tomatoes',
            'tomato paste', 'olive oil', 'salt', 'black pepper', 'parmesan cheese',
            'basil', 'pizza dough', 'mozzarella cheese', 'chicken breast', 'yogurt',
            'ginger', 'garam masala', 'cumin', 'paprika', 'heavy cream', 'basmati rice',
            'cilantro', 'hamburger buns', 'cheddar cheese', 'lettuce', 'tomato',
            'mayonnaise', 'ketchup', 'cooked rice', 'eggs', 'peas', 'soy sauce',
            'sesame oil', 'flour', 'sugar', 'baking powder', 'milk', 'butter',
            'vanilla extract', 'maple syrup', 'taco shells', 'chili powder',
            'sour cream', 'romaine lettuce', 'bread', 'lemon juice', 'worcestershire sauce',
            'chocolate chips', 'egg noodles', 'chicken broth', 'bay leaves', 'thyme',
            'parsley'
        ]
        
        for ingredient in common_ingredients:
            self.ingredients_inflammation[ingredient] = {
                'general': round(random.uniform(-1, 1), 3),
                'sam': round(random.uniform(-1, 1), 3) if random.choice([True, False]) else None,
                'andrea': round(random.uniform(-1, 1), 3) if random.choice([True, False]) else None
            }
    
    def load_recipes(self, json_path: str):
        """Load recipes from JSON file"""
        try:
            with open(json_path, 'r', encoding='utf-8') as file:
                data = json.load(file)
                self.recipes = data['popular_recipes_database']['recipes']
            print(f"Loaded {len(self.recipes)} recipes")
        except FileNotFoundError:
            print(f"Warning: {json_path} not found. No recipes loaded.")
            self.recipes = []
    
    def find_ingredient_match(self, recipe_ingredient: str) -> Optional[str]:
        """
        Try to find a matching ingredient in the inflammation database
        """
        recipe_ingredient = recipe_ingredient.lower().strip()
        
        # Direct match
        if recipe_ingredient in self.ingredients_inflammation:
            return recipe_ingredient
        
        # Check for partial matches
        for db_ingredient in self.ingredients_inflammation.keys():
            if recipe_ingredient in db_ingredient or db_ingredient in recipe_ingredient:
                return db_ingredient
        
        # Check for common ingredient mappings
        ingredient_mappings = {
            'ground beef': 'beef',
            'chicken breast': 'chicken',
            'all-purpose flour': 'flour',
            'canned tomatoes': 'tomatoes',
            'fresh basil': 'basil',
            'romaine lettuce': 'lettuce',
            'hamburger buns': 'bread',
            'egg noodles': 'pasta',
            'heavy cream': 'cream',
            'vegetable oil': 'oil'
        }
        
        if recipe_ingredient in ingredient_mappings:
            mapped_ingredient = ingredient_mappings[recipe_ingredient]
            if mapped_ingredient in self.ingredients_inflammation:
                return mapped_ingredient
        
        return None
    
    def calculate_recipe_inflammation_score(self, recipe: Dict, person: str = 'general') -> Dict:
        """
        Calculate inflammation score for a recipe for a specific person
        """
        total_score = 0.0
        matched_ingredients = 0
        unmatched_ingredients = []
        ingredient_details = []
        
        for ingredient in recipe['ingredients']:
            ingredient_name = ingredient['name']
            quantity = ingredient['quantity']
            
            # Find matching ingredient in inflammation database
            matched_ingredient = self.find_ingredient_match(ingredient_name)
            
            if matched_ingredient:
                inflammation_data = self.ingredients_inflammation[matched_ingredient]
                score = inflammation_data.get(person)
                
                if score is not None:
                    # Weight the score by quantity (simplified weighting)
                    weighted_score = score * (quantity / 100)  # Normalize by 100g
                    total_score += weighted_score
                    matched_ingredients += 1
                    
                    ingredient_details.append({
                        'name': ingredient_name,
                        'matched_as': matched_ingredient,
                        'quantity': quantity,
                        'inflammation_score': score,
                        'weighted_score': weighted_score
                    })
                else:
                    unmatched_ingredients.append(f"{ingredient_name} (no {person} data)")
            else:
                unmatched_ingredients.append(ingredient_name)
        
        # Calculate average inflammation score
        avg_score = total_score / matched_ingredients if matched_ingredients > 0 else 0
        
        return {
            'recipe_id': recipe['id'],
            'recipe_title': recipe['title'],
            'person': person,
            'total_inflammation_score': round(total_score, 3),
            'average_inflammation_score': round(avg_score, 3),
            'matched_ingredients': matched_ingredients,
            'total_ingredients': len(recipe['ingredients']),
            'match_percentage': round((matched_ingredients / len(recipe['ingredients'])) * 100, 1),
            'unmatched_ingredients': unmatched_ingredients,
            'ingredient_details': ingredient_details
        }
    
    def get_recipe_scores_for_all_people(self, recipe: Dict) -> Dict:
        """Get inflammation scores for a recipe for all people"""
        return {
            'general': self.calculate_recipe_inflammation_score(recipe, 'general'),
            'sam': self.calculate_recipe_inflammation_score(recipe, 'sam'),
            'andrea': self.calculate_recipe_inflammation_score(recipe, 'andrea')
        }
    
    def create_weekly_menu(self, person: str = 'general', minimize_inflammation: bool = True) -> Dict:
        """
        Create a weekly menu (7 days, 3 meals per day) optimized for inflammation scores
        """
        if not self.recipes:
            return {"error": "No recipes loaded"}
        
        # Calculate inflammation scores for all recipes
        recipe_scores = []
        for recipe in self.recipes:
            score_data = self.calculate_recipe_inflammation_score(recipe, person)
            recipe_scores.append({
                'recipe': recipe,
                'score_data': score_data
            })
        
        # Sort recipes by inflammation score (ascending for minimizing inflammation)
        if minimize_inflammation:
            recipe_scores.sort(key=lambda x: x['score_data']['average_inflammation_score'])
        else:
            recipe_scores.sort(key=lambda x: x['score_data']['average_inflammation_score'], reverse=True)
        
        # Create weekly menu
        weekly_menu = {}
        days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        
        recipe_index = 0
        for day in days:
            daily_menu = {}
            
            # Assign meals for the day
            for meal_type in ['Breakfast', 'Lunch', 'Dinner']:
                # Find a suitable recipe for this meal type
                suitable_recipes = [
                    rs for rs in recipe_scores 
                    if meal_type in rs['recipe'].get('meal_type', [])
                ]
                
                if suitable_recipes:
                    # Pick the best scoring suitable recipe
                    chosen_recipe = suitable_recipes[0]
                    daily_menu[meal_type] = {
                        'recipe': chosen_recipe['recipe'],
                        'inflammation_score': chosen_recipe['score_data']['average_inflammation_score'],
                        'prep_time': chosen_recipe['recipe']['prep_time_minutes'],
                        'total_time': chosen_recipe['recipe']['total_time_minutes'],
                        'servings': chosen_recipe['recipe']['servings']
                    }
                    # Remove this recipe from available options to avoid repetition
                    recipe_scores = [rs for rs in recipe_scores if rs['recipe']['id'] != chosen_recipe['recipe']['id']]
                else:
                    # If no suitable recipe found, pick any available recipe
                    if recipe_scores:
                        chosen_recipe = recipe_scores[recipe_index % len(recipe_scores)]
                        daily_menu[meal_type] = {
                            'recipe': chosen_recipe['recipe'],
                            'inflammation_score': chosen_recipe['score_data']['average_inflammation_score'],
                            'prep_time': chosen_recipe['recipe']['prep_time_minutes'],
                            'total_time': chosen_recipe['recipe']['total_time_minutes'],
                            'servings': chosen_recipe['recipe']['servings']
                        }
                        recipe_index += 1
            
            weekly_menu[day] = daily_menu
        
        # Calculate weekly statistics
        total_inflammation = sum(
            meal['inflammation_score'] 
            for day_menu in weekly_menu.values() 
            for meal in day_menu.values()
        )
        avg_daily_inflammation = total_inflammation / 7
        
        return {
            'person': person,
            'optimization_goal': 'minimize_inflammation' if minimize_inflammation else 'maximize_inflammation',
            'weekly_menu': weekly_menu,
            'statistics': {
                'total_weekly_inflammation_score': round(total_inflammation, 3),
                'average_daily_inflammation_score': round(avg_daily_inflammation, 3),
                'total_meals': len(days) * 3
            }
        }
    
    def generate_shopping_list(self, weekly_menu: Dict) -> Dict:
        """Generate a shopping list from the weekly menu"""
        shopping_list = {}
        
        for day, meals in weekly_menu['weekly_menu'].items():
            for meal_type, meal_data in meals.items():
                recipe = meal_data['recipe']
                for ingredient in recipe['ingredients']:
                    ingredient_name = ingredient['name']
                    quantity = ingredient['quantity']
                    unit = ingredient['unit']
                    
                    if ingredient_name in shopping_list:
                        # Add to existing quantity (simplified - assumes same unit)
                        shopping_list[ingredient_name]['total_quantity'] += quantity
                    else:
                        shopping_list[ingredient_name] = {
                            'unit': unit,
                            'total_quantity': quantity,
                            'used_in_meals': []
                        }
                    
                    shopping_list[ingredient_name]['used_in_meals'].append(f"{day} {meal_type}: {recipe['title']}")
        
        return {
            'shopping_list': shopping_list,
            'total_unique_ingredients': len(shopping_list)
        }

def main():
    """Main function to demonstrate the inflammation calculator"""
    calc = InflammationRecipeCalculator()
    
    print("\n=== INFLAMMATION RECIPE CALCULATOR ===\n")
    
    # Calculate scores for all recipes for all people
    print("Calculating inflammation scores for all recipes...")
    for recipe in calc.recipes:
        print(f"\nRecipe: {recipe['title']}")
        scores = calc.get_recipe_scores_for_all_people(recipe)
        
        for person, score_data in scores.items():
            print(f"  {person.capitalize()}: {score_data['average_inflammation_score']:.3f} "
                  f"({score_data['match_percentage']:.1f}% ingredients matched)")
    
    # Create weekly menus for each person
    print("\n=== WEEKLY MENU GENERATION ===\n")
    
    for person in ['general', 'sam', 'andrea']:
        print(f"\nCreating weekly menu for {person.capitalize()}...")
        weekly_menu = calc.create_weekly_menu(person, minimize_inflammation=True)
        
        if 'error' not in weekly_menu:
            print(f"Weekly inflammation score: {weekly_menu['statistics']['total_weekly_inflammation_score']:.3f}")
            print(f"Average daily inflammation: {weekly_menu['statistics']['average_daily_inflammation_score']:.3f}")
            
            # Save to file
            filename = f"weekly_menu_{person}.json"
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(weekly_menu, f, indent=2, ensure_ascii=False)
            print(f"Saved menu to {filename}")
            
            # Generate shopping list
            shopping_list = calc.generate_shopping_list(weekly_menu)
            shopping_filename = f"shopping_list_{person}.json"
            with open(shopping_filename, 'w', encoding='utf-8') as f:
                json.dump(shopping_list, f, indent=2, ensure_ascii=False)
            print(f"Saved shopping list to {shopping_filename}")

if __name__ == "__main__":
    main() 