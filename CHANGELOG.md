# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.3.0] - 2025-08-22
### Added
- **Asynchronous Job System:** Implemented a robust, app-wide system for handling all AI tasks in the background, ensuring the UI is never blocked.
- **Persistent Job History:** All background jobs and their AI-generated results are now saved to the local database, creating a persistent "hopper" and preventing data loss.
- **Universal Jobs Tray UI:** Added a global icon and a dedicated "Jobs Tray" screen to provide users with transparent feedback on the status of all background tasks.
- **Developer Mode & Job Inspector:** Implemented a hidden developer mode with a powerful "Job Inspector" for debugging API calls, prompts, and raw AI responses.
- **Dietary Profile Overhaul:** Refactored the dietary profile to use a flexible Markdown format, with a new tabbed UI for both raw text and a future visual editor.

### Changed
- **Architectural Refactor:** Performed a major refactoring to align the codebase with the principles of Separation of Concerns, moving business logic from UI controllers into dedicated services.
- **Asynchronous AI Calls:** Converted all remaining direct AI API calls (Meal Suggestions, Inventory Import, Profile Review) to use the new asynchronous job system.
- **Backend Prompt Engineering:** Significantly improved and consolidated backend prompts for better reliability and more accurate, "loyal" AI responses, especially for meal suggestions and health checks.

### Fixed
- Fixed numerous state management bugs, including lists not refreshing after saves and scroll positions jumping after edits.
- Resolved several data parsing errors by making data models more robust to handle different JSON formats from the AI and the local database.

## [0.2.2+4] - 2025-08-18
### Changed
- Updated Firebase options to pull from compile-time flags instead of .env

## [0.2.1+3] - 2025-08-18
### Added
- Location/category grouping in inventory list
- Crashlytics reporting for error tracking

## [0.2.0+2] - 2025-08-11
### Changed
- Consolidated backend with Firebase and Google Cloud Function in a new project called Recette
- Moved API keys to a .env file to limit abuse when publishing code

## [0.1.0] - 2025-08-11
### Added
- Initial release for testing.
- Recipe library with search and tagging.
- Foundational inventory system with import/export.
- On-demand nutritional analysis.
- "What can I make?" meal suggestion MVP.
- Skeleton UI for Shopping List and Meal Planner.