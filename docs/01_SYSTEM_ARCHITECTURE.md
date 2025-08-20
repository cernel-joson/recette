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

1.  **📍 Local Cache (`sqflite`):** Provides instantaneous, offline access to recently used data. It's the first place the app looks for information.
2.  **☁️ Cloud Cache (Firestore):** A shared, persistent cache to benefit all users and devices. It solves the "fresh install" problem and reduces redundant API calls across the user base.
3.  **🧠 Gemini API Call:** The ultimate source of truth, only accessed when a "cache miss" occurs at both the local and cloud levels.

## **4.0 Asynchronous Job Management (`ApiRequestManager`)**

A central `ApiRequestManager` service will manage all outbound communication to ensure a non-blocking UI.

* **Queuing & Batching:** It will queue all background tasks and intelligently batch similar requests (e.g., multiple health checks) into a single API call to improve efficiency.
* **Prioritization:** It will support prioritizing tasks, running user-facing requests (like parsing a recipe) before low-priority background jobs (like finding similar recipes).
* **"Jobs Tray" UI:** A user-facing "jobs tray" will provide a transparent view of all queued, in-progress, and completed background tasks, making the results of AI computations persistent and replayable.