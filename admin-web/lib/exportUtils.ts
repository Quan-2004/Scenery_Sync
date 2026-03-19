/**
 * Export utility — download data as CSV (no extra dependencies needed)
 */

type Row = Record<string, unknown>;

function formatCell(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'object' && 'seconds' in (value as Record<string, unknown>)) {
    // Firestore Timestamp
    return new Date(((value as { seconds: number }).seconds) * 1000).toLocaleDateString('vi-VN');
  }
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}

export function exportToCSV(rows: Row[], filename: string, columns?: { key: string; label: string }[]) {
  if (rows.length === 0) return;

  const cols = columns ?? Object.keys(rows[0]).map(k => ({ key: k, label: k }));
  const header = cols.map(c => `"${c.label}"`).join(',');
  const body = rows.map(row =>
    cols.map(c => {
      const val = formatCell(row[c.key]);
      // Escape double-quotes
      return `"${val.replace(/"/g, '""')}"`;
    }).join(',')
  ).join('\n');

  const bom = '\uFEFF'; // UTF-8 BOM for Excel to read Vietnamese correctly
  const csv = bom + header + '\n' + body;
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename.endsWith('.csv') ? filename : `${filename}.csv`;
  a.style.display = 'none';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// ── Column presets ──────────────────────────────────

export const USER_COLUMNS = [
  { key: 'uid', label: 'UID' },
  { key: 'displayName', label: 'Tên hiển thị' },
  { key: 'email', label: 'Email' },
  { key: 'role', label: 'Vai trò' },
  { key: 'status', label: 'Trạng thái' },
  { key: 'createdAt', label: 'Ngày tạo' },
];

export const ARTIST_COLUMNS = [
  { key: 'uid', label: 'UID' },
  { key: 'displayName', label: 'Tên nghệ sĩ' },
  { key: 'email', label: 'Email' },
  { key: 'companyName', label: 'Công ty / Hãng' },
  { key: 'artistVerified', label: 'Đã xác minh' },
];

export const TRACK_COLUMNS = [
  { key: 'id', label: 'ID' },
  { key: 'title', label: 'Tên bài hát' },
  { key: 'artistName', label: 'Nghệ sĩ' },
  { key: 'genre', label: 'Thể loại' },
  { key: 'status', label: 'Trạng thái' },
  { key: 'isHidden', label: 'Đang ẩn' },
  { key: 'playCount', label: 'Lượt nghe' },
  { key: 'favoriteCount', label: 'Yêu thích' },
  { key: 'sceneryMatchCount', label: 'Gợi ý AI' },
  { key: 'createdAt', label: 'Ngày tạo' },
];
