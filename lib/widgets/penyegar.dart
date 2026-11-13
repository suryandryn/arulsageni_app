import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';

/// Menyegarkan semua layar ([Repository.segarkan]) saat aplikasi kembali dibuka dan
/// tiap [jeda] selama aplikasi tampil, agar perubahan dari panel web atau perangkat
/// lain ikut terlihat (hosting tanpa websocket).
class Penyegar extends StatefulWidget {
  const Penyegar({super.key, required this.child, this.jeda = const Duration(seconds: 30)});

  final Widget child;
  final Duration jeda;

  @override
  State<Penyegar> createState() => _PenyegarState();
}

class _PenyegarState extends State<Penyegar> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(widget.jeda, (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) _segarkan();
    });
  }

  void _segarkan() {
    if (mounted) context.read<Repository>().segarkan();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _segarkan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
