'use client';
import { createContext, useContext } from 'react';
import type { AppUser } from '@/lib/auth';

export const ArtistCtx = createContext<AppUser | null>(null);
export const useArtist = () => useContext(ArtistCtx);
