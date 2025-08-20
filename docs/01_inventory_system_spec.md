# **Feature Spec: 01 - The Intelligent Inventory System**

*This document outlines the architecture and features for the food inventory management system.*

### **1.0 Core Mission**

The inventory system will serve as a persistent, structured store for a user's food items. It must be flexible enough to accommodate diverse kitchen setups and intelligent enough to minimize manual data entry. The primary goal is to provide a foundation for advanced AI features like meal planning, food waste reduction, and automated shopping lists.

---

### **2.0 Data Architecture**

The system will be driven by a flexible, database-centric model that allows for user customization.

#### **2.1 Database Schema (SQLite)**

**`locations` Table:** Stores user-defined storage locations.
```sql
CREATE TABLE locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    icon_name TEXT
);

categories Table: Stores user-defined item categories.
SQL

CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

inventory Table: The core table for all inventory items.
SQL

CREATE TABLE inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    brand TEXT,
    quantity TEXT,
    unit TEXT,
    location_id INTEGER,
    category_id INTEGER,
    health_rating TEXT,
    notes TEXT,
    FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
);

2.2 Data Models (Dart)

    InventoryItem: Represents a single item. It will include fields for id, name, brand, quantity, unit, notes, and healthRating. It will reference Location and InventoryCategory objects.

    Location: A simple model with id, name, and iconName.

    InventoryCategory: A simple model with id and name.

3.0 Feature Set & UI/UX Flow

The system will support three primary methods of interaction: manual, vision-based, and conversational.

3.1 Manual UI

    Inventory Screen: The primary screen will display all inventory items.

        Default View: Items will be grouped first by Location, then sub-grouped by Health Rating (🟢, 🟡, 🔴).

        Dynamic Controls: The user will have UI controls to dynamically change the grouping (e.g., group by Health Rating first) and sorting (e.g., sort by name, date added).

    "Manage Storage" Screen: A dedicated settings screen where users can perform full CRUD operations on their custom Locations and InventoryCategories.

    CRUD Operations: Standard dialogs for creating, reading, updating, and deleting individual InventoryItem records.

3.2 Vision-Based AI Update ("Scan Groceries")

    UI Flow: A "Scan Groceries" button will allow the user to select one or more photos from their camera or gallery.

    AI Prompt: The backend will send the image(s) to Gemini Pro with a prompt to identify distinct food items and return a structured JSON array ([{'name': '...', 'quantity': ..., 'unit': '...'}]).

    Confirmation UI: The app will display the AI-generated list to the user for review, allowing them to correct errors or remove duplicates before the items are saved to the database.

3.3 Conversational AI Update (via Universal Chat)

    UI Flow: The user will interact via a natural language chat interface.

    AI Prompt: The user's command (e.g., "add milk and eggs, remove the carrots") will be sent to the backend along with the entire current inventory as JSON. The AI's task is to analyze the command and the current state, returning a structured JSON object of changes: { "add": [...], "update": [...], "delete": [...] }.

    Confirmation UI: The app will present a summary of the proposed changes for the user to approve before executing the database transactions.

3.4 Import/Export Bridge Feature (MVP)

    To provide immediate value, the inventory screen will include a simple Import/Export feature.

    This allows the user to export their current inventory as a text list, paste it into an external Gemini chat for complex manipulation, and then paste the updated list back into the app to re-import it. This serves as a manual bridge to advanced AI capabilities before the Universal AI chat is fully implemented.