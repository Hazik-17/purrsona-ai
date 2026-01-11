# AGENTS.md - Purrsona AI Development Context

> **SYSTEM ROLE:** Senior Flutter Engineer & AI Integration Specialist
> **MODE:** Engineering & Stabilization (Phase: 95% Complete)

---

## 1. Project Overview
**Purrsona AI** is an offline-first mobile application for cat breed classification utilizing a custom **Hierarchical Deep Learning Pipeline**. The app is built with **Flutter (Dart)** following a strict **MVC (Model-View-Controller)** architecture.

### The AI Engine (EfficientNetV2B0)
The core logic relies on a sequential 3-stage inference pipeline running locally via `tflite_flutter`:
1.  **Gatekeeper:** Binary classifier (Cat vs. Not-Cat).
2.  **Generalist:** Classifies 12 primary breed classes.
3.  **Expert:** Conditional activation. Resolves specific high-ambiguity cases (e.g., distinguishing *Ragdoll* from *Birman*).

---

## 2. Key File Mapping
**CRITICAL NOTE:** Ignore the `components/ui` folder containing `.tsx` files. These are artifacts. Focus **ONLY** on `.dart` files.

### 🧠 Logic & Services (The "Controllers")
* **AI Engine (TFLite):** `lib/services/ml_model_service.dart`
  * *Handles interpreter loading, image preprocessing, and the hierarchical inference flow.*
* **Database (SQLite):** `lib/services/database_helper.dart`
  * *Manages offline storage for scan history and logs.*
* **Data Fetching:** `lib/services/json_data_service.dart`
  * *Handles local JSON assets for the Breed Codex and Quiz.*

### 📂 Asset Mapping (Models & Data)
* **TFLite Models:** `assets/models/`
  * `gatekeeper_model.tflite`
  * `generalist_breed_model.tflite`
  * `similar_breed_expert_model.tflite`
* **JSON Data:** `assets/data/`
  * `breed_data.json` (Codex content)
  * `quiz_questions.json` (Personality test)
* **Breed Images:** `assets/images/` (Used for Codex thumbnails)

### 📂 Data Models
* **Prediction Model:** `lib/models/prediction.dart`
* **Personality Data:** `lib/models/personality_data.dart`
* **Vet/Map Data:** `lib/models/vet_clinic.dart`

### 🎨 UI & Screens
* **Main Entry/Home:** `lib/screens/welcome_screen.dart`
* **Result Display:** `lib/screens/prediction_result_screen.dart` & `lib/screens/analysis_result_screen.dart`
* **Map/Services:** `lib/screens/nearby_services_screen.dart`
* **History/Archives:** `lib/screens/history_screen.dart` & `lib/screens/archives_screen.dart`
* **Codex/Info:** `lib/screens/codex_screen.dart` & `lib/screens/breed_info_screen.dart`

### 🧩 Reusable Widgets
* **Share Card:** `lib/widgets/cat_share_card.dart`
* **Charts:** `lib/widgets/history_chart_widget.dart`

---

## 3. Senior Engineering Rules (The "No-Vibe" Protocol)

### A. Architectural Guardrails
* **State Management:** Respect existing patterns found in `screens/` and `services/`. Do not introduce Riverpod/Bloc unless already present.
* **Isolates:** Any heavy image manipulation (resizing to 224x224, normalization) **MUST** run in a separate Isolate to prevent UI jank.
* **TSX Ignore:** Do not reference or attempt to import from `components/ui/*.tsx`.

### B. Type Safety & Production Standards
* **Strict Typing:** Never use `dynamic`. Define explicit types for all Futures (e.g., `Future<List<Prediction>>`).
* **Const Correctness:** Apply `const` to all immutable widgets in `screens/` and `widgets/`.
* **Error Handling:** All calls in `ml_model_service.dart` and `database_helper.dart` must have `try-catch` blocks.

### C. Impact Analysis
* **Rule:** Before suggesting code, verify dependencies.
  * *Example: "Modifying `prediction.dart` will require updates to `ml_model_service.dart` and `prediction_result_screen.dart`."*

### D. The "Plan-First" Protocol
- **Strict Rule:** Before the Agent modifies ANY file, it must present a "Logical Plan" in bullet points.
- **Wait for Approval:** Do not apply changes until I explicitly say "Proceed with the plan."
- **Diff Review:** Always explain the "Why" behind a change during the Review phase.

---

## 4. Security & Privacy Protocol

### A. Secrets Management
* **Zero-Trust for Keys:** Never hardcode API keys (especially Google Maps Keys) in Dart files or `AndroidManifest.xml`.
* **Enforcement:** Use `local.properties` or Build Config fields for injection. If a hardcoded key is found in `lib/screens/nearby_services_screen.dart`, flag it immediately.

### B. Data Safety (SQL Injection)
* **Parameterized Queries:** In `lib/services/database_helper.dart`, strictly forbid string interpolation in SQL queries (e.g., `WHERE name = '$name'`).
* **Mandate:** Always use the `whereArgs` property for user-supplied input to let the `sqflite` engine handle escaping.

### C. Principle of Least Privilege
* **Permission Review:** Analyze `android/app/src/main/AndroidManifest.xml`.
* **Rule:** Flag any permission that exceeds the app's core function (e.g., requesting `ACCESS_BACKGROUND_LOCATION` when `ACCESS_FINE_LOCATION` is sufficient for a "While In Use" map).

---

## 5. Stabilization Checklist (Final 5%)

### 🧹 Resource Management
- [ ] **TFLite Disposal:** Verify `interpreter.close()` is called in `ml_model_service.dart` `dispose()`.
- [ ] **DB Connections:** Ensure `database_helper.dart` manages connections efficiently (singleton pattern recommended).
- [ ] **Asset Loading:** Verify `pubspec.yaml` correctly declares `assets/models/` and `assets/data/`.

### 🛡️ Security Audit
- [ ] **API Key Check:** Ensure no secrets are visible in `nearby_services_screen.dart`.
- [ ] **SQL Audit:** Verify all `rawQuery` or `query` calls in `database_helper.dart` use arguments/binds.
- [ ] **Manifest Clean:** Remove unused permissions from `AndroidManifest.xml`.

### 💾 Offline Capability
- [ ] **Map Fallback:** Check `nearby_services_screen.dart` for internet connectivity checks. If offline, hide Google Maps and show a "Retry" or "List View" widget.

### 🐞 Known Risks
-   **Mixed File Types:** Be aware that `utils.ts` and `.tsx` files are present but irrelevant to the Flutter build. Do not let them distract logic generation.