import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

/// Isi chat antara satu akun pasien dan admin: gelembung pesan + kolom kirim.
///
/// [terlihat] = layar sedang tampil; pesan pihak lain ditandai dibaca.
// TODO(api): polling `GET /chat?after=` tiap ±5 detik saat terlihat.
class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.pasienId, required this.sebagaiAdmin, this.terlihat = true});

  final String pasienId;
  final bool sebagaiAdmin;
  final bool terlihat;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
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
              final belum = list.any((m) => m.dariAdmin != widget.sebagaiAdmin && !m.dibaca);
              if (widget.terlihat && belum) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<Repository>().tandaiChatDibaca(widget.pasienId, olehAdmin: widget.sebagaiAdmin);
                  }
                });
              }
              if (list.isEmpty) {
                return const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada pesan.', style: tsMut)),
                );
              }
              final terbalik = list.reversed.toList();
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: terbalik.length,
                itemBuilder: (context, i) {
                  final m = terbalik[i];
                  final saya = m.dariAdmin == widget.sebagaiAdmin;
                  return Align(
                    alignment: saya ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: saya ? AppColors.pri : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: saya ? AppColors.pri : AppColors.bd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(m.isi, style: TextStyle(color: saya ? Colors.white : AppColors.tx)),
                          Opacity(
                            opacity: 0.75,
                            child: Text(fmtWaktu(m.waktu),
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 11, color: saya ? Colors.white : AppColors.tx)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // .kirim
        Container(
          color: AppColors.bg,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Tulis pesan...', counterText: ''),
                  onSubmitted: (_) => _kirim(),
                ),
              ),
              const SizedBox(width: 8),
              Tombol('Kirim', kecil: true, onPressed: _kirim),
            ],
          ),
        ),
      ],
    );
  }
}
