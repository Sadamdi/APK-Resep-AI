# **Tastify AI Recipes 📱**

**Tastify AI Recipes** – An innovative platform that simplifies finding delicious recipes using AI. This Android app combines a vast collection of recipes with cutting-edge AI technology to generate recipe suggestions when none are found. Developed by **Group 1 of GDSC UIN Malang** as part of the IT Incubation program.

## Project Overview

Tastify AI Recipes provides users with an easy-to-use interface for browsing recipes across various categories (appetizers, main courses, desserts, and more). Recipes are dynamically fetched from [DummyJSON](https://dummyjson.com), and if no results are available, AI-powered recipe generation ensures users always have cooking inspiration.

### Key Features

- **Recipe Caching and Favorites**: Recipes are cached locally to optimize loading times and allow users to access their favorite recipes without needing to search again.
- **AI-Powered Recipe Search**: If no recipes are found in the database, AI Gemini generates custom recipes based on user input.
- **Detailed Recipe Information**: Each recipe comes with nutritional information, including calories per serving and preparation time.
- **Dynamic Recipe Search**: Search for recipes based on ingredients or keywords and get instant results.
- **User-Friendly Interface**: Simple navigation through categories such as appetizers, main courses, and desserts.

## Technologies Used

- **Frontend**: Flutter (App)
- **Backend**: API integration with [DummyJSON](https://dummyjson.com), AI-powered recipe generation (fallback)
- **Version Control**: Git & GitHub

## How to Run the Project

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/Sadamdi/APK-Resep-AI.git
   ```
2. Open the project in your Flutter development environment.
3. Run the project on a supported browser or mobile device:
   ```bash
   flutter run
   ```

## API and AI Reference

The sample data used in this project is fetched from [DummyJSON](https://dummyjson.com). Additionally, if no results are returned from the API, the app leverages AI to generate recipe suggestions dynamically based on user input.

## Contributors 👨‍🍳👩‍🍳

This project was created by **Group 1 of GDSC UIN Malang** as part of the IT Incubation program.

## License

This project is open-source and available under the [MIT License](LICENSE).