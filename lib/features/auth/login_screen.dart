import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../state/session.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identitas = TextEditingController();
  final _sandi = TextEditingController();
  bool _sembunyi = true;
  bool _proses = false;
  String? _galat;

  @override
  void dispose() {
    _identitas.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _proses = true;
      _galat = null;
    });
    try {
      await context.read<Session>().login(_identitas.text, _sandi.text);
    } catch (e) {
      if (mounted) setState(() => _galat = '$e');
    } finally {
      if (mounted) setState(() => _proses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(tema: tema),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Masuk', style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Daftar berobat dan lihat jadwal janji Anda.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _identitas,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sandi,
                      obscureText: _sembunyi,
                      onFieldSubmitted: (_) => _masuk(),
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_sembunyi ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _sembunyi = !_sembunyi),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    if (_galat != null) ...[
                      const SizedBox(height: 12),
                      Text(_galat!, style: TextStyle(color: tema.colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _proses ? null : _masuk,
                      child: _proses
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                    if (AppConfig.useMock) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.hijauMuda,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Mode demo\n'
                          'Pasien: 081234567890 / 123456\n'
                          'Admin: admin / admin123',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tema});
  final ThemeData tema;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.hijau, AppColors.hijauTua],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 24, 20, 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundImage: const AssetImage('assets/images/kang_arul.jpeg'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppConfig.namaAplikasi,
            textAlign: TextAlign.center,
            style: tema.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text('Kang Arul Sageni', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
