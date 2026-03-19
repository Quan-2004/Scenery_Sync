import {
  collection,
  getDocs,
  doc,
  updateDoc,
  query,
  orderBy,
  limit,
  getCountFromServer,
  writeBatch,
  serverTimestamp,
  where,
} from 'firebase/firestore';
import { db } from './firebase';

// ──────────────────────────────────────────
// USER MANAGEMENT
// ──────────────────────────────────────────

export async function getAllUsers(limitN = 200) {
  // Note: no orderBy to avoid requiring a Firestore composite index
  const q = query(collection(db, 'users'), limit(limitN));
  const snap = await getDocs(q);
  const docs = snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
  // Sort client-side by createdAt descending (handles missing field gracefully)
  return docs.sort((a: Record<string, unknown>, b: Record<string, unknown>) => {
    const aTime = (a.createdAt as { seconds?: number })?.seconds ?? 0;
    const bTime = (b.createdAt as { seconds?: number })?.seconds ?? 0;
    return bTime - aTime;
  });
}

export async function banUser(uid: string) {
  await updateDoc(doc(db, 'users', uid), { status: 'banned' });
}

export async function unbanUser(uid: string) {
  await updateDoc(doc(db, 'users', uid), { status: 'active' });
}

export async function setUserRole(uid: string, role: 'user' | 'artist' | 'admin') {
  await updateDoc(doc(db, 'users', uid), { role });
}

export async function deleteUserDoc(uid: string) {
  const { deleteDoc } = await import('firebase/firestore');
  await deleteDoc(doc(db, 'users', uid));
}

// ──────────────────────────────────────────
// ARTIST MANAGEMENT
// ──────────────────────────────────────────

export async function getPendingArtistRequests() {
  const q = query(collection(db, 'artist_requests'), limit(100));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ uid: d.id, ...d.data() }));
}

export async function getAllArtists(limitN = 200) {
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

export async function getAllTracks(limitN = 300) {
  // No orderBy to avoid index requirement — sort client-side
  const q = query(collection(db, 'tracks'), limit(limitN));
  const snap = await getDocs(q);
  const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  return docs.sort((a: Record<string, unknown>, b: Record<string, unknown>) => {
    const aTime = (a.createdAt as { seconds?: number })?.seconds ?? 0;
    const bTime = (b.createdAt as { seconds?: number })?.seconds ?? 0;
    return bTime - aTime;
  });
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
  const [totalUsers, artists, tracks, bannedUsers, hiddenTracks, pendingArtists] =
    await Promise.all([
      getCountFromServer(collection(db, 'users')),
      getCountFromServer(query(collection(db, 'users'), where('role', '==', 'artist'))),
      getCountFromServer(collection(db, 'tracks')),
      getCountFromServer(query(collection(db, 'users'), where('status', '==', 'banned'))),
      getCountFromServer(query(collection(db, 'tracks'), where('isHidden', '==', true))),
      getCountFromServer(collection(db, 'artist_requests')),
    ]);

  return {
    totalUsers: totalUsers.data().count,
    totalArtists: artists.data().count,
    totalTracks: tracks.data().count,
    bannedUsers: bannedUsers.data().count,
    hiddenTracks: hiddenTracks.data().count,
    pendingArtists: pendingArtists.data().count,
  };
}

export async function getTopKeywords(limitN = 15) {
  const q = query(collection(db, 'admin_keyword_reports'), limit(200));
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

export async function getTopTracks(limitN = 10) {
  const q = query(collection(db, 'tracks'), limit(200));
  const snap = await getDocs(q);
  const tracks = snap.docs.map((d) => {
    const data = d.data();
    const stats = (data.stats as Record<string, number>) ?? {};
    return {
      id: d.id,
      title: data.title ?? data.name ?? 'Unknown',
      artistName: data.artistName ?? data.artist ?? '—',
      playCount: stats.playCount ?? 0,
      favoriteCount: stats.favoriteCount ?? 0,
      sceneryMatchCount: stats.sceneryMatchCount ?? 0,
      isHidden: data.isHidden ?? false,
    };
  });
  return tracks
    .sort((a, b) => b.playCount - a.playCount)
    .slice(0, limitN);
}

export async function getTopArtists(limitN = 10) {
  const q = query(collection(db, 'tracks'), limit(500));
  const snap = await getDocs(q);
  const map: Record<string, { name: string; playCount: number; trackCount: number; favoriteCount: number }> = {};

  for (const d of snap.docs) {
    const data = d.data();
    const artistName: string = data.artistName ?? data.artist ?? 'Unknown';
    const stats = (data.stats as Record<string, number>) ?? {};
    const play = stats.playCount ?? 0;
    const fav  = stats.favoriteCount ?? 0;
    if (!map[artistName]) {
      map[artistName] = { name: artistName, playCount: 0, trackCount: 0, favoriteCount: 0 };
    }
    map[artistName].playCount     += play;
    map[artistName].trackCount    += 1;
    map[artistName].favoriteCount += fav;
  }

  return Object.values(map)
    .sort((a, b) => b.playCount - a.playCount)
    .slice(0, limitN);
}
