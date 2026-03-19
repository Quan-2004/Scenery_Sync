'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { login, getUserRole } from '@/lib/auth';
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
      setError(err);
      setLoading(false);
      return;
    }

    const uid = auth.currentUser?.uid;
    if (!uid) {
      setError('Authentication error');
      setLoading(false);
      return;
    }

    const role = await getUserRole(uid);

    if (role === 'admin') {
      router.replace('/admin/dashboard');
    } else if (role === 'artist') {
      router.replace('/artist/dashboard');
    } else {
      setError('Access denied. Only admins and artists can access this portal.');
      await import('@/lib/auth').then(m => m.logout());
    }
    setLoading(false);
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-logo">
          <div className="login-logo-icon">🎵</div>
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
            style={{ width: '100%', justifyContent: 'center', marginTop: 4 }}
            disabled={loading}
          >
            {loading ? 'Signing in…' : 'Sign In'}
          </button>
        </form>

        <p style={{ marginTop: 20, textAlign: 'center', fontSize: 12, color: 'var(--text-dim)' }}>
          This portal is for Admins and Artists only.
          <br />End-users please use the mobile app.
        </p>
      </div>
    </div>
  );
}
