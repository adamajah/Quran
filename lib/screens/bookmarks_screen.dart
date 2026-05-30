import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as q;
import '../constants/quran_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/verse_ref.dart';
import '../widgets/common/premium_card.dart';
import '../services/bookmark_service.dart';
import '../widgets/bookmarks/add_bookmark_sheet.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkEntry> _allBookmarks = [];
  List<BookmarkEntry> _filteredBookmarks = [];
  List<String> _folders = [];
  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  // Last read data
  int? _lastSurah;
  int? _lastVerse;
  int? _lastPage;

  final List<String> _filters = [
    'Semua',
    'Favorit',
    'Hafalan',
    'Terakhir dibaca',
    'Riwayat',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bms = await BookmarkService.getBookmarks();
    final f = await BookmarkService.getFolders();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _allBookmarks = bms;
      _folders = f;
      _lastSurah = prefs.getInt('lastSurah');
      _lastVerse = prefs.getInt('lastVerse') ?? 1;
      _lastPage = prefs.getInt('lastPage');
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      List<BookmarkEntry> list = _allBookmarks;

      if (_selectedFilter == 'Favorit') {
        list =
            list.where((e) => e.isFavorite || e.folder == 'Favorit').toList();
      } else if (_selectedFilter == 'Terakhir dibaca' ||
          _selectedFilter == 'Riwayat') {
        list = list.where((e) => e.folder == 'Riwayat').toList();
      } else if (_selectedFilter == 'Hafalan') {
        list = list.where((e) => e.folder == 'Hafalan').toList();
      } else if (_selectedFilter != 'Semua') {
        list = list.where((e) => e.folder == _selectedFilter).toList();
      }

      if (_searchQuery.isNotEmpty) {
        list =
            list
                .where(
                  (e) =>
                      e.surahName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      e.verse.toString().contains(_searchQuery) ||
                      (e.note?.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();
      }

      _filteredBookmarks = list;
    });
  }

  String _toAr(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          PremiumHeader(
            title: 'Semua Penanda',
            subtitle: 'Kelola catatan dan ayat pilihan Anda',
            actions: [
              IconButton(
                onPressed: _shareApp,
                icon: Icon(Icons.share_rounded, color: textColor),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.gold,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  _buildStats(),
                  const SizedBox(height: 24),
                  if (_lastSurah != null) ...[
                    _buildSectionTitle('Lanjutkan Membaca'),
                    const SizedBox(height: 12),
                    _buildLastReadCard(),
                    const SizedBox(height: 24),
                  ],
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Folder Koleksi'),
                  const SizedBox(height: 12),
                  _buildFolderGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Daftar Penanda'),
                  const SizedBox(height: 12),
                  if (_filteredBookmarks.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredBookmarks.map((bm) => _buildBookmarkCard(bm)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStatItem(
          'Total',
          _allBookmarks.length.toString(),
          Icons.bookmark_rounded,
        ),
        const SizedBox(width: 10),
        _buildStatItem(
          'Favorit',
          _allBookmarks.where((e) => e.isFavorite).length.toString(),
          Icons.star_rounded,
        ),
        const SizedBox(width: 10),
        _buildStatItem(
          'Folder',
          _folders.length.toString(),
          Icons.folder_rounded,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.dark,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: (isDark ? Colors.white : AppColors.dark).withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.dark,
      ),
    );
  }

  Widget _buildLastReadCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252525) : AppColors.gold;
    final iconBgColor =
        isDark
            ? AppColors.gold.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.15);
    final iconColor = isDark ? AppColors.gold : Colors.white;
    final btnColor = isDark ? AppColors.gold : Colors.white;
    final btnTextColor = isDark ? Colors.white : AppColors.gold;
    return PremiumCard(
      color: cardColor,
      onTap:
          () =>
              Navigator.pop(context, {'surah': _lastSurah, 'page': _lastPage}),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book_rounded, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.getSurahName(_lastSurah!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Ayat $_lastVerse • Terakhir dibuka baru saja',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap:
                () => Navigator.pop(context, {
                  'surah': _lastSurah,
                  'page': _lastPage,
                }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Lanjut',
                style: TextStyle(
                  color: btnTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) {
          setState(() => _searchQuery = v);
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Cari surah, ayat, atau catatan...',
          hintStyle: TextStyle(
            color: (isDark ? Colors.white : AppColors.dark).withValues(
              alpha: 0.3,
            ),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.gold,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _filters.map((f) {
              final active = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: active,
                  onSelected: (v) {
                    setState(() => _selectedFilter = f);
                    _applyFilter();
                  },
                  backgroundColor:
                      isDark ? const Color(0xFF252525) : Colors.white,
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                    color:
                        active
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.dark),
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          active
                              ? AppColors.gold
                              : AppColors.gold.withValues(alpha: 0.1),
                    ),
                  ),
                  elevation: 0,
                  pressElevation: 0,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFolderGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 80,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _folders.length + 1,
      itemBuilder: (context, index) {
        if (index == _folders.length) {
          return PremiumCard(
            onTap: _addFolder,
            color: AppColors.gold.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Folder Baru',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        final f = _folders[index];
        final count = _allBookmarks.where((b) => b.folder == f).length;
        final isSystem = [
          'Umum',
          'Favorit',
          'Hafalan',
          'Tafsir',
          'Riwayat',
        ].contains(f);

        return PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: () {
            setState(() => _selectedFilter = f);
            _applyFilter();
          },
          onDelete: isSystem ? null : () => _confirmDeleteFolder(f),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.dark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$count Ayat',
                      style: TextStyle(
                        fontSize: 10,
                        color: (isDark ? Colors.white : AppColors.dark)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookmarkCard(BookmarkEntry bm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: Key(
          '${bm.surah}:${bm.verse}:${bm.timestamp.millisecondsSinceEpoch}',
        ),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _toggleFavorite(bm),
              backgroundColor: AppColors.gold.withValues(alpha: 0.1),
              foregroundColor: AppColors.gold,
              icon:
                  bm.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
              label: 'Favorit',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _shareAyat(bm),
              backgroundColor: AppColors.dark.withValues(alpha: 0.1),
              foregroundColor: AppColors.dark,
              icon: Icons.share_rounded,
              label: 'Share',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _editBookmark(bm),
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              foregroundColor: Colors.blue,
              icon: Icons.edit_note_rounded,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _deleteBookmark(bm),
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
              icon: Icons.delete_outline_rounded,
              label: 'Hapus',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
            ),
          ],
        ),
        child: PremiumCard(
          onTap: () {},
          color:
              bm.highlightColor != null
                  ? Color(bm.highlightColor!).withValues(alpha: 0.05)
                  : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (bm.highlightColor != null
                                  ? Color(bm.highlightColor!)
                                  : AppColors.gold)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bm.folder,
                          style: TextStyle(
                            fontSize: 9,
                            color:
                                bm.highlightColor != null
                                    ? Color(bm.highlightColor!)
                                    : AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${bm.surahName} : ${bm.verse}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _deleteBookmark(bm),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red.withValues(alpha: 0.6),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      bm.highlightColor != null
                          ? Color(bm.highlightColor!).withValues(alpha: 0.1)
                          : AppColors.gold.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      bm.highlightColor != null
                          ? Border.all(
                            color: Color(
                              bm.highlightColor!,
                            ).withValues(alpha: 0.2),
                          )
                          : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: q.getVerse(
                              bm.surah,
                              bm.verse,
                              verseEndSymbol: false,
                            ),
                            style: AppQuranFonts.hafsStyle.copyWith(
                              fontSize: 24,
                              height: 1.85,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: _toAr(bm.verse),
                            style: AppQuranFonts.hafsStyle.copyWith(
                              fontSize: 18,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bm.translation ?? 'Sedang memuat terjemahan...',
                      style: TextStyle(
                        fontSize: 11,
                        color: (isDark ? Colors.white : AppColors.dark)
                            .withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              if (bm.note != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.sticky_note_2_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        bm.note!,
                        style: TextStyle(
                          fontSize: 11,
                          color: (isDark ? Colors.white : AppColors.dark)
                              .withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dibuat pada ${_formatDate(bm.timestamp)}',
                    style: TextStyle(
                      fontSize: 9,
                      color: (isDark ? Colors.white : AppColors.dark)
                          .withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: AppColors.gold.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada penanda tersimpan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ayat yang Anda tandai akan muncul di sini',
            style: TextStyle(
              fontSize: 13,
              color: (isDark ? Colors.white : AppColors.dark).withValues(
                alpha: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tambah Penanda Pertama'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Aplikasi Al-Quran Digital Premium - Yuk tadabbur bareng!',
      ),
    );
  }

  void _shareAyat(BookmarkEntry bm) {
    final text =
        '${q.getVerse(bm.surah, bm.verse, verseEndSymbol: true)}\n\n'
        '${bm.translation ?? ""}\n\n'
        '(Q.S ${bm.surahName}: ${bm.verse})';
    SharePlus.instance.share(ShareParams(text: text));
    HapticFeedback.mediumImpact();
  }

  void _showAddSheet() async {
    final res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBookmarkSheet(),
    );
    if (res == true) _loadData();
  }

  void _editBookmark(BookmarkEntry bm) async {
    final res = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBookmarkSheet(existing: bm),
    );
    if (res == true) _loadData();
  }

  void _addFolder() {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF252525) : AppColors.pageBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Tambah Folder Koleksi',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: ctrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Nama folder...',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
                filled: true,
                fillColor:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.isNotEmpty) {
                    await BookmarkService.addFolder(ctrl.text);
                    if (!context.mounted) return;
                    _loadData();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Tambah'),
              ),
            ],
          ),
    );
  }

  void _toggleFavorite(BookmarkEntry bm) async {
    await BookmarkService.toggleFavorite(bm.surah, bm.verse);
    _loadData();
    HapticFeedback.mediumImpact();
  }

  void _deleteBookmark(BookmarkEntry bm) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF252525) : AppColors.pageBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Hapus Penanda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus penanda ini?',
              style: TextStyle(color: textColor.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await BookmarkService.removeBookmark(bm.surah, bm.verse);
      _loadData();
    }
  }

  void _confirmDeleteFolder(String folderName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF252525) : AppColors.pageBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Hapus Folder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            content: Text(
              'Hapus folder "$folderName"? Penanda di dalamnya akan dipindahkan ke folder "Umum".',
              style: TextStyle(color: textColor.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await BookmarkService.deleteFolder(folderName);
      _loadData();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
