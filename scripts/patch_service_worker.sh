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
