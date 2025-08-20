# **Feature Spec: 04 - Asynchronous API & Caching Systems**

*This document outlines the architecture for handling all background tasks in a way that prioritizes a fast, responsive UI, optimizes for cost, and provides a transparent, user-centric experience.*

### **1.0 Core Mission**

The app's heavy reliance on the Gemini API means that network latency is a major risk to the user experience. This system mitigates those risks by implementing an asynchronous, non-blocking job management system. The UI should **never feel "stuck"** waiting for a network request, and the results of AI computations should be treated as **persistent, valuable assets**.

---

### **2.0 The `ApiRequestManager` Service**

A central `ApiRequestManager` service will manage all background work. Feature-specific services will no longer call the `ApiHelper` directly; they will submit **"Jobs"** to this manager.

* **Asynchronous by Default:** All tasks are non-blocking. The UI submits a job and is immediately free.
* **Request Queuing & Prioritization:** The manager will maintain a queue of pending jobs, allowing it to control the flow of requests and prioritize user-facing tasks over background analysis.
* **Intelligent Batching:** The manager can be designed to be "lazy," waiting a few hundred milliseconds to bundle similar, queued jobs (e.g., multiple health checks) into a single, efficient batch API call.

---

### **3.0 The Persistent Job Store**

To ensure no AI work is ever lost, the results of all jobs are stored persistently in the local `sqflite` database. This table also serves as a powerful caching layer.

* **`job_history` Table Schema:**
    ```sql
    CREATE TABLE job_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_type TEXT NOT NULL, -- e.g., 'recipe_parsing', 'meal_suggestion'
        status TEXT NOT NULL, -- 'queued', 'in_progress', 'complete', 'failed'
        request_fingerprint TEXT UNIQUE, -- A SHA-256 hash of the request payload for caching
        request_payload TEXT, -- The full JSON payload sent to the backend
        prompt_text TEXT, -- The exact prompt text sent to Gemini for debugging
        response_payload TEXT, -- The full JSON response from the AI
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
    ```

---

### **4.0 The "Jobs Tray": A Universal UI for Asynchronous Work**

A universal UI system will provide clear and consistent feedback about background tasks.

#### **4.1 Global Feedback**

* **The Jobs Tray Icon:** A dynamic icon will be present in the main `AppBar`. It will be static when idle and will animate (e.g., spin or pulse) when any job is `queued` or `in_progress`.
* **The Jobs Tray Screen:** Tapping the icon will open a dedicated screen that displays a list of recent jobs from the `job_history` table. Users can see the status of each job and tap on completed items to view the results (e.g., open a parsed recipe or see meal suggestions), effectively "replaying" the AI's response without a new API call.

#### **4.2 Context-Specific Feedback**

* **Immediate Confirmation:** When a user initiates an action, the UI element they interacted with will provide immediate feedback (e.g., a button shows a spinner).
* **Hand-off Notification:** Once the job is successfully queued with the `ApiRequestManager`, the local UI element returns to its normal state, and the global Jobs Tray icon begins its "in-progress" animation. This clearly communicates to the user that their request has been received and is being worked on in the background.