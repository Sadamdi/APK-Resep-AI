import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'detail_page.dart';
import 'recipe_data.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<dynamic>> _recipes;
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<bool> _hasInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  void _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    bool hasInternet = await _hasInternetConnection();

    if (hasInternet) {
      _recipes = RecipeData.fetchRecipes();
      setState(() {
        _isOffline = false;
      });
    } else {
      _recipes = Future.value(RecipeData.getLastSearchData());
      setState(() {
        _isOffline = true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _getImage(String imageUrl, String recipeId) async {
    // Cek apakah gambar sudah ada di lokal
    String? localImagePath = await RecipeData.getLocalImagePath(recipeId);

    if (localImagePath != null) {
      return localImagePath;
    }

    return await RecipeData.downloadAndSaveImage(imageUrl, recipeId);
  }

  void _searchRecipes(String query) async {
    setState(() {
      _isLoading = true;
    });

    bool hasInternet = await _hasInternetConnection();

    if (hasInternet) {
      RecipeData.searchRecipes(query).then((results) {
        setState(() {
          _recipes = Future.value(results);
          _isLoading = false;
          _isOffline = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      });
    } else {
      setState(() {
        _recipes = Future.value(RecipeData.getLastSearchData());
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Recipes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What is in your kitchen?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Find your perfect recipe here!',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (query) {
                    _searchRecipes(query);
                  },
                ),
                if (_isOffline)
                  const Text(
                    'You are offline. Showing last loaded data.',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<dynamic>>(
                    future: _recipes,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        final recipes = snapshot.data!;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 3 / 4,
                          ),
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return FutureBuilder<String>(
                              future: _getImage(
                                  recipe['image'], recipe['id'].toString()),
                              builder: (context, imageSnapshot) {
                                if (imageSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (imageSnapshot.hasError) {
                                  return const Center(
                                      child: Text('Failed to load image.'));
                                } else {
                                  final imagePath = imageSnapshot.data!;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailPage(
                                            recipeData: recipe,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: Image.file(
                                                File(imagePath),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recipe['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text('Best Recipe'),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        '${recipe['caloriesPerServing']?.toString() ?? 'N/A'} Kcal'),
                                                    Text(
                                                        '${recipe['prepTimeMinutes']?.toString() ?? 'N/A'} min'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('No recipes found.'));
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
