'use client';
import { useEffect, useState, useCallback } from 'react';
import { getAllUsers, banUser, unbanUser, setUserRole, deleteUserDoc } from '@/lib/adminQueries';
import { exportToCSV, USER_COLUMNS } from '@/lib/exportUtils';

interface UserRow {
  uid: string;
  email?: string;
  displayName?: string;
  name?: string;
  photoURL?: string;
  photoUrl?: string;
  role?: string;
  status?: string;
  createdAt?: { seconds: number };
  companyName?: string;
  phoneNumber?: string;
}

function resolveName(u: UserRow): string {
  return u.displayName || u.name || u.email || u.uid.slice(0, 10);
}
function resolveInitial(u: UserRow): string {
  return (u.displayName || u.name || u.email || u.uid)[0].toUpperCase();
}

// ── Custom Confirm Modal ─────────────────────────────────────────────────────
interface ConfirmOptions {
  icon: string;
  title: string;
  message: string;
  confirmLabel: string;
  danger?: boolean;
  onConfirm: () => void;
}

function ConfirmModal({ opts, onClose }: { opts: ConfirmOptions; onClose: () => void }) {
  return (
    <div
      style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)', zIndex: 2000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 }}
      onClick={e => e.target === e.currentTarget && onClose()}
    >
      <div style={{ background: '#fff', borderRadius: 16, padding: 32, width: '100%', maxWidth: 400, boxShadow: '0 20px 60px rgba(0,0,0,0.15)', border: '1px solid #e5ddd6', textAlign: 'center' }}>
        <div style={{ fontSize: 48, marginBottom: 12 }}>{opts.icon}</div>
        <div style={{ fontSize: 18, fontWeight: 700, color: '#1a1207', marginBottom: 8 }}>{opts.title}</div>
        <div style={{ fontSize: 14, color: '#6b5d4f', marginBottom: 28, lineHeight: 1.6 }}>{opts.message}</div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            onClick={onClose}
            style={{ flex: 1, padding: '10px 0', borderRadius: 8, border: '1px solid #e5ddd6', background: '#f4f1ee', color: '#6b5d4f', fontWeight: 600, fontSize: 14, cursor: 'pointer' }}
          >
            Hủy
          </button>
          <button
            onClick={() => { opts.onConfirm(); onClose(); }}
            style={{ flex: 1, padding: '10px 0', borderRadius: 8, border: 'none', background: opts.danger ? '#c0392b' : '#d4722a', color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer', boxShadow: opts.danger ? '0 4px 12px rgba(192,57,43,0.3)' : '0 4px 12px rgba(212,114,42,0.3)' }}
          >
            {opts.confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [filtered, setFiltered] = useState<UserRow[]>([]);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'user' | 'artist' | 'admin'>('all');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);
  const [detailUser, setDetailUser] = useState<UserRow | null>(null);
  const [confirmOpts, setConfirmOpts] = useState<ConfirmOptions | null>(null);

  const showConfirm = useCallback((opts: ConfirmOptions) => setConfirmOpts(opts), []);

  useEffect(() => {
    getAllUsers().then(data => {
      setUsers(data as UserRow[]);
      setLoading(false);
    });
  }, []);

  useEffect(() => {
    const q = search.toLowerCase();
    setFiltered(
      users.filter(u => {
        const matchSearch =
          (u.email ?? '').toLowerCase().includes(q) ||
          (u.displayName ?? '').toLowerCase().includes(q) ||
          (u.name ?? '').toLowerCase().includes(q) ||
          u.uid.toLowerCase().includes(q);
        const matchRole = roleFilter === 'all' || u.role === roleFilter;
        return matchSearch && matchRole;
      }),
    );
  }, [search, roleFilter, users]);

  function toggleBan(user: UserRow) {
    const isBanned = user.status === 'banned';
    showConfirm({
      icon: isBanned ? '🔓' : '🔒',
      title: isBanned ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?',
      message: isBanned
        ? `Tài khoản "${resolveName(user)}" sẽ được mở khóa và có thể đăng nhập lại.`
        : `Tài khoản "${resolveName(user)}" sẽ bị khóa và không thể đăng nhập.`,
      confirmLabel: isBanned ? '🔓 Mở khóa' : '🔒 Khóa',
      danger: !isBanned,
      onConfirm: async () => {
        setProcessing(user.uid);
        try {
          if (isBanned) await unbanUser(user.uid);
          else await banUser(user.uid);
          setUsers(prev => prev.map(u =>
            u.uid === user.uid ? { ...u, status: isBanned ? 'active' : 'banned' } : u,
          ));
        } finally { setProcessing(null); }
      },
    });
  }

  function handleSetRole(user: UserRow, role: 'user' | 'artist' | 'admin') {
    showConfirm({
      icon: role === 'admin' ? '🛡️' : role === 'artist' ? '🎤' : '👤',
      title: 'Đổi vai trò?',
      message: `Đổi quyền của "${resolveName(user)}" thành "${role === 'admin' ? 'Admin' : role === 'artist' ? 'Nghệ sĩ' : 'Người dùng'}"?`,
      confirmLabel: 'Xác nhận',
      onConfirm: async () => {
        setProcessing(user.uid);
        try {
          await setUserRole(user.uid, role);
          setUsers(prev => prev.map(u => u.uid === user.uid ? { ...u, role } : u));
          if (detailUser?.uid === user.uid) setDetailUser(d => d ? { ...d, role } : d);
        } finally { setProcessing(null); }
      },
    });
  }

  function handleDelete(user: UserRow) {
    showConfirm({
      icon: '🗑️',
      title: 'Xóa tài khoản vĩnh viễn?',
      message: `Tài khoản "${resolveName(user)}" sẽ bị xóa hoàn toàn khỏi hệ thống.\n\nHành động này không thể hoàn tác!`,
      confirmLabel: '🗑 Xóa vĩnh viễn',
      danger: true,
      onConfirm: async () => {
        setProcessing(user.uid);
        try {
          await deleteUserDoc(user.uid);
          setUsers(prev => prev.filter(u => u.uid !== user.uid));
          if (detailUser?.uid === user.uid) setDetailUser(null);
        } finally { setProcessing(null); }
      },
    });
  }

  function formatDate(ts?: { seconds: number }) {
    if (!ts) return '—';
    return new Date(ts.seconds * 1000).toLocaleDateString('vi-VN');
  }

  const roleTabs: { key: typeof roleFilter; label: string; icon: string }[] = [
    { key: 'all', label: 'Tất cả', icon: '👥' },
    { key: 'user', label: 'Người dùng', icon: '👤' },
    { key: 'artist', label: 'Nghệ sĩ', icon: '🎤' },
    { key: 'admin', label: 'Admin', icon: '🛡' },
  ];

  return (
    <div>
      {/* Custom confirm modal */}
      {confirmOpts && <ConfirmModal opts={confirmOpts} onClose={() => setConfirmOpts(null)} />}

      {/* Modal chi tiết user */}
      {detailUser && (
        <div
          style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 24 }}
          onClick={e => e.target === e.currentTarget && setDetailUser(null)}
        >
          <div style={{ background: 'var(--bg-card)', borderRadius: 16, padding: 32, width: '100%', maxWidth: 480, border: '1px solid var(--border-solid)', boxShadow: '0 20px 60px rgba(0,0,0,0.12)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, margin: 0 }}>Thông tin người dùng</h2>
              <button onClick={() => setDetailUser(null)} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: 'var(--text-dim)' }}>✕</button>
            </div>

            <div style={{ display: 'flex', gap: 16, alignItems: 'center', marginBottom: 24 }}>
              <div style={{ width: 60, height: 60, borderRadius: '50%', background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28, fontWeight: 700, color: 'white' }}>
                {resolveInitial(detailUser)}
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 17 }}>{resolveName(detailUser)}</div>
                <div style={{ color: 'var(--text-dim)', fontSize: 13 }}>{detailUser.email || '—'}</div>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 24 }}>
              {[
                { label: 'UID', value: detailUser.uid.slice(0, 12) + '…' },
                { label: 'Ngày tạo', value: formatDate(detailUser.createdAt) },
                { label: 'Trạng thái', value: detailUser.status === 'banned' ? '🔒 Bị khóa' : '✓ Hoạt động' },
                { label: 'SĐT', value: (detailUser as unknown as Record<string,string>).phone || detailUser.phoneNumber || '—' },
              ].map(row => (
                <div key={row.label} style={{ background: 'var(--bg-sidebar)', borderRadius: 8, padding: '10px 14px' }}>
                  <div style={{ fontSize: 11, color: 'var(--text-dim)', marginBottom: 2, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{row.label}</div>
                  <div style={{ fontWeight: 600, fontSize: 13 }}>{row.value}</div>
                </div>
              ))}
            </div>

            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 12, color: 'var(--text-dim)', marginBottom: 8, fontWeight: 600 }}>🛡 Đổi vai trò</div>
              <div style={{ display: 'flex', gap: 8 }}>
                {(['user', 'artist', 'admin'] as const).map(r => (
                  <button
                    key={r}
                    className={`btn btn-sm ${detailUser.role === r ? 'btn-primary' : 'btn-ghost'}`}
                    disabled={detailUser.role === r || processing === detailUser.uid}
                    onClick={() => handleSetRole(detailUser, r)}
                    style={{ flex: 1 }}
                  >
                    {r === 'user' ? '👤 User' : r === 'artist' ? '🎤 Artist' : '🛡 Admin'}
                  </button>
                ))}
              </div>
            </div>

            <div style={{ display: 'flex', gap: 8 }}>
              <button
                className={`btn btn-sm ${detailUser.status === 'banned' ? 'btn-success' : 'btn-danger'}`}
                style={{ flex: 1 }}
                disabled={processing === detailUser.uid}
                onClick={() => toggleBan(detailUser)}
              >
                {detailUser.status === 'banned' ? '🔓 Mở khóa' : '🔒 Khóa TK'}
              </button>
              <button
                className="btn btn-sm btn-danger"
                style={{ flex: 1, background: '#8b0000', color: '#fff' }}
                disabled={processing === detailUser.uid}
                onClick={() => handleDelete(detailUser)}
              >
                🗑 Xóa vĩnh viễn
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="page-header">
        <div>
          <h1 className="page-title">Quản lý Người dùng</h1>
          <p className="page-subtitle">Xem, phân quyền và kiểm soát tài khoản</p>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <span className="badge badge-user">{filtered.length}/{users.length}</span>
          <button
            className="btn btn-ghost btn-sm"
            disabled={users.length === 0}
            onClick={() => exportToCSV(users as unknown as Record<string, unknown>[], `danh-sach-nguoi-dung-${new Date().toLocaleDateString('vi-VN').replace(/\//g, '-')}.csv`, USER_COLUMNS)}
          >
            📥 Xuất CSV
          </button>
        </div>
      </div>

      {/* Role filter tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 16, background: 'var(--bg-card)', border: '1px solid var(--border-solid)', borderRadius: 10, padding: 4, width: 'fit-content' }}>
        {roleTabs.map(t => (
          <button
            key={t.key}
            onClick={() => setRoleFilter(t.key)}
            className={roleFilter === t.key ? 'btn btn-primary btn-sm' : 'btn btn-ghost btn-sm'}
            style={{ gap: 6 }}
          >
            {t.icon} {t.label}
            <span style={{ background: 'rgba(0,0,0,0.08)', borderRadius: 10, padding: '0 6px', fontSize: 11 }}>
              {t.key === 'all' ? users.length : users.filter(u => u.role === t.key).length}
            </span>
          </button>
        ))}
      </div>

      <div className="table-wrapper">
        <div className="table-toolbar">
          <span className="table-title">Danh sách người dùng</span>
          <input
            className="search-input"
            type="search"
            placeholder="Tìm kiếm email, tên hoặc UID…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        <table>
          <thead>
            <tr>
              <th>Người dùng</th>
              <th>Vai trò</th>
              <th>Trạng thái</th>
              <th>Ngày tạo</th>
              <th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={5} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)' }}>Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5}>
                <div className="empty-state"><div className="empty-state-icon">👥</div><div className="empty-state-text">Không tìm thấy người dùng</div></div>
              </td></tr>
            ) : (
              filtered.map(u => (
                <tr key={u.uid} style={{ cursor: 'pointer' }}>
                  <td onClick={() => setDetailUser(u)}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, fontWeight: 700, color: 'white', flexShrink: 0 }}>
                        {resolveInitial(u)}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, color: 'var(--text)', fontSize: 14 }}>{resolveName(u)}</div>
                        <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 1 }}>{u.email ?? '—'}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <select
                      value={u.role ?? 'user'}
                      onChange={e => handleSetRole(u, e.target.value as 'user' | 'artist' | 'admin')}
                      disabled={processing === u.uid}
                      style={{ background: 'var(--bg-sidebar)', border: '1px solid var(--border-solid)', borderRadius: 6, padding: '4px 8px', color: 'var(--text-main)', fontSize: 12, cursor: 'pointer' }}
                    >
                      <option value="user">👤 User</option>
                      <option value="artist">🎤 Artist</option>
                      <option value="admin">🛡 Admin</option>
                    </select>
                  </td>
                  <td>
                    <span className={`badge badge-${u.status === 'banned' ? 'banned' : 'active'}`}>
                      {u.status === 'banned' ? '🔒 Bị khóa' : '✓ Hoạt động'}
                    </span>
                  </td>
                  <td className="td-muted">{formatDate(u.createdAt)}</td>
                  <td>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button className="btn btn-ghost btn-sm" onClick={() => setDetailUser(u)} title="Xem chi tiết">👁</button>
                      <button
                        className={`btn btn-sm ${u.status === 'banned' ? 'btn-success' : 'btn-danger'}`}
                        style={{ fontSize: 11 }}
                        onClick={() => toggleBan(u)}
                        disabled={processing === u.uid}
                      >
                        {processing === u.uid ? '…' : u.status === 'banned' ? 'Mở' : 'Khóa'}
                      </button>
                      <button
                        className="btn btn-sm"
                        style={{ fontSize: 11, background: '#8b0000', color: '#fff' }}
                        onClick={() => handleDelete(u)}
                        disabled={processing === u.uid}
                        title="Xóa vĩnh viễn"
                      >
                        🗑
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
