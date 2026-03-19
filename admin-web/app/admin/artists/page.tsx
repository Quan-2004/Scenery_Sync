'use client';
import { useEffect, useState } from 'react';
import {
  getPendingArtistRequests,
  getAllArtists,
  approveArtist,
  revokeArtist,
} from '@/lib/adminQueries';

interface ArtistRequest {
  uid: string;
  artistName?: string;
  email?: string;
  companyName?: string;
  bio?: string;
  status?: string;
  createdAt?: { seconds: number };
}
interface Artist {
  uid: string;
  displayName?: string;
  email?: string;
  companyName?: string;
  artistVerified?: boolean;
  createdAt?: { seconds: number };
}

export default function AdminArtistsPage() {
  const [pending, setPending] = useState<ArtistRequest[]>([]);
  const [artists, setArtists] = useState<Artist[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<'pending' | 'active'>('pending');
  const [processing, setProcessing] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([getPendingArtistRequests(), getAllArtists()]).then(([p, a]) => {
      setPending(p as ArtistRequest[]);
      setArtists(a as Artist[]);
      setLoading(false);
    });
  }, []);

  async function handleApprove(uid: string) {
    setProcessing(uid);
    try {
      await approveArtist(uid);
      setPending(prev => prev.filter(r => r.uid !== uid));
    } finally {
      setProcessing(null);
    }
  }

  async function handleRevoke(uid: string) {
    if (!confirm('Bạn có chắc muốn thu hồi quyền nghệ sĩ?')) return;
    setProcessing(uid);
    try {
      await revokeArtist(uid);
      setArtists(prev => prev.filter(a => a.uid !== uid));
    } finally {
      setProcessing(null);
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản lý Nghệ sĩ / Công ty</h1>
          <p className="page-subtitle">Duyệt yêu cầu và quản lý tài khoản nghệ sĩ đã được xác nhận</p>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        <button
          className={`btn ${tab === 'pending' ? 'btn-primary' : 'btn-ghost'}`}
          onClick={() => setTab('pending')}
        >
          Chờ duyệt
          {pending.length > 0 && (
            <span style={{ background: 'rgba(0,0,0,0.25)', borderRadius: 99, padding: '1px 7px', fontSize: 11, marginLeft: 4 }}>
              {pending.length}
            </span>
          )}
        </button>
        <button
          className={`btn ${tab === 'active' ? 'btn-primary' : 'btn-ghost'}`}
          onClick={() => setTab('active')}
        >
          Đã duyệt ({artists.length})
        </button>
      </div>

      {tab === 'pending' && (
        <div className="table-wrapper">
          <div className="table-toolbar">
            <span className="table-title">Yêu cầu đăng ký nghệ sĩ</span>
          </div>
          <table>
            <thead>
              <tr>
                <th>Nghệ sĩ / Công ty</th>
                <th>Email</th>
                <th>Bio</th>
                <th>Ngày gửi</th>
                <th>Hành động</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={5} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)' }}>Đang tải…</td></tr>
              ) : pending.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">
                      <div className="empty-state-icon">✅</div>
                      <div className="empty-state-text">Không có yêu cầu chờ duyệt</div>
                    </div>
                  </td>
                </tr>
              ) : (
                pending.map(r => (
                  <tr key={r.uid}>
                    <td className="td-name">{r.artistName ?? r.uid.slice(0, 8)}{r.companyName ? ` (${r.companyName})` : ''}</td>
                    <td className="td-muted">{r.email ?? '—'}</td>
                    <td className="td-muted" style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{r.bio || '—'}</td>
                    <td className="td-muted">{r.createdAt ? new Date(r.createdAt.seconds * 1000).toLocaleDateString('vi-VN') : '—'}</td>
                    <td>
                      <button
                        className="btn btn-sm btn-success"
                        onClick={() => handleApprove(r.uid)}
                        disabled={processing === r.uid}
                      >
                        {processing === r.uid ? '…' : '✓ Duyệt'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {tab === 'active' && (
        <div className="table-wrapper">
          <div className="table-toolbar">
            <span className="table-title">Nghệ sĩ đang hoạt động</span>
          </div>
          <table>
            <thead>
              <tr>
                <th>Tên nghệ sĩ</th>
                <th>Email</th>
                <th>Công ty / Hãng</th>
                <th>Xác minh</th>
                <th>Hành động</th>
              </tr>
            </thead>
            <tbody>
              {artists.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    <div className="empty-state">
                      <div className="empty-state-icon">🎤</div>
                      <div className="empty-state-text">Chưa có nghệ sĩ nào</div>
                    </div>
                  </td>
                </tr>
              ) : (
                artists.map(a => (
                  <tr key={a.uid}>
                    <td className="td-name">{a.displayName ?? a.uid.slice(0, 8)}</td>
                    <td className="td-muted">{a.email ?? '—'}</td>
                    <td className="td-muted">{(a as { companyName?: string }).companyName || '—'}</td>
                    <td>
                      <span className={`badge ${a.artistVerified ? 'badge-active' : 'badge-pending'}`}>
                        {a.artistVerified ? '✓ Xác minh' : 'Chưa xác minh'}
                      </span>
                    </td>
                    <td>
                      <button
                        className="btn btn-sm btn-danger"
                        onClick={() => handleRevoke(a.uid)}
                        disabled={processing === a.uid}
                      >
                        {processing === a.uid ? '…' : 'Thu hồi'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
