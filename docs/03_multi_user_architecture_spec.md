### **`docs/03_multi_user_architecture_spec.md`**

````markdown
# **Feature Spec: 03 - Multi-User & Cloud Sync Architecture**

*This document outlines the architecture for transitioning the app from a single-user, local-only experience to a collaborative, multi-user, cloud-synchronized platform.*

### **1.0 Core Mission**

The goal is to allow multiple users within a defined group (e.g., a family) to share a common set of data, such as a recipe library and food inventory. The system must ensure strict data privacy between different groups while leveraging a shared cache for public, non-personal data to optimize performance and cost.

---

### **2.0 Cloud Architecture (Firestore)**

The cloud database will be structured to support three distinct levels of data ownership and sharing, enforced by Firestore Security Rules.

#### **2.1 👤 Private User Data**

* **Description**: Data that belongs exclusively to a single user.
* **Examples**: The user's personal `DietaryProfile`, private notes.
* **Firestore Structure**: Stored in a top-level `users` collection, with documents keyed by the user's unique authentication ID (`uid`).
    ```
    /users/{userId}/dietaryProfile
    ```
* **Security Rules**: `allow read, write: if request.auth.uid == userId;`

#### **2.2 👨‍👩‍👧‍👦 Family-Shared Data**

* **Description**: Data shared by a defined group of users, but private to that group.
* **Examples**: The shared recipe library, shared inventory, family meal plan.
* **Firestore Structure**: A top-level `families` collection will manage group membership. Shared data will live in sub-collections under a specific `familyId`.
    ```
    /families/{familyId}
      - members: ["user_abc", "user_xyz"]
      /recipes/{recipeId}
      /inventoryItems/{itemId}
    ```
* **Security Rules**: Access will be granted by checking if the requesting user's `uid` exists in the `members` array of the family document.
    ```
    allow read, write: if request.auth.uid in get(/databases/$(database)/documents/families/$(familyId)).data.members;
    ```

#### **2.3 🌎 Globally Cached Public Data**

* **Description**: Cached results of expensive, non-personal computations that can benefit all app users.
* **Examples**: Parsed recipe data from a public URL.
* **Firestore Structure**: A top-level `publicRecipeCache` collection, with documents keyed by a deterministic hash of the data source (e.g., a SHA-256 hash of the URL).
    ```
    /publicRecipeCache/{hashedUrl}/
      - parsedData: { ... }
    ```
* **Security Rules**: All authenticated users can read from this cache, but write access is restricted to the backend server to prevent data pollution.
    ```
    allow read: if request.auth != null;
    allow write: if false; // Or check for a service account token
    ```

---

### **3.0 App Architecture**

* **Authentication**: The app will implement user authentication (e.g., Sign in with Google) to get a stable `uid` for each user.
* **Data Repositories**: The existing `DatabaseHelper` for `sqflite` will be wrapped by or replaced with a `Repository` layer. This repository will be responsible for fetching data from the multi-layered cache (local -> cloud -> API) and synchronizing writes back to Firestore.
* **Offline Support**: The repository will manage a local `sqflite` cache of the shared Firestore data, allowing the app to remain functional when the user is offline. Changes made while offline will be synchronized when a connection is re-established.

````