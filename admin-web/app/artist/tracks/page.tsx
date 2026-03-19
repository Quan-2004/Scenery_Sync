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
const AUDIO_PRESET = 'scenery_audio_upload';
const COVER_PRESET = 'scenery_track_cover';

async function cloudinaryUpload(file: File, preset: string, resourceType = 'auto'): Promise<string> {
  const form = new FormData();
  form.append('file', file);
  form.append('upload_preset', preset);
  const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/${resourceType}/upload`, {
    method: 'POST', body: form,
  });
  const json = await res.json();
  if (!json.secure_url) throw new Error(json.error?.message ?? 'Upload failed');
  return json.secure_url as string;
}

export default function ArtistTracksPage() {
  const user = useArtist();
  const [tracks, setTracks] = useState<Track[]>([]);
  const [loading, setLoading] = useState(true);
  const [showUpload, setShowUpload] = useState(false);
  const [processing, setProcessing] = useState<string | null>(null);

  // Upload form state
  const [title, setTitle] = useState('');
  const [genre, setGenre] = useState('');
  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');
  const audioRef = useRef<HTMLInputElement>(null);
  const coverRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!user?.uid) return;
    getMyTracks(user.uid)
      .then(d => setTracks(d as Track[]))
      .finally(() => setLoading(false));
  }, [user]);

  async function handleUpload(e: React.FormEvent) {
    e.preventDefault();
    if (!audioFile || !title || !user?.uid) return;
    setUploading(true);
    setUploadError('');

    try {
      const [audioUrl, coverUrl] = await Promise.all([
        cloudinaryUpload(audioFile, AUDIO_PRESET, 'video'),
        coverFile ? cloudinaryUpload(coverFile, COVER_PRESET, 'image') : Promise.resolve(''),
      ]);

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
        genre,
        status: 'published',
        isHidden: false,
        isPublic: true,
        stats: { playCount: 0, favoriteCount: 0, sceneryMatchCount: 0 },
      });

      setTracks(prev => [{
        id: ref.id, title, name: title, genre, status: 'published',
        isHidden: false, imageUrl: coverUrl, audioUrl,
        stats: { playCount: 0, favoriteCount: 0, sceneryMatchCount: 0 },
      }, ...prev]);

      // Reset
      setTitle(''); setGenre(''); setAudioFile(null); setCoverFile(null);
      if (audioRef.current) audioRef.current.value = '';
      if (coverRef.current) coverRef.current.value = '';
      setShowUpload(false);
    } catch (err) {
      setUploadError(err instanceof Error ? err.message : 'Upload thất bại');
    } finally {
      setUploading(false);
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

      {/* Upload Form */}
      {showUpload && (
        <div className="chart-card" style={{ marginBottom: 24 }}>
          <div className="chart-title">📤 Upload bài hát mới</div>
          {uploadError && <div className="login-error">{uploadError}</div>}
          <form onSubmit={handleUpload}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div className="form-group">
                <label className="form-label">Tên bài hát *</label>
                <input className="form-control" value={title} onChange={e => setTitle(e.target.value)} required placeholder="VD: Lặng yên bên em" />
              </div>
              <div className="form-group">
                <label className="form-label">Thể loại</label>
                <input className="form-control" value={genre} onChange={e => setGenre(e.target.value)} placeholder="VD: Ballad, Pop, Acoustic…" />
              </div>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div className="form-group">
                <label className="form-label">File nhạc * (MP3, AAC, WAV)</label>
                <input ref={audioRef} type="file" accept="audio/*" className="form-control" onChange={e => setAudioFile(e.target.files?.[0] ?? null)} required />
              </div>
              <div className="form-group">
                <label className="form-label">Ảnh bìa (JPG, PNG)</label>
                <input ref={coverRef} type="file" accept="image/*" className="form-control" onChange={e => setCoverFile(e.target.files?.[0] ?? null)} />
              </div>
            </div>
            <button type="submit" className="btn btn-primary" disabled={uploading}>
              {uploading ? '⏳ Đang upload…' : '📤 Upload bài hát'}
            </button>
          </form>
        </div>
      )}

      {/* Track List */}
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
