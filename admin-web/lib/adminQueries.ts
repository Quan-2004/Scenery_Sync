import {
  collection,
  getDocs,
  doc,
  updateDoc,
  deleteDoc,
  query,
  orderBy,
  limit,
  getCountFromServer,
  getDoc,
  writeBatch,
  serverTimestamp,
  where,
} from 'firebase/firestore';
import { db } from './firebase';

// ──────────────────────────────────────────
// USER MANAGEMENT
// ──────────────────────────────────────────

export async function getAllUsers(limitN = 100) {
  const q = query(collection(db, 'users'), orderBy('createdAt', 'desc'), limit(limitN));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
}

export async function banUser(uid: string) {
  await updateDoc(doc(db, 'users', uid), { status: 'banned' });
}

export async function unbanUser(uid: string) {
  await updateDoc(doc(db, 'users', uid), { status: 'active' });
}

// ──────────────────────────────────────────
// ARTIST MANAGEMENT
// ──────────────────────────────────────────

export async function getPendingArtistRequests() {
  const q = query(
    collection(db, 'artist_requests'),
    orderBy('createdAt', 'desc'),
    limit(100),
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
}

export async function getAllArtists(limitN = 100) {
  const q = query(
    collection(db, 'users'),
    where('role', '==', 'artist'),
    limit(limitN),
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
}

export async function approveArtist(uid: string) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'users', uid), {
    role: 'artist',
    artistVerified: true,
    artistApprovedAt: serverTimestamp(),
  });
  batch.delete(doc(db, 'artist_requests', uid));
  await batch.commit();
}

export async function revokeArtist(uid: string) {
  await updateDoc(doc(db, 'users', uid), {
    role: 'user',
    artistVerified: false,
  });
}

// ──────────────────────────────────────────
// TRACK MANAGEMENT
// ──────────────────────────────────────────

export async function getAllTracks(limitN = 200) {
  const q = query(collection(db, 'tracks'), orderBy('createdAt', 'desc'), limit(limitN));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function hideTrack(trackId: string) {
  await updateDoc(doc(db, 'tracks', trackId), {
    isHidden: true,
    hiddenBy: 'admin',
    hiddenAt: serverTimestamp(),
  });
}

export async function unhideTrack(trackId: string) {
  await updateDoc(doc(db, 'tracks', trackId), {
    isHidden: false,
    hiddenBy: null,
    hiddenAt: null,
  });
}

// ──────────────────────────────────────────
// DASHBOARD STATS
// ──────────────────────────────────────────

export async function getDashboardCounts() {
  const [users, artists, tracks, hidden] = await Promise.all([
    getCountFromServer(query(collection(db, 'users'), where('role', '==', 'user'))),
    getCountFromServer(query(collection(db, 'users'), where('role', '==', 'artist'))),
    getCountFromServer(
      query(collection(db, 'tracks'), where('status', '==', 'published')),
    ),
    getCountFromServer(
      query(collection(db, 'tracks'), where('isHidden', '==', true)),
    ),
  ]);

  return {
    totalUsers: users.data().count,
    totalArtists: artists.data().count,
    totalTracks: tracks.data().count,
    hiddenTracks: hidden.data().count,
  };
}

export async function getTopKeywords(limitN = 15) {
  const q = query(
    collection(db, 'admin_keyword_reports'),
    orderBy('createdAt', 'desc'),
    limit(200),
  );
  const snap = await getDocs(q);
  const counts: Record<string, number> = {};

  for (const d of snap.docs) {
    const keywords = d.data().keywords;
    if (Array.isArray(keywords)) {
      for (const kw of keywords) {
        counts[kw] = (counts[kw] ?? 0) + 1;
      }
    }
  }

  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, limitN)
    .map(([keyword, count]) => ({ keyword, count }));
}
