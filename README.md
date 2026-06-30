<div align="center">

<img src="app/assets/icon/app_icon.png" width="96" alt="StudyMentor icon" />

# StudyMentor

**An adaptive learning platform that turns a child's curriculum into a personalized, gamified study path — and gives parents real oversight without becoming the bad guy.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](app/)
[![FastAPI](https://img.shields.io/badge/AI%20Engine-FastAPI-009688?logo=fastapi&logoColor=white)](ai_engine/)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=white)](app/firebase.json)
[![pgvector](https://img.shields.io/badge/Vector%20DB-pgvector-4169E1?logo=postgresql&logoColor=white)](ai_engine/docker-compose.yml)
[![Bayesian Knowledge Tracing](https://img.shields.io/badge/Mastery%20Model-BKT%20%2B%20IRT-6f42c1)](ai_engine/app/services/evaluation)

</div>

---

## What problem does this solve?

Generic study apps give every student the same worksheet. Screen-time apps just lock the phone and create a fight. StudyMentor does neither:

- It reads a student's **actual curriculum** (PDFs uploaded by a parent or teacher), turns it into searchable, skill-tagged knowledge, and generates **quizzes targeted at exactly what that student is ready to learn next** — not too easy, not too hard.
- It tracks mastery per skill with a real psychometric model (**Bayesian Knowledge Tracing + Item Response Theory**), not a hand-wavy progress bar.
- It turns screen time into a **reward for studying** instead of a punishment: kids unlock device time by completing quizzes, and parents configure the economy instead of policing it manually.
- It wraps all of that in gamification (a growing virtual garden, XP, ranks, an avatar shop, a mascot companion) that's designed to make a 9-year-old *want* to open the app.

---

## How it works, end to end

```
 Parent uploads          AI Engine ingests              Student takes an              BKT updates
 a curriculum PDF   ──►   & RAG-indexes it     ──►       adaptively generated   ──►    mastery, which
 in the Flutter app       into pgvector,                 quiz (server-chosen            reshapes the
                          extracts skills via             skill + difficulty,            next quiz and
                          regex + Gemini                  Gemini/Cohere-                 the garden's
                                                           generated questions)           growth stage
```

1. **Ingest** — A parent/teacher uploads a textbook PDF. The AI engine parses it (LlamaParse or PyMuPDF), cleans it, regex-extracts learning objectives ("mastery points") for free, chunks it (markdown/semantic/hybrid strategies), refines the objectives with an LLM, tags every chunk with the skills it teaches, and embeds it into Postgres/pgvector — scoped to that student's curriculum.
2. **Select** — When a student wants to practice, the server (never the client) decides what to ask. The `skill_selector` classifies every skill into a **frontier / review / preview** zone using the student's live BKT mastery state and picks a budget-weighted mix, so practice always sits in the student's zone of proximal development.
3. **Generate** — For each selected skill, the engine retrieves the relevant curriculum chunks via RAG and asks an LLM (Gemini, with Cohere as a strategy option) to write questions — using a **subject-specific strategy** (Math, English, Arabic, Science, Social Studies each get their own difficulty scale, formatting rules and tone) — falling back to a bank of previously generated questions if generation fails or coverage is thin.
4. **Evaluate** — Submitted answers are scored server-side and fed into the BKT engine, which adjusts guess/slip rates by difficulty and response time, flags spam/careless answering, and updates persisted per-skill mastery — which immediately reshapes the next quiz.
5. **Reward & grow** — Every completed quiz banks reward time the student can spend on their device; the mastery gains also grow their garden, push XP/rank progress, and unlock avatar shop items — all visible to parents in the analytics dashboard.

---

## Feature highlights

### 🎓 For students
| | |
|---|---|
| **Adaptive quizzes** | Difficulty and topic are computed server-side from real mastery data — never trusted from the client. |
| **Living garden** | A plant that visibly grows through 5 stages as the student masters skills — mastery made tangible. |
| **XP, ranks & avatar shop** | Coins and XP earned from quizzes buy avatar cosmetics and climb a rank ladder. |
| **Mascot companion** | An animated mascot (idle/happy/thinking/sad/celebration) reacts to quiz performance and nudges the student. |
| **Quiz-to-unlock screen time** | Restricted apps stay locked until a quiz is completed; each quiz banks a parent-configured chunk of time, with an optional cooldown once the bank runs dry. |
| **Bilingual UI** | Fully localized (Arabic + English) with the Cairo font applied app-wide. |

### 👪 For parents
| | |
|---|---|
| **Multi-student management** | Add and switch between multiple children from one parent account. |
| **Curriculum upload** | Upload textbook/worksheet PDFs that become the source of truth for that student's quizzes. |
| **Reports & analytics** | Per-subject, per-skill mastery breakdowns, weekly study charts, low-accuracy/inactivity alerts. |
| **Device & screen-time controls** | Android device-admin integration to gate Settings access and enforce the quiz-to-unlock reward model — without needing to physically take the phone away. |
| **Notifications** | Inactivity nudges, streak reminders, and parent-facing alerts when a student is struggling. |

### 🧠 The adaptive engine
- **Bayesian Knowledge Tracing** (`bkt_engine.py`) with guess/slip parameters tuned by question difficulty and response time, plus anti-gaming spam detection.
- **Item Response Theory** utilities (`irt_engine.py`) for difficulty calibration.
- **Ordered-frontier skill selection** with grade-aware frontier windows, a 60/30/10 frontier/review/preview budget split, and adaptive budget shifts based on recent accuracy.
- **Spaced repetition** scheduling for review questions (`srs_scheduler.py`).
- **RAG pipeline** with pluggable parsing (LlamaParse / PyMuPDF) and chunking (markdown / semantic / hybrid / basic) strategies.
- **Subject-aware generation strategies** so a Math quiz and an Arabic quiz don't read like the same template with swapped nouns.
- **Guardrails everywhere**: per-UID rate limiting on generation, exponential-backoff retries on LLM calls, a quiz bank fallback when live generation underperforms, and a daily scheduled data-retention purge.

---

## Architecture

```
┌─────────────────────────────┐        Firebase ID token (JWT)        ┌──────────────────────────────────┐
│         Flutter App         │ ─────────────────────────────────────►│       AI Engine (FastAPI)         │
│  (Students + Parents)       │                                       │                                    │
│                              │ ◄───────────────────────────────────  │  /api/v1/documents  /quizzes      │
│  flutter_bloc · Data Connect│              JSON over HTTPS           │  /analytics  /student  /garden    │
│  Firebase Auth/Firestore    │                                       │  /gamification  /subjects         │
└───────────────┬──────────────┘                                       └──────────────┬─────────────────────┘
                │                                                                       │
                ▼                                                                       ▼
   ┌───────────────────────┐                                          ┌───────────────────────────────────┐
   │       Firebase         │                                          │     Postgres + pgvector            │
   │ Auth · Firestore        │                                          │  curriculum chunks · skills ·      │
   │ Data Connect · Functions│                                          │  BKT mastery · quiz bank · garden  │
   │ App Check · Cloud Msg.  │                                          └───────────────────────────────────┘
   └───────────────────────┘                                                            │
                                                                                          ▼
                                                                          ┌───────────────────────────────────┐
                                                                          │   Gemini · Cohere · LlamaParse     │
                                                                          │ generation · embeddings · parsing  │
                                                                          └───────────────────────────────────┘
```

**Security model:** the AI engine treats the Firebase JWT as the only trustworthy identity signal. Clients send `student_uid` (derived from the verified token) and light preferences only — skill selection, difficulty, mastery values, and BKT hyperparameters are always computed or loaded server-side, never accepted from a request body.

---

## Tech stack

<table>
<tr><td valign="top" width="50%">

**Flutter app (`app/`)**
- Flutter / Dart, `flutter_bloc` + `equatable` for state management
- Firebase: Auth, Firestore, Data Connect, Cloud Functions, App Check, Analytics
- `workmanager` for background sync, `flutter_local_notifications` for reminders
- `flutter_svg` for the garden artwork, `google_fonts` (Cairo)
- `flutter_localizations` + ARB-based i18n (English / Arabic)
- Android device-admin APIs for parental screen-time control

</td><td valign="top" width="50%">

**AI Engine (`ai_engine/`)**
- FastAPI + Pydantic v2 + SQLAlchemy
- LangChain (`langchain-postgres`, `langchain-cohere`, `langchain-google-genai`)
- pgvector for embeddings, Cohere multilingual embeddings
- Gemini (generation) with Cohere as an alternate strategy
- LlamaParse / PyMuPDF for PDF→Markdown parsing
- `firebase-admin` for token verification, `slowapi` for rate limiting
- `apscheduler` for retention cleanup, `tenacity` for retry/backoff
- `pytest` + `httpx` for API/unit/integration/benchmark tests

</td></tr>
</table>

---

## Getting started

### AI Engine

```bash
cd ai_engine
python -m venv .venv && .venv\Scripts\activate   # Windows
pip install -r requirements.txt

# Start the pgvector Postgres instance (required before running the API)
docker-compose up -d

# Configure ai_engine/.env — API keys (Gemini, Cohere, LlamaParse),
# POSTGRES_CONNECTION, Firebase project config, guardrail thresholds

# Run the API
python -m app.main
# or
uvicorn app.main:app --reload
```

```bash
pytest tests/                                              # full suite
pytest tests/test_quiz_payload_builder.py -k test_very_low_mastery
```

### Flutter App

```bash
cd app
flutter pub get
flutter run                      # run on a connected device/emulator
flutter analyze                  # static analysis
flutter test                     # run tests
```

Firebase config is generated for project `studymentor-2026` across Android/iOS/macOS/web/Windows; the Data Connect schema lives in [`app/dataconnect/schema/schema.gql`](app/dataconnect/schema/schema.gql).

---

## Project layout

```
StudyMentor/
├── app/                  Flutter mobile app (students + parents)
│   └── lib/src/
│       ├── bloc/         auth, quiz, garden, gamification, shop, reports, ...
│       ├── data/         providers (Firebase/HTTP), repositories, static catalogs
│       ├── domain/       shared model classes
│       ├── features/     self-contained feature modules (e.g. the mascot)
│       ├── presentation/ screens (auth/parent/student) + shared widgets
│       ├── services/     device admin, notifications, overlay, quiz-lock, ...
│       └── utils/        gamification math (growth stage, rank, XP)
├── ai_engine/             FastAPI microservice (RAG + adaptive quizzing + BKT)
│   └── app/
│       ├── controllers/   documents, quizzes, analytics, student, garden, gamification, subjects
│       ├── services/      rag/, quiz/, evaluation/ (BKT + IRT)
│       ├── repositories/  all DB access (vector, skill, bkt, quiz, subject, analytics)
│       ├── models/        SQLAlchemy domain models + Pydantic schemas
│       └── core/          config, auth (Firebase token verification), rate limiting, cleanup
└── dataconnect/           Firebase Data Connect schema & generated SDK
```

---

## Project context

StudyMentor is a graduation project built at the **Faculty of Computers and Artificial Intelligence (FCAI)**, combining a production-style Flutter client with a research-grade adaptive learning backend — Bayesian Knowledge Tracing, RAG-based curriculum ingestion, and an LLM-driven quiz generation pipeline, wired into a real parent/student product experience rather than a notebook demo.
