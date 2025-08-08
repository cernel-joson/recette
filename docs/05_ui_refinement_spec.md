
### **`docs/05_ui_refinement_spec.md`**

```markdown
# **Feature Spec: 05 - UI Refinement & Accessibility**

*This document outlines key UI/UX improvements to make the app more intuitive, accessible, and user-friendly, particularly for a non-technical audience.*

### **1.0 Core Mission**

The app must feel like a helpful assistant, not a tedious administrative tool. The interface should be clean, clear, and forgiving. It must reduce the user's cognitive load by automating complex tasks and presenting information in an easily digestible format.

---

### **2.0 Key UI Refinements**

#### **2.1 `RecipeViewScreen` Overhaul (`SliverAppBar`)**

* **Problem**: The current layout with a `BottomAppBar` and a `PopupMenuButton` is becoming cluttered and is not scalable as more actions are added.
* **Solution**: Re-architect the screen to use a `CustomScrollView` and a `SliverAppBar`.
    * **Consolidate Actions**: All primary actions (Analyze, Edit, Share, Print, etc.) will be moved into the `SliverAppBar`'s `actions` property as `IconButton` widgets.
    * **Dynamic Layout**: The app bar will be configured to expand and collapse as the user scrolls, making better use of screen space and providing a more modern, dynamic feel.

#### **2.2 The "Split This Recipe" AI Assistant**

* **Problem**: Users cooking for multiple people with conflicting dietary needs (e.g., diabetic and a picky eater) face a significant daily challenge.
* **Solution**: A dedicated "Split This Recipe" feature.
    * **UI**: A button in the `RecipeViewScreen` will trigger the feature.
    * **AI Prompt**: The backend will use a specialized prompt that takes both dietary profiles and the recipe, instructing the AI to generate a simple, step-by-step "Split Modification Plan."
    * **Output**: The app will display a clean, two-column view ("For Person A" / "For Person B") showing the simple variations needed to cater to both individuals from one core meal.

#### **2.3 Proactive "Plan My Week" Feature**

* **Problem**: The daily question of "what's for dinner?" is a major source of user fatigue.
* **Solution**: A "Plan My Week" button on the dashboard.
    * **Functionality**: This will trigger a single, powerful AI call that considers all saved user profiles and the current inventory to generate a balanced, 7-day meal plan.
    * **Thematic Suggestions**: To reduce choice overload, the app will also offer curated, one-tap suggestions like "Easy One-Pot Meals" or "30-Minute Dinners."

---

### **3.0 Accessibility & Usability Principles**

* **Clear, Simple Language**: Use straightforward terminology throughout the app (e.g., "My Groceries" instead of "Inventory").
* **Legibility**: Ensure the default theme uses larger font sizes and high-contrast color combinations.
* **Frictionless Data Management**:
    * **"I Made This" Button**: A single tap after cooking a meal should be enough to intelligently deduct ingredients from the inventory.
    * **"Repurpose Leftovers" AI**: An AI-powered feature to suggest simple ways to use leftovers, reducing food waste and the need to cook from scratch every day.

```