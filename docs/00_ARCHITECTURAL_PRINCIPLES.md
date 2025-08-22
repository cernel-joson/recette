# **Spec: 00 - Architectural Principles & Patterns**

*This document is the foundational guide for the Recette application's architecture. It defines the core principles and patterns that all developers (human and AI) must follow to ensure the codebase is clean, consistent, and maintainable.*

### **1.0 Core Philosophy**

The app's primary goal is to be a helpful, non-intrusive **"Kitchen Assistant."** The architecture must reflect this by being:
* **Responsive:** The UI must never be blocked by long-running operations.
* **Robust:** The app must handle errors and imperfect data gracefully.
* **Maintainable:** The codebase must be easy to understand, test, and extend.

---

### **2.0 Separation of Concerns (SoC)**

The app follows a strict separation of concerns, with each layer having a single, well-defined responsibility.

* **`Services` (The "Back Office"):**
    * **Location:** `lib/features/.../data/services/`
    * **Responsibility:** Encapsulate all business logic (e.g., saving a recipe, importing from a URL, checking usage limits).
    * **Rule:** Services are **UI-agnostic**. They must not import `material.dart` or have any knowledge of widgets or `BuildContext`. They orchestrate data from repositories and helpers.

* **`Repositories` (The "Librarians"):**
    * **Location:** `lib/core/.../data/repositories/`
    * **Responsibility:** Mediate between business logic and a specific data source. They are the only classes that should directly talk to a data source helper (like `DatabaseHelper`).
    * **Example:** `JobRepository` handles all direct database communication for the `job_history` table.

* **`Controllers` (`ChangeNotifier`) (The "Floor Managers"):**
    * **Location:** `lib/features/.../presentation/controllers/`
    * **Responsibility:** Manage the UI's state and handle user input. They are the bridge between the UI and the services.
    * **Rule:** Controllers should contain minimal business logic. Their methods should be simple one-liners that delegate the real work to a **`Service`**.

* **`UI Layer` (Widgets & Screens):**
    * **Location:** `lib/features/.../presentation/screens/` and `widgets/`
    * **Responsibility:** To display state and capture user input.
    * **Rule:** UI components should call methods on a `Controller` in response to user actions (`onPressed`, `onSubmitted`, etc.).

---

### **3.0 Core Architectural Patterns**

* **Asynchronous by Default:** All I/O operations (database, network) must be asynchronous and handled through the **`JobManager`** system. Direct, blocking calls to `ApiHelper` or `DatabaseHelper` from the UI layer are forbidden.
* **Dependency Injection with `Provider`:** Services and controllers are instantiated once at the top of the widget tree (in `main.dart`) and made available to the rest of the app via `Provider`. This ensures a single instance of each service is used and makes testing easier.
* **Modularity ("Features" vs. "Core"):**
    * **`lib/features/`:** Contains self-contained feature modules (e.g., `recipes`, `inventory`). Each feature has its own `data`, `logic`, and `presentation` layers.
    * **`lib/core/`:** Contains cross-cutting concerns that are shared by all features (e.g., the `JobManager`, `DatabaseHelper`, `ApiHelper`).