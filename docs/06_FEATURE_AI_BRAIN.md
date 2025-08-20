# **Feature Spec: The Modular AI "Brain"**

*This document outlines the architecture for a portable, context-aware, and persistent AI system, designed to act as a reusable "brain" for various applications, including Recette.*

### **1.0 Core Mission & Vision**

The "Brain" module is designed to function as a long-term, intelligent partner that can perceive, remember, and reason. Its core mission is to overcome the limitations of stateless LLM interactions by creating a persistent, stateful memory, enabling a deeper level of personalization and proactive assistance. The system will be **Portable**, **Transparent**, and **Modular**.

---

### **2.0 Conceptual Framework: Perceive, Remember, Reason**

The brain's architecture is modeled after a simple cognitive loop.

* **👁️ Senses: The Input & Ingestion Layer**: Responsible for perceiving the world from various sources: **Sight** (image analysis), **Language** (text), **Structured Data** (database facts), and **Triggers & Events** (proactive stimuli).
* **🧠 Memory: The Storage & Consolidation Layer**: Uses a dual-memory model.
    * **Short-Term Memory**: A temporary, chronological log of all recent sensory inputs and AI interactions.
    * **Long-Term Memory**: A durable, optimized store of important facts. A background AI process performs "memory consolidation," analyzing the short-term log to extract key information and discard noise.
* **🤔 Cognition: The Retrieval & Reasoning Layer**: The "conscious mind" of the module. Its primary function is to **assemble the perfect "context payload"** for an external LLM to use by intelligently retrieving relevant facts and memories from Long-Term Memory.

---

### **3.0 Integration with Recette**

The Brain Module will be built as a distinct feature. A central `ContextService` will be its public interface. The `ApiRequestManager` will be the primary consumer, asking the `ContextService` to build a rich context payload for its jobs instead of constructing simple prompts.