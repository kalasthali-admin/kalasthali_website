self.addEventListener('push', (event) => {
  const payload = event.data ? event.data.json() : {};
  event.waitUntil(self.registration.showNotification(
    payload.title || 'New Kalasthali Order 🛍️',
    { body: payload.body || 'A new paid order has been placed.', data: { url: payload.url || '/admin' }, icon: '/android-chrome-192x192.png' },
  ));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL(event.notification.data?.url || '/admin', self.location.origin).href;
  event.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
    for (const windowClient of windows) {
      if (windowClient.url.startsWith(self.location.origin)) return windowClient.focus();
    }
    return clients.openWindow(url);
  }));
});
