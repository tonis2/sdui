# sdui

A new Flutter project.

## Getting Started


You can just install the webapp as PWA app, and it should be working offline.



#### Tips

* use CTRL + S to save the node configuration to local storage.
* You can create new folders from folder node, they can be passworded (slower) or just plain storage.
* 



Run locally

```
flutter run -d chrome --no-web-browser-launch --web-port 8000 --dart-define=flavor=prod

flutter run -d web-server --web-port 8000 --dart-define=flavor=prod
```


Build 
```
flutter build web --dart-define=flavor=prod --release --wasm --source-maps --pwa-strategy=offline-first
```


