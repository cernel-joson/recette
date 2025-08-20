This document has been updated to reflect the concrete implementation details of the Job model, the repository, controller, manager, and the first worker. It now serves as a more accurate description of the existing system.

# **Core Architecture Spec: The Asynchronous Job System**

*This document outlines the definitive architecture for Recette's core background task and data management system. This system is the foundation upon which all other features are built, prioritizing UI responsiveness, data persistence, and user transparency.*

---

## **1.0 Core Mission & Philosophy**

The app's primary value comes from complex, and often long-running, AI-driven tasks. The user experience must **never be blocked** by this work. The app must feel instantaneous and intelligent.

To achieve this, we have moved away from a traditional request/response model and adopted a **job-based architecture**. Every significant action a user takes (e.g., parsing a recipe, asking for meal ideas) is treated as a **durable, persistent "Job"** that is processed asynchronously. The AI's work is a valuable asset; its results are **never thrown away**.

---

## **2.0 The Three Pillars of the System**

This architecture is composed of three tightly integrated components: the **Job Management Service**, the **Persistent Job Store**, and the **Universal Feedback UI**.

### **Pillar 1: The `JobManager` Service (The Brain Stem)**

This is the central service layer responsible for handling all background tasks. It is the single entry point for any feature needing to perform asynchronous work.

#### **Core Components:**
* **`JobManager`**: The core scheduler. It manages an in-memory queue of jobs and processes them one at a time. It is agnostic about the job's content; it only knows how to delegate work to a registered "worker" based on the `jobType`.
* **`JobWorker`**: An abstract interface that defines the contract for executing a specific type of job. Concrete implementations, like `RecipeParsingWorker`, contain the feature-specific logic.
* **`JobController`**: A `ChangeNotifier` that acts as the central state manager for all jobs. It fetches job data from the `JobRepository` and notifies the UI of any changes, making it the single source of truth for the state of all background tasks.

### **Pillar 2: The Persistent Job Store (The Long-Term Memory)**

This is the database layer that makes the entire system durable and transparent. It serves as both a history log and a powerful cache.

#### **`job_history` Table Schema (sqflite):**
```sql
CREATE TABLE job_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_type TEXT NOT NULL,
    title TEXT,
    status TEXT NOT NULL, -- 'queued', 'inProgress', 'complete', 'failed', 'archived'
    priority TEXT NOT NULL DEFAULT 'normal',
    request_fingerprint TEXT UNIQUE,
    request_payload TEXT,
    prompt_text TEXT,
    response_payload TEXT,
    created_at DATETIME NOT NULL,
    completed_at DATETIME
);

    Job Model: A data class that represents a single job, mapping directly to the job_history table schema.

    JobRepository: A dedicated service that handles all database operations (CRUD) for the job_history table, isolating the database logic from the rest of the application.

Pillar 3: The Universal Feedback UI (The Public Face)

This system provides clear, consistent, and non-disruptive feedback about background tasks.

    Global Feedback (JobsTrayIcon): A dynamic icon in the main AppBar that animates when jobs are active. Tapping it opens the JobsTrayScreen.

    Centralized History (JobsTrayScreen): A dedicated screen that displays a persistent, scrollable list of recent jobs by reading directly from the JobController. It allows users to view the status of all tasks and "replay" the results of completed jobs.

    Contextual Notifications: For jobs that require user action upon completion (like recipe parsing), a contextual banner appears in the relevant screen (e.g., the RecipeLibraryScreen), prompting the user to review the result.


---

### `docs/02_ROADMAP.md`

I have updated the roadmap to show that the architectural overhaul is now in progress, with the foundational elements of the asynchronous job system being the first completed items.

```markdown
# **Development Roadmap**

*This document outlines the planned, high-level implementation sequence for the Recette app.*

### **Phase 1: Core Single-User Experience (✅ Complete)**
* Enhance Data Model Flexibility
* Implement Robust Fingerprinting & Duplicate Detection
* Implement Recipe Lineage (Variations)

### **Phase 2: The Organizational Layer (✅ Complete)**
* Implement AI-Powered Tagging
* Develop the Search Engine & Guided Filter UI

### **Phase 3: Advanced Intelligence & UI Refinement (🔄 In Progress)**
* Implement Multi-Model AI Backend
* Implement Asynchronous Fuzzy Similarity Matching
* Refine Recipe View UI with SliverAppBar
* Implement "Healthify This Recipe" AI Modifier
* Implement Dynamic Recipe Scaling

### **Phase 4: Foundational Architecture Overhaul (🔄 In Progress)**

*Focuses on rebuilding core service layers to be more efficient, scalable, and cost-effective in preparation for advanced inventory and multi-user features.*

* **🔄 (In Progress) Implement the Asynchronous `JobManager` System:**
    * ✅ **(Complete)** Design and build the core job management services (`JobManager`, `JobRepository`, `JobController`).
    * ✅ **(Complete)** Implement the persistent `job_history` store in the local database.
    * ✅ **(Complete)** Build the universal UI feedback system (`JobsTrayIcon`, `JobsTrayScreen`).
    * ✅ **(Complete)** Refactor the recipe parsing feature to use the new asynchronous job system.
* Implement Multi-Layered Caching Strategy (Local & Cloud)
* Implement Multi-Layered AI Strategy (On-Device & Tiered API)
* Refactor Backend into Modular Services

### **Phase 5: The Intelligent Inventory System**
*Builds the complete food inventory management system.*
* Build Core Inventory Functionality (Manual CRUD, Custom Locations)
* Implement Vision-Based Inventory Updates ("Scan Groceries")
* Implement On-the-Fly Health Ratings for Items

### **Phase 6: The Multi-User Overhaul**
*Transforms the app into a collaborative family tool.*
* Implement Multi-User Profiles & Cloud Sync via Firestore
* Upgrade to Multi-User Health Analysis
* Generate Smart Shopping Lists & Meal Plans

### **Phase 7: Universal Intelligence & Conversational UI**
*Transforms the app into a truly interactive kitchen assistant.*
* Implement Universal AI Integration ("Command Bus" Pattern)
* Implement Interactive Cooking Assistance ("AI Sous-Chef")