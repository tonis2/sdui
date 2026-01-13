# sdui

A new Flutter project.

## Getting Started

Run locally

```
flutter run -d chrome --no-web-browser-launch --web-port 8000 --dart-define=flavor=prod

flutter run -d web-server --web-port 8000 --dart-define=flavor=prod
```


Build 
```
flutter build web --dart-define=flavor=prod --release --wasm --source-maps
```