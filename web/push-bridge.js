window.kalasthaliPushSupported = () => 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
window.kalasthaliPushEnabled = async () => {
  if (!window.kalasthaliPushSupported()) return false;
  const registration = await navigator.serviceWorker.getRegistration('/push-sw.js');
  return Boolean(registration && await registration.pushManager.getSubscription());
};
window.kalasthaliPushEnable = async (vapidKey) => {
  if (!window.kalasthaliPushSupported()) throw new Error('This browser does not support Web Push.');
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') throw new Error('Notification permission was not granted.');
  const registration = await navigator.serviceWorker.register('/push-sw.js');
  let subscription = await registration.pushManager.getSubscription();
  if (!subscription) subscription = await registration.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: vapidKey });
  return JSON.stringify(subscription.toJSON());
};
window.kalasthaliPushDisable = async () => {
  const registration = await navigator.serviceWorker.getRegistration('/push-sw.js');
  const subscription = registration && await registration.pushManager.getSubscription();
  if (!subscription) return '';
  const endpoint = subscription.endpoint;
  await subscription.unsubscribe();
  return endpoint;
};
