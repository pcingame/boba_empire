# SFX — hiệu ứng âm thanh

Thả các file `.mp3` vào đây với **đúng tên** để game tự dùng (khai báo ở
`lib/audio/audio_service.dart`, enum `Sfx`):

| File           | Khi nào phát                                  |
| -------------- | --------------------------------------------- |
| `tap.mp3`      | Chạm ly pha trà                               |
| `buy.mp3`      | Mua/nâng cấp nguồn thu                         |
| `unlock.mp3`   | Mở khóa giai đoạn mới                          |
| `prestige.mp3` | Nhượng quyền thành công                        |
| `vip.mp3`      | Thu khách VIP (nhận Kim Cương)                 |
| `reward.mp3`   | Nhận thưởng (Mưa vàng / Tiền tức thì)          |

- Chưa có file thì **game vẫn chạy im lặng** — thiếu asset được bỏ qua, không
  lỗi (xem `flame_audio_service.dart`).
- Nên dùng SFX ngắn (< 1s), nhẹ. Nguồn miễn phí thương mại: freesound.org
  (lọc CC0), mixkit.co, pixabay.com/sound-effects.
- Đổi file phải **hot RESTART** (không phải hot reload) để nạp lại cache.
