# **Feature Spec: 06 - The Modular AI "Brain"**

*This document outlines the architecture for a portable, context-aware, and persistent AI system, designed to act as a reusable "brain" for various applications, including Recette.*

### **1.0 Core Mission & Vision**

The "Brain" module is designed to function as a long-term, intelligent partner that can perceive, remember, and reason about a user's world. Its core mission is to overcome the limitations of stateless LLM interactions by creating a persistent, stateful memory, enabling a deeper level of personalization and proactive assistance.

The system must be:
* **Portable:** The entire brain—its knowledge, personality, and logic—must be self-contained in a folder structure that can be moved, copied, and backed up easily.
* **Transparent & Controllable:** The user must have full control and visibility over the AI's memory and personality, which will be stored in human-readable files.
* **Modular:** The brain will be a self-contained module that can be integrated into any application (like Recette or a future AI companion) to provide its intelligence layer.

---

### **2.0 Conceptual Framework: Perceive, Remember, Reason**

The brain's architecture is modeled after a simple cognitive loop, consisting of three core components: Senses, Memory, and Cognition.

#### **2.1 👁️ Senses: The Input & Ingestion Layer**

This layer is responsible for perceiving the world and is designed to be agnostic to the input source. It can consume a wide variety of data types:

* **Sight:** Image analysis via OCR or object recognition (e.g., scanning groceries or a recipe page).
* **Language:** Unstructured text from user chats, documents, or web pages.
* **Structured Data:** Concrete facts from the application's own database, such as the inventory list, dietary profiles, or saved recipes.
* **Triggers & Events (The "Nervous System"):** Proactive stimuli from the operating system, such as a specific time of day, a change in location, or other device events.

#### **2.2 🧠 Memory: The Storage & Consolidation Layer**

This is the heart of the system's persistence. It uses a dual-memory model to balance fidelity with efficiency.

* **Short-Term Memory (The "Working Log"):**
    * **Function:** A temporary, chronological log of all recent sensory inputs and AI interactions. It is high-fidelity but noisy and inefficient for long-term retrieval.
    * **Implementation:** Could be a rotating log file or a temporary table in the local database.

* **Long-Term Memory (The "Structured Knowledge Base"):**
    * **Function:** A durable, optimized store of important, salient facts. This is where "memory consolidation" occurs. A background AI process analyzes the short-term log, extracts key information, and discards the noise.
    * **Implementation:** A hybrid system combining:
        1.  A **Vector Database** (e.g., ChromaDB) for fast, semantic searching of unstructured memories (like notes or conversation summaries).
        2.  A **Structured Database** (SQLite/Firestore) for concrete facts (e.g., "user dislikes cilantro").

#### **2.3 🤔 Cognition: The Retrieval & Reasoning Layer**

This is the "conscious mind" of the brain module. Its primary function is not to generate the final answer, but to **assemble the perfect "context payload"** for an external LLM to use.

* **Workflow:**
    1.  **Trigger:** A request is initiated by a user or a proactive event.
    2.  **Intelligent Retrieval:** The Cognition layer queries the **Long-Term Memory**. It uses vector search to find relevant memories and structured queries to pull concrete facts.
    3.  **Context Assembly:** It combines the retrieved memories, the immediate sensory input (e.g., the user's typed question), and the AI's defined **Persona** into a single, comprehensive "Grand Unified Prompt."
    4.  **Output:** The final output of the Brain Module is this rich context payload, ready to be sent to a powerful LLM (like Gemini Pro) for the final synthesis into a human-readable response.

---

### **3.0 Concrete Implementation: The Portable Folder Structure**

The entire brain will be contained within a single, syncable folder, making it fully portable and transparent.

`_BRAIN_CORE/`
|
|--- `👤_PERSONA.MD` *(A human-readable file defining the AI's name, personality, and core directives)*
|
|--- `⚡️_TRIGGERS/` *(A folder containing user-configurable files for proactive events)*
|    |--- `01_morning_check_in.md`
|
|--- `vector_db/` *(The folder for the local ChromaDB vector store)*
|
|--- `short_term_memory.log` *(The raw, rotating log of recent events)*

This core is then paired with the application's primary data (like Recette's `recipes.db` or an Obsidian vault for notes) to form the complete knowledge base.

### **4.0 Integration with Recette**

The Brain Module will be built as a distinct feature in `lib/features/brain/`.

* A central `ContextService` will be the public interface for the module.
* The `ApiRequestManager`, which we designed to handle all API calls, will be the primary consumer. Instead of constructing simple prompts, it will now ask the `ContextService` to build a rich context payload for its jobs.
* This architecture allows Recette to leverage the full power of the brain for its kitchen assistant tasks, while keeping the brain itself as a separate, reusable component for future projects.