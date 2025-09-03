import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Çeviri sınıfımızı import ediyoruz.
import '../translations.dart';
// Not detay sayfasını import ediyoruz.
import 'note_detail_page.dart';

// Notları listeleyen bir StatefulWidget
class NotesPage extends StatefulWidget {
  // ✅ Dışarıdan gelen dil bilgisini tutar.
  final String lang;
  const NotesPage({super.key, required this.lang});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

// Not listesi sayfasının durumunu yöneten sınıf
class _NotesPageState extends State<NotesPage> {
  // Firebase ve Firestore servisleri
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Mevcut kullanıcının not koleksiyonuna erişim
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('notes');
  }

  // Kullanıcıya kısa bir bildirim (snackbar) gösteren yardımcı metot.
  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // Not oluşturma işlemi
  Future<void> _createNote() async {
    final t = AppTexts.values[widget.lang]!;
    final col = _col;
    if (col == null) {
      _snack(t['noSession']!);
      return;
    }
    final doc = col.doc();
    await doc.set({
      'text': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NoteDetailPage(noteId: doc.id, initialText: '', lang: widget.lang),
      ),
    );
  }

  // Not silme işlemi
  Future<void> _deleteNote(String id) async {
    final t = AppTexts.values[widget.lang]!;
    final col = _col;
    if (col == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t['deleteNoteTitle']!),
        content: Text(t['deleteNoteContent']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t['cancel']!),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t['delete']!),
          ),
        ],
      ),
    );
    if (ok == true) {
      await col.doc(id).delete();
    }
  }

  // Metin önizlemesi oluşturan yardımcı metot
  String _previewOf(String s, Map<String, String> t) {
    final oneLine = s.replaceAll('\n', ' ').trim();
    if (oneLine.isEmpty) return t['emptyNote']!;
    return oneLine.length > 60 ? '${oneLine.substring(0, 60)}…' : oneLine;
  }

  // Zaman damgasını formatlayan yardımcı metot
  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // Sayfanın kullanıcı arayüzü
  @override
  Widget build(BuildContext context) {
    final t = AppTexts.values[widget.lang]!;
    final col = _col;

    return Scaffold(
      appBar: AppBar(title: Text(t['notes']!)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        icon: const Icon(Icons.note_add),
        label: Text(t['newNote']!),
      ),
      body: col == null
          ? Center(child: Text(t['noSessionFound']!))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: col.orderBy('updatedAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('${t['error']!}: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text(t['noNotes']!));
                }
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final id = d.id;
                    final data = d.data();
                    final text = (data['text'] as String?) ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final updatedAt = data['updatedAt'] as Timestamp?;

                    return ListTile(
                      title: Text(
                        _previewOf(text, t),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${t['update']!}: ${_fmtTs(updatedAt)}  •  ${t['creation']!}: ${_fmtTs(createdAt)}',
                      ),
                      leading: const Icon(Icons.note_outlined),
                      trailing: IconButton(
                        tooltip: t['delete']!,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteNote(id),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteDetailPage(
                              noteId: id,
                              initialText: text,
                              lang: widget.lang,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
