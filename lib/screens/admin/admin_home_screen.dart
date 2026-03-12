import 'package:flutter/material.dart';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildListenerEngagement(),
                    const SizedBox(height: 20),
                    _buildRevenueStream(),
                    const SizedBox(height: 20),
                    _buildTopArtists(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
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
            color: Colors.black.withOpacity(0.06),
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
    final cards = [
      _StatData(
        label: 'Tổng Lượt Nghe',
        value: '1.2M',
        change: '+12.4%',
        subLabel: 'so với tháng trước',
        icon: Icons.people_alt_outlined,
        positive: true,
      ),
      _StatData(
        label: 'Bài Hát Thịnh Hành',
        value: '842',
        change: '+5.2%',
        subLabel: 'so với tuần trước',
        icon: Icons.music_note_outlined,
        positive: true,
      ),
      _StatData(
        label: 'Doanh Thu Tháng',
        value: '\$12,540',
        change: '+8.1%',
        subLabel: 'so với tháng trước',
        icon: Icons.account_balance_wallet_outlined,
        positive: true,
      ),
    ];

    return Column(
      children: cards.map((d) => _StatCard(data: d)).toList(),
    );
  }

  // ── Listener Engagement ───────────────────────────────────────────────────
  Widget _buildListenerEngagement() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mức Độ Tương Tác',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AC.text,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _AC.bg,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '24 GIỜ QUA',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _AC.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 14, color: _AC.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '45.2k',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'Đang hoạt động  ',
                  style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '+4.2%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AC.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _LineChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0h', '6h', '12h', '18h', '23h']
                .map(
                  (t) => Text(
                    t,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: _AC.muted),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Revenue Stream ────────────────────────────────────────────────────────
  Widget _buildRevenueStream() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Doanh Thu',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AC.text,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _AC.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'DOANH THU QUẢNG CÁO',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _AC.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$2,104',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _AC.text,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'Mục tiêu ngày  ',
                  style: GoogleFonts.poppins(fontSize: 12, color: _AC.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '-1.5%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AC.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: CustomPaint(
              size: const Size(double.infinity, 110),
              painter: _BarChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                .map(
                  (d) => Text(
                    d,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: _AC.muted),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Top Artists ───────────────────────────────────────────────────────────
  Widget _buildTopArtists() {
    const artists = [
      _ArtistData('Luna Ray', 'Indie Pop', '450.2k', 'NỔI BẬT', _AC.primary),
      _ArtistData('Echo Bass', 'Techno', '382.1k', 'THỊNH HÀNH', Color(0xFFFF9800)),
      _ArtistData('Velvet Soul', 'R&B', '315.8k', 'ĐANG HOẠT ĐỘNG', Color(0xFF4CAF50)),
    ];

    return _Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nghệ Sĩ Nổi Bật',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _AC.text,
                ),
              ),
              Text(
                'XEM TẤT CẢ',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _AC.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Table header
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'NGHỆ SĨ',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _AC.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'LƯỢT NGHE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _AC.muted,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'TRẠNG THÁI',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _AC.muted,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: _AC.divider, height: 1),
          ...artists.map((a) => _ArtistRow(data: a)),
        ],
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: _AC.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
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
            color: Colors.black.withOpacity(0.05),
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
                  color: data.statusColor.withOpacity(0.12),
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

// ─── Line Chart Painter ───────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  // Normalised y values (0 = top, 1 = bottom)
  static const _pts = [
    Offset(0.0, 0.35),
    Offset(0.08, 0.20),
    Offset(0.18, 0.10),
    Offset(0.28, 0.30),
    Offset(0.38, 0.40),
    Offset(0.48, 0.20),
    Offset(0.55, 0.55),
    Offset(0.65, 0.70),
    Offset(0.72, 0.45),
    Offset(0.80, 0.15),
    Offset(0.88, 0.05),
    Offset(1.00, 0.30),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pts =
        _pts.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    // --- Fill path ---
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE48744).withOpacity(0.22),
          const Color(0xFFE48744).withOpacity(0.00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path();
    fillPath.moveTo(pts.first.dx, size.height);
    fillPath.lineTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    fillPath.lineTo(pts.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // --- Line ---
    final linePaint = Paint()
      ..color = const Color(0xFFE48744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Bar Chart Painter ────────────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  // Heights normalised 0-1; THU is highlighted (index 3)
  static const _vals = [0.45, 0.55, 0.65, 1.00, 0.70, 0.50, 0.60];

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = _vals.length;
    final totalWidth = size.width;
    final barWidth = (totalWidth / barCount) * 0.5;
    final gap = (totalWidth - barWidth * barCount) / (barCount + 1);

    for (int i = 0; i < barCount; i++) {
      final x = gap + i * (barWidth + gap);
      final barH = _vals[i] * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barH, barWidth, barH),
        const Radius.circular(8),
      );
      final paint = Paint()
        ..color = i == 3
            ? const Color(0xFFE48744)
            : const Color(0xFFE48744).withOpacity(0.20)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
