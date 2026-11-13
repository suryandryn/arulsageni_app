import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/emoji.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../widgets/async_view.dart';
import '../../widgets/ui.dart';

/// Isi chat antara satu akun pasien dan admin: gelembung pesan (centang terkirim/dibaca),
/// animasi "sedang mengetik", panel emoji, dan kolom kirim.
///
/// [terlihat] = layar sedang tampil; pesan pihak lain ditandai dibaca, dan pesan baru,
/// status dibaca, serta status mengetik diperiksa tiap 3 detik (hosting tanpa websocket).
class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.pasienId, required this.sebagaiAdmin, this.terlihat = true});

  final String pasienId;
  final bool sebagaiAdmin;
  final bool terlihat;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  static const _jedaPolling = Duration(seconds: 3);
  static const _jedaSinyalKetik = Duration(seconds: 3);

  final _input = TextEditingController();
  final _fokus = FocusNode();
  late final Repository _repo;
  Timer? _polling;
  bool _memeriksa = false;
  bool _panelEmoji = false;

  /// Waktu sinyal "sedang mengetik" terakhir dikirim; null = tidak sedang mengetik.
  DateTime? _terakhirKetik;

  @override
  void initState() {
    super.initState();
    _repo = context.read<Repository>();
    _input.addListener(_saatKetik);
    _aturPolling();
  }

  @override
  void didUpdateWidget(ChatView old) {
    super.didUpdateWidget(old);
    if (old.terlihat != widget.terlihat || old.pasienId != widget.pasienId) {
      if (!widget.terlihat) {
        _berhentiMengetik(old.pasienId);
        _panelEmoji = false;
      }
      _aturPolling();
      // Kembali tampil: segarkan status mengetik/dibaca tanpa menunggu putaran berikutnya.
      if (widget.terlihat) _periksa();
    }
  }

  void _aturPolling() {
    _polling?.cancel();
    _polling = widget.terlihat ? Timer.periodic(_jedaPolling, (_) => _periksa()) : null;
  }

  Future<void> _periksa() async {
    // Lewati bila aplikasi di latar belakang atau pemeriksaan sebelumnya belum selesai.
    if (_memeriksa || WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    _memeriksa = true;
    try {
      await _repo.periksaPesanBaru(widget.pasienId);
    } catch (_) {
      // Koneksi putus sesaat: coba lagi di putaran berikutnya.
    } finally {
      _memeriksa = false;
    }
  }

  // ---- Sinyal "sedang mengetik" ke lawan bicara

  void _saatKetik() {
    final ada = _input.text.trim().isNotEmpty;
    final sekarang = DateTime.now();
    if (ada && (_terakhirKetik == null || sekarang.difference(_terakhirKetik!) > _jedaSinyalKetik)) {
      _terakhirKetik = sekarang;
      _sinyal(widget.pasienId, true);
    } else if (!ada) {
      _berhentiMengetik(widget.pasienId);
    }
  }

  void _berhentiMengetik(String pasienId) {
    if (_terakhirKetik == null) return;
    _terakhirKetik = null;
    _sinyal(pasienId, false);
  }

  void _sinyal(String pasienId, bool aktif) {
    unawaited(() async {
      try {
        await _repo.kirimMengetik(pasienId, aktif: aktif);
      } catch (_) {
        // Tidak penting bila gagal; status kedaluwarsa sendiri di server.
      }
    }());
  }

  @override
  void dispose() {
    _polling?.cancel();
    _berhentiMengetik(widget.pasienId);
    _input.dispose();
    _fokus.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final isi = _input.text.trim();
    if (isi.isEmpty) return;
    // Server menghapus status mengetik saat pesan masuk; tidak perlu sinyal berhenti.
    _terakhirKetik = null;
    _input.clear();
    try {
      await _repo.kirimPesan(widget.pasienId, isi, dariAdmin: widget.sebagaiAdmin);
    } catch (e) {
      // Kembalikan teks agar tidak perlu diketik ulang.
      if (_input.text.isEmpty) _input.text = isi;
      if (mounted) toast(context, 'Pesan belum terkirim', '$e');
    }
  }

  // ---- Emoji

  void _aturPanelEmoji(bool tampil) {
    if (tampil) _fokus.unfocus();
    setState(() => _panelEmoji = tampil);
    if (!tampil) _fokus.requestFocus();
  }

  void _sisipkan(String emoji) {
    final v = _input.value;
    final s = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    _input.value = TextEditingValue(
      text: v.text.replaceRange(s.start, s.end, emoji),
      selection: TextSelection.collapsed(offset: s.start + emoji.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali menutup panel emoji lebih dulu.
      canPop: !_panelEmoji,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _panelEmoji) setState(() => _panelEmoji = false);
      },
      child: Column(
        children: [
          Expanded(
            child: AsyncView(
              load: (repo) => repo.pesan(widget.pasienId),
              builder: (context, list) {
                final belum = list.any((m) => m.dariAdmin != widget.sebagaiAdmin && !m.dibaca);
                if (widget.terlihat && belum) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _repo.tandaiChatDibaca(widget.pasienId, olehAdmin: widget.sebagaiAdmin);
                  });
                }
                return ValueListenableBuilder<bool>(
                  valueListenable: _repo.lawanMengetik(widget.pasienId),
                  builder: (context, mengetik, _) {
                    final tampilMengetik = mengetik && widget.terlihat;
                    if (list.isEmpty && !tampilMengetik) {
                      return const Align(
                        alignment: Alignment.topLeft,
                        child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada pesan.', style: tsMut)),
                      );
                    }
                    final terbalik = list.reversed.toList();
                    final geser = tampilMengetik ? 1 : 0;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: terbalik.length + geser,
                      itemBuilder: (context, i) {
                        if (tampilMengetik && i == 0) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: _GelembungMengetik(siapa: widget.sebagaiAdmin ? 'Pasien' : 'Admin'),
                          );
                        }
                        final m = terbalik[i - geser];
                        return _Gelembung(isi: m.isi, waktu: m.waktu, saya: m.dariAdmin == widget.sebagaiAdmin, dibaca: m.dibaca);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // .kirim
          Container(
            color: AppColors.bg,
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: _panelEmoji ? 'Keyboard' : 'Emoji',
                  color: AppColors.mut,
                  icon: Icon(_panelEmoji ? Icons.keyboard_outlined : Icons.emoji_emotions_outlined),
                  onPressed: () => _aturPanelEmoji(!_panelEmoji),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _fokus,
                    maxLength: 1000,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Tulis pesan...', counterText: ''),
                    onTap: () {
                      if (_panelEmoji) setState(() => _panelEmoji = false);
                    },
                    onSubmitted: (_) => _kirim(),
                  ),
                ),
                const SizedBox(width: 8),
                // Nonaktif selama isian kosong (sama dengan panel web). Isian dikosongkan
                // sebelum dikirim, jadi ketukan ganda tidak mengirim pesan dua kali.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _input,
                  builder: (context, v, _) => IconButton.filled(
                    tooltip: 'Kirim',
                    onPressed: v.text.trim().isEmpty ? null : _kirim,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.pri,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.pri.withValues(alpha: 0.4),
                      disabledForegroundColor: Colors.white,
                      fixedSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 22),
                  ),
                ),
              ],
            ),
          ),
          if (_panelEmoji) _PanelEmoji(onPilih: _sisipkan),
        ],
      ),
    );
  }
}

class _Gelembung extends StatelessWidget {
  const _Gelembung({required this.isi, required this.waktu, required this.saya, required this.dibaca});

  final String isi;
  final DateTime waktu;
  final bool saya;
  final bool dibaca;

  @override
  Widget build(BuildContext context) {
    final warna = saya ? Colors.white : AppColors.tx;
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
            Text(isi, style: TextStyle(color: warna)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Opacity(opacity: 0.75, child: Text(fmtWaktu(waktu), style: TextStyle(fontSize: 11, color: warna))),
                if (saya) ...[
                  const SizedBox(width: 4),
                  Icon(
                    dibaca ? Icons.done_all : Icons.done,
                    size: 15,
                    // Biru muda = sudah dibaca lawan, putih redup = terkirim.
                    color: dibaca ? const Color(0xFF9AD8FF) : Colors.white70,
                    semanticLabel: dibaca ? 'Dibaca' : 'Terkirim',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gelembung tiga titik yang melompat bergantian.
class _GelembungMengetik extends StatefulWidget {
  const _GelembungMengetik({required this.siapa});

  final String siapa;

  @override
  State<_GelembungMengetik> createState() => _GelembungMengetikState();
}

class _GelembungMengetikState extends State<_GelembungMengetik> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diam = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '${widget.siapa} sedang mengetik',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bd),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) _titik(diam ? 0 : (_anim.value - i * 0.15) % 1.0),
            ],
          ),
        ),
      ),
    );
  }

  /// [t] 0..1 dalam satu putaran; titik naik-turun di 40% pertama putarannya.
  Widget _titik(double t) {
    final naik = t < 0.4 ? math.sin(t / 0.4 * math.pi) : 0.0;
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      transform: Matrix4.translationValues(0, -5 * naik, 0),
      decoration: BoxDecoration(
        color: AppColors.mut.withValues(alpha: 0.4 + 0.6 * naik),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PanelEmoji extends StatelessWidget {
  const _PanelEmoji({required this.onPilih});

  final ValueChanged<String> onPilih;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.bd)),
      ),
      child: CustomScrollView(
        slivers: [
          for (final (nama, isi) in grupEmoji) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              sliver: SliverToBoxAdapter(child: Text(nama, style: tsMut.copyWith(fontSize: 12))),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 46),
                itemCount: isi.length,
                itemBuilder: (context, i) => InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPilih(isi[i]),
                  child: Center(child: Text(isi[i], style: const TextStyle(fontSize: 26))),
                ),
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
        ],
      ),
    );
  }
}
