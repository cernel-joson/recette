# **System Architecture Specification**

*This document outlines the high-level technical architecture for the Recette application, its backend services, and its data management strategies.*

## **1.0 Core Technologies**

* **Frontend (Mobile App):** Flutter & Dart
* **Backend (Serverless API):** Python on Google Cloud Functions
* **AI Engine:** A multi-model approach using Gemini Pro and Flash.
* **Local Storage:** `sqflite` for the on-device database.
* **Cloud Storage & Cache:** Firestore.

## **2.0 The AI Cascade (Multi-Layered AI Strategy)**

To balance speed, cost, and intelligence, the system processes requests through a tiered cascade of AI models.

1.  **📱 On-Device AI (e.g., Gemma):** For instantaneous, zero-cost processing of simple tasks like intent recognition and basic entity extraction.
2.  **⚡ Gemini Flash API:** The cost-effective workhorse for standard, structured tasks like recipe parsing and standard health checks.
3.  **💎 Gemini Pro API:** Reserved for specialist tasks requiring creativity or multi-modal understanding, such as vision analysis (OCR), recipe modification ("Healthify"), and complex meal planning.

## **3.0 The Data Cascade (Multi-Layered Caching Strategy)**

All data requests flow through a three-tiered system to maximize performance and minimize cost.

1.  **📍 Local Cache (`sqflite`):** Provides instantaneous, offline access to recently used data. It's the first place the app looks for information, particularly the results of completed jobs.
2.  **☁️ Cloud Cache (Firestore):** A shared, persistent cache to benefit all users and devices. It solves the "fresh install" problem and reduces redundant API calls across the user base.
3.  **🧠 Gemini API Call:** The ultimate source of truth, only accessed when a "cache miss" occurs at both the local and cloud levels.

## **4.0 Asynchronous Job Management**

The app's architecture is built around an asynchronous job system to ensure the UI is **never blocked** by long-running AI tasks. This system is the foundation upon which all other features are built, prioritizing UI responsiveness, data persistence, and user transparency.

* **The `JobManager` Service**: A central service layer handles all background tasks. It manages a queue of `Job` objects, is agnostic about their content, and delegates work to specialized `JobWorker` classes.
* **The Persistent Job Store**: A `job_history` table in the local `sqflite` database makes the entire system durable. It serves as both a history log and a powerful cache, ensuring that the results of AI computations are **never thrown away**.
* **The Universal Feedback UI**: A user-facing "jobs tray" provides a transparent view of all queued, in-progress, and completed background tasks, making the results of AI computations persistent and replayable.

## **5.0 API Versioning**

To ensure backward compatibility between the frontend app and the backend service, the project will use a URL-based API versioning strategy.

* **Strategy**: Each breaking change to the backend API will result in the deployment of a new, versioned Cloud Function (e.g., `recipe_analyzer_api-v1`, `recipe_analyzer_api-v2`).
* **Frontend**: The Flutter app will be hardcoded to a specific version of the API. This ensures that older versions of the app continue to function by calling older, stable versions of the backend.
* **Deprecation**: Older API versions can be monitored for traffic and safely decommissioned once all users have upgraded to a newer version of the app.

This approach prevents breaking changes in the backend from crashing older app versions in the wild, providing a stable and reliable user experience.