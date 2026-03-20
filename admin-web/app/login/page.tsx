'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { login, loginWithGoogle, getUserRole } from '@/lib/auth';
import { auth } from '@/lib/firebase';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);

    const err = await login(email, password);
    if (err) {
      setError(err.replace('Firebase: ', '').replace(/\(auth\/.*\)\.?/, '').trim());
      setLoading(false);
      return;
    }

    const uid = auth.currentUser?.uid;
    if (!uid) { setLoading(false); return; }
    const role = await getUserRole(uid);

    if (role === 'admin') router.replace('/admin/dashboard');
    else if (role === 'artist') router.replace('/artist/dashboard');
    else {
      setError('Access denied. Only admins and artists can access this portal.');
      await import('@/lib/auth').then(m => m.logout());
    }
    setLoading(false);
  }

  async function handleGoogleLogin() {
    setError('');
    setLoading(true);
    
    const err = await loginWithGoogle();
    if (err) {
      setError(err);
      setLoading(false);
      return;
    }

    const uid = auth.currentUser?.uid;
    if (!uid) { 
      setLoading(false); 
      return; 
    }

    const role = await getUserRole(uid);

    if (role === 'admin') router.replace('/admin/dashboard');
    else if (role === 'artist') router.replace('/artist/dashboard');
    else {
      setError('Access denied. Only admins and artists can access this portal.');
      await import('@/lib/auth').then(m => m.logout());
    }
    setLoading(false);
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-logo">
          <img src="/logo.png" alt="Scenery Sync" style={{ width: 44, height: 44, borderRadius: 12, objectFit: 'contain' }} />
          <div>
            <div className="login-logo-name">Scenery Sync</div>
            <div className="login-logo-sub">Management Portal</div>
          </div>
        </div>

        <h1 className="login-title">Welcome back</h1>
        <p className="login-desc">Sign in with your Admin or Artist account</p>

        {error && <div className="login-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Email</label>
            <input
              type="email"
              className="form-control"
              placeholder="your@email.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <input
              type="password"
              className="form-control"
              placeholder="••••••••"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              autoComplete="current-password"
            />
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%', justifyContent: 'center', marginTop: 4, height: 42 }}
            disabled={loading}
          >
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>

        <div style={{ display: 'flex', alignItems: 'center', margin: '20px 0', gap: 12 }}>
          <div style={{ flex: 1, height: 1, background: 'var(--border-solid)' }} />
          <span style={{ fontSize: 12, color: 'var(--text-dim)', fontWeight: 600 }}>OR</span>
          <div style={{ flex: 1, height: 1, background: 'var(--border-solid)' }} />
        </div>

        <button
          className="btn btn-ghost"
          style={{ width: '100%', justifyContent: 'center', gap: 10, height: 42, background: 'white', color: '#333' }}
          disabled={loading}
          onClick={handleGoogleLogin}
        >
          <svg width="18" height="18" viewBox="0 0 48 48">
            <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
            <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
            <path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238A11.91 11.91 0 0124 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
            <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571.001-.001.002-.001.003-.002l6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
          </svg>
          Sign in with Google
        </button>

        <p style={{ marginTop: 24, textAlign: 'center', fontSize: 12, color: 'var(--text-dim)' }}>
          This portal is for Admins and Artists only.
          <br />End-users please use the mobile app.
        </p>
      </div>
    </div>
  );
}
