import 'package:flutter/material.dart';

import 'landing_page.dart';
import 'recipe_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecipeData.loadCache();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tastify',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: LandingPage(),
    );
  }
}
