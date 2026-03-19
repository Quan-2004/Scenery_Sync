'use client';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { onAuthChange, logout, type AppUser } from '@/lib/auth';
import { AdminCtx } from './context';

function AdminSidebar({ user }: { user: AppUser }) {
  const pathname = usePathname();

  const links = [
    { href: '/admin/dashboard', icon: '📊', label: 'Dashboard' },
    { href: '/admin/users', icon: '👥', label: 'Người dùng' },
    { href: '/admin/tracks', icon: '🎵', label: 'Bài hát' },
  ];

  return (
    <aside className="sidebar">
      <Link href="/admin/dashboard" className="sidebar-logo">
        <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--primary-medium)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>🎵</div>
        <div>
          <div className="sidebar-logo-text">Scenery Sync</div>
          <div className="sidebar-logo-sub">Admin Portal</div>
        </div>
      </Link>

      <nav className="sidebar-nav">
        <div className="sidebar-section">Quản lý</div>
        {links.map(l => (
          <Link
            key={l.href}
            href={l.href}
            className={`nav-link${pathname === l.href || pathname.startsWith(l.href + '/') ? ' active' : ''}`}
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
            <div className="sidebar-role-badge role-admin">Admin</div>
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

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthChange((u) => {
      if (!u) {
        router.replace('/login');
      } else if (u.role !== 'admin') {
        router.replace('/artist/dashboard');
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
    <AdminCtx.Provider value={user}>
      <div className="portal-layout">
        <AdminSidebar user={user} />
        <main className="portal-main">
          <div className="portal-content">{children}</div>
        </main>
      </div>
    </AdminCtx.Provider>
  );
}
