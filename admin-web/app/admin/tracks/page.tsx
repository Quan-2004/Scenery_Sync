'use client';
import { useEffect, useState } from 'react';
import { getAllTracks, hideTrack, unhideTrack } from '@/lib/adminQueries';
import { exportToCSV, TRACK_COLUMNS } from '@/lib/exportUtils';

interface TrackRow {
  id: string;
  title?: string;
  name?: string;
  artistName?: string;
  artist?: string;
  ownerName?: string;
  imageUrl?: string;
  artworkUrl?: string;
  status?: string;
  isHidden?: boolean;
  hiddenBy?: string;
  genre?: string;
  stats?: { playCount?: number; favoriteCount?: number; sceneryMatchCount?: number };
  createdAt?: { seconds: number };
}

export default function AdminTracksPage() {
  const [tracks, setTracks] = useState<TrackRow[]>([]);
  const [filtered, setFiltered] = useState<TrackRow[]>([]);
  const [search, setSearch] = useState('');
  const [filterHidden, setFilterHidden] = useState<'all' | 'visible' | 'hidden'>('all');
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);

  useEffect(() => {
    getAllTracks().then(data => {
      setTracks(data as TrackRow[]);
      setLoading(false);
    });
  }, []);

  useEffect(() => {
    const q = search.toLowerCase();
    setFiltered(
      tracks.filter(t => {
        const matchSearch =
          (t.title ?? t.name ?? '').toLowerCase().includes(q) ||
          (t.artistName ?? t.artist ?? '').toLowerCase().includes(q);
        const matchHidden =
          filterHidden === 'all' ||
          (filterHidden === 'hidden' && t.isHidden) ||
          (filterHidden === 'visible' && !t.isHidden);
        return matchSearch && matchHidden;
      }),
    );
  }, [search, tracks, filterHidden]);

  async function toggleHide(track: TrackRow) {
    setProcessing(track.id);
    try {
      if (track.isHidden) {
        await unhideTrack(track.id);
      } else {
        await hideTrack(track.id);
      }
      setTracks(prev =>
        prev.map(t => (t.id === track.id ? { ...t, isHidden: !t.isHidden, hiddenBy: t.isHidden ? undefined : 'admin' } : t)),
      );
    } finally {
      setProcessing(null);
    }
  }

  const title = (t: TrackRow) => t.title ?? t.name ?? 'Không có tên';
  const artist = (t: TrackRow) => t.artistName ?? t.artist ?? t.ownerName ?? '—';
  const cover = (t: TrackRow) => t.imageUrl ?? t.artworkUrl ?? '';

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản lý Bài hát</h1>
          <p className="page-subtitle">Xem metadata và tạm ẩn bài hát vi phạm</p>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <span className="badge badge-draft">{filtered.length} bài</span>
          <button
            className="btn btn-ghost btn-sm"
            disabled={tracks.length === 0}
            onClick={() => {
              const rows = tracks.map(t => ({
                ...t,
                playCount: (t.stats as Record<string, number>)?.playCount ?? 0,
                favoriteCount: (t.stats as Record<string, number>)?.favoriteCount ?? 0,
                sceneryMatchCount: (t.stats as Record<string, number>)?.sceneryMatchCount ?? 0,
                title: t.title ?? t.name,
                artistName: t.artistName ?? t.artist ?? t.ownerName,
              }));
              exportToCSV(rows as Record<string, unknown>[], `danh-sach-bai-hat-${new Date().toLocaleDateString('vi-VN').replace(/\//g, '-')}.csv`, TRACK_COLUMNS);
            }}
          >
            📥 Xuất CSV
          </button>
        </div>
      </div>

      <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border-solid)', borderRadius: 'var(--radius)', padding: '4px 4px 0', marginBottom: 16, display: 'inline-flex', gap: 4 }}>
        {(['all', 'visible', 'hidden'] as const).map(f => (
          <button
            key={f}
            className={`btn btn-sm ${filterHidden === f ? 'btn-primary' : 'btn-ghost'}`}
            style={{ border: 'none' }}
            onClick={() => setFilterHidden(f)}
          >
            {f === 'all' ? 'Tất cả' : f === 'visible' ? 'Đang hiển thị' : 'Đang ẩn'}
          </button>
        ))}
      </div>

      <div className="table-wrapper">
        <div className="table-toolbar">
          <span className="table-title">Danh sách bài hát</span>
          <input
            className="search-input"
            type="search"
            placeholder="Tìm theo tên bài, nghệ sĩ…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        <table>
          <thead>
            <tr>
              <th style={{ width: 48 }} />
              <th>Bài hát</th>
              <th>Nghệ sĩ</th>
              <th>Thể loại</th>
              <th>▶ Lượt nghe</th>
              <th>🔍 Gợi ý AI</th>
              <th>Trạng thái</th>
              <th>Hành động</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={8} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)' }}>Đang tải…</td></tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={8}>
                  <div className="empty-state">
                    <div className="empty-state-icon">🎵</div>
                    <div className="empty-state-text">Không tìm thấy bài hát</div>
                  </div>
                </td>
              </tr>
            ) : (
              filtered.map(t => (
                <tr key={t.id} style={{ opacity: t.isHidden ? 0.6 : 1 }}>
                  <td>
                    <div style={{ width: 40, height: 40, borderRadius: 6, background: 'var(--primary-medium)', backgroundImage: cover(t) ? `url(${cover(t)})` : undefined, backgroundSize: 'cover', backgroundPosition: 'center', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>
                      {!cover(t) && '🎵'}
                    </div>
                  </td>
                  <td className="td-name" style={{ maxWidth: 200, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{title(t)}</td>
                  <td className="td-muted">{artist(t)}</td>
                  <td className="td-muted">{t.genre ?? '—'}</td>
                  <td className="td-muted">{(t.stats?.playCount ?? 0).toLocaleString()}</td>
                  <td className="td-muted">{(t.stats?.sceneryMatchCount ?? 0).toLocaleString()}</td>
                  <td>
                    {t.isHidden ? (
                      <span className="badge badge-hidden">
                        🚫 Ẩn{t.hiddenBy === 'admin' ? ' (Admin)' : ''}
                      </span>
                    ) : (
                      <span className="badge badge-active">✓ Hiển thị</span>
                    )}
                  </td>
                  <td>
                    <button
                      className={`btn btn-sm ${t.isHidden ? 'btn-success' : 'btn-danger'}`}
                      onClick={() => toggleHide(t)}
                      disabled={processing === t.id}
                    >
                      {processing === t.id ? '…' : t.isHidden ? 'Bỏ ẩn' : 'Tạm ẩn'}
                    </button>
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
