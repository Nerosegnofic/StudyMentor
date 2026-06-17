# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

StudyMentor is an adaptive learning platform with two main components:

- **`app/`** — Flutter mobile app (students + parents). Uses Firebase (Auth, Firestore, Data Connect, Cloud Functions, App Check) as its primary backend.
- **`ai_engine/`** — Python FastAPI microservice providing RAG-based curriculum ingestion, adaptive quiz generation, and BKT (Bayesian Knowledge Tracing) mastery tracking. Talks to a separate Postgres + pgvector database, and to Firebase Admin SDK for auth verification.
- **`DevDocs/`** — Architecture notes, ERDs, and design docs. Many of these are outdated/aspirational — do not rely on them; verify against the actual code instead.

## AI Engine (`ai_engine/`)

### Setup & Running

```bash
cd ai_engine
python -m venv .venv && .venv\Scripts\activate   # Windows
pip install -r requirements.txt

# Start the pgvector Postgres instance (required before running the API)
docker-compose up -d

# Run the API (reads config from ai_engine/.env)
python -m app.main
# or
uvicorn app.main:app --reload
```

Configuration is centralized in [ai_engine/app/core/config.py](ai_engine/app/core/config.py) (`Settings`, loaded from `ai_engine/.env`). Key settings include API keys (Gemini, Cohere, LlamaParse), `POSTGRES_CONNECTION`, Firebase project config, and tunable guardrails (`RETRIEVAL_SCORE_THRESHOLD`, `QUIZ_BANK_MIN_COVERAGE`, rate limits, BKT spam-detection thresholds).

### Tests

```bash
cd ai_engine
pytest tests/
pytest tests/test_quiz_payload_builder.py -k test_very_low_mastery
```

Note: `tests/test_quiz_payload_builder.py` imports `app.services.quiz.priority_engine` and `app.services.quiz.allocator`, which do not currently exist under `app/services/quiz/` — that test module is stale relative to the current skill-selection implementation ([skill_selector.py](ai_engine/app/services/quiz/skill_selector.py), [builder.py](ai_engine/app/services/quiz/builder.py)). Check before assuming it passes.

### Architecture

**Request flow (FastAPI app: [app/main.py](ai_engine/app/main.py))**

- Routers are registered under `/api/v1`: `routes_documents`, `routes_quizzes`, `routes_analytics`, `routes_student` (in [app/controllers/](ai_engine/app/controllers/)).
- Auth: every protected route depends on `get_current_user` ([app/core/auth.py](ai_engine/app/core/auth.py)), which verifies a Firebase ID token (`Authorization: Bearer <JWT>`) via the Firebase Admin SDK and returns the `firebase_uid`/`student_uid`. There is no separate app-level user table for the AI engine — Firebase UID is the identity key.
- A global exception handler returns generic 500s (no internal details leaked). `/health` does a deep check of DB + vector store connectivity.
- A daily cleanup scheduler (APScheduler, [app/core/cleanup.py](ai_engine/app/core/cleanup.py)) runs for data retention, started/stopped in the FastAPI lifespan.
- Rate limiting via `slowapi` ([app/core/rate_limit.py](ai_engine/app/core/rate_limit.py)), applied per-UID to the quiz generation endpoint.

**RAG ingestion pipeline** ([app/services/rag/ingestion.py](ai_engine/app/services/rag/ingestion.py) — `process_and_ingest_document`, run as a FastAPI background task from `POST /documents/upload`):

1. Parse PDF → Markdown via a pluggable parser strategy (`ParserContext` + `LlamaParseStrategy`/`PyMuPDFStrategy` in [app/services/rag/parsers/](ai_engine/app/services/rag/parsers/)).
2. Preprocess/clean text ([preprocessors.py](ai_engine/app/services/rag/preprocessors.py)).
3. Extract "mastery points" (learning objectives) via regex — zero LLM cost ([processors/objective_extractor.py](ai_engine/app/services/rag/processors/objective_extractor.py)).
4. Chunk text via a pluggable chunker strategy (`ChunkerContext` + Markdown/Semantic/Hybrid/Basic strategies in [app/services/rag/chunkers/](ai_engine/app/services/rag/chunkers/)).
5. Refine raw mastery points via Gemini LLM ([processors/mastery_refiner.py](ai_engine/app/services/rag/processors/mastery_refiner.py)).
6. Tag each chunk's metadata with `skill_names` derived from the lesson → skills mapping, for precision retrieval.
7. Store chunk embeddings in pgvector (`save_chunks_to_pgvector`, [app/repositories/vector_repo.py](ai_engine/app/repositories/vector_repo.py)), tagged with `firebase_uid` and `subject_id` for ownership scoping.
8. Persist extracted skills to the relational DB (`save_skills_from_mastery_data`).

The pipeline writes intermediate debug artifacts to `ai_engine/debug_output/<document_id>_*` (parsed markdown, raw/refined skills JSON, chunks JSON) — useful for debugging ingestion issues.

**Adaptive quiz generation** ([app/services/quiz/](ai_engine/app/services/quiz/)):

- `quiz_generation_service.py` orchestrates: build a per-skill quiz payload server-side (skill, target difficulty, question count), retrieve relevant curriculum chunks via RAG ([rag/retrieval.py](ai_engine/app/services/rag/retrieval.py)), then generate questions via an LLM strategy (`GenerationContext` + Gemini/Cohere strategies in [app/services/rag/generation/](ai_engine/app/services/rag/generation/)).
- `skill_selector.py` + `builder.py`: select skills using "Ordered Frontier" zone classification (frontier/review/preview) based on BKT mastery state, then `build_quiz_payload()` produces `{skill, difficulty, count, zone, mastery}` entries — **difficulty and topic selection are always server-computed from stored mastery state, never accepted from the client** (see Security Model below).
- `difficulty_mapper.py`: maps a mastery probability to a 1–5 ZPD (zone of proximal development) difficulty level.
- `quiz_bank_service.py`: fallback to a bank of previously-generated questions when live LLM generation fails or coverage is insufficient (governed by `QUIZ_BANK_MIN_COVERAGE` / `QUIZ_BANK_MIN_AGE_DAYS`).
- `srs_scheduler.py`: spaced-repetition scheduling for review questions.
- **Subject strategies** ([app/services/quiz/strategies/](ai_engine/app/services/quiz/strategies/)): per-subject prompt customization (difficulty scales, formatting rules, pedagogical tone, question format pools) for Math/English/Arabic/Science/Social Studies/General. `strategy_resolver.py` maps a free-text subject name (Arabic or English) to the right strategy via keyword matching, falling back to `GeneralStrategy` for unknown subjects — to support a new subject, add a strategy class and register its keywords in `_KEYWORD_MAP`.

**BKT / Evaluation** ([app/services/evaluation/](ai_engine/app/services/evaluation/)):

- `bkt_engine.py`: Bayesian Knowledge Tracing — `update_mastery()` adjusts guess/slip rates based on question difficulty and response time, then performs the Bayesian mastery update. Includes anti-spam detection (answers faster than `MINIMUM_GENUINE_TIME_MS` are flagged; `SPAM_THRESHOLD` consecutive spam answers trigger a punishment).
- `irt_engine.py`: Item Response Theory utilities.
- `analytics_service.py`: aggregates student performance for the analytics endpoints.
- `quiz_submission_service.py` ([app/services/quiz/](ai_engine/app/services/quiz/)) processes `POST /quizzes/submit`: scores answers and feeds each into the BKT engine to update persisted mastery state.

**Data layer**:

- SQLAlchemy ORM models in [app/models/domain/](ai_engine/app/models/domain/) (`Base.metadata.create_all` runs on startup — no migration framework currently).
- Repositories in [app/repositories/](ai_engine/app/repositories/) encapsulate all DB access (`vector_repo`, `skill_repo`, `bkt_repo`, `quiz_repo`, `subject_repo`, `analytics_repo`).
- Pydantic request/response schemas in [app/models/schemas/](ai_engine/app/models/schemas/).
- Vector store: pgvector via `langchain-postgres`, collection name `math_curriculum`, embeddings via Cohere (`RateLimitedCohereEmbeddings`, [app/core/embeddings.py](ai_engine/app/core/embeddings.py)).

### Security model (important when touching quiz/analytics endpoints)

The server is the source of truth for all adaptive-learning state — see [DevDocs/architecture_analysis.md](DevDocs/architecture_analysis.md) for the full rationale (note: some of that doc describes target/proposed schemas, not all of which may be implemented yet — check `app/models/domain/` and `app/repositories/` for current state). Key invariants to preserve:

- Clients send only identity (`student_uid`, derived from the Firebase JWT — never trust a client-supplied UID for authorization) and lightweight preferences (e.g. `total_questions`).
- Skill selection, difficulty, mastery values, and BKT hyperparameters are computed/loaded server-side — never accept these directly from request bodies for grading or quiz composition.
- Where question correctness/difficulty must be verified, look it up server-side rather than trusting client echoes.

## Flutter App (`app/`)

### Setup & Running

```bash
cd app
flutter pub get
flutter run                      # run on connected device/emulator
flutter analyze                  # static analysis (flutter_lints)
flutter test                     # run all tests
flutter test test/widget_test.dart
```

Firebase config is generated (`lib/firebase_options.dart`, `firebase.json`) for project `studymentor-2026` across Android/iOS/macOS/web/Windows. Data Connect schema lives in [app/dataconnect/schema/schema.gql](app/dataconnect/schema/schema.gql).

### Architecture

Standard `lib/src/` layered structure using **flutter_bloc**:

- **`bloc/`** — one Bloc (event/state/bloc triplet) per feature domain: `auth`, `document` (upload), `garden`, `quiz`, `shop`.
- **`data/`**
  - `providers/` — thin wrappers over external SDKs: `FirebaseAuthProvider`, `DataConnectProvider` (Firebase Data Connect / Postgres-backed GraphQL), `CloudFunctionProvider`.
  - `repositories/` — `AuthRepositoryImpl` (implements `domain/repositories/auth_repository.dart`), `AiEngineRepository` (HTTP client for the `ai_engine` FastAPI service — attaches the Firebase ID token as a Bearer header).
  - `catalog/` — static data tables (subjects, avatar/shop items, document type models).
- **`domain/models/`** — plain Dart model classes (`StudentModel`, `UserModel`, `SkillProgressModel`, `SubjectProgressModel`, `AvatarConfig`, etc.) shared across blocs/UI.
- **`presentation/screens/`** — split by role: `auth/`, `parent/`, `student/`. `presentation/widgets/` holds shared widgets (avatar, plant/garden visuals, navigation bars, cards).
- **`services/`** — platform/device integration: `device_admin_service.dart` (Android device admin / parental controls), `installed_apps_service.dart` (app inventory, synced via WorkManager background task), `permission_service.dart`, `mastery_service.dart`, `settings_service.dart`, `support_ticket_service.dart`, plus `services/overlay/` for an on-screen mascot overlay.
- **`utils/`** — gamification helpers: `growth_stage_utils`, `student_rank_utils`, `subject_xp_engine`.

### App startup & auth flow ([lib/main.dart](app/lib/main.dart))

- Initializes Firebase, then registers a periodic WorkManager background task (`installedAppSync`, every 15 min) that syncs the device's installed-app inventory to Data Connect — this requires its own Firebase init in the background isolate (`callbackDispatcher`).
- `AuthBloc` drives top-level navigation via `RootPage`: `AuthUnauthenticated` → `LoginScreen`, `AuthEmailUnverified` → `ConfirmEmailScreen`, `AuthAuthenticated` → `ParentScreen` or `StudentScreen` based on `user.role`.
- **Parental control / device admin**: `DeviceAdminService` guards access to system Settings on the student's device. Student mode (`isStudentLoggedIn`) is only activated by `PermissionGateScreen` once *all* required permissions are granted — activating it earlier would lock the student out of Settings before they can grant remaining permissions. When a parent logs in or any user logs out, `DeviceAdminService.onStudentLogout()` disables the guard. Be careful preserving this ordering when touching auth/permission flows.

### Generated files

`lib/firebase_options.dart`, `lib/dataconnect_generated/`, and the `linux/`, `macos/`, `windows/` Flutter plugin registrant files are auto-generated by `flutterfire`/`flutter pub get`/Data Connect codegen — avoid hand-editing; regenerate via the relevant CLI instead.
