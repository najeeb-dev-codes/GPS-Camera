# Mobile App Base

Reusable Flutter mobile starter copied from the existing mobile client
structure. The source project is untouched. This copy keeps the same
foundation: theme tokens, shared widgets, platform folders, assets, tests, and
a `features/` layout.

## Setup

```bash
flutter pub get
flutter run
```

## Structure

```text
lib/
|-- main.dart
|-- app.dart
|-- core/
|   `-- theme/
|-- shared/
|   `-- widgets/
`-- features/
    `-- sample/
        `-- sample_screen.dart
```

Use `SampleScreen` as the first screen to replace when starting a new app.
