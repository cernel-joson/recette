# **Intelligent Nutrition App: Project Plan & System Specification**

*Last Updated: August 19, 2025*

### **1.0 Core Mission & Vision**

The project's goal is to create a sophisticated mobile application, **Recette**, to help users navigate complex dietary needs. It will evolve from a single-user recipe utility into a comprehensive, multi-user **"Kitchen Assistant."** The system will intelligently manage the entire lifecycle of food in a household—from inventory and recipes to meal planning and leftovers—providing personalized guidance tailored to the specific, and often conflicting, needs of each individual.

### **2.0 Core Technologies & Architecture**

* **Front-End (Mobile App):** Flutter & Dart
* **Back-End (Serverless API):** Python on Google Cloud Functions
* **AI Engine:** A multi-model approach for optimal performance and intelligence:
    * **gemini-2.5-pro**: For complex analysis, reasoning, and generation tasks requiring deep understanding.
    * **gemini-2.5-flash**: For faster, less complex operations like quick categorizations or simple parsing to improve responsiveness.
* **Local Storage:** sqflite for the on-device database and shared_preferences for simple key-value storage.
* **Version Control:** Git & GitHub

### **3.0 Current Project Status**

The project is a highly functional, single-user prototype. The core architecture is stable, and the codebase has been refactored into a clean, multi-file structure and is under version control on GitHub.

#### **3.1 Implemented Features**

* **Multi-Modal Recipe Import:** From a URL, pasted text, or via OCR from the phone's camera/gallery.
* **Local Recipe Library:** A full CRUD (Create, Read, Update, Delete) system for a local sqflite recipe database.
* **Document Generation & Sharing:** Users can Print or Share recipes as cleanly formatted PDF or plain text documents.
* **System Integration:** The app is registered as a "Share Target" in Android, allowing users to share URLs and images directly into the app.
* **Personalized Dietary Profile & Health Check:** Users can save a dietary profile as natural language text. A "Health Check" feature analyzes a recipe against this profile to provide a "traffic light" health rating (Green/Yellow/Red) and actionable suggestions.

### **4.0 System Architecture & Design Principles**

#### **4.1 Data & Caching Model**

* **Multi-User Foundation:** The architecture will be built around a users table to store individual profiles. A generic, multi-user health_cache table will store health ratings for specific item-user pairs, creating a many-to-many relationship.
* **Robust Fingerprinting:**
    * **Recipe Content Fingerprint:** The system will generate a fingerprint of a recipe's content (e.g., title, ingredients, instructions).
    * **Cache Invalidation:** The health cache for a recipe will be considered stale if *either* the user's profile_fingerprint changes or the recipe's item_fingerprint changes, ensuring ratings are always accurate.
* **Hybrid Caching Strategy:**
    * **Centralized (Cloud) Cache:** The Python Cloud Function will check a central cache (like Firestore or Redis) before making a call to the Gemini API.
    * **Local (On-Device) Cache:** The Flutter app will cache recently viewed recipes and health ratings on the device for speed and offline access.
* **Flexible Data Models:**
    * The ingredient quantity field will be a flexible String to accurately capture non-standard measurements like "a splash."
    * An optional quantity_numeric field will be added to the ingredient model, which the AI will attempt to populate for future features like recipe scaling.

#### **4.2 User Experience (UX) Design**

* **"Traffic Light" Health Rating:** The app uses an intuitive Green/Yellow/Red system for visual feedback on how a recipe aligns with a user's health profile.
* **Unified Multi-User Display:** In list views, a single icon will show the *most restrictive* health rating for the group. Tapping the icon will reveal a detailed breakdown for every person.
* **Rules vs. Preferences:** User profiles will distinguish between "Health Rules & Allergies" (hard constraints for the AI) and "Likes, Dislikes & Preferences" (soft suggestions) to provide more nuanced results.

### **5.0 Development Roadmap**

This roadmap outlines the planned implementation sequence, focusing on building foundational features before adding more complex layers.

---

### **Phase 1: Solidify the Core Single-User Experience**

*This phase focused on making the current data model and library features robust and reliable before major new functionality was added.*

1.  **✅ (Complete) Enhance Data Model Flexibility:**
    * Modify the Ingredient model and database schema to ensure the quantity field is a flexible String to accurately capture non-standard measurements.
    * Add the optional quantity_numeric field to the model and update the AI import prompt to populate it when possible.
2.  **✅ (Complete) Implement Robust Fingerprinting & Duplicate Detection:**
    * Develop a reliable function to generate a content-based item_fingerprint for each recipe.
    * Use this fingerprint to prevent identical recipes from being saved to the library, prompting the user if a duplicate is detected.
    * Update the single-user "Health Check" caching logic to use this item_fingerprint for cache invalidation.
3.  **✅ (Complete) Implement Recipe Lineage:**
    * Add a nullable parent_recipe_id column to the recipes table in the database.
    * Update the UI to allow a user to create a variation of an existing recipe, correctly setting the parent-child relationship.

---

### **Phase 2: Build the Organizational Layer**

*This phase focused on making a large library of recipes manageable and searchable.*

1.  **✅ (Complete) Implement AI-Powered Tagging:**
    * Create a recipe_tags table to store a many-to-many relationship between recipes and tags.
    * Enhance the AI import prompt to suggest relevant tags (cuisine, meal type, etc.) for each new recipe.
2.  **✅ (Complete) Develop the Search Engine:**
    * **Canonical Search Parser:** Build the internal parser that can translate a power-user query string (e.g., `tag:dinner -ingredient:cilantro`) into a complex SQL query.
    * **Guided Filter UI:** Create the user-facing filter panel with checkboxes, sliders, and text fields that programmatically constructs the canonical search string in the background.

---

### **Phase 3: Advanced Intelligence & UI Refinement**

*This phase focuses on adding more sophisticated AI features and improving the user experience based on the now-complex feature set.*

1.  **🔄 (In Progress) Implement a Multi-Model AI Backend:**
    * Refactor the `ApiHelper` to support both `gemini-2.5-pro` and `gemini-2.5-flash`.
    * Update the API backend to route requests to the chosen model, optimizing for cost and speed.
2.  **Implement Asynchronous Fuzzy Similarity Matching:**
    * Adopt a "save now, notify later" pattern. The recipe saves instantly to the local database for a responsive UI.
    * Trigger a background AI analysis to find semantically similar recipes.
    * Save pending suggestions to the database and notify the user with a non-intrusive UI element on their next visit, allowing them to link recipes at their convenience.
3.  **Refine Recipe View UI with SliverAppBar:**
    * Re-architect the `RecipeViewScreen` to use a `CustomScrollView` and `SliverAppBar`.
    * Consolidate all recipe actions (Analyze, Edit, Share, etc.) into the `SliverAppBar` to declutter the UI.
4.  **Implement "Healthify This Recipe" AI Modifier:**
    * Add a button to the recipe view that allows a user to request a healthier version of the recipe based on a specific goal (e.g., "lower in carbohydrates").
5.  **Implement Dynamic Recipe Scaling:**
    * Add a UI element to the recipe view that allows a user to change the serving size.
    * Use an AI prompt to intelligently adjust ingredient quantities, leveraging the `quantity_numeric` field.

---

### **Phase 4: Foundational Architecture Overhaul**

*This phase focuses on rebuilding the core service layers to be more efficient, scalable, and cost-effective in preparation for advanced inventory and multi-user features.*

1.  **Implement Multi-Layered Caching Strategy:**
    * **Local Cache:** Solidify the existing `sqflite` on-device cache for instantaneous access to recently used data.
    * **Cloud Cache (Firestore):** Implement a structured, multi-layered cloud cache to reduce redundant API calls and solve the "fresh install" problem.
        * **Private User Data:** Store personal data (e.g., dietary profiles, private notes) in a user-specific document path, secured by rules that only allow access to the authenticated owner.
        * **Family-Shared Data:** Create a `families` collection to manage shared data (e.g., recipe libraries, meal plans) for a defined group of users, secured by rules that check for group membership.
        * **Globally Cached Public Data:** Use a separate collection to cache non-personal, computationally expensive data (e.g., parsed recipes from public URLs), readable by all users but writable only by the backend.
    * **API Layer:** Ensure Gemini is only called as a final step when a "cache miss" occurs at both the local and cloud levels.
2.  **Implement Multi-Layered AI Strategy:**
    * **On-Device AI:** Integrate a lightweight, on-device model (e.g., Gemma) to handle high-frequency, low-complexity tasks like intent recognition for the universal chat, providing instant responses with zero API cost.
    * **API Tiering:** Solidify the use of Gemini Flash for standard, structured tasks and reserve Gemini Pro for the most complex, creative, and multi-modal operations.
3.  **Refactor Backend into Modular Services:**
    * Break down the monolithic `main.py` cloud function into a modular, route-based architecture.
    * Create separate, single-responsibility handlers for recipe parsing, AI enhancements, and the new inventory service to improve maintainability and testability.

---

### **Phase 5: The Intelligent Inventory System**

*This phase builds the complete food inventory management system, a core pillar of the "Kitchen Assistant" vision.*

1.  **Build Core Inventory Functionality:**
    * Implement the `InventoryItem` data model and create the `inventory` table in the local `sqflite` database.
    * Build the manual UI: a dedicated `InventoryScreen` with full CRUD (Create, Read, Update, Delete) capabilities for managing items.
2.  **Implement Vision-Based Inventory Updates:**
    * Create a "Scan Groceries" feature that allows users to add items by taking pictures of their shopping or pantry.
    * Build the backend logic to have Gemini identify food items from images and return a structured list.
    * Implement a "Review Items" UI for the user to confirm the AI's findings before adding them to the inventory.
3.  **Implement On-the-Fly Nutritional Estimation & Health Ratings:**
    * When a new item is added to the inventory, trigger a background AI call to get its "at-a-glance" health rating (🟢, 🟡, 🔴) against the user's profile.
    * For recipes, implement the feature to get an estimated nutritional breakdown (calories, fat, protein, carbs) per serving.

---

### **Phase 6: The Multi-User Overhaul**

*This is the major version update that transforms the app into a collaborative family tool.*

1.  **Implement Multi-User Profiles & Cloud Sync:**
    * Create the `users` table and a dedicated screen for managing family profiles.
    * Transition the local `sqflite` database to a shared, cloud-based solution using the Firestore architecture from Phase 4.
    * Implement user authentication.
2.  **Upgrade to Multi-User Health Analysis:**
    * Update the API and caching system to handle health ratings for multiple users.
    * Implement the "Unified Multi-User Display" logic in the UI.
3.  **Generate Smart Shopping Lists & Meal Plans:**
    * Develop features for creating shared shopping lists from recipes and inventory levels.
    * Build AI-powered meal planning tools ("Use What I Have," Thematic Plans) that operate on the shared recipe library and inventory.

---

### **Phase 7: Universal Intelligence & Conversational UI**

*This final phase transforms the app from a structured tool into a truly interactive and conversational kitchen assistant.*

1.  **Implement Universal AI Integration:**
    * Build a persistent, universal chat interface accessible from anywhere in the app, powered by the multi-layered AI architecture from Phase 4.
    * This interface will handle conversational inventory updates ("remove the apples and add milk") and context-aware queries.
2.  **Implement Interactive Cooking Assistance ("AI Sous-Chef"):**
    * Leverage the universal chat interface within the recipe view to create a conversational cooking assistant that can answer ad-hoc questions during the cooking process.

### **6.0 Development Workflow & Quality Assurance**

* **Developer Mode:** Implement a hidden "Developer Mode" that, among other tools, allows the developer to view the raw prompts being sent to the Gemini API to facilitate on-the-fly testing and refinement.
* **Version Control:** Continue to use Git for version control and GitHub for remote backup. Feature development will occur on separate branches to keep the main branch stable.
* **Testing Suite:** Implement a comprehensive testing suite:
    * **Unit Tests:** For data models and business logic.
    * **Widget Tests:** For individual UI components.
    * **Integration Tests:** For end-to-end user flows.
* **Continuous Integration (CI):** Explore using a service like GitHub Actions to automatically run all tests and build the app on every push, ensuring that no change breaks the project.