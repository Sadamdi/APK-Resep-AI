import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RecipeData {
  static const String apiKey = '';
  static final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  static final uuid = Uuid();
  static final Map<int, dynamic> _recipeCache = {};
  static final Map<String, String> _imageCache = {};
  static final Map<String, List<dynamic>> _queryCache = {};

  static Future<void> loadCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? recipeCacheString = prefs.getString('recipeCache');
    if (recipeCacheString != null) {
      Map<String, dynamic> loadedCache = jsonDecode(recipeCacheString);
      loadedCache.forEach((key, value) {
        _recipeCache[int.parse(key)] = value;
      });
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
    prefs.setString(
        'recipeCache',
        jsonEncode(
            _recipeCache.map((key, value) => MapEntry(key.toString(), value))));
    prefs.setString('imageCache', jsonEncode(_imageCache));
    prefs.setString('queryCache', jsonEncode(_queryCache));
  }

  static Future<List<dynamic>> fetchRecipes() async {
    final response = await http.get(Uri.parse('https://dummyjson.com/recipes'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['recipes'];
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  static Future<dynamic> fetchRecipeById(int id) async {
    if (_recipeCache.containsKey(id)) {
      return _recipeCache[id];
    }
    final response =
        await http.get(Uri.parse('https://dummyjson.com/recipes/$id'));
    if (response.statusCode == 200) {
      final recipe = jsonDecode(response.body);
      _recipeCache[id] = recipe;
      await saveCache();
      return recipe;
    } else {
      throw Exception('Failed to load recipe');
    }
  }

  static Future<List<dynamic>> searchRecipes(String query) async {
    if (_queryCache.containsKey(query)) {
      return _queryCache[query]!;
    }
    final response = await http
        .get(Uri.parse('https://dummyjson.com/recipes/search?q=$query'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> recipes;
      if (data['recipes'].isEmpty) {
        recipes = await generateRecipesWithAI(query);
      } else {
        recipes = data['recipes'];
      }
      _queryCache[query] = recipes;
      await saveCache();
      return recipes;
    } else {
      throw Exception('Failed to search recipes');
    }
  }

  static Future<List<dynamic>> generateRecipesWithAI(String query) async {
    final prompt = '''
    Generate 3 recipes based on the following input: "$query".
    For each recipe, provide the following information in JSON format:
    {
      "name": "Recipe Name",
      "ingredients": ["Ingredient 1", "Ingredient 2", ...],
      "instructions": ["Step 1", "Step 2", ...],
      "prepTimeMinutes": 30,
      "caloriesPerServing": 300
    }
    Provide only the JSON output, without any additional text.
    ''';
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    final responseText = response.text;
    print(responseText);
    if (responseText != null) {
      try {
        String cleanedResponse = responseText
            .replaceAll(RegExp(r'```json'), '')
            .replaceAll(RegExp(r'```'), '');
        cleanedResponse = cleanedResponse.replaceAll(RegExp(r'}\s*{'), '},{');
        final jsonString = '[$cleanedResponse]';
        final List<dynamic> recipes = jsonDecode(jsonString);
        if (recipes is List) {
          List<Future<String>> imageFetchFutures = [];
          for (var recipe in recipes) {
            String recipeName = recipe['name'] ?? 'Recipe';
            imageFetchFutures.add(fetchImageForRecipe(recipeName));
          }
          List<String> imageUrls = await Future.wait(imageFetchFutures);
          List<dynamic> processedRecipes = [];
          for (int i = 0; i < recipes.length; i++) {
            var recipe = recipes[i];
            int prepTimeMinutes =
                int.tryParse(recipe['prepTimeMinutes'].toString()) ?? 0;
            int caloriesPerServing =
                int.tryParse(recipe['caloriesPerServing'].toString()) ?? 0;
            processedRecipes.add({
              'id': uuid.v4(),
              'name': recipe['name'],
              'ingredients': recipe['ingredients'] ?? [],
              'instructions': recipe['instructions'] ?? [],
              'prepTimeMinutes': prepTimeMinutes,
              'caloriesPerServing': caloriesPerServing,
              'image': imageUrls[i],
            });
          }
          _queryCache[query] = processedRecipes;
          await saveCache();
          return processedRecipes;
        } else {
          throw Exception(
              'Expected a list of recipes, but received something else.');
        }
      } catch (e) {
        print("Error while parsing JSON: $e");
        throw Exception('Invalid JSON format received from AI');
      }
    } else {
      throw Exception('Failed to generate recipes with AI');
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
    return _queryCache.isNotEmpty ? _queryCache.values.first : [];
  }

  static Future<String> _getImage(String imageUrl, String recipeName) async {
    String? localImagePath = await RecipeData.getLocalImagePath(recipeName);
    if (localImagePath != null) {
      return await RecipeData.fetchNewImage(recipeName);
    } else {
      return await RecipeData.downloadAndSaveImage(imageUrl, recipeName);
    }
  }
}
