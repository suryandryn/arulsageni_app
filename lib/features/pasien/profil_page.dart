import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../state/session.dart';
import '../../widgets/ui.dart';
import 'pasien_shell.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _sandi = TextEditingController();

  @override
  void dispose() {
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    try {
      await context.read<Repository>().ubahSandi(context.read<Session>().user!.id, _sandi.text);
      _sandi.clear();
      if (mounted) toast(context, 'Tersimpan', 'Kata sandi diperbarui.');
    } catch (e) {
      if (mounted) toast(context, 'Gagal', '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user!;
    return Scaffold(
      appBar: headerApp('Profil', aksi: const [TombolNotif()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(user.noHp, style: tsMut),
              ],
            ),
          ),
          Kartu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JudulKartu('Ubah kata sandi'),
                const Label('Sandi baru'),
                TextField(controller: _sandi, obscureText: true),
                Tombol('Simpan sandi', varian: Varian.garis, onPressed: _simpan),
              ],
            ),
          ),
          Tombol('Notifikasi', atas: 0, varian: Varian.garis, onPressed: () => bukaNotifikasi(context)),
          Tombol('Keluar', varian: Varian.merah, onPressed: session.keluar),
        ],
      ),
    );
  }
}
