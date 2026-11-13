import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/klinik.dart';
import '../../core/theme.dart';
import '../../state/session.dart';
import '../../widgets/ui.dart';
import 'auth_layout.dart';

class AkunBaruPage extends StatefulWidget {
  const AkunBaruPage({super.key});

  @override
  State<AkunBaruPage> createState() => _AkunBaruPageState();
}

class _AkunBaruPageState extends State<AkunBaruPage> {
  final _nama = TextEditingController();
  final _hp = TextEditingController();
  final _sandi = TextEditingController();
  final _ulangi = TextEditingController();
  bool _proses = false;

  @override
  void dispose() {
    for (final c in [_nama, _hp, _sandi, _ulangi]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _daftar() async {
    FocusScope.of(context).unfocus();
    if (_nama.text.trim().isEmpty || _hp.text.trim().isEmpty) {
      return toast(context, 'Lengkapi', 'Isi nama dan nomor HP.');
    }
    if (_sandi.text.length < 6) return toast(context, 'Kata sandi terlalu pendek', 'Minimal 6 karakter.');
    if (_sandi.text != _ulangi.text) {
      return toast(context, 'Kata sandi tidak sama', 'Ketik ulang kata sandi yang sama.');
    }
    setState(() => _proses = true);
    try {
      await context.read<Session>().daftarAkun(nama: _nama.text, noHp: _hp.text, sandi: _sandi.text);
      if (!mounted) return;
      toast(context, 'Akun dibuat', 'Selamat datang di ${Klinik.nama}');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, 'Gagal mendaftar', '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      kembali: true,
      children: [
        const AuthHero(
          judul: 'Buat Akun Pasien',
          keterangan: 'Untuk mendaftar berobat dan melihat jadwal janji temu Anda.',
          ukuranFoto: 96,
        ),
        AutofillGroup(
          child: Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Label('Nama lengkap', atas: 0),
                TextField(
                  controller: _nama,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(hintText: 'Sesuai KTP'),
                ),
                const Label('Nomor HP (WhatsApp)'),
                TextField(
                  controller: _hp,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
                  decoration: const InputDecoration(hintText: '08xxxxxxxxxx'),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Dipakai untuk masuk dan dihubungi admin.', style: tsCap),
                ),
                const Label('Kata sandi'),
                _KolomSandi(controller: _sandi, petunjuk: 'Minimal 6 karakter', aksi: TextInputAction.next),
                const Label('Ulangi kata sandi'),
                _KolomSandi(controller: _ulangi, petunjuk: 'Ketik ulang kata sandi', onSelesai: _daftar),
                Tombol('Daftar dan Masuk', memuat: _proses, onPressed: _daftar),
              ],
            ),
          ),
        ),
        AuthTautan(
          teks: 'Sudah punya akun?',
          tautan: 'Masuk',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Kolom kata sandi dengan tombol tampilkan/sembunyikan.
class _KolomSandi extends StatefulWidget {
  const _KolomSandi({
    required this.controller,
    required this.petunjuk,
    this.aksi = TextInputAction.done,
    this.onSelesai,
  });

  final TextEditingController controller;
  final String petunjuk;
  final TextInputAction aksi;
  final VoidCallback? onSelesai;

  @override
  State<_KolomSandi> createState() => _KolomSandiState();
}

class _KolomSandiState extends State<_KolomSandi> {
  bool _tersembunyi = true;

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    obscureText: _tersembunyi,
    textInputAction: widget.aksi,
    autofillHints: const [AutofillHints.newPassword],
    onSubmitted: widget.onSelesai == null ? null : (_) => widget.onSelesai!(),
    decoration: InputDecoration(
      hintText: widget.petunjuk,
      suffixIcon: IconButton(
        tooltip: _tersembunyi ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
        icon: Icon(_tersembunyi ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
        onPressed: () => setState(() => _tersembunyi = !_tersembunyi),
      ),
    ),
  );
}
