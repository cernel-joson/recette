# **Design Spec: 08 - Ethical & Cooperative Design**

*This document outlines the principles and features designed to ensure Recette acts as an ethical and symbiotic partner to the content creators whose recipes it helps users organize.*

### **1.0 Core Mission**

While the app provides a powerful utility for parsing and organizing recipes, it must do so in a way that respects the business models of the original creators (often ad-supported food blogs). The goal is to avoid "leeching" content and instead act as a **curation and value-add service** that drives traffic and engagement back to the source.

---

### **2.0 Key Features & Strategies**

#### **2.1 Prominent and Persistent Sourcing (MVP)**

* **Principle:** The original source of a recipe must always be clear, prominent, and easy to access.
* **Implementation:**
    * The `RecipeViewScreen` will feature a highly visible, tappable card or button at the top of every imported recipe.
    * The call to action will be explicit, such as **"View Original Recipe at [Website Name]"** to encourage click-throughs.

#### **2.2 The "Cooking Mode" with Web View**

* **Principle:** Balance the clean, ad-free utility of the app with the need for creators to receive ad revenue from their content.
* **Implementation:**
    * An imported recipe will offer two viewing modes:
        1.  **"App Mode":** The clean, parsed, structured view ideal for active cooking.
        2.  **"Web Mode":** An in-app browser that loads the original `sourceUrl`, displaying the creator's full post with its layout, photos, and ads.
    * This provides the best of both worlds: the creator gets the page view, and the user gets both the rich original content and the functional utility of the app.

#### **2.3 Official Partner Model (Long-Term Vision)**

* **Principle:** Move from scraping to direct, legitimate partnerships where possible.
* **Implementation:**
    * Integrate with the official APIs that many large recipe websites and services provide.
    * This ensures high-quality data, respects the creators' terms of service, and can unlock deeper integrations, such as a "Save to Recette" button on the partner's website.