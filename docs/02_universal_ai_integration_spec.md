***

### **`docs/02_universal_ai_integration_spec.md`**

```markdown
# **Feature Spec: 02 - Universal AI Integration**

*This document outlines the architecture for a universal, context-aware AI chat interface.*

### **1.0 Core Mission**

The Universal AI Integration aims to transform the app from a set of structured tools into a flexible, conversational assistant. It will provide a single, persistent interface for users to interact with all of the app's features using natural language. The system must be fast, efficient, and context-aware.

---

### **2.0 System Architecture**

The integration will be architected as a new service layer that sits above the existing feature-specific services, following a **"Command Bus"** or **"Dispatcher"** pattern.

#### **2.1 The AI Cascade (Multi-Layered AI Strategy)**

To balance speed, cost, and intelligence, the system will process user input through a tiered cascade of AI models. A request only proceeds to the next layer if the current one cannot fulfill the need.

1.  **📱 On-Device AI (e.g., Gemma)**:
    * **Role**: Instantaneous, zero-cost processing of simple tasks.
    * **Primary Task**: **Intent Recognition**. Its sole job is to classify the user's natural language command (e.g., "how healthy is this?") into a structured intent (e.g., `{ "intent": "health_check" }`).
    * **Other Tasks**: Simple entity extraction (e.g., finding "apples" in "add apples to my list").

2.  **⚡ Gemini Flash API**:
    * **Role**: The cost-effective workhorse for the majority of structured, server-side tasks.
    * **Tasks**: Executing recognized intents like recipe parsing, standard health checks, and applying conversational inventory updates.

3.  **💎 Gemini Pro API**:
    * **Role**: The specialist reserved for tasks requiring creativity, deep reasoning, or multi-modal understanding.
    * **Tasks**: Vision-based analysis (OCR, grocery scanning), "Healthify This Recipe," and complex meal plan generation.

#### **2.2 The "Command Bus" Pattern**

1.  **Input**: A user types a command into the persistent chat UI.
2.  **Intent Recognition (On-Device)**: The text is first processed by the on-device model to determine the user's intent and extract key entities.
3.  **Dispatch**: A new, central `UniversalAiService` receives the structured intent from the on-device model.
4.  **Delegation**: The `UniversalAiService` acts as a router, calling the appropriate specialized service (`HealthCheckService`, `InventoryService`, etc.) to handle the execution of the command.
5.  **Execution**: The specialized service performs the necessary business logic, making a call to the appropriate Gemini API (Flash or Pro) via the `ApiRequestManager`.

---

### **3.0 UI/UX Flow**

* **Persistent Entry Point**: A floating action button or similar persistent icon will be available globally throughout the app to open the chat interface.
* **Context-Awareness**: When the chat is opened, it will automatically be aware of the user's current context. For example, if opened from a `RecipeViewScreen`, the prompt will implicitly include the data for that recipe.
* **Rich Responses**: The chat will not be limited to text. It will be able to display rich UI components as responses, such as a recipe card, a list of inventory items to confirm, or a meal plan for the week.

````
