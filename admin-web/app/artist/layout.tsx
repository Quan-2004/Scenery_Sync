'use client';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { onAuthChange, logout, type AppUser } from '@/lib/auth';
import { ArtistCtx } from './context';

function ArtistSidebar({ user }: { user: AppUser }) {
  const pathname = usePathname();

  const links = [
    { href: '/artist/dashboard', icon: '📊', label: 'Dashboard' },
    { href: '/artist/tracks', icon: '🎵', label: 'Sáng tác của tôi' },
    { href: '/artist/analytics', icon: '📈', label: 'Thống kê chi tiết' },
  ];

  return (
    <aside className="sidebar">
      <Link href="/artist/dashboard" className="sidebar-logo">
        <img src="/logo.png" alt="Scenery Sync" style={{ width: 34, height: 34, borderRadius: 8, objectFit: 'contain' }} />
        <div>
          <div className="sidebar-logo-text">Scenery Sync</div>
          <div className="sidebar-logo-sub">Artist Studio</div>
        </div>
      </Link>

      <nav className="sidebar-nav">
        <div className="sidebar-section">Studio</div>
        {links.map(l => (
          <Link
            key={l.href}
            href={l.href}
            className={`nav-link${pathname === l.href ? ' active' : ''}`}
          >
            <span>{l.icon}</span>
            <span>{l.label}</span>
          </Link>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-user">
          <div className="sidebar-avatar">
            {(user.displayName ?? user.email ?? 'A')[0].toUpperCase()}
          </div>
          <div className="sidebar-user-info">
            <div className="sidebar-user-name">{user.displayName ?? user.email}</div>
            <div className="sidebar-role-badge role-artist">Artist</div>
          </div>
        </div>
        <button
          className="btn btn-ghost"
          style={{ width: '100%', justifyContent: 'center', fontSize: 12 }}
          onClick={() => logout().then(() => (window.location.href = '/login'))}
        >
          Đăng xuất
        </button>
      </div>
    </aside>
  );
}

export default function ArtistLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthChange((u) => {
      if (!u) {
        router.replace('/login');
      } else if (u.role === 'admin') {
        router.replace('/admin/dashboard');
      } else if (u.role !== 'artist') {
        router.replace('/login');
      } else {
        setUser(u);
      }
      setLoading(false);
    });
  }, [router]);

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', color: 'var(--text-muted)' }}>
        Đang tải…
      </div>
    );
  }

  if (!user) return null;

  return (
    <ArtistCtx.Provider value={user}>
      <div className="portal-layout">
        <ArtistSidebar user={user} />
        <main className="portal-main">
          <div className="portal-content">{children}</div>
        </main>
      </div>
    </ArtistCtx.Provider>
  );
}
