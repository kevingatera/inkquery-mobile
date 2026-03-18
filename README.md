# Inkquery Mobile

Android-first Flutter client for Inkquery.

## Features

- Configurable API server, defaulting to `http://192.168.1.108:8420`
- Local username/password sign-in
- Optional mobile OIDC flow through `flutter_web_auth_2`
- Secure token storage with refresh-token restore on startup
- Oracle chat with streamed stage updates and citations
- Library browse with book detail sheet
- Entity browse with mention detail sheet

## Run

```bash
flutter pub get
flutter run
```

## Validate

```bash
flutter analyze
flutter test
flutter build apk --debug
```
