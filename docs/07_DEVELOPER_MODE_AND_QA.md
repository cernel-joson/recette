# **Feature Spec: Developer Mode & Quality Assurance**

*This document outlines the architecture for a hidden "Developer Mode" to facilitate testing, debugging, and quality assurance.*

### **1.0 Core Mission**

As the app's complexity grows, a robust set of internal tools is necessary to diagnose issues, test new features, and manage data without requiring external tools or database clients. "Developer Mode" will provide a hidden, in-app toolkit that is powerful for the developer but invisible to the end-user.

---

### **2.0 Activation Mechanism**

To keep the primary UI clean, Developer Mode will be activated via a hidden gesture.

* **Activation**: Tapping a specific UI element (e.g., the app version number on a new "About" screen) 7 times in quick succession will enable Developer Mode.
* **Persistence**: The enabled status will be saved to `shared_preferences`, so it persists across app restarts.
* **Deactivation**: A toggle switch within the Developer Options screen will allow the mode to be disabled.

---

### **3.0 The Developer Toolkit**

Once enabled, a new "Developer Options" card will appear on the main `DashboardScreen`. This will lead to a dedicated screen with the following tools:

#### **3.1 The Job Inspector (Network Console)**

This tool is for "cracking open" the `JobsTrayScreen` to get the raw details of any API call.

* **UI**: In Developer Mode, tapping a job in the `JobsTrayScreen` will open a new, detailed inspector view.
* **Functionality**:
    * **Request Payload**: Displays the exact JSON `requestPayload` sent to the backend.
    * **Prompt Text**: Displays the full `promptText` sent to Gemini, crucial for prompt engineering and debugging.
    * **Raw Response**: Displays the unformatted JSON `responsePayload` received from the AI before being parsed by the app.

#### **3.2 Data Manipulation Tools (The "Backdoor")**

These tools provide direct control over the app's local data for testing and workarounds.

* **JSON Import/Export**: The "Paste Recipe JSON" feature will be a permanent tool within the "Add Recipe" menu, visible only in Developer Mode. A corresponding "Export to JSON" option will be added to the recipe view screen.
* **Database Manager**: A new screen that provides:
    * **View Tables**: A simple, read-only view of key database tables (`recipes`, `inventory`, `job_history`).
    * **Clear Tables**: Buttons to wipe the data from specific tables, useful for testing migrations or starting a feature from a clean slate.

#### **3.3 The Control Panel**

The main "Developer Options" screen will also provide:

* **Feature Flags**: A section of switches to enable or disable features that are still in development.
* **Reset App Data**: A button to delete the `sqflite` database file and clear `SharedPreferences`, simulating a fresh install without needing to uninstall the app.