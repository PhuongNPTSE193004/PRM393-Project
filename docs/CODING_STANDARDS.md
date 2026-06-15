# Airsoft Shop — Coding Standards

This document defines the coding standards for the **airsoft_shop** Flutter project.
The project follows a **layered architecture**: UI → Services → Repositories → Firebase (BaaS).

All contributors should follow these rules when adding or changing code.

---

## 1. Architecture Overview

### Layers

```
┌─────────────────────────────────────────┐
│  Presentation Layer                     │
│  screens/, widgets/, navigation/, theme │
├─────────────────────────────────────────┤
│  Application / Service Layer            │
│  services/                              │
├─────────────────────────────────────────┤
│  Repository Layer                       │
│  repositories/ (interfaces)             │
│  repositories/firebase/ (implementations)│
├─────────────────────────────────────────┤
│  Domain Helpers                         │
│  models/, utils/                        │
├─────────────────────────────────────────┤
│  External (Framework / BaaS)            │
│  Firebase Auth, Cloud Firestore         │
└─────────────────────────────────────────┘
```

### Dependency Rule

**Dependencies must only flow downward.**

| Layer            | May depend on                         | Must NOT depend on              |
|------------------|---------------------------------------|---------------------------------|
| `screens/`       | `services/`, `models/`, `utils/`, `theme/`, `navigation/`, `widgets/` | Firebase SDK, repositories directly |
| `widgets/`       | `models/`, `theme/`                   | `services/`, Firebase, repositories |
| `navigation/`    | `screens/`, `models/`                 | `services/`, Firebase, repositories |
| `services/`      | `repositories/`, `models/`, `utils/`  | `screens/`, `widgets/`, Firebase SDK |
| `repositories/` (interface) | `models/` only              | Firebase SDK, Flutter, services |
| `repositories/firebase/` | Firebase SDK, repository interfaces | `screens/`, `services/`         |
| `models/`        | Dart SDK only                         | Flutter, Firebase, services     |
| `utils/`         | Dart SDK only                         | Flutter, Firebase, services     |
| `theme/`         | Flutter SDK only                      | `services/`, Firebase           |

---

## 2. Folder Structure

```
lib/
├── main.dart                 # App entry, Firebase init, root MaterialApp
├── firebase_options.dart     # Generated Firebase config (do not edit manually)
│
├── models/                   # Plain data types, enums, exceptions
├── utils/                    # Pure helper functions (validators, formatters)
├── repositories/             # Abstract data access interfaces
│   └── firebase/             # Firebase implementations of repositories
├── services/                 # Business logic (uses repositories)
├── navigation/               # Route helpers and role-based navigation
├── theme/                    # Colors, typography, ThemeData
├── widgets/                  # Reusable UI components
└── screens/                  # Full-page views, grouped by feature/role
    ├── auth/
    ├── admin/
    ├── customer/
    └── staff/
```

### Placement Rules

- **New screen** → `lib/screens/<feature>/`
- **Reusable UI** (used in 2+ places) → `lib/widgets/`
- **Firebase or auth logic** → `lib/repositories/firebase/` (data access) + `lib/services/` (business rules)
- **Data shape / enum** → `lib/models/`
- **Input validation** → `lib/utils/`
- **Colors and styling** → `lib/theme/`

Do not create new top-level folders without team agreement.

---

## 3. Layer Responsibilities

### Presentation (`screens/`, `widgets/`)

**Responsible for:**
- Rendering UI
- Handling user input
- Local UI state (`isLoading`, `activeTab`, form controllers)
- Calling service methods
- Displaying errors returned by services

**Must NOT:**
- Call `FirebaseAuth.instance` or `FirebaseFirestore.instance` directly
- Import repository implementations (`repositories/firebase/`)
- Contain business rules (role checks, password policy, etc.)
- Map raw Firebase exceptions to user messages

```dart
// Good — screen delegates to service
final role = await authService.login(
  identifier: identifierController.text,
  password: passwordController.text,
);

// Bad — Firebase in UI
await FirebaseAuth.instance.signInWithEmailAndPassword(...);

// Bad — repository in UI
await FirebaseAuthRepository().signInWithEmailAndPassword(...);
```

### Service (`services/`)

**Responsible for:**
- Business logic and orchestration
- Validation before calling repositories
- Throwing domain-friendly errors (`AuthException`)
- Returning typed results (`UserRole`, `Product`, etc.)

**Must NOT:**
- Import screen or widget files
- Import Firebase SDK packages directly
- Hold UI state or reference `BuildContext`
- Return raw `FirebaseAuthException` to the UI

```dart
// Good — service uses repository interface
final uid = await _authRepository.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Bad — Firebase in service
await FirebaseAuth.instance.signInWithEmailAndPassword(...);
```

### Repository (`repositories/`)

**Responsible for:**
- Defining abstract data access contracts (interfaces)
- Firebase implementations in `repositories/firebase/`
- CRUD operations, queries, auth session access
- Returning plain data (`String` uid, `UserRole`, etc.)

**Must NOT:**
- Contain business validation (password rules, role routing)
- Import screens, widgets, or services
- Map errors to user-facing messages (that is the service layer's job)

```dart
// Good — abstract interface (no Firebase import)
abstract class AuthRepository {
  Future<String> signInWithEmailAndPassword({...});
}

// Good — Firebase implementation
class FirebaseAuthRepository implements AuthRepository { ... }
```

### Models (`models/`)

**Responsible for:**
- Defining data structures and enums
- Simple parsing or conversion helpers

**Must NOT:**
- Import Flutter or Firebase packages
- Contain network calls or UI logic

### Utils (`utils/`)

**Responsible for:**
- Pure, stateless helper functions
- Validation, formatting, constants

**Must NOT:**
- Import Flutter widgets or Firebase
- Access global app state

---

## 4. Naming Conventions

| Item                  | Convention        | Example                          |
|-----------------------|-------------------|----------------------------------|
| File names            | `snake_case.dart` | `auth_service.dart`              |
| Classes / enums       | `PascalCase`      | `AuthService`, `UserRole`        |
| Methods / variables   | `camelCase`       | `getUserRole`, `isLoading`       |
| Private members       | `_prefix`         | `_formKey`, `_logout()`          |
| Constants (theme)     | `kPascalCase`     | `kNeon`, `kBackground`           |
| Private widgets       | `_PascalCase`     | `_HeroHeader`, `_AuthTabs`       |
| Asset files           | `snake_case`      | `hero_background.png`            |
| Firestore fields      | `camelCase`       | `displayName`, `createdAt`       |
| Collections           | plural `camelCase`| `users`, `products`, `orders`    |

---

## 5. Import Order

Imports must be grouped in this order, separated by a blank line:

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter framework
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:firebase_auth/firebase_auth.dart';

// 4. Project imports (relative within lib/)
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
```

Rules:
- Prefer relative imports within `lib/`
- No unused imports
- No circular imports between layers

---

## 6. Dart & Flutter Style

### General

- Follow [Effective Dart](https://dart.dev/effective-dart)
- Run `dart format .` before committing
- Run `flutter analyze` — zero errors required
- Use `const` constructors wherever possible
- Prefer `final` over `var`
- Use `async`/`await` instead of raw `.then()` chains

### Widgets

- One primary public widget per screen file
- Extract sub-widgets as private classes when build methods grow large
- Always `dispose()` `TextEditingController`, `AnimationController`, etc.
- Check `mounted` before `setState` or `Navigator` after `await`

```dart
await authService.login(...);
if (!mounted) return;
RoleRouter.navigateToRole(context, role);
```

### State

| State type              | Where it lives                          |
|-------------------------|-----------------------------------------|
| UI state (loading, tab) | Screen `State` class                    |
| Auth session            | `AuthService` + `AuthGate`              |
| Persistent data         | Firestore via `services/`               |
| Theme / colors          | `theme/app_theme.dart`                  |

### Error Handling

- Services throw typed exceptions with user-safe messages
- Screens catch exceptions and display them — never show stack traces
- Use constants for repeated error strings (`Validators.loginPasswordError`)

---

## 7. Firebase Conventions

### Auth (`auth_service.dart` + `auth_repository.dart`)

- `AuthService` — `login()`, `register()`, `logout()`, `sendPasswordReset()`
- `AuthRepository` — abstract auth data contract
- `FirebaseAuthRepository` — Firebase Auth implementation
- Maps `FirebaseAuthException` to `AuthException` inside the service

### Firestore (`user_repository.dart` + `firestore_user_repository.dart`)

- `UserRepository` — abstract user profile contract
- `FirestoreUserRepository` — Firestore `users` collection implementation
- One repository per Firestore domain (`users`, `products`, `orders`)
- Document IDs for user profiles = Firebase Auth `uid`
- Use `FieldValue.serverTimestamp()` for `createdAt` / `updatedAt`

### User document shape

```json
{
  "email": "user@example.com",
  "phone": "+84901234567",
  "role": "customer",
  "displayName": "John Doe",
  "createdAt": "<timestamp>"
}
```

Valid roles: `admin`, `staff`, `customer` (defined in `models/user_role.dart`).

---

## 8. Navigation

- Role-based routing lives in `navigation/role_router.dart`
- Use `RoleRouter.navigateToRole()` after login/register
- Use `pushAndRemoveUntil` when switching auth state (login → home, logout → login)
- `AuthGate` in `main.dart` handles session restore on app start

Screens must not contain role-switching logic — delegate to `RoleRouter`.

---

## 9. Theming & UI

- All colors and `ThemeData` in `theme/app_theme.dart`
- Screens use `kNeon`, `kBackground`, etc. — no magic color literals in UI
- Typography: `fontFamily: 'monospace'` for the tactical UI style
- Buttons and inputs use theme defaults; override only when necessary

---

## 10. Validation

- All input validation rules in `utils/validators.dart`
- Form validators return `String?` (`null` = valid, `String` = error message)
- Business-level validation (e.g. checking Firestore) stays in `services/`
- UI calls `Validators` in `TextFormField.validator`, services re-validate before API calls

---

## 11. Testing Standards

| Layer       | What to test                                    |
|-------------|-------------------------------------------------|
| `utils/`    | Unit tests for all validators                   |
| `services/` | Unit tests with mocked Firebase                 |
| `screens/`  | Widget tests for critical flows (login, routing)  |

Minimum before merging auth-related changes:
- Validator unit tests pass
- `flutter analyze` passes
- Manual test: login, register, logout, session restore

---

## 12. Git & Review Checklist

### Commit messages

Use imperative mood, concise:

```
Add register password validation
Fix role routing for staff users
```

### Pre-merge checklist

- [ ] Code is in the correct layer and folder
- [ ] No Firebase imports in `screens/` or `widgets/`
- [ ] No business logic in UI files
- [ ] `const` / `final` used appropriately
- [ ] Controllers disposed, `mounted` checked after async
- [ ] Error messages are user-friendly
- [ ] `dart format .` applied
- [ ] `flutter analyze` passes with no issues
- [ ] No secrets committed (API keys, credentials)

---

## 13. Adding a New Feature (Example)

Adding a **product listing** feature:

1. `models/product.dart` — `Product` class
2. `repositories/product_repository.dart` — abstract interface
3. `repositories/firebase/firestore_product_repository.dart` — Firestore queries
4. `services/product_service.dart` — business logic using the repository
5. `widgets/product_card.dart` — reusable card widget
6. `screens/customer/product_list_screen.dart` — screen UI
7. Wire navigation in `role_router.dart` if needed

**Do not** put Firestore queries directly in `product_list_screen.dart` or `product_service.dart` without going through a repository.

---

## 14. Anti-Patterns (Do Not Do)

| Anti-pattern                              | Correct approach                        |
|-------------------------------------------|-----------------------------------------|
| Firebase call in a screen                 | Call via `services/`                    |
| Firebase call in a service                | Call via `repositories/`                |
| Business logic in `build()`               | Move to service or validator            |
| Giant god-service doing everything        | Split by domain (`auth`, `user`, `product`) |
| Raw exception shown to user               | Map to `AuthException` with clear text  |
| Hardcoded colors in widgets               | Use `theme/app_theme.dart` constants    |
| `models/` importing Firebase              | Keep models as pure Dart                |
| Repository mapping user-facing errors     | Map errors in `services/` only          |
| Navigation logic duplicated per screen    | Centralize in `navigation/`             |

---

## 15. Tooling

```bash
# Format all Dart files
dart format .

# Static analysis (required to pass)
flutter analyze

# Run tests
flutter test
```

Lint rules are configured in `analysis_options.yaml` (extends `flutter_lints`).

---

*Last updated: June 2026*
