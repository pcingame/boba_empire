/// Chọn ảnh gửi vào chat Hội: thu nhỏ + nén JPEG ở máy; trần dung lượng khớp bucket 'guild-images' (350KB).
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const guildChatImageMaxBytes = 350 * 1024;

/// null = người dùng huỷ. Tách thành provider để test thay bằng bản giả.
typedef GuildChatImagePicker = Future<Uint8List?> Function();

final guildChatImagePickerProvider = Provider<GuildChatImagePicker>((_) => () async {
      final f = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 70);
      return f?.readAsBytes();
    });
