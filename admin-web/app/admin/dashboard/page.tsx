'use client';
import { useEffect, useState } from 'react';
import { getDashboardCounts, getTopKeywords, getTopTracks, getTopArtists } from '@/lib/adminQueries';
import { exportToCSV } from '@/lib/exportUtils';
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
} from 'recharts';

interface Counts {
  totalUsers: number; totalArtists: number; totalTracks: number;
  bannedUsers: number; hiddenTracks: number; pendingArtists: number;
}
interface Keyword { keyword: string; count: number; }
interface TopTrack {
  id: string; title: string; artistName: string;
  playCount: number; favoriteCount: number; sceneryMatchCount: number;
  isHidden: boolean;
}

interface TopArtist { name: string; playCount: number; trackCount: number; favoriteCount: number; }

export default function AdminDashboard() {
  const [counts, setCounts]     = useState<Counts | null>(null);
  const [keywords, setKeywords] = useState<Keyword[]>([]);
  const [topTracks, setTopTracks]   = useState<TopTrack[]>([]);
  const [topArtists, setTopArtists] = useState<TopArtist[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getDashboardCounts(), getTopKeywords(15), getTopTracks(10), getTopArtists(10)])
      .then(([c, kw, tt, ta]) => {
        setCounts(c as Counts);
        setKeywords(kw as Keyword[]);
        setTopTracks(tt as TopTrack[]);
        setTopArtists(ta as TopArtist[]);
      })
      .finally(() => setLoading(false));
  }, []);

  const stats = counts
    ? [
        { label: 'Tổng người dùng', value: counts.totalUsers, icon: '👥', color: 'var(--info)' },
        { label: 'Nghệ sĩ đã duyệt', value: counts.totalArtists, icon: '🎤', color: 'var(--primary)' },
        { label: 'Yêu cầu chờ duyệt', value: counts.pendingArtists, icon: '⏳', color: 'var(--warning)' },
        { label: 'Tổng bài hát', value: counts.totalTracks, icon: '🎵', color: 'var(--success)' },
        { label: 'Bài đang bị ẩn', value: counts.hiddenTracks, icon: '🚫', color: 'var(--error)' },
        { label: 'Tài khoản bị khóa', value: counts.bannedUsers, icon: '🔒', color: '#ff8c5c' },
      ]
    : [];

  function exportReport() {
    const rows = [
      { 'Chỉ số': 'Tổng người dùng', 'Giá trị': counts?.totalUsers ?? 0 },
      { 'Chỉ số': 'Nghệ sĩ đã duyệt', 'Giá trị': counts?.totalArtists ?? 0 },
      { 'Chỉ số': 'Yêu cầu chờ duyệt', 'Giá trị': counts?.pendingArtists ?? 0 },
      { 'Chỉ số': 'Tổng bài hát', 'Giá trị': counts?.totalTracks ?? 0 },
      { 'Chỉ số': 'Bài đang bị ẩn', 'Giá trị': counts?.hiddenTracks ?? 0 },
      { 'Chỉ số': 'Tài khoản bị khoá', 'Giá trị': counts?.bannedUsers ?? 0 },
    ];
    exportToCSV(rows, `bao-cao-tong-quan-${new Date().toLocaleDateString('vi-VN').replace(/\//g, '-')}.csv`);
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Tổng quan hệ thống</h1>
          <p className="page-subtitle">Thống kê & báo cáo toàn nền tảng — {new Date().toLocaleString('vi-VN')}</p>
        </div>
        <button className="btn btn-ghost" onClick={exportReport} disabled={!counts}>
          📥 Xuất báo cáo CSV
        </button>
      </div>

      {/* 6 Stats */}
      <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))' }}>
        {loading
          ? [1, 2, 3, 4, 5, 6].map(i => (
              <div key={i} className="stat-card"><div className="skeleton" style={{ height: 80 }} /></div>
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

      {/* Keyword Pie Chart */}
      <div className="chart-card">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <div className="chart-title" style={{ marginBottom: 0 }}>🔍 Top từ khóa phong cảnh AI phát hiện</div>
          {keywords.length > 0 && (
            <button className="btn btn-ghost btn-sm" onClick={() => exportToCSV(keywords as unknown as Record<string, unknown>[], 'tu-khoa-scenery.csv')}>
              📥 CSV
            </button>
          )}
        </div>
        {loading ? (
          <div className="skeleton" style={{ height: 300 }} />
        ) : keywords.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📷</div>
            <div className="empty-state-text">Chưa có dữ liệu từ khóa</div>
          </div>
        ) : (
          <div>
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={keywords.slice(0, 10)}
                  dataKey="count"
                  nameKey="keyword"
                  cx="50%"
                  cy="50%"
                  outerRadius={110}
                  innerRadius={55}
                  paddingAngle={3}
                >
                  {keywords.slice(0, 10).map((_, i) => (
                    <Cell
                      key={i}
                      fill={[
                        '#e48744','#f5c469','#7ecfa0','#5ba4cf','#c377e0',
                        '#ff7c7c','#4ecdc4','#ffa07a','#98fb98','#dda0dd',
                      ][i % 10]}
                    />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ background: '#ffffff', border: '1px solid #e5ddd6', borderRadius: 8, fontSize: 13, boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                  labelStyle={{ color: '#1a1207', fontWeight: 600 }}
                  itemStyle={{ color: '#d4722a' }}
                  formatter={(value: number, name: string) => [`${value} lần`, name]}
                />
              </PieChart>
            </ResponsiveContainer>
            {/* Custom legend */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: '8px 16px', marginTop: 8 }}>
              {keywords.slice(0, 10).map((kw, i) => (
                <div key={kw.keyword} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 10, height: 10, borderRadius: '50%', flexShrink: 0, background: [
                    '#e48744','#f5c469','#7ecfa0','#5ba4cf','#c377e0',
                    '#ff7c7c','#4ecdc4','#ffa07a','#98fb98','#dda0dd',
                  ][i % 10] }} />
                  <span style={{ fontSize: 12, color: 'var(--text)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{kw.keyword}</span>
                  <span style={{ fontSize: 12, color: 'var(--primary)', fontWeight: 600, marginLeft: 'auto', flexShrink: 0 }}>{kw.count}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Top Artists / Companies */}
      <div className="table-wrapper">
        <div className="table-toolbar">
          <span className="table-title">🎤 Top nghệ sĩ / công ty theo lượt nghe</span>
          {topArtists.length > 0 && (
            <button className="btn btn-ghost btn-sm" onClick={() =>
              exportToCSV(
                topArtists.map((a, i) => ({
                  '#': i + 1, 'Nghệ sĩ / Công ty': a.name,
                  'Lượt nghe': a.playCount, 'Yêu thích': a.favoriteCount, 'Số bài': a.trackCount,
                })),
                'top-nghe-si.csv'
              )}>
              📥 CSV
            </button>
          )}
        </div>

        {loading ? (
          <div className="skeleton" style={{ height: 200 }} />
        ) : topArtists.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">🎤</div>
            <div className="empty-state-text">Chưa có dữ liệu nghệ sĩ</div>
          </div>
        ) : (
            <table style={{ marginTop: 0 }}>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Nghệ sĩ / Công ty</th>
                  <th>▶ Lượt nghe</th>
                  <th>❤️ Yêu thích</th>
                  <th>🎵 Số bài</th>
                </tr>
              </thead>
              <tbody>
                {topArtists.map((a, i) => (
                  <tr key={a.name}>
                    <td style={{ fontWeight: 700, color: i < 3 ? 'var(--primary)' : 'var(--text-dim)', fontSize: 14 }}>
                      {i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : `#${i + 1}`}
                    </td>
                    <td className="td-name">{a.name}</td>
                    <td style={{ fontWeight: 600 }}>{a.playCount.toLocaleString()}</td>
                    <td className="td-muted">{a.favoriteCount.toLocaleString()}</td>
                    <td className="td-muted">{a.trackCount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
        )}
      </div>

      {/* Top Tracks Table */}
      <div className="table-wrapper">
        <div className="table-toolbar">
          <span className="table-title">🔥 Top 10 bài hát được nghe nhiều nhất</span>
          {topTracks.length > 0 && (
            <button className="btn btn-ghost btn-sm" onClick={() =>
              exportToCSV(
                topTracks.map(t => ({
                  'Tên bài': t.title, 'Nghệ sĩ': t.artistName,
                  'Lượt nghe': t.playCount, 'Yêu thích': t.favoriteCount,
                  'Gợi ý AI': t.sceneryMatchCount, 'Bị ẩn': t.isHidden ? 'Có' : 'Không',
                })),
                'top-bai-hat.csv'
              )}>
              📥 CSV
            </button>
          )}
        </div>
        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Tên bài hát</th>
              <th>Nghệ sĩ</th>
              <th>▶ Lượt nghe</th>
              <th>❤️ Yêu thích</th>
              <th>🔍 Gợi ý AI</th>
              <th>Trạng thái</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ padding: 32, textAlign: 'center', color: 'var(--text-muted)' }}>Đang tải…</td></tr>
            ) : topTracks.length === 0 ? (
              <tr><td colSpan={7}><div className="empty-state"><div className="empty-state-icon">🎵</div><div className="empty-state-text">Chưa có dữ liệu</div></div></td></tr>
            ) : (
              topTracks.map((t, i) => (
                <tr key={t.id}>
                  <td style={{ fontWeight: 700, color: i < 3 ? 'var(--primary)' : 'var(--text-dim)', fontSize: 14 }}>
                    {i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : `#${i + 1}`}
                  </td>
                  <td className="td-name">{t.title}</td>
                  <td className="td-muted">{t.artistName}</td>
                  <td style={{ fontWeight: 600 }}>{t.playCount.toLocaleString()}</td>
                  <td className="td-muted">{t.favoriteCount.toLocaleString()}</td>
                  <td className="td-muted">{t.sceneryMatchCount.toLocaleString()}</td>
                  <td>
                    {t.isHidden
                      ? <span className="badge badge-hidden">🚫 Ẩn</span>
                      : <span className="badge badge-active">✓ Hiển thị</span>}
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
