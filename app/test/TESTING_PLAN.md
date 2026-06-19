# Flutter Frontend Testing — Implementation Plan

## Overview

This plan covers unit and integration testing for the Flutter app (`app/`).
Scope: Blocs, domain models, utility functions, widgets/screens, repositories, and full user-journey integration tests.

---

## Setup Checklist

Add to `pubspec.yaml` under `dev_dependencies` if not already present:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  network_image_mock: ^2.1.1
```

Run:

```bash
cd app
flutter pub get
```

---

## Phase 1 — Bloc Unit Tests

> **Goal:** Test every Bloc in isolation using fakes for repositories. No Firebase, no HTTP.
>
> **Tools:** `bloc_test`, `mocktail`
>
> **Reference pattern:** `test/gamification_bloc_test.dart`

### Files to create

| Test File | Bloc Under Test |
|---|---|
| `test/bloc/auth_bloc_test.dart` | `AuthBloc` |
| `test/bloc/quiz_bloc_test.dart` | `QuizBloc` |
| `test/bloc/shop_bloc_test.dart` | `ShopBloc` |
| `test/bloc/garden_bloc_test.dart` | `GardenBloc` |
| `test/bloc/student_profile_bloc_test.dart` | `StudentProfileBloc` |
| `test/bloc/parent_profile_bloc_test.dart` | `ParentProfileBloc` |
| `test/bloc/subject_detail_bloc_test.dart` | `SubjectDetailBloc` |
| `test/bloc/gamification_bloc_test.dart` | `GamificationBloc` (extend existing) |

### Scenarios per Bloc

#### `AuthBloc`
- [ ] Login success → emits `AuthAuthenticated` with correct role (parent vs student)
- [ ] Login failure (wrong password) → emits `AuthError`
- [ ] Email unverified → emits `AuthEmailUnverified`
- [ ] Logout → emits `AuthUnauthenticated`
- [ ] Token refresh on app resume

#### `QuizBloc`
- [ ] Start quiz → emits `QuizLoaded` with questions
- [ ] Answer question → emits `QuizAnswerRecorded`
- [ ] Timer expiry → auto-advances to next question
- [ ] Submit quiz → emits `QuizSubmitted` with score
- [ ] AI engine unreachable → emits `QuizError`

#### `ShopBloc`
- [ ] Load items → emits `ShopLoaded` with catalog
- [ ] Purchase success → emits `ShopPurchaseSuccess`, coins deducted
- [ ] Purchase with insufficient coins → emits `ShopInsufficientCoins`
- [ ] Purchase failure (network) → emits `ShopError`

#### `GardenBloc`
- [ ] Load plants → emits `GardenLoaded`
- [ ] Plant at correct growth stage per XP
- [ ] All plants wilted state

#### `StudentProfileBloc`
- [ ] Load profile → emits `StudentProfileLoaded`
- [ ] Avatar update → emits `StudentProfileUpdated`
- [ ] XP change reflects new level

#### `ParentProfileBloc`
- [ ] Load profile → emits `ParentProfileLoaded`
- [ ] Update preferences → emits `ParentProfileUpdated`

#### `SubjectDetailBloc`
- [ ] Load subject → emits `SubjectDetailLoaded` with skills list
- [ ] Skill mastery percentage correct

#### `GamificationBloc` (extend existing)
- [ ] Level-up trigger fires at correct XP threshold
- [ ] Streak milestone modal triggers at day 3, 7, 30
- [ ] Double reward claim is blocked

---

## Phase 2 — Domain Model & Utility Unit Tests

> **Goal:** Pure Dart tests, zero dependencies. Fast to write, great for catching regressions.

### Files to create

| Test File | Target |
|---|---|
| `test/models/student_model_test.dart` | `StudentModel` |
| `test/models/user_model_test.dart` | `UserModel` |
| `test/models/skill_progress_model_test.dart` | `SkillProgressModel` |
| `test/utils/growth_stage_utils_test.dart` | `growth_stage_utils.dart` |
| `test/utils/student_rank_utils_test.dart` | `student_rank_utils.dart` |
| `test/utils/subject_xp_engine_test.dart` | `subject_xp_engine.dart` |
| `test/catalog/subject_metadata_registry_test.dart` | `SubjectMetadataRegistry` (extend existing) |

### Scenarios

#### Models (`fromMap` / `toMap` roundtrip)
- [ ] All required fields parse correctly
- [ ] Optional/nullable fields default to null without throwing
- [ ] `toMap` output roundtrips back through `fromMap` identically

#### `growth_stage_utils`
- [ ] 0 XP → seedling stage
- [ ] Mid-range XP → correct intermediate stage
- [ ] Max XP → final stage
- [ ] Boundary values (exact threshold) → correct stage

#### `student_rank_utils`
- [ ] 0 XP → lowest rank
- [ ] Max XP → highest rank
- [ ] Each rank boundary returns the correct rank label
- [ ] Rank icon/asset key is non-null for every rank

#### `subject_xp_engine`
- [ ] Correct answer at difficulty 1 → baseline XP
- [ ] Correct answer at difficulty 5 → higher XP
- [ ] Wrong answer → 0 XP (or penalty if applicable)
- [ ] Streak bonus applied after consecutive correct answers

---

## Phase 3 — Widget Tests for Key Screens

> **Goal:** Render screens with stubbed Bloc states, assert correct UI output.
>
> **Tools:** `WidgetTester`, `MockBloc` (mocktail), `network_image_mock`
>
> **Reference pattern:** `test/student_config_screen_test.dart`

### Files to create

| Test File | Screen / Widget |
|---|---|
| `test/screens/login_screen_test.dart` | `LoginScreen` |
| `test/screens/forgot_password_screen_test.dart` | `ForgotPasswordScreen` |
| `test/screens/student_home_test.dart` | `StudentHome` |
| `test/screens/student_quiz_test.dart` | `StudentQuiz` |
| `test/screens/subject_detail_screen_test.dart` | `SubjectDetailScreen` |
| `test/screens/parent_home_dashboard_test.dart` | `ParentHomeDashboard` |
| `test/screens/student_config_screen_test.dart` | `StudentConfigScreen` (extend existing) |
| `test/widgets/avatar_widget_test.dart` | `AvatarWidget` |
| `test/widgets/plant_widget_test.dart` | `PlantWidget` |
| `test/widgets/level_up_modal_test.dart` | `LevelUpModal` |
| `test/widgets/streak_milestone_modal_test.dart` | `StreakMilestoneModal` |

### Scenarios per screen

#### `LoginScreen`
- [ ] Empty form submit → validation errors shown
- [ ] Invalid email format → field error shown
- [ ] Loading state → button shows spinner, inputs disabled
- [ ] Auth error → error banner appears
- [ ] Forgot password link → navigates to `ForgotPasswordScreen`

#### `ForgotPasswordScreen`
- [ ] Empty email → validation error
- [ ] Valid email submit → success message shown
- [ ] Error state → error message shown

#### `StudentHome`
- [ ] XP bar fills to correct percentage
- [ ] Level badge shows correct number
- [ ] Mascot visible when enabled
- [ ] Subject cards render with correct subject names

#### `StudentQuiz`
- [ ] Question text rendered
- [ ] All answer options rendered
- [ ] Selecting an option highlights it
- [ ] Submit button disabled until option selected
- [ ] Submit button enabled after selection

#### `SubjectDetailScreen`
- [ ] Skills list renders all skills
- [ ] Mastery progress bar fills correctly
- [ ] Locked skills shown as disabled

#### `ParentHomeDashboard`
- [ ] Student cards render with name and avatar
- [ ] Tapping student card navigates to correct screen
- [ ] Empty students state → add student prompt shown

#### Standalone Widgets
- [ ] `AvatarWidget` — renders all equipped item layers in correct z-order
- [ ] `PlantWidget` — correct asset displayed per growth stage enum
- [ ] `LevelUpModal` — shows new level number, dismiss closes modal
- [ ] `StreakMilestoneModal` — shows streak count, dismiss closes modal

---

## Phase 4 — Repository Unit Tests

> **Goal:** Test the data layer contracts without hitting Firebase or the AI engine.
>
> **Tools:** `mocktail` to mock `FirebaseAuthProvider`, `http.Client`, Firestore

### Files to create

| Test File | Repository |
|---|---|
| `test/repositories/auth_repository_test.dart` | `AuthRepositoryImpl` |
| `test/repositories/ai_engine_repository_test.dart` | `AiEngineRepository` |
| `test/repositories/gamification_repository_test.dart` | `GamificationRepositoryImpl` |

### Scenarios

#### `AuthRepositoryImpl`
- [ ] `getAppConfigForStudent` parses Firestore document correctly
- [ ] `getAppConfigForStudent` throws on missing document
- [ ] `getInstalledAppsForStudent` returns empty list when none stored

#### `AiEngineRepository`
- [ ] Quiz generation happy path → returns parsed `QuizAttemptModel`
- [ ] 401 response → throws `UnauthenticatedException` (token refresh needed)
- [ ] 503 response → throws `AiEngineUnavailableException`
- [ ] Malformed JSON response → throws parse exception

#### `GamificationRepositoryImpl`
- [ ] `claimReward` writes correct fields to Firestore
- [ ] Double-claim guard → second call within guard window is rejected
- [ ] XP update persists and is readable back

---

## Phase 5 — Integration Tests (Golden Path Flows)

> **Goal:** Full user journeys on a real emulator with mocked Firebase/HTTP at the boundary.
>
> **Location:** `integration_test/`
>
> **Run with:** `flutter test integration_test/`

### Files to create

| Test File | Flow |
|---|---|
| `integration_test/auth_flow_test.dart` | Login → land on home |
| `integration_test/quiz_flow_test.dart` | Subject → start quiz → results |
| `integration_test/document_flow_test.dart` | Parent uploads doc → subject appears |
| `integration_test/shop_flow_test.dart` | Open shop → buy item → avatar updates |

### Scenarios

#### Auth Flow
- [ ] App launches to login screen when unauthenticated
- [ ] Enter valid credentials → submit → lands on correct role screen
- [ ] Enter wrong password → error banner shown, stays on login

#### Quiz Flow
- [ ] Student home → tap subject → subject detail loads
- [ ] Tap "Start Quiz" → quiz screen loads with questions
- [ ] Answer all questions → results screen shows score and XP gained
- [ ] XP on home screen updated after returning

#### Document Flow
- [ ] Parent logs in → navigates to subject management
- [ ] Selects upload → processing banner appears
- [ ] After processing → subject card appears in student's view

#### Shop Flow
- [ ] Student opens shop → items listed with coin costs
- [ ] Tap item with sufficient coins → confirm dialog → purchase succeeds
- [ ] Avatar preview updates to show purchased item
- [ ] Coin balance on header is decremented

---

## Execution Order

```
Phase 1 (Blocs)
    └── Phase 2 (Models/Utils)   ← can run in parallel with Phase 1
            └── Phase 3 (Widgets)   ← reuses Bloc fakes from Phase 1
                    └── Phase 4 (Repositories)
                            └── Phase 5 (Integration)   ← requires stable widget + bloc layers
```

## Running the tests

```bash
# Unit + widget tests
cd app
flutter test

# Specific phase
flutter test test/bloc/
flutter test test/models/
flutter test test/screens/
flutter test test/repositories/

# Integration tests (requires running emulator)
flutter test integration_test/

# With coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Coverage Targets

| Layer | Target |
|---|---|
| Blocs | 90%+ |
| Domain models & utils | 95%+ |
| Screens & widgets | 70%+ |
| Repositories | 80%+ |
| Integration flows | 4 golden paths covered |
