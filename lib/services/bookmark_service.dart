import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse_ref.dart';

class BookmarkService {
  static const String _key = 'bookmarks_v3';
  static const String _folderKey = 'bookmark_folders';

  static Future<List<BookmarkEntry>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => BookmarkEntry.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> addBookmark(BookmarkEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final List<BookmarkEntry> current = await getBookmarks();

    current.removeWhere(
      (e) => e.surah == entry.surah && e.verse == entry.verse,
    );
    current.insert(0, entry);

    await prefs.setStringList(
      _key,
      current.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> updateBookmark(BookmarkEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final List<BookmarkEntry> current = await getBookmarks();
    final idx = current.indexWhere(
      (e) => e.surah == entry.surah && e.verse == entry.verse,
    );
    if (idx != -1) {
      current[idx] = entry;
      await prefs.setStringList(
        _key,
        current.map((e) => jsonEncode(e.toJson())).toList(),
      );
    }
  }

  static Future<void> removeBookmark(int surah, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    final List<BookmarkEntry> current = await getBookmarks();
    current.removeWhere((e) => e.surah == surah && e.verse == verse);
    await prefs.setStringList(
      _key,
      current.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> toggleFavorite(int surah, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    final List<BookmarkEntry> current = await getBookmarks();
    final idx = current.indexWhere((e) => e.surah == surah && e.verse == verse);
    if (idx != -1) {
      final old = current[idx];
      current[idx] = old.copyWith(isFavorite: !old.isFavorite);
      await prefs.setStringList(
        _key,
        current.map((e) => jsonEncode(e.toJson())).toList(),
      );
    }
  }

  // Folder Management
  static Future<List<String>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_folderKey) ??
        ['Umum', 'Favorit', 'Hafalan', 'Tafsir'];
  }

  static Future<void> addFolder(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = await getFolders();
    if (!current.contains(name)) {
      current.add(name);
      await prefs.setStringList(_folderKey, current);
    }
  }

  static Future<void> renameFolder(String oldName, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = await getFolders();
    final idx = current.indexOf(oldName);
    if (idx != -1) {
      current[idx] = newName;
      await prefs.setStringList(_folderKey, current);

      // Update all bookmarks in this folder
      final bms = await getBookmarks();
      final updatedBms =
          bms
              .map((b) => b.folder == oldName ? b.copyWith(folder: newName) : b)
              .toList();
      await prefs.setStringList(
        _key,
        updatedBms.map((e) => jsonEncode(e.toJson())).toList(),
      );
    }
  }

  static Future<void> deleteFolder(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = await getFolders();
    current.remove(name);
    await prefs.setStringList(_folderKey, current);

    // Move bookmarks back to 'Umum'
    final bms = await getBookmarks();
    final updatedBms =
        bms
            .map((b) => b.folder == name ? b.copyWith(folder: 'Umum') : b)
            .toList();
    await prefs.setStringList(
      _key,
      updatedBms.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
