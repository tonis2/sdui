# sdui

Node based web UI for managing AI prompts, development is in early stage.

## Getting Started


You can just install the webapp as PWA app, and it should be working offline.



#### Tips

* use CTRL + S to save the node configuration to local storage.
* You can create new folders from folder node, they can be passworded (slower) or just plain storage.
* You can create your own new nodes, check the current [nodes](https://github.com/tonis2/sdui/tree/main/lib/pages/node_editor/nodes) for example, maybe in the future I can get dynamic code working with dart, so its possible to download new nodes without rebuilding the project.


Run locally

```
flutter run -d chrome --no-web-browser-launch --web-port 8000

flutter run -d web-server --web-port 8000
```

Build 
```
flutter build web --release --wasm --source-maps --pwa-strategy=offline-first
```


