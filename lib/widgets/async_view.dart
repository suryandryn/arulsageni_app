import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';

/// Memuat data dari [Repository] dan memuat ulang otomatis saat data berubah.
///
/// Bila `load` bergantung pada nilai dari luar (filter, tanggal), beri widget
/// ini `key: ValueKey(nilai)` agar dimuat ulang ketika nilainya berganti.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder});

  final Future<T> Function(Repository repo) load;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  Repository? _repo;
  late Future<T> _future;
  T? _terakhir;
  bool _adaData = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.read<Repository>();
    if (!identical(repo, _repo)) {
      _repo?.removeListener(_muatUlang);
      _repo = repo..addListener(_muatUlang);
      _future = widget.load(repo);
    }
  }

  void _muatUlang() {
    if (mounted) setState(() => _future = widget.load(_repo!));
  }

  @override
  void dispose() {
    _repo?.removeListener(_muatUlang);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Gagal memuat data.\n${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _muatUlang, child: const Text('Coba lagi')),
                ],
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.done) {
          _terakhir = snap.data;
          _adaData = true;
        }
        // Tampilkan data lama saat memuat ulang agar tidak berkedip.
        if (_adaData) return widget.builder(context, _terakhir as T);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
