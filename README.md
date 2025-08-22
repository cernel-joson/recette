# Recette - An Intelligent Kitchen Assistant

*Last Updated: August 20, 2025*

## 🚀 Core Mission

Recette is a mobile application designed to function as a comprehensive **"Kitchen Assistant."** Its primary goal is to help users navigate the complex and often conflicting dietary needs within a household by intelligently managing the entire lifecycle of food—from inventory and recipes to meal planning.

The app's core purpose is to **reduce the daily cognitive load and stress** associated with answering the question, "what's for dinner?" by acting as a proactive, intelligent, and empathetic partner in the kitchen.

---

## 🛠️ Core Technologies

* **Frontend (Mobile App):** Flutter & Dart
* **Backend (Serverless API):** Python on Google Cloud Functions
* **AI Engine:** A multi-model approach using Gemini Pro and Flash.
* **Local Storage:** `sqflite` for the on-device database.

---

## ✨ Current Project Status

The project is a highly functional, single-user prototype. The core architecture is stable, and the codebase has been refactored into a clean, multi-file structure. A comprehensive suite of unit tests has been established for core models and services.

### Implemented Features & Phases:

* **Phase 1: Core Single-User Experience (✅ Complete):** Includes a robust data model, duplicate detection, and recipe lineage (variations).
* **Phase 2: The Organizational Layer (✅ Complete):** Features AI-powered tagging and a powerful search engine with a guided filter UI.
* **Phase 3: Advanced Intelligence & UI Refinement (🔄 In Progress):** A multi-model AI backend is in place.
* **Phase 4: Foundational Architecture Overhaul (🔄 In Progress):** The core asynchronous `JobManager` system has been implemented, making the app more responsive and ensuring AI-generated data is never lost.
* **MVPs Implemented:** Foundational versions of the **Inventory System**, **On-Demand Nutritional Analysis**, and **Context-Aware Meal Suggestions** are functional.

---

## 🏛️ Project Documentation

This project is guided by a set of living design documents that outline its architecture and feature specifications.

* **[Architectural Principles](./docs/00_ARCHITECTURAL_PRINCIPLES.md):** The foundational guide for the app's architecture and design patterns.
* **[System Architecture](./docs/01_SYSTEM_ARCHITECTURE.md):** A high-level overview of the app's technical architecture, including the AI and data caching strategies.
* **[Development Roadmap](./docs/02_ROADMAP.md):** The planned, high-level implementation sequence for the Recette app.
* **[Feature Spec: Inventory System](./docs/03_FEATURE_INVENTORY_SYSTEM.md):** Detailed specification for the food inventory management system.
* **[Feature Spec: Multi-User & Cloud Sync](./docs/04_FEATURE_MULTI_USER.md):** The architecture for transitioning to a collaborative, cloud-synchronized platform.
* **[Feature Spec: UI Refinement](./docs/05_FEATURE_UI_REFINEMENT.md):** Key UI/UX improvements, including the "Split This Recipe" AI assistant.
* **[Feature Spec: The AI "Brain"](./docs/06_FEATURE_AI_BRAIN.md):** The long-term vision for a portable, context-aware, and persistent AI system.
* **[Dev Mode & QA](./docs/07_DEVELOPER_MODE_AND_QA.md):** The specification for a hidden developer toolkit for debugging and testing.
* **[Ethical Design Principles](./docs/08_ETHICAL_DESIGN.md):** The strategy for ensuring the app is a cooperative partner to content creators.