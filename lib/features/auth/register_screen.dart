import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  final _sandi = TextEditingController();
  bool _proses = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await context.read<Session>().register(nama: _nama.text, noWa: _wa.text, password: _sandi.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nama,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Minimal 3 huruf' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wa,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor WhatsApp', hintText: '08xxxxxxxxxx'),
              validator: (v) {
                final n = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                return n.length < 10 ? 'Nomor WhatsApp tidak valid' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sandi,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi'),
              validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ulangi kata sandi'),
              validator: (v) => v != _sandi.text ? 'Kata sandi tidak sama' : null,
            ),
            if (_galat != null) ...[
              const SizedBox(height: 12),
              Text(_galat!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _proses ? null : _daftar,
              child: _proses
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
