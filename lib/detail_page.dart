import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DetailPage extends StatelessWidget {
  final dynamic recipeData;

  const DetailPage({Key? key, required this.recipeData}) : super(key: key);

  Future<String?> _getLocalImagePath(String fileName) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    final filePath = '${documentDirectory.path}/$fileName';

    if (File(filePath).existsSync()) {
      return filePath;
    } else {
      return null;
    }
  }

  Widget _buildRecipeImage(String imageUrl) {
    final fileName = Uri.parse(imageUrl).pathSegments.last;

    return FutureBuilder<String?>(
      future: _getLocalImagePath(fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            // Display the image from local storage
            return Image.file(File(snapshot.data!), fit: BoxFit.cover);
          } else {
            // Display a placeholder or default image if not found
            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/placeholder.png',
                  fit: BoxFit.cover,
                );
              },
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double appBarHeight = 250;
          final double opacityStart = appBarHeight - kToolbarHeight;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: appBarHeight,
                pinned: true,
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    double scrollOffset = constraints.biggest.height;
                    double opacity =
                        (scrollOffset - kToolbarHeight) / opacityStart;
                    if (opacity > 1) opacity = 1;
                    if (opacity < 0) opacity = 0;

                    final double t = (1 -
                            (scrollOffset - kToolbarHeight) /
                                (appBarHeight - kToolbarHeight))
                        .clamp(0.0, 1.0);

                    final Alignment titleAlignment = Alignment.lerp(
                        Alignment.bottomLeft, const Alignment(-1.0, 0.4), t)!;

                    return FlexibleSpaceBar(
                      titlePadding: EdgeInsets.lerp(
                          const EdgeInsets.only(left: 16, bottom: 8),
                          const EdgeInsets.only(left: 60, bottom: 2),
                          t)!,
                      title: Align(
                        alignment: titleAlignment,
                        child: Text(
                          recipeData['name'],
                          style: TextStyle(
                            fontSize: 20 + (5 * (1 - t)),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                offset: Offset(1.5, 1.5),
                                blurRadius: 2.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildRecipeImage(recipeData['image'] ??
                              'https://via.placeholder.com/150'),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(opacity * 0.7),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                      collapseMode: CollapseMode.parallax,
                    );
                  },
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer),
                                const SizedBox(width: 4),
                                Text('${recipeData['prepTimeMinutes']} min'),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department),
                                const SizedBox(width: 4),
                                Text(
                                    '${recipeData['caloriesPerServing']} Kcal'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.teal),
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var ingredient
                                    in recipeData['ingredients'])
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text('- $ingredient'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.teal),
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0;
                                    i < recipeData['instructions'].length;
                                    i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                        '${i + 1}. ${recipeData['instructions'][i]}'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
