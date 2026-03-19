import {
  collection,
  getDocs,
  doc,
  addDoc,
  updateDoc,
  query,
  orderBy,
  where,
  serverTimestamp,
  deleteField,
} from 'firebase/firestore';
import { db } from './firebase';

export async function getMyTracks(uid: string) {
  const q = query(
    collection(db, 'tracks'),
    where('ownerId', '==', uid),
    orderBy('createdAt', 'desc'),
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function createTrack(data: Record<string, unknown>) {
  return addDoc(collection(db, 'tracks'), {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

export async function updateTrack(trackId: string, data: Record<string, unknown>) {
  await updateDoc(doc(db, 'tracks', trackId), {
    ...data,
    updatedAt: serverTimestamp(),
  });
}

export async function hideMyTrack(trackId: string) {
  await updateDoc(doc(db, 'tracks', trackId), {
    isHidden: true,
    hiddenBy: 'artist',
    updatedAt: serverTimestamp(),
  });
}

export async function unhideMyTrack(trackId: string) {
  await updateDoc(doc(db, 'tracks', trackId), {
    isHidden: false,
    hiddenBy: deleteField(),
    updatedAt: serverTimestamp(),
  });
}

export async function getMyAnalytics(uid: string) {
  const q = query(collection(db, 'tracks'), where('ownerId', '==', uid));
  const snap = await getDocs(q);

  let totalPlays = 0;
  let totalFavorites = 0;
  let totalScenery = 0;

  const tracks = snap.docs.map((d) => {
    const data = d.data();
    const stats = (data.stats as Record<string, number>) ?? {};
    const plays = stats.playCount ?? 0;
    const favs = stats.favoriteCount ?? 0;
    const scenery = stats.sceneryMatchCount ?? 0;
    totalPlays += plays;
    totalFavorites += favs;
    totalScenery += scenery;

    return {
      id: d.id,
      title: data.title ?? data.name ?? 'Unknown',
      imageUrl: data.imageUrl ?? data.artworkUrl ?? '',
      isHidden: data.isHidden ?? false,
      hiddenBy: data.hiddenBy ?? null,
      status: data.status ?? 'published',
      playCount: plays,
      favoriteCount: favs,
      sceneryMatchCount: scenery,
    };
  });

  tracks.sort((a, b) => b.playCount - a.playCount);

  return { totalPlays, totalFavorites, totalScenery, tracks };
}

export async function applyForArtist(
  uid: string,
  data: { artistName: string; companyName?: string; bio?: string; email?: string },
) {
  await updateDoc(doc(db, 'artist_requests', uid), {
    uid,
    ...data,
    status: 'pending',
    createdAt: serverTimestamp(),
  }).catch(async () => {
    // If doc doesn't exist, create it
    const { setDoc } = await import('firebase/firestore');
    await setDoc(doc(db, 'artist_requests', uid), {
      uid,
      ...data,
      status: 'pending',
      createdAt: serverTimestamp(),
    });
  });
}
