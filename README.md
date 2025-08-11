# Recette - An Intelligent Kitchen Assistant

*Last Updated: August 11, 2025*

## 🚀 Core Mission

Recette is a sophisticated mobile application designed to function as a comprehensive **"Kitchen Assistant."** Its core mission is to help users navigate complex and often conflicting dietary needs within a household by intelligently managing the entire lifecycle of food—from inventory and recipes to meal planning and shopping lists.

The app is being built with the goal of reducing the daily cognitive load and stress associated with answering the question, "what's for dinner?"

## 🛠️ Core Technologies

* **Frontend (Mobile App):** Flutter & Dart
* **Backend (Serverless API):** Python on Google Cloud Functions
* **AI Engine:** A multi-model approach using Gemini Pro and Flash for complex reasoning and fast, efficient analysis.
* **Local Storage:** `sqflite` for the on-device database.

## ✨ Current Features (v0.1.0)

The project is currently a highly functional, single-user prototype with a robust set of features.

#### Recipe Management
* **Multi-Modal Recipe Import:** Add recipes from a URL, pasted text, or via OCR from the phone's camera/gallery.
* **AI-Powered Tagging & Search:** Recipes are automatically tagged by the AI, and users can use a powerful search engine to find recipes with complex queries (e.g., `tag:dinner -ingredient:cilantro`).
* **Recipe Lineage:** Create and track variations of a core recipe (e.g., a gluten-free version of a family favorite).
* **Export & Share:** Share recipes as cleanly formatted PDF or plain text documents.

#### Intelligence & Analysis
* **Personalized Health Checks:** Analyze any recipe against a natural-language dietary profile to get a simple "traffic light" health rating (🟢, 🟡, 🔴) and actionable suggestions.
* **On-Demand Nutritional Analysis:** Get a detailed nutritional breakdown (calories, fat, protein, sodium, etc.) for any block of recipe text, even without saving it to the app.
* **Context-Aware Meal Suggestions:** Get intelligent meal ideas based on your current inventory, dietary profile, and immediate situation (e.g., "I'm tired and need something quick").

#### Kitchen Management
* **Inventory System:** A foundational inventory system to manually track food items, complete with an AI-powered import/export feature to sync with an external chat.
* **Shopping List (Skeleton):** A basic, functional shopping list for adding and checking off items.
* **Meal Planner (Skeleton):** A basic weekly meal planner that allows users to assign recipes from their library to specific days and meals.

## 🗺️ Future Roadmap

The long-term vision for Recette is to continue evolving into a proactive, multi-user assistant. Key future phases include:

* **Architectural Overhaul:** Implementing a robust, asynchronous `ApiRequestManager` with intelligent caching and a "jobs tray" to make the app faster and more responsive.
* **The "AI Brain":** Developing a modular, persistent memory system that allows the AI to learn user preferences over time and provide more personalized, proactive assistance.
* **Multi-User & Cloud Sync:** Transitioning the app to a collaborative, cloud-synchronized platform where a family can share a common inventory, recipe library, and meal plan.