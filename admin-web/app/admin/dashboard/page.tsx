'use client';
import { useEffect, useState } from 'react';
import { getDashboardCounts, getTopKeywords } from '@/lib/adminQueries';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

interface Counts { totalUsers: number; totalArtists: number; totalTracks: number; hiddenTracks: number; }
interface Keyword { keyword: string; count: number; }

export default function AdminDashboard() {
  const [counts, setCounts] = useState<Counts | null>(null);
  const [keywords, setKeywords] = useState<Keyword[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getDashboardCounts(), getTopKeywords(15)])
      .then(([c, kw]) => {
        setCounts(c as Counts);
        setKeywords(kw as Keyword[]);
      })
      .finally(() => setLoading(false));
  }, []);

  const stats = counts
    ? [
        { label: 'Tổng người dùng', value: counts.totalUsers, icon: '👥', color: 'var(--info)' },
        { label: 'Nghệ sĩ đã duyệt', value: counts.totalArtists, icon: '🎤', color: 'var(--primary)' },
        { label: 'Bài hát đã đăng', value: counts.totalTracks, icon: '🎵', color: 'var(--success)' },
        { label: 'Bài đang bị ẩn', value: counts.hiddenTracks, icon: '🚫', color: 'var(--warning)' },
      ]
    : [];

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Tổng quan hệ thống</h1>
          <p className="page-subtitle">Thống kê & báo cáo toàn nền tảng</p>
        </div>
        <div className="text-sm text-muted">
          Cập nhật: {new Date().toLocaleString('vi-VN')}
        </div>
      </div>

      {/* Stats */}
      <div className="stats-grid">
        {loading
          ? [1, 2, 3, 4].map(i => (
              <div key={i} className="stat-card">
                <div className="skeleton" style={{ height: 80 }} />
              </div>
            ))
          : stats.map(s => (
              <div className="stat-card" key={s.label}>
                <div className="stat-card-header">
                  <span className="stat-card-label">{s.label}</span>
                  <span className="stat-card-icon">{s.icon}</span>
                </div>
                <div className="stat-card-value" style={{ color: s.color }}>{s.value.toLocaleString()}</div>
              </div>
            ))}
      </div>

      {/* Keyword Chart */}
      <div className="chart-card">
        <div className="chart-title">🔍 Top từ khóa phong cảnh được AI phát hiện</div>
        {loading ? (
          <div className="skeleton" style={{ height: 260 }} />
        ) : keywords.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📷</div>
            <div className="empty-state-text">Chưa có dữ liệu từ khóa</div>
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={keywords} margin={{ top: 8, right: 16, left: -12, bottom: 40 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.06)" />
              <XAxis
                dataKey="keyword"
                tick={{ fill: '#b8afa5', fontSize: 11 }}
                angle={-35}
                textAnchor="end"
                interval={0}
              />
              <YAxis tick={{ fill: '#b8afa5', fontSize: 11 }} />
              <Tooltip
                contentStyle={{ background: '#221508', border: '1px solid rgba(228,135,68,0.25)', borderRadius: 8, fontSize: 13 }}
                labelStyle={{ color: '#f5f1ed', fontWeight: 600 }}
                itemStyle={{ color: '#e48744' }}
              />
              <Bar dataKey="count" fill="#e48744" radius={[4, 4, 0, 0]} name="Lượt xuất hiện" />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}
