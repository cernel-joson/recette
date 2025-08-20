# **Feature Spec: UI Refinement & Accessibility**

*This document outlines key UI/UX improvements to make the app more intuitive, accessible, and user-friendly.*

### **1.0 Core Mission**

The app must feel like a helpful assistant, not a tedious administrative tool. The interface should be clean, clear, and forgiving, reducing the user's cognitive load by automating complex tasks and presenting information in an easily digestible format.

---

### **2.0 Key UI Refinements**

* **`RecipeViewScreen` Overhaul (`SliverAppBar`)**: Re-architect the screen to use a `CustomScrollView` and a `SliverAppBar`, consolidating all primary actions into the app bar to reduce clutter.
* **The "Split This Recipe" AI Assistant**: A dedicated feature to help users cooking for multiple people with conflicting dietary needs. The AI will generate a simple, step-by-step "Split Modification Plan" to cater to both individuals from one core meal.
* **Proactive "Plan My Week" Feature**: A button on the dashboard that triggers a powerful AI call to generate a balanced, 7-day meal plan based on user profiles and inventory.

### **3.0 Accessibility & Usability Principles**

* **Clear, Simple Language**: Use straightforward terminology (e.g., "My Groceries" instead of "Inventory").
* **Legibility**: Use larger font sizes and high-contrast color combinations.
* **Frictionless Data Management**: Implement features like a one-tap "I Made This" button to intelligently deduct ingredients from inventory and a "Repurpose Leftovers" AI to reduce food waste.