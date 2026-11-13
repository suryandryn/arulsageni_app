import 'package:flutter/widgets.dart';

/// Emoji yang sering dipakai di chat; sama dengan panel web
/// (`resources/js/lib/emoji.ts` di repo dashboard).
final grupEmoji = <(String, List<String>)>[
  (
    'Wajah',
    '😀😃😄😁😆😅😂🤣😊😇🙂😉😌😍🥰😘😋😛🤗🤭🤔🤨😐😑😶🙄😏😴😪😮😯😲🥺😢😭😥😓😞😔😟😕🙁😣😖😫😩🥱😤😠😡🤒🤕🤧😷🥴😵🤢🤮😎🤓'
        .characters
        .toList(),
  ),
  ('Tangan & hati', '👍👎👌🤞🤟👋🙏👏🙌💪🤝👆👇👉👈❤️🧡💛💚💙💜🤍🖤💔💯✨🔥⭐🌟'.characters.toList()),
  ('Lainnya', '🌿🍃🌱🌸🌹🌼🌙⛅☕🍵💊💉🩺🩹🏥🚑🕌📿📅⏰⌛📍📞📱✅❌❓❗🎉🎁'.characters.toList()),
];
