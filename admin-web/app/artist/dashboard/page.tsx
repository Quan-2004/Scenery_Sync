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

export default function ArtistDashboardPage() {
  const user = useArtist();
  const [data, setData] = useState<Analytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user?.uid) return;
    getMyAnalytics(user.uid)
      .then(d => setData(d as Analytics))
      .finally(() => setLoading(false));
  }, [user]);

  const topTracks = data?.tracks.slice(0, 10) ?? [];

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Xin chào, {user?.displayName ?? 'Nghệ sĩ'} 👋</h1>
          <p className="page-subtitle">Tổng quan hiệu suất các sáng tác của bạn</p>
        </div>
      </div>

      {/* Summary stats */}
      <div className="stats-grid">
        {[
          { label: 'Tổng lượt nghe', value: data?.totalPlays ?? 0, icon: '▶️', color: 'var(--primary)' },
          { label: 'Tổng lượt yêu thích', value: data?.totalFavorites ?? 0, icon: '❤️', color: '#ff5c8a' },
          { label: 'Gợi ý AI (Scenery)', value: data?.totalScenery ?? 0, icon: '🔍', color: 'var(--info)' },
          { label: 'Tổng sáng tác', value: data?.tracks.length ?? 0, icon: '🎵', color: 'var(--success)' },
        ].map(s => (
          <div className="stat-card" key={s.label}>
            {loading ? (
              <div className="skeleton" style={{ height: 72 }} />
            ) : (
              <>
                <div className="stat-card-header">
                  <span className="stat-card-label">{s.label}</span>
                  <span className="stat-card-icon">{s.icon}</span>
                </div>
                <div className="stat-card-value" style={{ color: s.color }}>
                  {s.value.toLocaleString()}
                </div>
              </>
            )}
          </div>
        ))}
      </div>

      {/* Top tracks chart */}
      <div className="chart-card">
        <div className="chart-title">🔥 Bài hát theo lượt nghe (Top 10)</div>
        {loading ? (
          <div className="skeleton" style={{ height: 260 }} />
        ) : topTracks.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">🎵</div>
            <div className="empty-state-text">Chưa có dữ liệu thống kê</div>
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={topTracks} margin={{ top: 8, right: 16, left: -12, bottom: 60 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.06)" />
              <XAxis
                dataKey="title"
                tick={{ fill: '#b8afa5', fontSize: 11 }}
                angle={-35}
                textAnchor="end"
                interval={0}
              />
              <YAxis tick={{ fill: '#b8afa5', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#221508', border: '1px solid rgba(228,135,68,0.25)', borderRadius: 8, fontSize: 13 }}
                labelStyle={{ color: '#f5f1ed', fontWeight: 600 }}
              />
              <Bar dataKey="playCount" fill="#e48744" radius={[4, 4, 0, 0]} name="Lượt nghe" />
              <Bar dataKey="sceneryMatchCount" fill="#5bc0eb" radius={[4, 4, 0, 0]} name="Gợi ý AI" />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}
