# **Tastify AI Recipes 📱**

**Tastify AI Recipes** is an innovative platform that simplifies finding delicious recipes using AI. This Android app combines a vast collection of recipes with cutting-edge AI technology to generate recipe suggestions when none are found. Developed by **Group 1 of GDSC UIN Malang** as part of the IT Incubation program.

## Project Overview

Tastify AI Recipes provides users with an easy-to-use interface for browsing and searching for recipes. Recipes are dynamically fetched from [DummyJSON](https://dummyjson.com) and cached locally for offline access. If no matching recipes are found in the existing data, AI-powered recipe generation ensures users always have cooking inspiration. The app offers robust offline support, allowing users to search and view recipes even without an internet connection.

### Key Features

- **Offline Support**: Access your recipes anytime, even without an internet connection. The app loads and caches recipes and images for offline use.
- **Recipe Caching**: Recipes and images are cached locally to optimize loading times and reduce data usage.
- **AI-Powered Recipe Generation**: If no recipes are found in the database, the app uses Google's Generative AI to generate custom recipes based on user input, which are then saved for future offline access.
- **Duplicate Recipe Handling**: The app intelligently handles duplicates by displaying only unique recipes based on their names.
- **Dynamic Recipe Search**: Search for recipes based on ingredients or keywords. The app searches both cached data and the API, ensuring comprehensive results.
- **Detailed Recipe Information**: Each recipe comes with nutritional information, including calories per serving and preparation time.
- **User-Friendly Interface**: Simple navigation and intuitive design make it easy to find and view recipes.

## Technologies Used

- **Frontend**: Flutter
- **Backend**:
  - **API Integration**: Fetches data from [DummyJSON](https://dummyjson.com)
  - **AI-Powered Recipe Generation**: Uses Google's Generative AI (e.g., Gemini model) to generate recipes
- **Data Storage**: `SharedPreferences` for caching recipes and `path_provider` and `dart:io` for caching images locally
- **Networking**: `http` package for API calls
- **Connectivity Check**: `connectivity_plus` package
- **Unique Identifiers**: `uuid` package
- **Version Control**: Git & GitHub

## How to Run the Project

1. **Clone the repository to your local machine:**

   ```bash
   git clone https://github.com/Sadamdi/APK-Resep-AI.git
   ```

2. **Navigate to the project directory:**

   ```bash
   cd APK-Resep-AI
   ```

3. **Install dependencies:**

   ```bash
   flutter pub get
   ```

4. **Set up your Google API Key for AI Recipe Generation:**

   - Obtain an API key from [Google Cloud Platform](https://cloud.google.com/) for the Generative AI service.
   - Enable the necessary APIs in your Google Cloud Console.
   - In `lib/recipe_data.dart`, replace `'YOUR_GOOGLE_API_KEY'` with your actual API key:

     ```dart
     static const String apiKey = 'YOUR_GOOGLE_API_KEY'; // Replace with your API key
     ```

5. **Run the project on a supported device or emulator:**

   ```bash
   flutter run
   ```

   - **Note**: Ensure that the device or emulator has internet connectivity during the initial use to fetch and cache data.

6. **Testing Offline Mode:**

   - After running the app once with internet connectivity, you can test offline functionality by turning off internet access and restarting the app.
   - The app should load cached recipes and allow you to search within them.

## API and AI Reference

- **Sample Data API**: Recipes are fetched from [DummyJSON](https://dummyjson.com).
- **AI Recipe Generation**: The app uses Google's Generative AI to generate recipes when no matching recipes are found. Generated recipes are saved to local storage for offline access and future searches.

## Additional Dependencies

Ensure the following dependencies are included in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.4
  path_provider: ^2.0.11
  shared_preferences: ^2.0.15
  connectivity_plus: ^2.3.5
  google_generative_ai: # Add the correct version
  uuid: ^3.0.6
```

## Additional Notes

- **AI Model Access**: The AI recipe generation feature relies on Google's Generative AI models (e.g., Gemini). Access to these models may require participation in specific programs or have usage limits.
- **API Quotas and Limits**: Be aware of any quotas or rate limits associated with your API key to avoid interruptions in service.
- **Privacy and Data Storage**: The app stores recipes and images locally using `SharedPreferences` and the device's file system. Ensure that this complies with any data privacy requirements.
- **Error Handling**: The app includes error handling to manage exceptions, especially related to network connectivity. Users are informed when they are offline, and cached data is used when necessary.

## Contributors 👨‍🍳👩‍🍳

This project was created by **Group 1 of GDSC UIN Malang** as part of the IT Incubation program.

## License

This project is open-source and available under the [MIT License](LICENSE).