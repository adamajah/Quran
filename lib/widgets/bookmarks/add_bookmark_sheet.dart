import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import '../../constants/app_colors.dart';
import '../../models/verse_ref.dart';
import '../../services/bookmark_service.dart';

class AddBookmarkSheet extends StatefulWidget {
  final BookmarkEntry? existing;
  final int? initialSurah;
  final int? initialVerse;

  const AddBookmarkSheet({
    super.key,
    this.existing,
    this.initialSurah,
    this.initialVerse,
  });

  @override
  State<AddBookmarkSheet> createState() => _AddBookmarkSheetState();
}

class _AddBookmarkSheetState extends State<AddBookmarkSheet> {
  late int _surah;
  late int _verse;
  late String _folder;
  late bool _isFavorite;
  late int? _highlightColor;
  final _noteCtrl = TextEditingController();
  List<String> _folders = [];

  final List<Color> _colors = [
    const Color(0xFFA07848), // Gold
    const Color(0xFF2E7D32), // Hijau
    const Color(0xFF0D5C78), // Biru
    const Color(0xFFD32F2F), // Merah
    const Color(0xFF6A1B9A), // Ungu
  ];

  @override
  void initState() {
    super.initState();
    _surah = widget.existing?.surah ?? widget.initialSurah ?? 1;
    _verse = widget.existing?.verse ?? widget.initialVerse ?? 1;
    _folder = widget.existing?.folder ?? 'Umum';
    _isFavorite = widget.existing?.isFavorite ?? false;
    _highlightColor = widget.existing?.highlightColor;
    _noteCtrl.text = widget.existing?.note ?? '';
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final f = await BookmarkService.getFolders();
    setState(() => _folders = f);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.pageBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: textColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tambah Penanda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                IconButton(
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.gold, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSelectionRow(cardBg, textColor),
            const SizedBox(height: 20),
            Text('Kategori / Folder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            _buildFolderSelector(cardBg, textColor),
            const SizedBox(height: 20),
            Text('Warna Highlight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            _buildColorSelector(cardBg),
            const SizedBox(height: 20),
            Text('Catatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.3), fontSize: 13),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow(Color cardBg, Color textColor) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildPickerCard('Surah', q.getSurahName(_surah), _showSurahPicker, cardBg, textColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _buildPickerCard('Ayat', '$_verse', _showVersePicker, cardBg, textColor),
        ),
      ],
    );
  }

  void _showSurahPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text('Pilih Surah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 114,
                itemBuilder: (context, index) {
                  final sNum = index + 1;
                  return ListTile(
                    title: Text('$sNum. ${q.getSurahName(sNum)}', style: TextStyle(fontSize: 14, color: textColor)),
                    trailing: Text('${q.getVerseCount(sNum)} Ayat', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.4))),
                    onTap: () {
                      setState(() {
                        _surah = sNum;
                        _verse = 1; // Reset verse to 1 when surah changes
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVersePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final count = q.getVerseCount(_surah);
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text('Pilih Ayat (1 - $count)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemCount: count,
                itemBuilder: (context, index) {
                  final vNum = index + 1;
                  return InkWell(
                    onTap: () {
                      setState(() => _verse = vNum);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _verse == vNum ? AppColors.gold : (isDark ? Colors.white.withOpacity(0.05) : AppColors.pageBg),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text('$vNum', style: TextStyle(color: _verse == vNum ? Colors.white : textColor, fontWeight: FontWeight.bold))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerCard(String label, String value, VoidCallback onTap, Color cardBg, Color textColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.5))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelector(Color cardBg, Color textColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._folders.map((f) {
            final active = _folder == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: active,
                onSelected: (v) => setState(() => _folder = f),
                backgroundColor: cardBg,
                selectedColor: AppColors.gold,
                labelStyle: TextStyle(color: active ? Colors.white : textColor, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
              ),
            );
          }),
          IconButton(
            onPressed: _showAddFolderDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog() {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF252525) : AppColors.pageBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Folder', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Nama folder...',
            hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await BookmarkService.addFolder(ctrl.text);
                await _loadFolders();
                setState(() => _folder = ctrl.text);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(Color cardBg) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _highlightColor = null),
          child: Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: _highlightColor == null ? AppColors.gold : Colors.grey.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.block, size: 16, color: Colors.grey),
          ),
        ),
        ..._colors.map((c) {
          final active = _highlightColor == c.value;
          return GestureDetector(
            onTap: () => setState(() => _highlightColor = c.value),
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: active ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: active ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8)] : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _save() async {
    final entry = BookmarkEntry(
      surah: _surah,
      verse: _verse,
      pageIdx: q.getPageNumber(_surah, _verse) - 1,
      surahName: q.getSurahName(_surah),
      surahNameAr: q.getSurahNameArabic(_surah),
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      folder: _folder,
      isFavorite: _isFavorite,
      highlightColor: _highlightColor,
      timestamp: DateTime.now(),
      translation: 'Terjemahan ayat pilihan ini tersimpan.', 
    );
    
    await BookmarkService.addBookmark(entry);
    if (mounted) Navigator.pop(context, true);
  }
}
