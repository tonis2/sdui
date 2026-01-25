#!/bin/bash
# Patch Flutter's service worker to use offline-first for all requests
# Run this after: flutter build web

SERVICE_WORKER="build/web/flutter_service_worker.js"

if [ ! -f "$SERVICE_WORKER" ]; then
    echo "Error: Service worker not found at $SERVICE_WORKER"
    echo "Run 'flutter build web' first."
    exit 1
fi

# Check if already patched
if grep -q "function offlineFirst" "$SERVICE_WORKER"; then
    echo "Service worker already patched."
    exit 0
fi

# Replace onlineFirst with offlineFirst for index.html
sed -i 's/return onlineFirst(event);/return offlineFirst(event);/g' "$SERVICE_WORKER"
sed -i 's/perform an online-first request/perform an offline-first request/g' "$SERVICE_WORKER"

# Fix manifest.json paths for subdirectory deployment (GitHub/GitLab Pages)
MANIFEST="build/web/manifest.json"
if [ -f "$MANIFEST" ]; then
    # Detect base-href from index.html
    BASE_HREF=$(grep -oP '(?<=<base href=")[^"]+' build/web/index.html || echo "/")
    if [ "$BASE_HREF" != "/" ]; then
        echo "Detected base-href: $BASE_HREF"
        sed -i "s|\"start_url\": \"/\"|\"start_url\": \"$BASE_HREF\"|g" "$MANIFEST"
        sed -i "s|\"scope\": \"/\"|\"scope\": \"$BASE_HREF\"|g" "$MANIFEST"
        sed -i "s|\"id\": \"/\"|\"id\": \"$BASE_HREF\"|g" "$MANIFEST"
        echo "Manifest.json patched for subdirectory deployment!"
    fi
fi

# Fix service worker key calculation for subdirectory deployment
# The default uses origin.length which breaks when app is in a subdirectory
# We need to use the service worker's base path instead
sed -i 's|var origin = self.location.origin;|var baseUrl = self.location.href.replace(/flutter_service_worker\\.js$/, "");|g' "$SERVICE_WORKER"
sed -i 's|event.request.url.substring(origin.length + 1)|event.request.url.substring(baseUrl.length)|g' "$SERVICE_WORKER"
sed -i 's|request.url.substring(origin.length + 1)|request.url.substring(baseUrl.length)|g' "$SERVICE_WORKER"
# Add baseUrl to downloadOffline function (it only has local scope in other handlers)
sed -i '/async function downloadOffline() {/a\  var baseUrl = self.location.href.replace(/flutter_service_worker\\.js$/, "");' "$SERVICE_WORKER"
# Also fix the root URL check
sed -i 's|event.request.url == origin|event.request.url == baseUrl.slice(0, -1)|g' "$SERVICE_WORKER"
sed -i "s|event.request.url.startsWith(origin + '/#')|event.request.url.startsWith(baseUrl + '#')|g" "$SERVICE_WORKER"
echo "Service worker patched for subdirectory URL handling!"

# Add offlineFirst function at the end
cat >> "$SERVICE_WORKER" << 'OFFLINE_FIRST_FUNC'

// Offline-first: serve from cache immediately, update cache in background
function offlineFirst(event) {
  return event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((cachedResponse) => {
        // If we have a cached response, return it immediately
        if (cachedResponse) {
          // Update cache in background (stale-while-revalidate)
          fetch(event.request).then((networkResponse) => {
            if (networkResponse && networkResponse.ok) {
              cache.put(event.request, networkResponse.clone());
            }
          }).catch(() => {});
          return cachedResponse;
        }
        // No cache available, try network
        return fetch(event.request).then((networkResponse) => {
          if (networkResponse && networkResponse.ok) {
            cache.put(event.request, networkResponse.clone());
          }
          return networkResponse;
        });
      });
    })
  );
}
OFFLINE_FIRST_FUNC

echo "Service worker patched for offline-first behavior!"
