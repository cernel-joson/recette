### **`docs/04_asynchronous_systems_spec.md`**

```markdown
# **Feature Spec: 04 - Asynchronous API & Caching Systems**

*This document outlines the architecture for handling API calls and caching in a way that prioritizes a fast, responsive UI and optimizes for cost and efficiency.*

### **1.0 Core Mission**

The app's heavy reliance on the Gemini API means that network latency and computational time are major risks to the user experience. This system aims to mitigate those risks by implementing a smart, multi-layered caching strategy and an asynchronous, non-blocking API request manager. The user interface should never feel "stuck" waiting for a network request.

---

### **2.0 Multi-Layered Caching Strategy**

All data requests will flow through a three-tiered cascade. A request only proceeds to the next, slower layer if the current one results in a "cache miss."

1.  **📍 Layer 1: Local On-Device Cache (`sqflite`)**:
    * **Role**: Instantaneous retrieval of recently accessed data.
    * **Cost/Speed**: Free / Milliseconds.

2.  **☁️ Layer 2: Shared Cloud Cache (Firestore)**:
    * **Role**: A shared, persistent cache to benefit all users and devices, solving the "fresh install" problem.
    * **Cost/Speed**: Very low / Fast (100-500ms).

3.  **🧠 Layer 3: Gemini API Call**:
    * **Role**: The ultimate source of truth for new computations.
    * **Cost/Speed**: Highest cost / Slowest (seconds).

---

### **3.0 The `ApiRequestManager` Service**

A new, central service will be created to manage all outbound communication with the backend. Feature-specific services will no longer call the `ApiHelper` directly; they will submit requests to this manager.

#### **3.1 Core Principles**

* **Asynchronous by Default**: All API requests will be non-blocking. The UI submits a request and is immediately free. The manager notifies the UI with the result via a callback or a stream when the background task is complete.
* **Request Queuing**: The manager will maintain a queue of pending tasks, allowing it to control the flow of requests.
* **Intelligent Batching**: The manager will be designed to be "lazy," waiting a few hundred milliseconds to see if multiple, similar requests are added to the queue. It will then automatically bundle them into a single, more efficient batch API call. (e.g., running a health check on 5 recipes at once).
* **Prioritization**: The manager will support request prioritization. A user actively waiting for a recipe to parse is a **high-priority, foreground task**. A background task like the fuzzy similarity check is a **low-priority, background task** that can be deferred until the device is idle or charging.

#### **3.2 "Save Now, Notify Later" Pattern**

This pattern will be applied to features like the Asynchronous Fuzzy Similarity Matching.

1.  **Instant UI Action**: The user saves a recipe. The app saves it to the local database *immediately* and closes the edit screen. The UI feels instant.
2.  **Submit Background Task**: The app submits a low-priority "find similar recipes" request to the `ApiRequestManager`.
3.  **Process in Background**: The manager eventually sends the request to the API.
4.  **Save Result**: The result (a list of similar recipe IDs) is saved to a "pending suggestions" table in the local database.
5.  **Non-intrusive Notification**: The next time the user opens the `RecipeLibraryScreen`, the UI checks this table and, if a suggestion exists, displays a non-intrusive banner, allowing the user to address it at their convenience.

```