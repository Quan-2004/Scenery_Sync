'use client';
import { createContext, useContext } from 'react';
import type { AppUser } from '@/lib/auth';

export const AdminCtx = createContext<AppUser | null>(null);
export const useAdmin = () => useContext(AdminCtx);
