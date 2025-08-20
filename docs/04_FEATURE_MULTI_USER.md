# **Feature Spec: Multi-User & Cloud Sync Architecture**

*This document outlines the architecture for transitioning the app from a single-user, local-only experience to a collaborative, multi-user, cloud-synchronized platform.*

### **1.0 Core Mission**

The goal is to allow multiple users within a defined group (e.g., a family) to share a common set of data, such as a recipe library and food inventory. The system must ensure strict data privacy between different groups while leveraging a shared cache for public, non-personal data.

---

### **2.0 Cloud Architecture (Firestore)**

The cloud database will be structured to support three distinct levels of data ownership, enforced by Firestore Security Rules.

* **👤 Private User Data**: Data belonging exclusively to a single user (e.g., `DietaryProfile`, private notes). Stored in `/users/{userId}` and secured by rules where `request.auth.uid == userId`.
* **👨‍👩‍👧‍👦 Family-Shared Data**: Data shared by a defined group of users (e.g., shared recipe library, inventory). Stored under a `/families/{familyId}` document that contains a list of member UIDs for security rule checks.
* **🌎 Globally Cached Public Data**: Cached results of expensive, non-personal computations (e.g., a parsed recipe from a public URL). Stored in a public collection readable by all authenticated users but writable only by the backend server.

---

### **3.0 App Architecture**

* **Authentication**: The app will implement user authentication to get a stable `uid` for each user.
* **Repository Layer**: The existing `DatabaseHelper` will be wrapped by or replaced with a `Repository` layer responsible for fetching from the multi-layered cache (local -> cloud -> API).
* **Offline Support**: The repository will manage a local `sqflite` cache of the shared Firestore data, allowing the app to remain functional offline.