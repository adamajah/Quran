import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import '../../constants/app_colors.dart';
import '../../constants/app_text_style.dart';
import '../../models/verse_ref.dart';
import '../../utils/quran_utils.dart';
import '../../screens/hafalan_screen.dart';
import '../../screens/bookmarks_screen.dart';
import '../../screens/offline_download_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/prayer/prayer_schedule_screen.dart';

class MushafDrawer extends StatefulWidget {
  final int curSurah, curPageIdx;
  final List<PageData> pages;
  final List<BookmarkEntry> bookmarks;
  final Function(int) onSurah, onJuz, onPage;
  final Function(int)? onPageJump;
  final Function(BookmarkEntry) onBookmark;
  final VoidCallback onTranslate;

  const MushafDrawer({
    super.key,
    required this.curSurah,
    required this.curPageIdx,
    required this.pages,
    required this.bookmarks,
    required this.onSurah,
    required this.onJuz,
    required this.onPage,
    this.onPageJump,
    required this.onBookmark,
    required this.onTranslate,
  });
  @override
  State<MushafDrawer> createState() => _MushafDrawerState();
}

class _MushafDrawerState extends State<MushafDrawer> {
  int _panel = 0;
  final _ctrl = TextEditingController();
  String _q = '';

  static Map<int, int> _buildJuzFirstSurah() {
    final map = <int, int>{};
    for (int s = 1; s <= q.totalSurahCount; s++) {
      final cnt = q.getVerseCount(s);
      for (int v = 1; v <= cnt; v++) {
        final juz = q.getJuzNumber(s, v);
        if (!map.containsKey(juz)) map[juz] = s;
      }
    }
    return map;
  }

  static Map<int, int>? _juzFirstSurahCache;

  static Map<int, int> get _juzFirstSurah =>
      _juzFirstSurahCache ??= _buildJuzFirstSurah();

  String _type(int s) {
    const m = [
      1,
      6,
      7,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      23,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      50,
      51,
      52,
      53,
      54,
      56,
      67,
      68,
      69,
      70,
      71,
      72,
      73,
      74,
      75,
      76,
      77,
      78,
      79,
      80,
      81,
      82,
      83,
      84,
      85,
      86,
      87,
      88,
      89,
      90,
      91,
      92,
      93,
      94,
      95,
      96,
      97,
      100,
      101,
      102,
      103,
      104,
      105,
      106,
      107,
      108,
      109,
      111,
      112,
      113,
      114,
    ];
    return m.contains(s) ? 'Makkiyyah' : 'Madaniyyah';
  }

  List<int> get _surahs =>
      List.generate(q.totalSurahCount, (i) => i + 1)
          .where(
            (i) =>
                _q.isEmpty ||
                q.getSurahName(i).toLowerCase().contains(_q.toLowerCase()) ||
                q.getSurahNameArabic(i).contains(_q),
          )
          .toList();

  List<int> get _juzs =>
      List.generate(30, (i) => i + 1).where((j) {
        if (_q.isEmpty) return true;
        final surah = _juzFirstSurah[j] ?? 1;
        return '$j'.contains(_q) ||
            q.getSurahName(surah).toLowerCase().contains(_q.toLowerCase()) ||
            q.getSurahNameArabic(surah).contains(_q);
      }).toList();

  void _setPanel(int p) => setState(() {
    _panel = (_panel == p) ? 0 : p;
    _q = '';
    _ctrl.clear();
  });
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.drawerBg;

    return Drawer(
      backgroundColor: bgColor,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          SafeArea(bottom: false, child: _hdr()),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.1),
                  AppColors.gold,
                  isDark ? Colors.white24 : AppColors.dark,
                  AppColors.gold,
                  AppColors.gold.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                _NavBtn(
                  label: 'Surah',
                  icon: Icons.format_list_bulleted_rounded,
                  active: _panel == 1,
                  onTap: () => _setPanel(1),
                ),
                const SizedBox(width: 8),
                _NavBtn(
                  label: 'Juz',
                  icon: Icons.grid_view_rounded,
                  active: _panel == 2,
                  onTap: () => _setPanel(2),
                ),
                const SizedBox(width: 8),
                _NavBtn(
                  label: 'Hal',
                  icon: Icons.auto_stories_rounded,
                  active: _panel == 3,
                  onTap: () => _setPanel(3),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
          const SafeArea(top: false, child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  Widget _hdr() => CustomPaint(
    painter: const _DrawerHeaderPainter(),
    child: SizedBox(
      width: double.infinity,
      height: 110,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القرآن الكريم',
              style: AppTextStyle.quranSurahNameStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            Text(
              'Al-Quran Al-Karim',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _body() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_panel == 0) return _menu();
    String hintText =
        _panel == 1
            ? 'Cari Surah...'
            : _panel == 2
            ? 'Cari Juz...'
            : 'Cari halaman 1 - 604';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F2E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _q = v),
              keyboardType:
                  _panel == 3 ? TextInputType.number : TextInputType.text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.dark,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: (isDark ? Colors.white : AppColors.dark).withValues(
                    alpha: 0.35,
                  ),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.gold,
                  size: 19,
                ),
                suffixIcon:
                    _q.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: (isDark ? Colors.white : AppColors.dark)
                                .withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _q = '');
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),
        Expanded(child: _list()),
      ],
    );
  }

  Widget _list() {
    if (_panel == 1) {
      return _SurahList(
        surahs: _surahs,
        cur: widget.curSurah,
        type: _type,
        onTap: widget.onSurah,
      );
    }
    if (_panel == 2) {
      return _JuzList(
        juzs: _juzs,
        juzFirstSurah: _juzFirstSurah,
        onTap: widget.onJuz,
      );
    }
    if (_panel == 3) {
      final filtered =
          _q.isEmpty
              ? widget.pages
              : widget.pages.where((p) => '${p.pageNum}'.contains(_q)).toList();
      return _PageList(
        pages: filtered,
        curIdx: widget.curPageIdx,
        onTap: widget.onPage,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _menu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.only(top: 4),
      children: [
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.bookmark_rounded,
          label: 'Semua Penanda',
          onTap: () async {
            Navigator.pop(context);
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
            );
            if (res != null && res is Map && res.containsKey('page')) {
              if (widget.onPageJump != null) {
                widget.onPageJump!(res['page']);
              } else {
                widget.onPage(res['page']);
              }
            }
          },
        ),
        _MenuTile(
          icon: Icons.download_for_offline_rounded,
          label: 'Offline & Download',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OfflineDownloadScreen()),
            );
          },
        ),
        _MenuTile(
          icon: Icons.settings_rounded,
          label: 'Pengaturan',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Menu Lainnya',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        _MenuTile(
          icon: Icons.translate_rounded,
          label: 'Terjemah & Tafsir',
          onTap: () {
            final nav = Navigator.of(context);
            final onTranslate = widget.onTranslate;
            nav.pop();
            Future.delayed(const Duration(milliseconds: 300), () {
              onTranslate();
            });
          },
        ),
        _MenuTile(
          icon: Icons.access_time_rounded,
          label: 'Jadwal Sholat',
          onTap: () {
            final nav = Navigator.of(context);
            nav.pop();
            Future.delayed(const Duration(milliseconds: 300), () {
              nav.push(
                MaterialPageRoute(builder: (_) => const PrayerScheduleScreen()),
              );
            });
          },
        ),
        _MenuTile(
          icon: Icons.headphones_rounded,
          label: 'Murattal & Hafalan',
          onTap: () {
            final nav = Navigator.of(context);
            nav.pop();
            Future.delayed(const Duration(milliseconds: 300), () {
              nav.push(
                MaterialPageRoute(builder: (_) => const HafalanScreen()),
              );
            });
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Al-Quran Digital',
            style: TextStyle(
              fontSize: 11,
              color: (isDark ? Colors.white : AppColors.dark).withValues(
                alpha: 0.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurahList extends StatelessWidget {
  final List<int> surahs;
  final int cur;
  final String Function(int) type;
  final Function(int) onTap;
  const _SurahList({
    required this.surahs,
    required this.cur,
    required this.type,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: surahs.length,
      separatorBuilder:
          (_, _) => Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: AppColors.gold.withValues(alpha: 0.2),
          ),
      itemBuilder: (_, i) {
        final s = surahs[i];
        final active = s == cur;
        return InkWell(
          onTap: () => onTap(s),
          child: Container(
            color:
                active
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                _DiamondBadge(n: s, active: active),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$s. ${q.getSurahName(s)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${q.getVerseCount(s)} Ayat · ${type(s)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  q.getSurahNameArabic(s),
                  style: AppTextStyle.quranSurahNameStyle(
                    fontSize: 18,
                    color:
                        active
                            ? AppColors.gold
                            : textColor.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  final List<int> juzs;
  final Map<int, int> juzFirstSurah;
  final Function(int) onTap;
  const _JuzList({
    required this.juzs,
    required this.juzFirstSurah,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: juzs.length,
      separatorBuilder:
          (_, _) => Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: AppColors.gold.withValues(alpha: 0.2),
          ),
      itemBuilder: (_, i) {
        final juz = juzs[i];
        final s = juzFirstSurah[juz] ?? 1;
        return InkWell(
          onTap: () => onTap(juz),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _DiamondBadge(n: juz, active: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$juz. Juz $juz',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Dari ${q.getSurahName(s)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  q.getSurahNameArabic(s),
                  style: AppTextStyle.quranSurahNameStyle(
                    fontSize: 16,
                    color: textColor.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageList extends StatelessWidget {
  final List<PageData> pages;
  final int curIdx;
  final Function(int) onTap;
  const _PageList({
    required this.pages,
    required this.curIdx,
    required this.onTap,
  });
  String _prev(PageData p) {
    final t = QuranUtils.getCleanVerse(
      p.verses.first.surah,
      p.verses.first.verse,
      verseEndSymbol: false,
    );
    return t.length > 45 ? '${t.substring(0, 45)}...' : t;
  }

  bool _newSurah(int i) => i == 0 || pages[i].surah != pages[i - 1].surah;
  bool _isLast(int i) =>
      i == pages.length - 1 || pages[i + 1].surah != pages[i].surah;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: pages.length,
      itemBuilder: (_, i) {
        final pg = pages[i];
        final isCur = i == curIdx;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_newSurah(i))
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF252525)
                          : AppColors.dark.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      pg.surahName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      pg.surahNameAr,
                      style: AppTextStyle.quranSurahNameStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: () => onTap(pg.pageNum - 1),
              child: Container(
                margin: EdgeInsets.fromLTRB(12, 0, 12, _isLast(i) ? 0 : 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isCur
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF7F2E8).withValues(alpha: 0.5),
                  border:
                      isCur
                          ? Border.all(color: AppColors.gold, width: 1)
                          : null,
                  borderRadius:
                      _isLast(i)
                          ? const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          )
                          : BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isCur
                                ? AppColors.gold
                                : AppColors.gold.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${pg.pageNum}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isCur ? Colors.white : textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _prev(pg),
                        style: AppTextStyle.quranPageInfoStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pg.verses.first.verse}–${pg.verses.last.verse}',
                      style: TextStyle(
                        fontSize: 9,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color:
                active
                    ? (isDark ? AppColors.gold : AppColors.dark)
                    : AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  active
                      ? (isDark ? AppColors.gold : AppColors.dark)
                      : AppColors.gold.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : textColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gold),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiamondBadge extends StatelessWidget {
  final int n;
  final bool active;
  const _DiamondBadge({required this.n, required this.active});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _DiamondBadgePainter(active: active),
        child: Center(
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? AppColors.gold : textColor.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiamondBadgePainter extends CustomPainter {
  final bool active;
  const _DiamondBadgePainter({required this.active});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    final path =
        Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color =
            (active
                ? AppColors.gold.withValues(alpha: 0.15)
                : AppColors.gold.withValues(alpha: 0.08))
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color =
            (active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DrawerHeaderPainter extends CustomPainter {
  const _DrawerHeaderPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.dark, AppColors.dark.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    final p =
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
    const step = 22.0;
    for (double x = 0; x < w; x += step) {
      for (double y = 0; y < h; y += step) {
        final path =
            Path()
              ..moveTo(x + step / 2, y)
              ..lineTo(x + step, y + step / 2)
              ..lineTo(x + step / 2, y + step)
              ..lineTo(x, y + step / 2)
              ..close();
        canvas.drawPath(path, p);
      }
    }
    canvas.drawLine(
      Offset(0, h - 1),
      Offset(w, h - 1),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
