# SFX — hiệu ứng âm thanh

Các file `.wav` ở đây được game tự dùng theo **đúng tên** (khai báo ở
`lib/audio/audio_service.dart`, enum `Sfx`):

| File           | Khi nào phát                          | Nguồn (file gốc)     |
| -------------- | ------------------------------------- | -------------------- |
| `tap.wav`      | Chạm ly pha trà                       | glass_002            |
| `buy.wav`      | Mua/nâng cấp nguồn thu                 | confirmation_001     |
| `unlock.wav`   | Mở khóa giai đoạn mới                  | open_002             |
| `prestige.wav` | Nhượng quyền thành công                | bong_001             |
| `vip.wav`      | Thu khách VIP (nhận Kim Cương)         | pluck_001            |
| `reward.wav`   | Nhận thưởng (Mưa vàng / Tiền tức thì)  | select_005           |

## Nguồn & giấy phép

Bộ mặc định lấy từ Kenney **Interface Sounds** (đóng gói bởi Calinou),
giấy phép **CC0-1.0** — miễn phí hoàn toàn, dùng thương mại, **không cần ghi
công**. <https://github.com/Calinou/kenney-interface-sounds>

## Tải lại / đổi bộ tiếng

```
bash scripts/fetch_sfx.sh
```

Muốn đổi tiếng khác: sửa bảng ánh xạ trong `scripts/fetch_sfx.sh` (vế phải là
tên file trong repo nguồn) rồi chạy lại.

- Đổi/thêm file phải **HOT RESTART** (không phải hot reload) để nạp lại cache.
- Thiếu file nào thì phần đó chạy **im lặng**, không lỗi
  (xem `lib/audio/flame_audio_service.dart`).
- Nguồn khác dùng thương mại: pixabay.com/sound-effects, mixkit.co, kenney.nl,
  freesound.org (lọc CC0).
