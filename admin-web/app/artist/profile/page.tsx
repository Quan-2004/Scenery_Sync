'use client';
import { useEffect, useState, useRef } from 'react';
import { useArtist } from '../context';
import { getArtistProfile, updateArtistProfile } from '@/lib/artistQueries';

const CLOUDINARY_CLOUD = 'dvcebine7';
const COVER_PRESET = 'scenery_track_cover';

async function uploadAvatar(file: File): Promise<string> {
  const form = new FormData();
  form.append('file', file);
  form.append('upload_preset', COVER_PRESET);
  const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/image/upload`, {
    method: 'POST', body: form,
  });
  const json = await res.json();
  if (!json.secure_url) throw new Error(json.error?.message ?? 'Upload failed');
  return json.secure_url as string;
}

export default function ArtistProfilePage() {
  const user = useArtist();

  const [displayName, setDisplayName]   = useState('');
  const [companyName, setCompanyName]   = useState('');
  const [bio, setBio]                   = useState('');
  const [phoneNumber, setPhoneNumber]   = useState('');
  const [photoUrl, setPhotoUrl]         = useState('');
  const [avatarPreview, setAvatarPreview] = useState('');
  const [avatarFile, setAvatarFile]     = useState<File | null>(null);

  const [loading, setLoading]   = useState(true);
  const [saving, setSaving]     = useState(false);
  const [toast, setToast]       = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');
  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!user?.uid) return;
    getArtistProfile(user.uid).then((data) => {
      if (data) {
        const d = data as Record<string, string>;
        setDisplayName(d.displayName ?? d.name ?? '');
        setCompanyName(d.companyName ?? '');
        setBio(d.bio ?? '');
        setPhoneNumber(d.phoneNumber ?? '');
        setPhotoUrl(d.photoUrl ?? d.photoURL ?? '');
        setAvatarPreview(d.photoUrl ?? d.photoURL ?? '');
      }
      setLoading(false);
    });
  }, [user]);

  function showToast(msg: string, type: 'success' | 'error' = 'success') {
    setToast(msg);
    setToastType(type);
    setTimeout(() => setToast(''), 3000);
  }

  function handleAvatarChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    setAvatarFile(file);
    if (file) setAvatarPreview(URL.createObjectURL(file));
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!user?.uid) return;
    setSaving(true);
    try {
      let finalPhotoUrl = photoUrl;
      if (avatarFile) {
        finalPhotoUrl = await uploadAvatar(avatarFile);
        setPhotoUrl(finalPhotoUrl);
      }
      await updateArtistProfile(user.uid, {
        displayName: displayName.trim(),
        companyName: companyName.trim(),
        bio: bio.trim(),
        phoneNumber: phoneNumber.trim(),
        photoUrl: finalPhotoUrl,
      });
      setAvatarFile(null);
      showToast('✅ Hồ sơ đã được cập nhật!', 'success');
    } catch {
      showToast('❌ Lưu thất bại, vui lòng thử lại.', 'error');
    } finally {
      setSaving(false);
    }
  }

  const initials = (displayName || user?.displayName || user?.email || 'A')[0].toUpperCase();

  return (
    <div>
      {/* Toast */}
      {toast && (
        <div style={{
          position: 'fixed', top: 24, right: 24, zIndex: 9999,
          background: toastType === 'success' ? '#1a9e72' : '#d94040',
          color: '#fff', borderRadius: 10, padding: '12px 20px',
          fontWeight: 600, fontSize: 14, boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
          animation: 'fadeIn 0.2s ease',
        }}>
          {toast}
        </div>
      )}

      <div className="page-header">
        <div>
          <h1 className="page-title">Hồ sơ nghệ sĩ</h1>
          <p className="page-subtitle">Chỉnh sửa thông tin cá nhân và hình đại diện</p>
        </div>
      </div>

      {loading ? (
        <div style={{ display: 'grid', gap: 16 }}>
          {[1, 2, 3, 4].map(i => <div key={i} className="skeleton" style={{ height: 56, borderRadius: 10 }} />)}
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: 28, alignItems: 'start' }}>

          {/* Avatar Card */}
          <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border-solid)', borderRadius: 'var(--radius)', padding: 28, textAlign: 'center', boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ position: 'relative', display: 'inline-block', marginBottom: 16 }}>
              {avatarPreview ? (
                <img
                  src={avatarPreview}
                  alt="avatar"
                  style={{ width: 96, height: 96, borderRadius: '50%', objectFit: 'cover', border: '3px solid var(--border)' }}
                />
              ) : (
                <div style={{
                  width: 96, height: 96, borderRadius: '50%',
                  background: 'var(--primary)', color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 38, fontWeight: 700, border: '3px solid var(--border)',
                }}>
                  {initials}
                </div>
              )}
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                style={{
                  position: 'absolute', bottom: 0, right: 0,
                  width: 30, height: 30, borderRadius: '50%',
                  background: 'var(--primary)', color: '#fff', border: 'none',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 14, cursor: 'pointer', boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
                }}
                title="Đổi ảnh đại diện"
              >
                ✏️
              </button>
            </div>
            <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleAvatarChange} />
            <div style={{ fontWeight: 700, fontSize: 16, color: 'var(--text)' }}>{displayName || '—'}</div>
            <div style={{ fontSize: 12, color: 'var(--text-dim)', marginTop: 4 }}>{user?.email}</div>
            <div style={{ marginTop: 10 }}>
              <span className="badge role-artist" style={{ fontSize: 11, padding: '3px 12px', borderRadius: 99, background: 'rgba(212,114,42,0.12)', color: 'var(--primary)', fontWeight: 700 }}>
                🎤 Artist
              </span>
            </div>
            {avatarFile && (
              <p style={{ fontSize: 11, color: 'var(--primary)', marginTop: 10 }}>
                📎 {avatarFile.name}
              </p>
            )}
          </div>

          {/* Form */}
          <form onSubmit={handleSave} style={{ background: 'var(--bg-card)', border: '1px solid var(--border-solid)', borderRadius: 'var(--radius)', padding: 28, boxShadow: 'var(--shadow-sm)' }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 20 }}>
              👤 Thông tin cá nhân
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div className="form-group">
                <label className="form-label">Tên nghệ sĩ / Nghệ danh</label>
                <input
                  className="form-control"
                  value={displayName}
                  onChange={e => setDisplayName(e.target.value)}
                  placeholder="VD: Sơn Tùng M-TP"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Tên Công ty / Label</label>
                <input
                  className="form-control"
                  value={companyName}
                  onChange={e => setCompanyName(e.target.value)}
                  placeholder="VD: M-TP Entertainment"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Email hiển thị</label>
                <input
                  className="form-control"
                  type="email"
                  value={user?.email ?? ''}
                  disabled
                  style={{ opacity: 0.6, cursor: 'not-allowed' }}
                  title="Email đăng nhập không thể thay đổi"
                />
              </div>

              <div className="form-group">
                <label className="form-label">Số điện thoại</label>
                <input
                  className="form-control"
                  value={phoneNumber}
                  onChange={e => setPhoneNumber(e.target.value)}
                  placeholder="VD: 0901234567"
                />
              </div>

              <div className="form-group" style={{ gridColumn: '1 / -1' }}>
                <label className="form-label">Bio / Giới thiệu bản thân</label>
                <textarea
                  className="form-control"
                  rows={4}
                  value={bio}
                  onChange={e => setBio(e.target.value)}
                  placeholder="Chia sẻ đôi điều về bạn, phong cách âm nhạc, câu chuyện nghệ thuật…"
                  style={{ resize: 'vertical' }}
                />
                <div style={{ fontSize: 11, color: 'var(--text-dim)', marginTop: 4 }}>
                  {bio.length} / 500 ký tự
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: 10, marginTop: 8 }}>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={saving}
                style={{ minWidth: 160 }}
              >
                {saving ? '⏳ Đang lưu…' : '💾 Lưu thay đổi'}
              </button>
              <button
                type="button"
                className="btn btn-ghost"
                onClick={() => {
                  setAvatarFile(null);
                  setAvatarPreview(photoUrl);
                }}
                disabled={saving}
              >
                Hủy
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
