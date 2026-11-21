// web/firebase-messaging-sw.js
//
// Service worker obligatoire pour la réception des notifications push web
// en arrière-plan (onglet fermé/masqué) — P3.6. Doit être servi à la
// RACINE du domaine (pas dans un sous-dossier) : Firebase Cloud Messaging
// n'accepte que le scope par défaut d'un service worker placé ici.
//
// Valeurs alignées sur `lib/firebase_options.dart` (bloc `web`, généré par
// `flutterfire configure` pour le projet yeki-84b1a) — à régénérer avec
// `flutterfire configure` si le projet Firebase change, PAS à modifier ici
// à la main.

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBKsq8gVAFh4t7OrLOgDlAph611ly3xNXM',
  appId: '1:1048634603484:web:3cdb4de92165073273c119',
  messagingSenderId: '1048634603484',
  projectId: 'yeki-84b1a',
  authDomain: 'yeki-84b1a.firebaseapp.com',
  storageBucket: 'yeki-84b1a.firebasestorage.app',
});

const messaging = firebase.messaging();

// Notification par défaut quand l'app est en arrière-plan/fermée. Le
// contenu réel (titre/corps/icône par type de notification) est une
// décision produit hors périmètre de ce ticket d'infrastructure — voir
// docs/FIREBASE_SETUP.md.
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Yéki';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
