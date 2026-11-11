import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ubah 08xx / +62xx menjadi 628xx untuk wa.me.
String nomorWaInternasional(String noWa) {
  var n = noWa.replaceAll(RegExp(r'[^0-9]'), '');
  if (n.startsWith('0')) n = '62${n.substring(1)}';
  return n;
}

Future<void> bukaUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak dapat membuka $url')),
    );
  }
}

/// Membuka chat WhatsApp ke nomor tertentu (bukan kirim otomatis).
Future<void> bukaWhatsApp(BuildContext context, String noWa, {String? pesan}) {
  final teks = pesan == null ? '' : '?text=${Uri.encodeComponent(pesan)}';
  return bukaUrl(context, 'https://wa.me/${nomorWaInternasional(noWa)}$teks');
}
