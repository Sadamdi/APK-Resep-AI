import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RecipeData {
  static const String apiKey = '';
  static final model =
      GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  static final uuid = Uuid();

  static final Map<String, dynamic> _recipeCache = {};
  static final Map<String, String> _imageCache = {};
  static final Map<String, List<dynamic>> _queryCache = {};

  static Future<void> loadCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? recipeCacheString = prefs.getString('recipeCache');
    if (recipeCacheString != null) {
      Map<String, dynamic> loadedCache = jsonDecode(recipeCacheString);
      _recipeCache.addAll(loadedCache);
    }
    String? imageCacheString = prefs.getString('imageCache');
    if (imageCacheString != null) {
      Map<String, String> loadedCache =
          Map<String, String>.from(jsonDecode(imageCacheString));
      _imageCache.addAll(loadedCache);
    }
    String? queryCacheString = prefs.getString('queryCache');
    if (queryCacheString != null) {
      Map<String, dynamic> loadedCache = jsonDecode(queryCacheString);
      loadedCache.forEach((key, value) {
        _queryCache[key] = List<dynamic>.from(value);
      });
    }
  }

  static Future<void> saveCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('recipeCache', jsonEncode(_recipeCache));
    prefs.setString('imageCache', jsonEncode(_imageCache));
    prefs.setString('queryCache', jsonEncode(_queryCache));
  }

  static Future<void> initializeData() async {
    await loadCache();
    try {
      List<dynamic> recipesFromApi = await fetchRecipesFromApi();
      for (var recipe in recipesFromApi) {
        _recipeCache[recipe['name']] = recipe;
      }
      await saveCache();
    } catch (e) {
      print('Failed to fetch recipes from API: $e');
    }
  }

  static Future<List<dynamic>> fetchRecipesFromApi() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/recipes'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<dynamic>.from(data['recipes']);
    } else {
      throw Exception('Failed to load recipes from API');
    }
  }

  static Future<List<dynamic>> searchRecipes(String query) async {
    List<dynamic> cachedResults = _recipeCache.values
        .where((recipe) => recipe['name']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    if (cachedResults.isNotEmpty) {
      return cachedResults;
    }

    final response = await http
        .get(Uri.parse('https://dummyjson.com/recipes/search?q=$query'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> apiResults = data['recipes'];

      List<dynamic> combinedResults = _mergeRecipes([], apiResults);

      if (combinedResults.isEmpty) {
        combinedResults = await generateRecipesWithAI(query);
      }

      // Update caches
      for (var recipe in combinedResults) {
        _recipeCache[recipe['name']] = recipe;
      }
      _queryCache[query] = combinedResults;
      await saveCache();

      return combinedResults;
    } else {
      throw Exception('Failed to search recipes');
    }
  }

  static List<dynamic> _mergeRecipes(List<dynamic> list1, List<dynamic> list2) {
    Map<String, dynamic> recipeMap = {};

    for (var recipe in list1) {
      recipeMap[recipe['name']] = recipe;
    }
    for (var recipe in list2) {
      recipeMap[recipe['name']] = recipe;
    }

    return recipeMap.values.toList();
  }

  static Future<List<dynamic>> generateRecipesWithAI(String query) async {
    final prompt = '''
Based on the input "$query", generate 2 unique recipes. Each recipe should have the following structure:

Recipe Name: <Recipe Name>
Ingredients:
- Ingredient 1
- Ingredient 2
...
Instructions:
1. Step 1
2. Step 2
...
Prep Time: <prep time in minutes>
Calories per Serving: <calories>

Please return 2 recipes in this exact format. Do not add headers like "Recipe 1" or "##". DO NOT ADD ANYTHING ELSE THAT IS NOT CONTAINED IN THE FORMAT, YOU SHOULD RESPOND WITH FOLLOWING FORMAT!!
''';

    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    final responseText = response.text;

    if (responseText != null) {
      try {
        final RegExp recipePattern =
            RegExp(r'Recipe Name:.*?(?=Recipe Name:|$)', dotAll: true);
        final List<String> recipeMatches = recipePattern
            .allMatches(responseText)
            .map((match) => match.group(0) ?? '')
            .toList();

        List<dynamic> recipes = [];

        for (String recipeString in recipeMatches) {
          if (recipeString.trim().isEmpty) continue;

          final recipe = _parseRecipeText(recipeString.trim());
          if (recipe != null) {
            recipes.add(recipe);
          }
        }

        recipes = recipes.take(2).toList();

        List<Future<String>> imageFetchFutures = recipes.map((recipe) {
          return fetchImageForRecipe(recipe['name']);
        }).toList();

        List<String> imageUrls = await Future.wait(imageFetchFutures);

        for (int i = 0; i < recipes.length; i++) {
          recipes[i]['image'] = imageUrls[i];
        }

        for (var recipe in recipes) {
          _recipeCache[recipe['name']] = recipe;
        }
        await saveCache();
        return recipes;
      } catch (e) {
        print("Error while parsing recipe text: $e");
        throw Exception('Invalid recipe format received from AI');
      }
    } else {
      throw Exception('Failed to generate recipes with AI');
    }
  }

  static Map<String, dynamic>? _parseRecipeText(String recipeText) {
    try {
      final lines = recipeText.split('\n');
      String name = '';
      List<String> ingredients = [];
      List<String> instructions = [];
      int prepTimeMinutes = 0;
      int caloriesPerServing = 0;

      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('Recipe Name:')) {
          name = lines[i].replaceFirst('Recipe Name:', '').trim();
        } else if (lines[i].startsWith('Ingredients:')) {
          for (int j = i + 1; j < lines.length; j++) {
            if (lines[j].startsWith('Instructions:')) {
              i = j - 1;
              break;
            }
            ingredients.add(lines[j].trim().replaceFirst('- ', ''));
          }
        } else if (lines[i].startsWith('Instructions:')) {
          for (int j = i + 1; j < lines.length; j++) {
            if (lines[j].startsWith('Prep Time:')) {
              i = j - 1;
              break;
            }
            instructions
                .add(lines[j].trim().replaceFirst(RegExp(r'^\d+\.\s'), ''));
          }
        } else if (lines[i].startsWith('Prep Time:')) {
          final prepTimeString = lines[i]
              .replaceFirst('Prep Time:', '')
              .replaceAll('minutes', '')
              .trim();
          prepTimeMinutes = int.tryParse(prepTimeString) ?? 0;
        } else if (lines[i].startsWith('Calories per Serving:')) {
          caloriesPerServing = int.tryParse(
                  lines[i].replaceFirst('Calories per Serving:', '').trim()) ??
              0;
        }
      }

      name = name.replaceAll(RegExp(r'\*\*|##'), '').trim();

      return {
        'name': name,
        'ingredients': ingredients.isEmpty ? ['N/A'] : ingredients,
        'instructions': instructions.isEmpty ? ['N/A'] : instructions,
        'prepTimeMinutes': prepTimeMinutes,
        'caloriesPerServing': caloriesPerServing
      };
    } catch (e) {
      print("Error while parsing recipe text: $e");
      return null;
    }
  }

  static Future<String> fetchImageForRecipe(String recipeName) async {
    if (_imageCache.containsKey(recipeName)) {
      final cachedImageUrl = _imageCache[recipeName]!;
      if (cachedImageUrl.contains('placeholder.com')) {
        return await fetchNewImage(recipeName);
      } else {
        return cachedImageUrl;
      }
    } else {
      return await fetchNewImage(recipeName);
    }
  }

  static Future<String> fetchNewImage(String recipeName) async {
    try {
      final response = await http.get(Uri.parse(
          'https://img-url-ten.vercel.app/api/search?q=${Uri.encodeQueryComponent(recipeName)}&offset=0'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'].isNotEmpty) {
          final imageUrl = data['items'][0]['url'];
          _imageCache[recipeName] = imageUrl;
          await saveCache();
          return imageUrl;
        }
      }
    } catch (e) {
      print('Error fetching image for $recipeName: $e');
    }
    final placeholderUrl =
        'https://via.placeholder.com/150?text=${Uri.encodeComponent(recipeName)}';
    _imageCache[recipeName] = placeholderUrl;
    await saveCache();
    return placeholderUrl;
  }

  static Future<String> downloadAndSaveImage(
      String imageUrl, String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$imageName';
    final File imageFile = File(imagePath);
    if (await imageFile.exists()) {
      return imagePath;
    }
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      await imageFile.writeAsBytes(response.bodyBytes);
      return imagePath;
    } else {
      throw Exception('Failed to download image');
    }
  }

  static Future<String?> getLocalImagePath(String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$imageName';
    final File imageFile = File(imagePath);
    if (await imageFile.exists()) {
      return imagePath;
    } else {
      return null;
    }
  }

  static List<dynamic> getLastSearchData() {
    return _recipeCache.values.toList();
  }

  static List<dynamic> getRecipesByName(String query) {
    return _recipeCache.values
        .where((recipe) => recipe['name']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
  }
}
