importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyCrE_3jFLXKcQY3wfAakAfkSubFBAiBkQU",
  authDomain: "sama-asc-aa8cb.firebaseapp.com",
  projectId: "sama-asc-aa8cb",
  storageBucket: "sama-asc-aa8cb.firebasestorage.app",
  messagingSenderId: "613103570154",
  appId: "1:613103570154:web:86e64cd4a675202dcf5b93"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'Notification Sama ASC';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
