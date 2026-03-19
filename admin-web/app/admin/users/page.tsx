'use client';
import { useEffect, useState } from 'react';
import { getAllUsers, banUser, unbanUser } from '@/lib/adminQueries';

interface UserRow {
  uid: string;
  email?: string;
  displayName?: string;
  role?: string;
  status?: string;
  createdAt?: { seconds: number };
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [filtered, setFiltered] = useState<UserRow[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);

  useEffect(() => {
    getAllUsers().then(data => {
      setUsers(data as UserRow[]);
      setFiltered(data as UserRow[]);
      setLoading(false);
    });
  }, []);

  useEffect(() => {
    const q = search.toLowerCase();
    setFiltered(
      users.filter(u =>
        (u.email ?? '').toLowerCase().includes(q) ||
        (u.displayName ?? '').toLowerCase().includes(q),
      ),
    );
  }, [search, users]);

  async function toggleBan(user: UserRow) {
    setProcessing(user.uid);
    try {
      if (user.status === 'banned') {
        await unbanUser(user.uid);
      } else {
        await banUser(user.uid);
      }
      setUsers(prev =>
        prev.map(u =>
          u.uid === user.uid
            ? { ...u, status: u.status === 'banned' ? 'active' : 'banned' }
            : u,
        ),
      );
    } finally {
      setProcessing(null);
    }
  }

  function formatDate(ts?: { seconds: number }) {
    if (!ts) return '—';
    return new Date(ts.seconds * 1000).toLocaleDateString('vi-VN');
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản lý Người dùng</h1>
          <p className="page-subtitle">Xem và kiểm soát tài khoản người dùng</p>
        </div>
        <span className="badge badge-user">{filtered.length} users</span>
      </div>

      <div className="table-wrapper">
        <div className="table-toolbar">
          <span className="table-title">Danh sách người dùng</span>
          <input
            className="search-input"
            type="search"
            placeholder="Tìm kiếm email hoặc tên…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        <table>
          <thead>
            <tr>
              <th>Người dùng</th>
              <th>Email</th>
              <th>Vai trò</th>
              <th>Trạng thái</th>
              <th>Ngày tạo</th>
              <th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)' }}>
                  Đang tải…
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={6}>
                  <div className="empty-state">
                    <div className="empty-state-icon">👥</div>
                    <div className="empty-state-text">Không tìm thấy người dùng</div>
                  </div>
                </td>
              </tr>
            ) : (
              filtered.map(u => (
                <tr key={u.uid}>
                  <td className="td-name">
                    {u.displayName || (u.email?.split('@')[0]) || u.uid.slice(0, 8)}
                  </td>
                  <td className="td-muted">{u.email ?? '—'}</td>
                  <td>
                    <span className={`badge badge-${u.role ?? 'user'}`}>
                      {u.role ?? 'user'}
                    </span>
                  </td>
                  <td>
                    <span className={`badge badge-${u.status === 'banned' ? 'banned' : 'active'}`}>
                      {u.status === 'banned' ? '🔒 Bị khóa' : '✓ Hoạt động'}
                    </span>
                  </td>
                  <td className="td-muted">{formatDate(u.createdAt)}</td>
                  <td>
                    {(u.role ?? 'user') !== 'admin' && (
                      <button
                        className={`btn btn-sm ${u.status === 'banned' ? 'btn-success' : 'btn-danger'}`}
                        onClick={() => toggleBan(u)}
                        disabled={processing === u.uid}
                      >
                        {processing === u.uid
                          ? '…'
                          : u.status === 'banned'
                          ? 'Mở khóa'
                          : 'Khóa'}
                      </button>
                    )}
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
