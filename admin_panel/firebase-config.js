// Firebase Configuration for Scenery Sync Admin Panel
// This file initializes Firebase App and Firestore for the admin panel

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';
import { getStorage } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-storage.js';

// Firebase configuration from your Flutter project
const firebaseConfig = {
    apiKey: 'AIzaSyDL_K-Ogus20Yc-3zd5H9FWZpbWpY-TSzU',
    appId: '1:521689710584:web:60efcdfa60c62854ffe00d',
    messagingSenderId: '521689710584',
    projectId: 'scenery-sync-81273',
    authDomain: 'scenery-sync-81273.firebaseapp.com',
    storageBucket: 'scenery-sync-81273.firebasestorage.app',
    measurementId: 'G-1LJMRMKS5K',
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firestore
const db = getFirestore(app);

// Initialize Storage
const storage = getStorage(app);

// Export for use in other modules
export { app, db, storage };
