import {
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User,
} from 'firebase/auth';
import {
  doc,
  getDoc,
} from 'firebase/firestore';
import { auth, db } from './firebase';

export type UserRole = 'user' | 'artist' | 'admin';

export interface AppUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  role: UserRole;
  photoUrl?: string;
  status?: string;
}

/** Sign in with email and password. Returns error string or null. */
export async function login(email: string, password: string): Promise<string | null> {
  try {
    await signInWithEmailAndPassword(auth, email, password);
    return null;
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'Login failed';
    return msg;
  }
}

export async function logout(): Promise<void> {
  await signOut(auth);
}

/** Fetch the user's role from Firestore. */
export async function getUserRole(uid: string): Promise<UserRole> {
  try {
    const snap = await getDoc(doc(db, 'users', uid));
    if (snap.exists()) {
      return (snap.data().role as UserRole) ?? 'user';
    }
    return 'user';
  } catch {
    return 'user';
  }
}

/** Subscribe to auth state changes with role lookup. */
export function onAuthChange(callback: (user: AppUser | null) => void) {
  return onAuthStateChanged(auth, async (firebaseUser: User | null) => {
    if (!firebaseUser) {
      callback(null);
      return;
    }
    const role = await getUserRole(firebaseUser.uid);
    callback({
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      role,
    });
  });
}
