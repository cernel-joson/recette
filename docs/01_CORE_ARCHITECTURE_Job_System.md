# **Core Architecture Spec: The Asynchronous Job System**

*This document outlines the definitive architecture for Recette's core background task and data management system. This system is the foundation upon which all other features are built, prioritizing UI responsiveness, data persistence, and user transparency.*

---

## **1.0 Core Mission & Philosophy**

The app's primary value comes from complex, and often long-running, AI-driven tasks. The user experience must **never be blocked** by this work. The app must feel instantaneous and intelligent.

To achieve this, we will move away from a traditional request/response model and adopt a **job-based architecture**. Every significant action a user takes (e.g., parsing a recipe, asking for meal ideas) is treated as a **durable, persistent "Job"** that is processed asynchronously. The AI's work is a valuable asset; its results are **never thrown away**.

---

## **2.0 The Three Pillars of the System**

This architecture is composed of three tightly integrated components: the **Job Management Service**, the **Persistent Job Store**, and the **Universal Feedback UI**.

### **Pillar 1: The `JobManager` Service (The Brain Stem)**

This is the central service layer responsible for handling all background tasks. It is the single entry point for any feature needing to perform asynchronous work.

#### **Core Principles:**
* **Job-Oriented:** The manager does not handle raw API calls; it manages a queue of `Job` objects.
* **Asynchronous & Non-Blocking:** When a feature submits a job, the manager immediately returns control to the UI. The work happens entirely in the background.
* **Intelligent Batching:** The manager is "lazy" by design. It can wait a few hundred milliseconds to see if multiple, similar jobs are queued, bundling them into a single, efficient batch API call to the backend.
* **Prioritization:** Jobs can be assigned a priority (`high` for user-facing tasks like parsing a recipe, `low` for background analysis like finding similar recipes). The manager will process high-priority jobs first.
* **Request Fingerprinting:** Before executing a job, the manager will generate a fingerprint of its request payload. It will check the **Persistent Job Store** for a completed job with a matching fingerprint. If a "cache hit" is found, it will return the stored result instantly, avoiding a redundant API call.

### **Pillar 2: The Persistent Job Store (The Long-Term Memory)**

This is the database layer that makes the entire system durable and transparent. It serves as both a history log and a powerful cache.

#### **`job_history` Table Schema (sqflite):**
```sql
CREATE TABLE job_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_type TEXT NOT NULL, -- e.g., 'recipe_parsing', 'meal_suggestion'
    status TEXT NOT NULL, -- 'queued', 'in_progress', 'complete', 'failed'
    priority TEXT NOT NULL DEFAULT 'normal', -- 'low', 'normal', 'high'
    request_fingerprint TEXT UNIQUE, -- SHA-256 hash for caching
    request_payload TEXT, -- The JSON payload sent to the backend
    prompt_text TEXT, -- The exact prompt sent to Gemini (for debugging)
    response_payload TEXT, -- The full JSON response from the AI
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);