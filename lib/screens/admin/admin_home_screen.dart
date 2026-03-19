import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ────────────────────────────────────────────────────────────────
class _AC {
  static const bg = Color(0xFFFFF4EC);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFFE48744);
  static const primaryLight = Color(0xFFF7DCC7);
  static const text = Color(0xFF2D241E);
  static const muted = Color(0xFF9E9086);
  static const green = Color(0xFF4CAF50);
  static const red = Color(0xFFE53935);
  static const divider = Color(0xFFEDE8E3);
  static const navBg = Color(0xFFFFFFFF);
}

// ─── Entry point ────────────────────────────────────────────────────────────
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _navIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'TỔNG QUAN'),
    _NavItem(Icons.people_alt_rounded, 'NGHỆ SĨ'),
    _NavItem(Icons.music_note_rounded, 'BÀI HÁT'),
    _NavItem(Icons.person_rounded, 'NGƯỜI DÙNG'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AC.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCurrentTabContent(),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    if (_navIndex == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildUserManagementTab(),
          const SizedBox(height: 24),
        ],
      );
    }

    if (_navIndex == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSongManagementTab(),
          const SizedBox(height: 24),
        ],
      );
    }

    if (_navIndex == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 20),
          _buildArtistManagementTab(),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildHeader(),
        const SizedBox(height: 24),
        _buildStatCards(),
        const SizedBox(height: 20),
        _buildKeywordLearningReports(),
        const SizedBox(height: 20),
        _buildListenerEngagement(),
        const SizedBox(height: 20),
        _buildRevenueStream(),
        const SizedBox(height: 20),
        _buildTopArtists(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserManagementTab() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý người dùng',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              Text(
                'Realtime',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AC.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? const [],
              );

              docs.sort((a, b) {
                final aTs = a.data()['createdAt'];
                final bTs = b.data()['createdAt'];
                final aTime = aTs is Timestamp
                    ? aTs.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = bTs is Timestamp
                    ? bTs.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa có người dùng nào.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                  ),
                );
              }

              return Column(
                children: docs.map(_buildUserRow).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSongManagementTab() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý bài hát',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              Text(
                'Realtime',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AC.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('tracks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? const [],
              );

              docs.sort((a, b) {
                final aTs = a.data()['createdAt'];
                final bTs = b.data()['createdAt'];
                final aTime = aTs is Timestamp
                    ? aTs.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = bTs is Timestamp
                    ? bTs.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa có bài hát nào.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                  ),
                );
              }

              return Column(
                children: docs.map(_buildTrackRow).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtistManagementTab() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quản lý nghệ sĩ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _AC.text,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AC.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _showAddArtistDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm nghệ sĩ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('artists').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? const [],
              );

              docs.sort((a, b) {
                final aTs = a.data()['createdAt'];
                final bTs = b.data()['createdAt'];
                final aTime = aTs is Timestamp
                    ? aTs.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = bTs is Timestamp
                    ? bTs.toDate()
                    : DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa có nghệ sĩ nào. Nhấn "Thêm nghệ sĩ" để tạo mới.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                  ),
                );
              }

              return Column(
                children: docs.map(_buildArtistRow).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtistRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final artistName = _artistName(data);
    final genre = (data['genre'] ?? 'Unknown').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AC.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AC.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _artistAvatar(data),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AC.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  genre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _AC.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xem thông tin & sáng tác',
            onPressed: () => _showArtistDetails(doc),
            icon: const Icon(Icons.visibility_outlined, color: _AC.primary),
          ),
        ],
      ),
    );
  }

  String _artistName(Map<String, dynamic> data) {
    return (data['name'] ?? data['artistName'] ?? 'Unknown Artist').toString();
  }

  Widget _artistAvatar(Map<String, dynamic> data) {
    final avatarUrl = (data['avatarUrl'] ?? data['imageUrl'] ?? data['photoUrl'] ?? '').toString();
    if (avatarUrl.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        color: _AC.primaryLight,
        child: const Icon(Icons.person, color: _AC.primary, size: 18),
      );
    }

    return Image.network(
      avatarUrl,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 40,
        height: 40,
        color: _AC.primaryLight,
        child: const Icon(Icons.person, color: _AC.primary, size: 18),
      ),
    );
  }

  void _showAddArtistDialog() {
    final nameController = TextEditingController();
    final genreController = TextEditingController();
    final bioController = TextEditingController();
    final avatarController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Thêm nghệ sĩ',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên nghệ sĩ'),
              ),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(labelText: 'Thể loại'),
              ),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Tiểu sử ngắn'),
                minLines: 2,
                maxLines: 3,
              ),
              TextField(
                controller: avatarController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _AC.primary),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Tên nghệ sĩ không được để trống')),
                );
                return;
              }

              await FirebaseFirestore.instance.collection('artists').add({
                'name': name,
                'genre': genreController.text.trim(),
                'bio': bioController.text.trim(),
                'avatarUrl': avatarController.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
                'createdBy': FirebaseAuth.instance.currentUser?.uid,
              });

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Đã thêm nghệ sĩ mới')),
              );
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showArtistDetails(QueryDocumentSnapshot<Map<String, dynamic>> artistDoc) {
    final artistData = artistDoc.data();
    final artistId = artistDoc.id;
    final artistName = _artistName(artistData);
    final genre = (artistData['genre'] ?? '').toString();
    final bio = (artistData['bio'] ?? '').toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin nghệ sĩ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _AC.text,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Tên: $artistName', style: GoogleFonts.poppins(fontSize: 13, color: _AC.text)),
                const SizedBox(height: 4),
                Text('ID: $artistId', style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted)),
                const SizedBox(height: 4),
                Text('Thể loại: ${genre.isEmpty ? '(chưa cập nhật)' : genre}',
                    style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted)),
                const SizedBox(height: 4),
                Text('Tiểu sử: ${bio.isEmpty ? '(chưa cập nhật)' : bio}',
                    style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted)),
                const SizedBox(height: 14),
                Text(
                  'Các sáng tác thuộc nghệ sĩ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AC.text,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('tracks').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      final tracks = (snapshot.data?.docs ?? const [])
                          .map((d) => d.data())
                          .where((track) => _trackBelongsToArtist(
                                track,
                                artistId: artistId,
                                artistName: artistName,
                              ))
                          .toList();

                      if (tracks.isEmpty) {
                        return Center(
                          child: Text(
                            'Chưa có sáng tác nào liên kết với nghệ sĩ này.',
                            style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final title = _trackTitle(track);
                          final status = (track['status'] ?? 'unknown').toString();
                          final publicText = track['isPublic'] == false ? 'private' : 'public';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _AC.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _AC.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _AC.text,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Status: $status · $publicText',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: _AC.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _trackBelongsToArtist(
    Map<String, dynamic> track, {
    required String artistId,
    required String artistName,
  }) {
    final normalizedArtistId = artistId.trim().toLowerCase();
    final normalizedArtistName = artistName.trim().toLowerCase();

    final trackArtistId = (track['artistId'] ?? '').toString().trim().toLowerCase();
    final trackArtistName =
        (track['artistName'] ?? track['artist'] ?? '').toString().trim().toLowerCase();

    if (normalizedArtistId.isNotEmpty && trackArtistId == normalizedArtistId) {
      return true;
    }

    if (normalizedArtistName.isNotEmpty && trackArtistName == normalizedArtistName) {
      return true;
    }

    return false;
  }

  Widget _buildTrackRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final trackId = doc.id;
    final title = _trackTitle(data);
    final artist = _trackArtist(data);
    final status = (data['status'] ?? 'unknown').toString();
    final isPublic = data['isPublic'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AC.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AC.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _trackImage(data),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AC.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _AC.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $status · Public: ${isPublic ? 'Yes' : 'No'}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _AC.muted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Xem chi tiết',
                onPressed: () => _showTrackDetails(doc),
                icon: const Icon(Icons.visibility_outlined, color: _AC.primary),
              ),
              IconButton(
                tooltip: 'Sửa',
                onPressed: () => _showEditTrackDialog(doc),
                icon: const Icon(Icons.edit_outlined, color: _AC.green),
              ),
              IconButton(
                tooltip: 'Xóa',
                onPressed: () => _confirmDeleteTrack(trackId),
                icon: const Icon(Icons.delete_outline_rounded, color: _AC.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _trackTitle(Map<String, dynamic> data) {
    return (data['title'] ?? data['name'] ?? 'Untitled').toString();
  }

  String _trackArtist(Map<String, dynamic> data) {
    return (data['artist'] ?? data['artistName'] ?? 'Unknown Artist').toString();
  }

  Widget _trackImage(Map<String, dynamic> data) {
    final imageUrl = (data['imageUrl'] ?? data['coverImage'] ?? '').toString();
    if (imageUrl.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        color: _AC.primaryLight,
        child: const Icon(Icons.music_note_rounded, color: _AC.primary, size: 18),
      );
    }

    return Image.network(
      imageUrl,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 44,
        height: 44,
        color: _AC.primaryLight,
        child: const Icon(Icons.music_note_rounded, color: _AC.primary, size: 18),
      ),
    );
  }

  void _showTrackDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final trackId = doc.id;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final rows = <MapEntry<String, String>>[
          MapEntry('Track ID', trackId),
          MapEntry('Title', _trackTitle(data)),
          MapEntry('Artist', _trackArtist(data)),
          MapEntry('Status', (data['status'] ?? 'unknown').toString()),
          MapEntry('Public', ((data['isPublic'] != false) ? 'Yes' : 'No')),
          MapEntry('Audio URL', (data['audioUrl'] ?? '').toString()),
          MapEntry('Image URL', (data['imageUrl'] ?? data['coverImage'] ?? '').toString()),
        ];

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết bài hát',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _AC.text,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: entry.value.isEmpty ? '(trống)' : entry.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTrackDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final titleController = TextEditingController(text: _trackTitle(data));
    final artistController = TextEditingController(text: _trackArtist(data));
    final imageController = TextEditingController(
      text: (data['imageUrl'] ?? data['coverImage'] ?? '').toString(),
    );
    final audioController = TextEditingController(
      text: (data['audioUrl'] ?? data['previewUrl'] ?? '').toString(),
    );
    String selectedStatus = (data['status'] ?? 'published').toString();
    bool isPublic = data['isPublic'] != false;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocalState) => AlertDialog(
            title: Text(
              'Sửa bài hát',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  TextField(
                    controller: artistController,
                    decoration: const InputDecoration(labelText: 'Nghệ sĩ'),
                  ),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                  ),
                  TextField(
                    controller: audioController,
                    decoration: const InputDecoration(labelText: 'Audio URL'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'published', child: Text('published')),
                      DropdownMenuItem(value: 'draft', child: Text('draft')),
                      DropdownMenuItem(value: 'archived', child: Text('archived')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocalState(() => selectedStatus = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public'),
                    value: isPublic,
                    onChanged: (v) => setLocalState(() => isPublic = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _AC.primary),
                onPressed: () async {
                  final payload = <String, dynamic>{
                    'title': titleController.text.trim(),
                    'artist': artistController.text.trim(),
                    'imageUrl': imageController.text.trim(),
                    'audioUrl': audioController.text.trim(),
                    'status': selectedStatus,
                    'isPublic': isPublic,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  await doc.reference.set(payload, SetOptions(merge: true));
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật bài hát')),
                  );
                },
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteTrack(String trackId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Xóa bài hát',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xóa bài hát này không?\nID: $trackId',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('tracks').doc(trackId).delete();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Đã xóa bài hát')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: _AC.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final uid = doc.id;
    final name = (data['name'] ?? data['displayName'] ?? 'Unknown').toString();
    final email = (data['email'] ?? '').toString();
    final role = (data['role'] ?? 'user').toString();
    final createdAt = data['createdAt'];

    final createdLabel = createdAt is Timestamp
        ? _formatDate(createdAt.toDate())
        : '--/--/----';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AC.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AC.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _AC.primaryLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: _AC.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AC.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isEmpty ? '(không có email)' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _AC.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: $role · Tạo: $createdLabel',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _AC.muted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Xem chi tiết',
                onPressed: () => _showUserDetails(doc),
                icon: const Icon(Icons.visibility_outlined, color: _AC.primary),
              ),
              IconButton(
                tooltip: 'Sửa',
                onPressed: () => _showEditUserDialog(doc),
                icon: const Icon(Icons.edit_outlined, color: _AC.green),
              ),
              IconButton(
                tooltip: 'Xóa',
                onPressed: () => _confirmDeleteUser(uid),
                icon: const Icon(Icons.delete_outline_rounded, color: _AC.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year.toString();
    return '$d/$m/$y';
  }

  void _showUserDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final uid = doc.id;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final rows = <MapEntry<String, String>>[
          MapEntry('UID', uid),
          MapEntry('Tên', (data['name'] ?? data['displayName'] ?? '').toString()),
          MapEntry('Email', (data['email'] ?? '').toString()),
          MapEntry('Role', (data['role'] ?? 'user').toString()),
          MapEntry('Photo URL', (data['photoUrl'] ?? '').toString()),
        ];

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết người dùng',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _AC.text,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: entry.value.isEmpty ? '(trống)' : entry.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditUserDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final nameController = TextEditingController(
      text: (data['name'] ?? data['displayName'] ?? '').toString(),
    );
    final emailController = TextEditingController(
      text: (data['email'] ?? '').toString(),
    );
    final roleController = TextEditingController(
      text: (data['role'] ?? 'user').toString(),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sửa người dùng',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Role (user/admin)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _AC.primary),
            onPressed: () async {
              final payload = <String, dynamic>{
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'role': roleController.text.trim().isEmpty
                    ? 'user'
                    : roleController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              await doc.reference.set(payload, SetOptions(merge: true));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật người dùng')),
              );
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String uid) {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == adminUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa chính tài khoản admin đang đăng nhập')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Xóa người dùng',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xóa hồ sơ người dùng này không?\nUID: $uid',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Đã xóa hồ sơ người dùng')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: _AC.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordLearningReports() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Từ Khóa Mới Từ Ảnh',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AC.text,
                ),
              ),
              Text(
                'Realtime',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AC.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('admin_keyword_reports')
                .orderBy('createdAt', descending: true)
                .limit(8)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Chưa có từ khóa mới được học.',
                    style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final keywords = ((data['keywords'] as List?) ?? const [])
                      .map((e) => e.toString())
                      .where((e) => e.trim().isNotEmpty)
                      .toList();
                  final name = (data['displayName'] ?? data['email'] ?? 'Unknown')
                      .toString();
                  final createdAt = data['createdAt'] ?? data['clientCreatedAt'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _AC.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AC.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: _AC.primary, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _AC.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatReportTime(createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: _AC.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          keywords.isEmpty ? '-' : keywords.join(', '),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _AC.text,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatReportTime(dynamic value) {
    DateTime? dt;
    if (value is Timestamp) {
      dt = value.toDate();
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return '--:--';

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar – orange circle with headphone icon
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: _AC.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.headphones, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bảng Điều Khiển',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              Text(
                'Chào mừng trở lại, Alex',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _AC.muted,
                ),
              ),
            ],
          ),
        ),
        _iconButton(Icons.search_rounded),
        const SizedBox(width: 8),
        _iconButton(Icons.notifications_none_rounded),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: _AC.primaryLight,
          child: const Icon(Icons.person, color: _AC.primary, size: 20),
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _AC.card,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: _AC.text),
    );
  }

  // ── Stat Cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('tracks').snapshots(),
          builder: (context, trackSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('artists').snapshots(),
              builder: (context, artistSnap) {
                if (userSnap.connectionState == ConnectionState.waiting ||
                    trackSnap.connectionState == ConnectionState.waiting ||
                    artistSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final users = userSnap.data?.docs ?? const [];
                final tracks = trackSnap.data?.docs ?? const [];
                final artists = artistSnap.data?.docs ?? const [];

                final publishedTracks = tracks.where((d) {
                  final data = d.data();
                  return (data['status'] ?? '').toString().toLowerCase() == 'published';
                }).length;

                final publicTracks = tracks.where((d) {
                  final data = d.data();
                  return data['isPublic'] != false;
                }).length;

                final cards = [
                  _StatData(
                    label: 'Tổng người dùng',
                    value: _formatCompactNumber(users.length),
                    change: 'Realtime',
                    subLabel: 'Tài khoản hiện có',
                    icon: Icons.people_alt_outlined,
                    positive: true,
                  ),
                  _StatData(
                    label: 'Tổng bài hát',
                    value: _formatCompactNumber(tracks.length),
                    change: '$publishedTracks',
                    subLabel: 'Bài đã publish',
                    icon: Icons.music_note_outlined,
                    positive: true,
                  ),
                  _StatData(
                    label: 'Nghệ sĩ',
                    value: _formatCompactNumber(artists.length),
                    change: '$publicTracks',
                    subLabel: 'Track public',
                    icon: Icons.mic_external_on_outlined,
                    positive: true,
                  ),
                ];

                return Column(
                  children: cards.map((d) => _StatCard(data: d)).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Listener Engagement ───────────────────────────────────────────────────
  Widget _buildListenerEngagement() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final users = snapshot.data?.docs ?? const [];
        final genderCounts = <String, int>{
          'male': 0,
          'female': 0,
          'other': 0,
          'unknown': 0,
        };

        for (final doc in users) {
          final g = _normalizeGender(doc.data()['gender'] ?? doc.data()['sex']);
          genderCounts[g] = (genderCounts[g] ?? 0) + 1;
        }

        final total = users.length;

        Widget buildGenderBar(String label, String key, Color color) {
          final count = genderCounts[key] ?? 0;
          final pct = total == 0 ? 0.0 : count / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(fontSize: 12, color: _AC.text),
                    ),
                    Text(
                      '$count (${(pct * 100).toStringAsFixed(1)}%)',
                      style: GoogleFonts.poppins(fontSize: 11, color: _AC.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: _AC.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân bố giới tính (Realtime)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AC.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tổng người dùng: $total',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _AC.muted,
                ),
              ),
              const SizedBox(height: 12),
              buildGenderBar('Nam', 'male', _AC.primary),
              buildGenderBar('Nữ', 'female', _AC.green),
              buildGenderBar('Khác', 'other', Colors.blueGrey),
              buildGenderBar('Chưa cập nhật', 'unknown', _AC.muted),
            ],
          ),
        );
      },
    );
  }

  // ── Revenue Stream ────────────────────────────────────────────────────────
  Widget _buildRevenueStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tracks').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final tracks = snapshot.data?.docs ?? const [];
        final published = tracks.where((d) {
          final status = (d.data()['status'] ?? '').toString().toLowerCase();
          return status == 'published';
        }).length;
        final draft = tracks.where((d) {
          final status = (d.data()['status'] ?? '').toString().toLowerCase();
          return status == 'draft';
        }).length;
        final archived = tracks.where((d) {
          final status = (d.data()['status'] ?? '').toString().toLowerCase();
          return status == 'archived';
        }).length;

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trạng thái bài hát (Realtime)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AC.text,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatusChip('Published', published, _AC.green),
              const SizedBox(height: 8),
              _buildStatusChip('Draft', draft, _AC.primary),
              const SizedBox(height: 8),
              _buildStatusChip('Archived', archived, _AC.red),
            ],
          ),
        );
      },
    );
  }

  // ── Top Artists ───────────────────────────────────────────────────────────
  Widget _buildTopArtists() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('artists').snapshots(),
      builder: (context, artistSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('tracks').snapshots(),
          builder: (context, trackSnap) {
            if (artistSnap.connectionState == ConnectionState.waiting ||
                trackSnap.connectionState == ConnectionState.waiting) {
              return const _Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              );
            }

            final artistDocs = artistSnap.data?.docs ?? const [];
            final tracks = trackSnap.data?.docs ?? const [];

            final top = artistDocs.map((artistDoc) {
              final data = artistDoc.data();
              final artistId = artistDoc.id;
              final artistName = _artistName(data);
              final genre = (data['genre'] ?? 'Unknown').toString();

              final works = tracks.where((trackDoc) {
                final t = trackDoc.data();
                return _trackBelongsToArtist(
                  t,
                  artistId: artistId,
                  artistName: artistName,
                );
              }).length;

              return {
                'name': artistName,
                'genre': genre,
                'works': works,
              };
            }).toList()
              ..sort((a, b) => (b['works'] as int).compareTo(a['works'] as int));

            final topArtists = top.take(5).toList();

            return _Card(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nghệ sĩ nổi bật (Realtime)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _AC.text,
                        ),
                      ),
                      Text(
                        'TOP 5',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _AC.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (topArtists.isEmpty)
                    Text(
                      'Chưa có nghệ sĩ để thống kê.',
                      style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                    )
                  else
                    ...topArtists.map((a) {
                      final works = a['works'] as int;
                      return _ArtistRow(
                        data: _ArtistData(
                          a['name'] as String,
                          a['genre'] as String,
                          '$works sáng tác',
                          works > 0 ? 'ĐANG HOẠT ĐỘNG' : 'CHƯA CÓ TRACK',
                          works > 0 ? _AC.green : _AC.muted,
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _AC.text,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _AC.text,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  String _normalizeGender(dynamic raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    if (value.isEmpty) return 'unknown';
    if (value == 'male' || value == 'nam' || value == 'm') return 'male';
    if (value == 'female' || value == 'nu' || value == 'nữ' || value == 'f') {
      return 'female';
    }
    if (value == 'other' || value == 'khac' || value == 'khác') return 'other';
    return 'unknown';
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: _AC.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final selected = i == _navIndex;
          return GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: selected ? _AC.primary : _AC.muted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _AC.primary : _AC.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Reusable Card wrapper ────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AC.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────
class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.change,
    required this.subLabel,
    required this.icon,
    required this.positive,
  });
  final String label, value, change, subLabel;
  final IconData icon;
  final bool positive;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _Card(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _AC.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _AC.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        data.positive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: data.positive ? _AC.green : _AC.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${data.change}  ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: data.positive ? _AC.green : _AC.red,
                        ),
                      ),
                      Text(
                        data.subLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _AC.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _AC.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: _AC.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Artist Row ───────────────────────────────────────────────────────────
class _ArtistData {
  const _ArtistData(
      this.name, this.genre, this.listeners, this.status, this.statusColor);
  final String name, genre, listeners, status;
  final Color statusColor;
}

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({required this.data});
  final _ArtistData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: _AC.primaryLight,
            child: Text(
              data.name[0],
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _AC.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AC.text,
                  ),
                ),
                Text(
                  data.genre,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _AC.muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              data.listeners,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _AC.text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: data.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.status,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: data.statusColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
