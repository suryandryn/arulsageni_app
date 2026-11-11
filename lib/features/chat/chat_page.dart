import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/async_view.dart';

/// Chat teks antara satu pasien dan admin klinik.
// TODO(api): polling `GET /chat?after=` tiap ±5 detik saat halaman terbuka.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.pasienId, required this.sebagaiAdmin});

  final String pasienId;
  final bool sebagaiAdmin;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final isi = _input.text.trim();
    if (isi.isEmpty) return;
    _input.clear();
    await context.read<Repository>().kirimPesan(widget.pasienId, isi, dariAdmin: widget.sebagaiAdmin);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AsyncView(
            load: (repo) => repo.pesan(widget.pasienId),
            builder: (context, list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(widget.sebagaiAdmin
                      ? 'Belum ada pesan dengan pasien ini.'
                      : 'Ada pertanyaan? Kirim pesan ke admin klinik.'),
                );
              }
              final terbalik = list.reversed.toList();
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: terbalik.length,
                itemBuilder: (context, i) {
                  final m = terbalik[i];
                  final milikSaya = m.dariAdmin == widget.sebagaiAdmin;
                  return Align(
                    alignment: milikSaya ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: milikSaya ? AppColors.hijau : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: milikSaya ? null : Border.all(color: AppColors.garis),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(m.isi, style: TextStyle(color: milikSaya ? Colors.white : null)),
                          const SizedBox(height: 2),
                          Text(fmtWaktu(m.waktu),
                              style: TextStyle(fontSize: 10, color: milikSaya ? Colors.white70 : Colors.black45)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Tulis pesan...', isDense: true),
                    onSubmitted: (_) => _kirim(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(onPressed: _kirim, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Versi halaman penuh (dipakai admin).
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.pasienId, required this.namaPasien});

  final String pasienId;
  final String namaPasien;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(namaPasien)),
      body: ChatPage(pasienId: pasienId, sebagaiAdmin: true),
    );
  }
}
