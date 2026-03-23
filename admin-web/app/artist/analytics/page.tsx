'use client';
import { useEffect, useState } from 'react';
import { useArtist } from '../context';
import { getMyAnalytics } from '@/lib/artistQueries';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

interface TrackStat {
  id: string;
  title: string;
  imageUrl: string;
  playCount: number;
  favoriteCount: number;
  sceneryMatchCount: number;
  isHidden: boolean;
  hiddenBy?: string;
}

interface Analytics {
  totalPlays: number;
  totalFavorites: number;
  totalScenery: number;
  tracks: TrackStat[];
}

export default function ArtistAnalyticsPage() {
  const user = useArtist();
  const [data, setData] = useState<Analytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user?.uid) return;
    getMyAnalytics(user.uid)
      .then(d => setData(d as Analytics))
      .finally(() => setLoading(false));
  }, [user]);

  const chartData = (data?.tracks ?? []).slice(0, 12).map(t => ({
    name: t.title.length > 18 ? t.title.slice(0, 16) + '…' : t.title,
    'Lượt nghe': t.playCount,
    'Gợi ý AI': t.sceneryMatchCount,
  }));

  const topByScenery = [...(data?.tracks ?? [])]
    .sort((a, b) => b.sceneryMatchCount - a.sceneryMatchCount)
    .slice(0, 5);

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Thống kê chi tiết</h1>
          <p className="page-subtitle">Phân tích hiệu suất và xu hướng các sáng tác của bạn</p>
        </div>
      </div>

      {/* Summary */}
      <div className="analytics-summary">
        {[
          { label: 'Tổng lượt nghe', value: data?.totalPlays ?? 0, icon: '▶️', c: 'var(--primary)' },
          { label: 'Gợi ý bởi AI', value: data?.totalScenery ?? 0, icon: '🔍', c: 'var(--info)' },
          { label: 'Tổng sáng tác', value: data?.tracks.length ?? 0, icon: '🎵', c: 'var(--success)' },
        ].map(s => (
          <div key={s.label} className="stat-card">
            {loading ? (
              <div className="skeleton" style={{ height: 60 }} />
            ) : (
              <>
                <div className="stat-card-header">
                  <span className="stat-card-label">{s.label}</span>
                  <span>{s.icon}</span>
                </div>
                <div className="stat-card-value" style={{ color: s.c, fontSize: 24 }}>
                  {s.value.toLocaleString()}
                </div>
              </>
            )}
          </div>
        ))}
      </div>

      {/* Full chart */}
      <div className="chart-card">
        <div className="chart-title">📊 So sánh chỉ số theo bài hát</div>
        {loading ? (
          <div className="skeleton" style={{ height: 310 }} />
        ) : chartData.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📈</div>
            <div className="empty-state-text">Chưa có dữ liệu. Upload bài hát để xem thống kê!</div>
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={320}>
            <BarChart data={chartData} margin={{ top: 8, right: 16, left: -12, bottom: 68 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.06)" />
              <XAxis dataKey="name" tick={{ fill: '#b8afa5', fontSize: 11 }} angle={-35} textAnchor="end" interval={0} />
              <YAxis tick={{ fill: '#b8afa5', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#221508', border: '1px solid rgba(228,135,68,0.25)', borderRadius: 8, fontSize: 13 }}
                labelStyle={{ color: '#f5f1ed', fontWeight: 600 }}
              />
              <Legend iconType="circle" wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
              <Bar dataKey="Lượt nghe" fill="#e48744" radius={[4, 4, 0, 0]} />
              <Bar dataKey="Gợi ý AI" fill="#5bc0eb" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>

      {/* Top by scenery match */}
      <div className="chart-card">
        <div className="chart-title">🌄 Bài hát được AI gợi ý nhiều nhất (Scenery Match)</div>
        <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 16 }}>
          Đây là những bài hát mà AI của Scenery Sync thường chọn để gợi ý khi người dùng chụp ảnh phong cảnh.
        </p>
        {loading ? (
          <div className="skeleton" style={{ height: 200 }} />
        ) : topByScenery.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📷</div>
            <div className="empty-state-text">Chưa có dữ liệu gợi ý AI</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {topByScenery.map((t, i) => (
              <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '10px 14px', background: 'var(--bg-surface)', borderRadius: 10 }}>
                <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--primary)', width: 24, textAlign: 'center' }}>#{i + 1}</span>
                <div
                  style={{ width: 40, height: 40, borderRadius: 8, background: 'var(--primary-medium)', backgroundImage: t.imageUrl ? `url(${t.imageUrl})` : undefined, backgroundSize: 'cover', flexShrink: 0 }}
                />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 600, fontSize: 14, overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis' }}>{t.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>
                    🔍 {t.sceneryMatchCount.toLocaleString()} lần được AI gợi ý
                  </div>
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-dim)' }}>
                  ▶ {t.playCount.toLocaleString()}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
