/// Nhắc tên (@tag) trong chat Hội — thuần phía client: tin vẫn là chữ thường, người nhận nhận ra bằng cách khớp
/// "@" + biệt danh một thành viên (biệt danh không trùng trong cùng hội, không phân biệt hoa thường — xem
/// guild_members_nick_idx). Biệt danh có thể có khoảng trắng/emoji ("🐶áu áu#2") nên khớp theo TÊN DÀI NHẤT.
library;

/// Một lần nhắc trong tin: [start, end) là đoạn "@tên" (gồm cả '@'), [nickname] là biệt danh khớp (đúng chữ hoa
/// thường của danh sách thành viên).
class MentionSpan {
  const MentionSpan(this.start, this.end, this.nickname);
  final int start;
  final int end;
  final String nickname;
}

final _wordChar = RegExp(r'[\p{L}\p{N}_]', unicode: true);

bool _isWordChar(String s) => _wordChar.hasMatch(s);

/// Tìm mọi "@biệt danh" trong [body]. '@' phải ở đầu tin hoặc sau khoảng trắng/dấu câu (không dính vào email
/// "a@b.c"); sau biệt danh phải là hết chuỗi hoặc ký tự không phải chữ/số (để "@An" không khớp trong "@Anh").
List<MentionSpan> findMentions(String body, Iterable<String> nicknames) {
  // Dài trước → "@Bob Lee" thắng "@Bob".
  final names = [...nicknames]..sort((a, b) => b.length.compareTo(a.length));
  final lower = body.toLowerCase();
  final out = <MentionSpan>[];
  var i = 0;
  while (i < body.length) {
    if (body[i] != '@' || (i > 0 && _isWordChar(body[i - 1]))) {
      i++;
      continue;
    }
    MentionSpan? hit;
    for (final n in names) {
      if (n.isEmpty) continue;
      final end = i + 1 + n.length;
      if (end > body.length) continue;
      if (lower.substring(i + 1, end) != n.toLowerCase()) continue;
      if (end < body.length && _isWordChar(body[end])) continue;
      hit = MentionSpan(i, end, n);
      break;
    }
    if (hit == null) {
      i++;
    } else {
      out.add(hit);
      i = hit.end;
    }
  }
  return out;
}

/// [body] có nhắc [nickname] không (không phân biệt hoa thường), xét trong bối cảnh [allNicknames].
bool mentionsNickname(String body, String nickname, Iterable<String> allNicknames) {
  final n = nickname.toLowerCase();
  return findMentions(body, allNicknames).any((m) => m.nickname.toLowerCase() == n);
}

/// Đang gõ dở một lần nhắc ở con trỏ [cursor] không? Trả phần chữ sau '@' (có thể rỗng) hoặc null. '@' phải ở đầu
/// hoặc sau khoảng trắng, không xuống dòng, và phần gõ dài tối đa [maxLen] (độ dài biệt danh tối đa là 20).
String? activeMentionQuery(String text, int cursor, {int maxLen = 20}) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  final at = before.lastIndexOf('@');
  if (at < 0) return null;
  if (at > 0 && !RegExp(r'\s').hasMatch(before[at - 1])) return null;
  final q = before.substring(at + 1);
  if (q.length > maxLen || q.contains('\n') || q.contains('@')) return null;
  return q;
}

/// Gợi ý biệt danh cho phần đang gõ [query]: bắt đầu bằng [query] (không phân biệt hoa thường), bỏ [exclude],
/// tối đa [limit]. Rỗng khi chưa gõ gì thì gợi ý theo thứ tự đầu vào (người đầu danh sách).
List<String> mentionSuggestions(String query, Iterable<String> nicknames,
    {String? exclude, int limit = 5}) {
  final q = query.toLowerCase();
  final out = <String>[];
  for (final n in nicknames) {
    if (exclude != null && n.toLowerCase() == exclude.toLowerCase()) continue;
    if (q.isEmpty || n.toLowerCase().startsWith(q)) out.add(n);
    if (out.length >= limit) break;
  }
  return out;
}

/// Thay phần "@query" đang gõ ở [cursor] bằng "@nickname " và trả (chữ mới, vị trí con trỏ mới).
(String, int) insertMention(String text, int cursor, String nickname) {
  final before = text.substring(0, cursor);
  final at = before.lastIndexOf('@');
  final head = text.substring(0, at);
  final tail = text.substring(cursor);
  // Sau chỗ chèn đã có khoảng trắng thì dùng luôn (không để hai dấu cách), con trỏ nhảy qua nó.
  final spaced = tail.isNotEmpty && RegExp(r'^\s').hasMatch(tail);
  final inserted = spaced ? '@$nickname' : '@$nickname ';
  return ('$head$inserted$tail', head.length + inserted.length + (spaced ? 1 : 0));
}
