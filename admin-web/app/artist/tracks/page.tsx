'use client';
import { useEffect, useState, useRef } from 'react';
import { useArtist } from '../context';
import { getMyTracks, hideMyTrack, unhideMyTrack, createTrack } from '@/lib/artistQueries';

interface Track {
  id: string;
  title?: string;
  name?: string;
  genre?: string;
  status?: string;
  isHidden?: boolean;
  hiddenBy?: string;
  imageUrl?: string;
  artworkUrl?: string;
  audioUrl?: string;
  stats?: { playCount?: number; favoriteCount?: number; sceneryMatchCount?: number };
}

const CLOUDINARY_CLOUD = 'dvcebine7';
const AUDIO_PRESET = 'scenery_upload';
const COVER_PRESET = 'scenery_upload';

async function cloudinaryUpload(file: File, preset: string, resourceType = 'auto'): Promise<string> {
  const form = new FormData();
  form.append('file', file);
  form.append('upload_preset', preset);
  const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/${resourceType}/upload`, {
    method: 'POST', body: form,
  });
  const json = await res.json();
  if (!res.ok || !json.secure_url) {
    const apiMessage = json?.error?.message;
    const fallback = `Upload failed (HTTP ${res.status})`;
    throw new Error(typeof apiMessage === 'string' && apiMessage.trim() ? apiMessage : fallback);
  }
  return json.secure_url as string;
}

const GENRE_OPTIONS = [
  'Pop', 'Ballad', 'R&B', 'Hip-hop', 'Rap', 'Rock', 'Indie',
  'Acoustic', 'Electronic', 'EDM', 'Jazz', 'Classical', 'Folk',
  'Country', 'Lo-fi', 'OST', 'Bolero', 'Dân ca', 'Khác',
];

export default function ArtistTracksPage() {
  const user = useArtist();
  const [tracks, setTracks] = useState<Track[]>([]);
  const [loading, setLoading] = useState(true);
  const [showUpload, setShowUpload] = useState(false);
  const [processing, setProcessing] = useState<string | null>(null);

  // Upload form state
  const [title, setTitle]             = useState('');
  const [genre, setGenre]             = useState('');
  const [customGenre, setCustomGenre] = useState('');
  const [description, setDescription] = useState('');
  const [releaseYear, setReleaseYear] = useState(new Date().getFullYear().toString());
  const [language, setLanguage]       = useState('Tiếng Việt');
  const [tags, setTags]               = useState('');
  const [lyrics, setLyrics]           = useState('');
  const [lyricsMode, setLyricsMode]   = useState<'plain' | 'synced'>('plain');
  const [audioFile, setAudioFile]     = useState<File | null>(null);
  const [audioPreview, setAudioPreview] = useState('');
  const [coverFile, setCoverFile]     = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState('');
  const [uploading, setUploading]     = useState<string>(''); // step description
  const [uploadError, setUploadError] = useState('');
  const audioRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!user?.uid) return;
    getMyTracks(user.uid)
      .then(d => setTracks(d as Track[]))
      .finally(() => setLoading(false));
  }, [user]);

  function handleCoverChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    setCoverFile(file);
    if (file) {
      const url = URL.createObjectURL(file);
      setCoverPreview(url);
    } else {
      setCoverPreview('');
    }
  }

  function handleAudioChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    setAudioFile(file);
    if (file) {
      const url = URL.createObjectURL(file);
      setAudioPreview(url);
    } else {
      setAudioPreview('');
    }
  }

  function handleLrcUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (ev) => {
      const content = ev.target?.result;
      if (typeof content === 'string') {
        setLyrics(content);
        setLyricsMode('synced');
      }
    };
    reader.readAsText(file);
    // Reset to allow re-upload if needed
    e.target.value = '';
  }

  async function handleUpload(e: React.FormEvent) {
    e.preventDefault();
    if (!audioFile || !title || !user?.uid) return;
    setUploading('Đang upload file nhạc…');
    setUploadError('');

    try {
      const audioUrl = await cloudinaryUpload(audioFile, AUDIO_PRESET, 'auto');
      let coverUrl = '';
      if (coverFile) {
        setUploading('Đang upload ảnh bìa…');
        coverUrl = await cloudinaryUpload(coverFile, COVER_PRESET, 'image');
      }
      setUploading('Đang lưu thông tin…');

      const finalGenre = genre === 'Khác' ? customGenre : genre;

      const ref = await createTrack({
        title,
        name: title,
        artist: user.displayName ?? '',
        artistName: user.displayName ?? '',
        ownerName: user.displayName ?? '',
        ownerId: user.uid,
        audioUrl,
        previewUrl: audioUrl,
        imageUrl: coverUrl,
        artworkUrl: coverUrl,
        genre: finalGenre,
        description,
        releaseYear: parseInt(releaseYear) || new Date().getFullYear(),
        language,
        tags: tags.split(',').map(t => t.trim()).filter(Boolean),
        lyrics,
        lyricsMode,
        status: 'published',
        isHidden: false,
        isPublic: true,
        stats: { playCount: 0, favoriteCount: 0, sceneryMatchCount: 0 },
      });

      setTracks(prev => [{
        id: ref.id, title, name: title, genre: finalGenre, status: 'published',
        isHidden: false, imageUrl: coverUrl, audioUrl,
        stats: { playCount: 0, favoriteCount: 0, sceneryMatchCount: 0 },
      }, ...prev]);

      // Reset
      setTitle(''); setGenre(''); setCustomGenre(''); setDescription('');
      setReleaseYear(new Date().getFullYear().toString()); setLanguage('Tiếng Việt');
      setTags(''); setLyrics(''); setLyricsMode('plain');
      setAudioFile(null); setCoverFile(null); setCoverPreview(''); setAudioPreview('');
      if (audioRef.current) audioRef.current.value = '';
      if (coverRef.current) coverRef.current.value = '';
      setShowUpload(false);
    } catch (err) {
      setUploadError(err instanceof Error ? err.message : 'Upload thất bại');
    } finally {
      setUploading('');
    }
  }

  async function toggleMyHide(track: Track) {
    setProcessing(track.id);
    try {
      if (track.isHidden && track.hiddenBy !== 'admin') {
        await unhideMyTrack(track.id);
        setTracks(prev => prev.map(t => t.id === track.id ? { ...t, isHidden: false, hiddenBy: undefined } : t));
      } else if (!track.isHidden) {
        await hideMyTrack(track.id);
        setTracks(prev => prev.map(t => t.id === track.id ? { ...t, isHidden: true, hiddenBy: 'artist' } : t));
      }
    } finally {
      setProcessing(null);
    }
  }

  const displayTitle = (t: Track) => t.title ?? t.name ?? 'Không có tên';

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Sáng tác của tôi</h1>
          <p className="page-subtitle">Quản lý và upload bài hát của bạn</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowUpload(v => !v)}>
          {showUpload ? '✕ Đóng' : '+ Upload bài mới'}
        </button>
      </div>

      {/* ── Upload Form Modal ─────────────────────────── */}
      {showUpload && (
        <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border-solid)', borderRadius: 16, padding: 28, marginBottom: 28, boxShadow: '0 8px 32px rgba(0,0,0,0.08)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24, paddingBottom: 16, borderBottom: '1px solid var(--border-solid)' }}>
            <span style={{ fontSize: 22 }}>📤</span>
            <span style={{ fontWeight: 700, fontSize: 18, color: 'var(--text)' }}>Upload bài hát mới</span>
          </div>

          {uploadError && (
            <div style={{ background: '#ffeaea', border: '1px solid #fca5a5', borderRadius: 8, padding: '10px 14px', marginBottom: 16, color: '#dc2626', fontSize: 13 }}>
              ⚠️ {uploadError}
            </div>
          )}

          <form onSubmit={handleUpload}>

            {/* ── SECTION 1: Basic Info ── */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 12 }}>
                🎵 Thông tin cơ bản
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                  <label className="form-label">Tên bài hát <span style={{ color: 'var(--primary)' }}>*</span></label>
                  <input className="form-control" value={title} onChange={e => setTitle(e.target.value)} required placeholder="VD: Lặng yên bên em" />
                </div>

                <div className="form-group">
                  <label className="form-label">Thể loại</label>
                  <select className="form-control" value={genre} onChange={e => setGenre(e.target.value)} style={{ cursor: 'pointer' }}>
                    <option value="">-- Chọn thể loại --</option>
                    {GENRE_OPTIONS.map(g => <option key={g} value={g}>{g}</option>)}
                  </select>
                </div>

                {genre === 'Khác' && (
                  <div className="form-group">
                    <label className="form-label">Nhập thể loại khác</label>
                    <input className="form-control" value={customGenre} onChange={e => setCustomGenre(e.target.value)} placeholder="VD: City Pop, Vocaloid…" />
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">Ngôn ngữ</label>
                  <select className="form-control" value={language} onChange={e => setLanguage(e.target.value)} style={{ cursor: 'pointer' }}>
                    {['Tiếng Việt', 'English', 'Korean', 'Japanese', 'Chinese', 'Instrumental', 'Khác'].map(l =>
                      <option key={l} value={l}>{l}</option>
                    )}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Năm phát hành</label>
                  <input className="form-control" type="number" min={1900} max={new Date().getFullYear()} value={releaseYear} onChange={e => setReleaseYear(e.target.value)} />
                </div>

                <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                  <label className="form-label">Mô tả / Câu chuyện bài hát</label>
                  <textarea className="form-control" rows={3} value={description} onChange={e => setDescription(e.target.value)} placeholder="Chia sẻ cảm hứng hay câu chuyện đằng sau bài hát này…" style={{ resize: 'vertical' }} />
                </div>

                <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                  <label className="form-label">Tags (ngăn cách bằng dấu phẩy)</label>
                  <input className="form-control" value={tags} onChange={e => setTags(e.target.value)} placeholder="VD: buồn, mưa, tình yêu, acoustic, chill…" />
                  <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>
                    Tags giúp AI nhận diện cảm xúc và gợi ý bài hát phù hợp với phong cảnh
                  </div>
                </div>
              </div>
            </div>

            {/* ── SECTION 2: Files ── */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 12 }}>
                📁 File media
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>

                {/* Audio */}
                <div className="form-group">
                  <label className="form-label">File nhạc <span style={{ color: 'var(--primary)' }}>*</span> <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(MP3, AAC, WAV, FLAC)</span></label>
                  <label style={{
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    gap: 8, cursor: 'pointer', border: '2px dashed var(--border-solid)', borderRadius: 10,
                    padding: '20px 16px', background: audioFile ? 'rgba(212,114,42,0.06)' : 'var(--bg-sidebar)',
                    borderColor: audioFile ? 'var(--primary)' : 'var(--border-solid)', transition: 'all 0.2s',
                  }}>
                    <input ref={audioRef} type="file" accept="audio/*" style={{ display: 'none' }} required onChange={handleAudioChange} />
                    <span style={{ fontSize: 28 }}>{audioFile ? '🎵' : '🎧'}</span>
                    <span style={{ fontSize: 13, fontWeight: 600, color: audioFile ? 'var(--primary)' : 'var(--text-muted)' }}>
                      {audioFile ? audioFile.name : 'Nhấn để chọn file nhạc'}
                    </span>
                    {audioFile && (
                      <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                        {(audioFile.size / 1024 / 1024).toFixed(1)} MB
                      </span>
                    )}
                  </label>
                  {audioPreview && (
                    <audio controls src={audioPreview} style={{ width: '100%', marginTop: 12, height: 40, borderRadius: 8 }} />
                  )}
                </div>

                {/* Cover */}
                <div className="form-group">
                  <label className="form-label">Ảnh bìa <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}>(JPG, PNG — khuyến nghị 1:1)</span></label>
                  <label style={{
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                    gap: 8, cursor: 'pointer', border: '2px dashed var(--border-solid)', borderRadius: 10,
                    padding: coverPreview ? 0 : '20px 16px', background: 'var(--bg-sidebar)',
                    borderColor: coverFile ? 'var(--primary)' : 'var(--border-solid)',
                    overflow: 'hidden', transition: 'all 0.2s', minHeight: 100,
                  }}>
                    <input ref={coverRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleCoverChange} />
                    {coverPreview ? (
                      <img src={coverPreview} alt="preview" style={{ width: '100%', objectFit: 'cover', maxHeight: 180 }} />
                    ) : (
                      <>
                        <span style={{ fontSize: 28 }}>🖼️</span>
                        <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-muted)' }}>Nhấn để chọn ảnh bìa</span>
                      </>
                    )}
                  </label>
                </div>
              </div>
            </div>

            <div style={{ marginBottom: 24 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
                <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase', letterSpacing: '0.1em' }}>
                  📝 Lời bài hát
                </div>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <label htmlFor="lrc-upload" style={{
                    border: '1px dashed var(--primary)', borderRadius: 6, padding: '3px 10px',
                    fontSize: 12, fontWeight: 600, cursor: 'pointer', color: 'var(--primary)',
                    display: 'flex', alignItems: 'center', gap: 4, background: 'rgba(212,114,42,0.08)'
                  }}>
                    📁 Tải lên .lrc
                    <input id="lrc-upload" type="file" accept=".lrc,text/plain" style={{ display: 'none' }} onChange={handleLrcUpload} />
                  </label>
                  {(['plain', 'synced'] as const).map(m => (
                    <button
                      key={m} type="button"
                      onClick={() => setLyricsMode(m)}
                      style={{
                        border: '1px solid var(--border-solid)', borderRadius: 6, padding: '3px 10px',
                        fontSize: 12, fontWeight: 600, cursor: 'pointer',
                        background: lyricsMode === m ? 'var(--primary)' : 'var(--bg-sidebar)',
                        color: lyricsMode === m ? '#fff' : 'var(--text-muted)',
                      }}
                    >
                      {m === 'plain' ? '📄 Thường' : '⏱ Có timestamp'}
                    </button>
                  ))}
                </div>
              </div>

              {lyricsMode === 'synced' && (
                <div style={{ background: 'rgba(212,114,42,0.08)', borderRadius: 8, padding: '8px 12px', marginBottom: 8, fontSize: 12, color: 'var(--text-muted)' }}>
                  💡 Định dạng timestamp: <code style={{ background: 'rgba(0,0,0,0.06)', padding: '1px 4px', borderRadius: 3 }}>[mm:ss.xx]</code> mỗi dòng. VD: <code style={{ background: 'rgba(0,0,0,0.06)', padding: '1px 4px', borderRadius: 3 }}>[00:12.34] Lặng yên bên em…</code>
                </div>
              )}

              <textarea
                className="form-control"
                rows={10}
                value={lyrics}
                onChange={e => setLyrics(e.target.value)}
                placeholder={lyricsMode === 'plain'
                  ? 'Nhập lời bài hát…\n\n[Verse 1]\n...\n\n[Chorus]\n...'
                  : '[00:00.00] Intro\n[00:12.34] Dòng lời đầu tiên\n[00:18.50] Dòng tiếp theo…'
                }
                style={{ resize: 'vertical', fontFamily: 'monospace', fontSize: 13, lineHeight: 1.7 }}
              />
              <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>
                {lyrics.split('\n').length} dòng · {lyrics.length} ký tự
              </div>
            </div>

            {/* ── Submit ── */}
            <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
              <button type="submit" className="btn btn-primary" disabled={!!uploading} style={{ minWidth: 160 }}>
                {uploading ? `⏳ ${uploading}` : '📤 Publish bài hát'}
              </button>
              <button type="button" className="btn btn-ghost" onClick={() => setShowUpload(false)}>
                Hủy
              </button>
              {uploading && (
                <span style={{ fontSize: 13, color: 'var(--text-muted)' }}>Vui lòng không đóng trang…</span>
              )}
            </div>
          </form>
        </div>
      )}

      {/* ── Track List ──────────────────────────────── */}
      <div className="card-grid">
        {loading
          ? [1, 2, 3].map(i => (
              <div key={i} className="track-card">
                <div className="skeleton" style={{ width: 48, height: 48, borderRadius: 8, flexShrink: 0 }} />
                <div style={{ flex: 1 }}>
                  <div className="skeleton" style={{ height: 16, width: '70%', marginBottom: 6 }} />
                  <div className="skeleton" style={{ height: 12, width: '40%' }} />
                </div>
              </div>
            ))
          : tracks.length === 0
          ? (
            <div className="empty-state" style={{ gridColumn: '1/-1' }}>
              <div className="empty-state-icon">🎤</div>
              <div className="empty-state-text">Bạn chưa có bài hát nào. Upload bài đầu tiên!</div>
            </div>
          )
          : tracks.map(t => (
            <div key={t.id} className={`track-card${t.isHidden ? ' hidden' : ''}`}>
              <div
                className="track-cover"
                style={{ backgroundImage: (t.imageUrl ?? t.artworkUrl) ? `url(${t.imageUrl ?? t.artworkUrl})` : undefined, backgroundSize: 'cover', backgroundPosition: 'center' }}
              >
                {!(t.imageUrl ?? t.artworkUrl) && '🎵'}
              </div>
              <div className="track-info">
                <div className="track-title">{displayTitle(t)}</div>
                <div className="track-artist">{t.genre ?? '—'}</div>
                <div className="track-meta">
                  {t.isHidden ? (
                    <span className="badge badge-hidden" style={{ fontSize: 10 }}>
                      {t.hiddenBy === 'admin' ? '🚫 Ẩn (Admin)' : '👁 Đã ẩn'}
                    </span>
                  ) : (
                    <span className="badge badge-active" style={{ fontSize: 10 }}>✓ Công khai</span>
                  )}
                  <span className="track-stat">▶ {(t.stats?.playCount ?? 0).toLocaleString()}</span>
                  <span className="track-stat">❤️ {(t.stats?.favoriteCount ?? 0).toLocaleString()}</span>
                </div>
              </div>
              <div>
                {t.hiddenBy !== 'admin' && (
                  <button
                    className={`btn btn-sm ${t.isHidden ? 'btn-success' : 'btn-ghost'}`}
                    onClick={() => toggleMyHide(t)}
                    disabled={processing === t.id}
                  >
                    {processing === t.id ? '…' : t.isHidden ? 'Hiện' : 'Ẩn'}
                  </button>
                )}
              </div>
            </div>
          ))}
      </div>
    </div>
  );
}
