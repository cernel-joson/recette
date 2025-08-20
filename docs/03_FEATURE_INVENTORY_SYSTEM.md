# **Feature Spec: The Intelligent Inventory System**

*This document outlines the architecture and features for the food inventory management system.*

### **1.0 Core Mission**

The inventory system will serve as a persistent, structured store for a user's food items. It must be flexible enough to accommodate diverse kitchen setups and intelligent enough to minimize manual data entry. Its primary goal is to provide a foundation for advanced AI features like meal planning, food waste reduction, and automated shopping lists.

---

### **2.0 Data Architecture**

The system is driven by a flexible, database-centric model that allows for user customization.

#### **2.1 Database Schema (SQLite)**

* **`locations` Table:** Stores user-defined storage locations (e.g., 'Downstairs Freezer').
* **`categories` Table:** Stores user-defined item categories (e.g., 'Baking', 'Canned Goods').
* **`inventory` Table:** The core table for all inventory items, linked to locations and categories via foreign keys.

#### **2.2 Data Models (Dart)**

* **`InventoryItem`**: Represents a single item with fields for `name`, `brand`, `quantity`, `unit`, `notes`, and `healthRating`.
* **`Location`**: A simple model with `id`, `name`, and `iconName`.
* **`InventoryCategory`**: A simple model with `id` and `name`.

---

### **3.0 Feature Set & UI/UX Flow**

The system supports manual, vision-based, and conversational interaction.

* **Manual UI**: A primary `InventoryScreen` displays all items, grouped by location. A dedicated "Manage Storage" screen allows users to perform full CRUD operations on their custom `Locations` and `InventoryCategories`.
* **Vision-Based AI Update ("Scan Groceries")**: Allows users to add items by taking pictures of their groceries. The backend AI identifies items and returns a structured list for user confirmation before saving.
* **Conversational AI Update**: The user can issue natural language commands (e.g., "add milk and eggs, remove the carrots") which the AI translates into a structured set of changes for user approval.
* **Import/Export Bridge Feature (MVP)**: Allows users to export their inventory as a simple text list for use in an external Gemini chat, and then re-import the updated list.