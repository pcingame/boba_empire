# Release Notes — nội dung "Có gì mới" để dán vào console

Mỗi mục dưới đây dán vào **What's New** (App Store Connect) / **What's new in
this release** (Play Console), đúng ngôn ngữ.

**Giới hạn:** Play **≤ 500 ký tự**, App Store ≤ 4000. Mọi bản dưới đây viết
dưới 500 để dùng chung được cho cả hai store. Bản dịch do máy soạn — nên nhờ
người bản ngữ soát.

---

## 1.0.14 (+29) — 2026-10-29

**Bản trước:** 1.0.13 (+28) đã live trên store.

**Nội dung:**
- **Thử thách tháng** (tab Tuần của hub Nhiệm vụ & Quà): 3 mục tiêu cho cả tháng, 150💎 mỗi mục, rương tháng 500💎 + phụ kiện Sử thi trở lên.
- **Phòng truyền thống:** 11 huy hiệu cột mốc trên Hồ sơ của tôi (chỉ bản thân xem được).
- **Quà chào mừng trở lại:** vắng ≥3 ngày tặng 50/100/200💎 (tối đa 1 lần/7 ngày), hiện trong popup offline; thông báo nhắc vắng 3/7 ngày hứa quà khi đủ điều kiện.
- **Tổng kết tuần:** popup số liệu tuần vừa qua khi mở app (xếp sau tiền offline, trước "Có gì mới").
- **Chi nhánh:** MỞ chi nhánh bằng 💎 (30 × (giai đoạn mở − 1); nâng cấp vẫn bằng Xu, chi nhánh đã mở giữ nguyên), thu nhập mỗi cấp 1.2% → 1.5%, thẻ hiện thời gian hoàn vốn.
- **Sửa test** hỏng trong dịp lễ hội (không ảnh hưởng người chơi).

Soạn sẵn: `assets/store/whatsnew_1.0.14/`; hộp "Có gì mới" trong app đã cập nhật (`whatsNewVersion` = 1.0.14). KHÔNG cần chạy SQL mới (mọi thứ trong bản này chỉ ở client). Chưa làm: mô tả store, review notes.

**Lệnh build:** iOS `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify` → Xcode Organizer. Android `flutter build appbundle --release` (versionCode +29).

⚠️ Mọi con số mới (giá 💎 chi nhánh, thưởng Thử thách tháng, mức quà trở lại) là ước lượng chưa playtest. Bản dịch máy chưa có người bản ngữ duyệt. Giá mở chi nhánh bằng 💎 là thay đổi kinh tế đáng chú ý với người chơi mới.

## 1.0.13 (+27) — 2026-10-22

**Bản trước:** 1.0.12 (+26) đã live trên store.

**Nội dung:**
- **Nhân viên, Linh vật, Đấu giá cuối tuần** (trong "Quán của tôi"; Pha theo đơn + Thử thách ngày gộp vào trang Công thức).
- **Khách quen, Thời tiết & Giao hàng, Di sản** (endgame sau Kỷ Nguyên 4).
- **Trang trí quán:** 20 món, 8 ô, 4 chủ đề, thưởng bộ (client-only).
- **Trang Quyền lợi VIP, Thống kê & ảnh khoe;** gửi ảnh trong chat Hội; Boss Thế Giới + Đấu giá chuyển vào hộp Thi đấu.
- **Sửa lỗi:** văng khi rời màn Boss Thế Giới lúc đang refresh; Android nay gửi biên nhận lên server xác thực (trước đây không xác thực); sửa tràn số giá linh vật.

Soạn sẵn: `assets/store/whatsnew_1.0.13/`. CHƯA làm: hộp "Có gì mới" trong app (`whatsNewVersion` vẫn `1.0.12`), mô tả store, review notes.

**BẮT BUỘC trước khi nộp:** chạy các SQL mới của Đấu giá (`auction_schema.sql`) và chat Hội có ảnh nếu chưa chạy; Play Console cần service account cho server xác thực IAP.

**Lệnh build:** iOS `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify` → Xcode Organizer. Android `flutter build appbundle --release` (versionCode +27).

⚠️ Số liệu cân bằng (nhân viên, linh vật, đấu giá, trang trí) là ước lượng, chưa playtest. Bản dịch máy chưa có người bản ngữ duyệt.

### Có gì mới (dán vào console)

#### 🇻🇳 Tiếng Việt (vi)

```
Mới: NHÂN VIÊN, LINH VẬT, KHÁCH QUEN & TRANG TRÍ QUÁN!

• Nhân viên & Linh vật trong "Quán của tôi", đấu giá cuối tuần
• Khách quen, thời tiết, giao hàng và Di sản cho giai đoạn cuối game
• Trang trí quán: 20 món, 8 ô, 4 chủ đề, thưởng khi đủ bộ
• Trang Quyền lợi VIP, Thống kê và ảnh khoe thành tích
• Gửi ảnh trong chat Hội
• Sửa lỗi văng ở Boss Thế Giới, xác thực giao dịch Android
```

#### 🇬🇧 English (en)

```
New: STAFF, PETS, REGULARS & SHOP DECOR!

• Staff & Mascots in "My Shop", plus weekend auctions
• Regular customers, weather, deliveries and Legacy for the late game
• Shop decor: 20 items, 8 slots, 4 themes, set bonuses
• VIP Benefits page, Stats and a shareable brag image
• Send photos in Guild chat
• Fixed a World Boss crash and Android purchase verification
```

#### 🇪🇸 Español (es)

```
Novedad: PERSONAL, MASCOTAS, HABITUALES Y DECORACIÓN

• Personal y mascotas en "Mi tienda", y subastas de fin de semana
• Clientes habituales, clima, repartos y Legado para el final del juego
• Decoración: 20 objetos, 8 huecos, 4 temas y bonus por conjunto
• Página de beneficios VIP, estadísticas e imagen para presumir
• Envía fotos en el chat del gremio
• Corregido un cierre en el Jefe Mundial y la verificación de compras en Android
```

#### 🇧🇷 Português (pt)

```
Novidade: EQUIPE, MASCOTES, CLIENTES FIÉIS E DECORAÇÃO!

• Equipe e mascotes em "Minha loja", e leilões de fim de semana
• Clientes fiéis, clima, entregas e Legado para o fim do jogo
• Decoração: 20 itens, 8 espaços, 4 temas e bônus por conjunto
• Página de benefícios VIP, estatísticas e imagem para compartilhar
• Envie fotos no chat da guilda
• Corrigido um travamento no Chefe Mundial e a verificação de compras no Android
```

#### 🇮🇩 Indonesia (id)

```
Baru: STAF, MASKOT, LANGGANAN & DEKORASI TOKO!

• Staf & Maskot di "Toko Saya", plus lelang akhir pekan
• Pelanggan tetap, cuaca, pengiriman, dan Warisan untuk akhir game
• Dekorasi toko: 20 item, 8 slot, 4 tema, bonus set lengkap
• Halaman Keuntungan VIP, Statistik, dan gambar untuk pamer
• Kirim foto di chat Guild
• Perbaikan crash Boss Dunia dan verifikasi pembelian Android
```

#### 🇰🇷 한국어 (ko)

```
신규: 직원, 마스코트, 단골 & 가게 꾸미기!

• "내 가게"에서 직원·마스코트 관리, 주말 경매
• 단골 손님, 날씨, 배달, 유산 시스템 (후반부 콘텐츠)
• 가게 꾸미기: 20종, 8칸, 4가지 테마, 세트 보너스
• VIP 혜택 페이지, 통계, 자랑용 이미지
• 길드 채팅에서 사진 전송
• 월드 보스 강제 종료 및 Android 결제 검증 수정
```

#### 🇹🇭 ไทย (th)

```
ใหม่: พนักงาน มาสคอต ลูกค้าประจำ และตกแต่งร้าน!

• พนักงานและมาสคอตใน "ร้านของฉัน" พร้อมประมูลสุดสัปดาห์
• ลูกค้าประจำ สภาพอากาศ การจัดส่ง และมรดก สำหรับช่วงท้ายเกม
• ตกแต่งร้าน 20 ชิ้น 8 ช่อง 4 ธีม พร้อมโบนัสครบชุด
• หน้าสิทธิพิเศษ VIP สถิติ และภาพโชว์ผลงาน
• ส่งรูปในแชทกิลด์
• แก้แอปปิดเองที่บอสโลก และการตรวจสอบการซื้อบน Android
```

---

## 1.0.12 (+26) — 2026-10-20

**Bản trước:** 1.0.11 (+25) đã live trên iOS (2026-10-20); Play 1.0.11 đang/đã duyệt.

**Nội dung:**
- **Bạn bè:** tìm theo biệt danh, lời mời, quà ngày, BXH bạn bè, ghé thăm quán, đột kích quán bạn (PvP idle, không ai mất Xu); giới tính hồ sơ.
- **Boss Thế Giới:** boss tuần (Chủ Nhật) + boss ngày cả server, 5 mốc thưởng.
- **Chi nhánh thành phố:** 17 thành phố trên bản đồ, đặc sản, bộ sưu tập, quản lý, sự kiện, chuyên môn, quầy riêng, nhiệm vụ ngày, giao diện bản đồ, BXH Chi nhánh; cấp chi nhánh cộng thu nhập quán chính (+0.5%/cấp).
- **UI:** popup nảy vào, hiệu ứng thưởng/số chạy, BXH xuất hiện lần lượt, boss đỡ rung (tránh mỏi mắt).
- **Không có sản phẩm IAP mới.**

Soạn sẵn: `assets/store/whatsnew_1.0.12/`, `assets/store/description_1.0.12/` (thêm mục Bạn bè & Chi nhánh), hộp "Có gì mới" (`whatsNewVersion` = `1.0.12`), `APP_REVIEW_NOTES_1.0.12.md`, `supabase/all_1.0.12.sql`.

**BẮT BUỘC trước khi nộp:**
- **Supabase — chạy `supabase/all_1.0.12.sql`** (idempotent) TRƯỚC khi người chơi cập nhật: friends, player_gender, world_boss, branch_leaderboard (đã chạy), arena_leaderboard (có đổi). Nếu đổi hằng số boss, cần UPDATE HP hàng boss hiện có.
- Review Notes: dán `APP_REVIEW_NOTES_1.0.12.md`.

**Lệnh build:** iOS `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify` → Xcode Organizer. Android `flutter build appbundle --release` (versionCode +26).

⚠️ Mọi số cân bằng (thưởng chi nhánh, +0.5%/cấp, quầy +6%, quản lý 120💎, boss) là ước lượng, chưa playtest. Bản dịch máy chưa có người bản ngữ duyệt.

### Có gì mới (dán vào console)

#### 🇻🇳 Tiếng Việt (vi)

```
Mới: BẠN BÈ, BOSS THẾ GIỚI & CHI NHÁNH!

• Bạn bè: tìm theo biệt danh, tặng quà mỗi ngày, ghé thăm và đột kích quán bạn
• Boss Thế Giới mỗi Chủ Nhật cùng boss ngày: chạm để gây sát thương, 5 mốc thưởng
• Chi nhánh 17 thành phố trên bản đồ thế giới: sự kiện, nhiệm vụ, quầy riêng, bảng xếp hạng
• Cấp chi nhánh cộng thu nhập quán chính và được giữ khi Nhượng quyền
• Hiệu ứng mượt hơn: popup nảy, thưởng bung đẹp mắt; boss nhún nhẹ, đỡ rung mắt
```

#### 🇬🇧 English (en)

```
New: FRIENDS, WORLD BOSS & CITY BRANCHES!

• Friends: find by nickname, daily gifts, visit and raid your friends' shops
• World Boss every Sunday plus a daily boss: tap to deal damage, 5 reward tiers
• City Branches: 17 cities on a world map with events, quests, stalls and a leaderboard
• Branch levels boost your main shop income and are kept through Franchise
• Smoother visuals: bouncy popups and reward effects; gentler boss hits
```

#### 🇪🇸 Español (es)

```
Novedad: AMIGOS, JEFE MUNDIAL Y SUCURSALES

• Amigos: busca por apodo, regalos diarios, visita y asalta las tiendas de tus amigos
• Jefe Mundial cada domingo y jefe diario: toca para hacer daño, 5 niveles de premios
• Sucursales: 17 ciudades en un mapa mundial con eventos, misiones, puestos y ranking
• Los niveles de sucursal aumentan los ingresos de la tienda principal y se conservan al franquiciar
• Efectos más fluidos: popups con rebote y premios animados; golpes al jefe más suaves
```

#### 🇮🇩 Indonesia (id)

```
Baru: TEMAN, BOSS DUNIA & CABANG KOTA!

• Teman: cari lewat nama panggilan, hadiah harian, kunjungi dan serbu toko teman
• Boss Dunia tiap Minggu plus boss harian: ketuk untuk memberi damage, 5 tingkat hadiah
• Cabang Kota: 17 kota di peta dunia dengan acara, misi, kios, dan papan peringkat
• Level cabang menambah pendapatan toko utama dan tetap ada saat Waralaba
• Visual lebih mulus: popup memantul dan efek hadiah; pukulan boss lebih lembut
```

#### 🇰🇷 한국어 (ko)

```
신규: 친구, 월드 보스 & 도시 지점!

• 친구: 닉네임으로 찾기, 매일 선물, 친구 가게 방문과 습격
• 매주 일요일 월드 보스와 일일 보스: 탭으로 데미지, 보상 5단계
• 도시 지점: 세계 지도의 17개 도시, 이벤트·퀘스트·가판대·순위표
• 지점 레벨은 본점 수익을 올려 주고 프랜차이즈 후에도 유지돼요
• 더 부드러운 연출: 튀어오르는 팝업과 보상 효과, 보스 타격 효과 완화
```

#### 🇧🇷 Português (pt)

```
Novo: AMIGOS, CHEFE MUNDIAL E FILIAIS!

• Amigos: busque por apelido, presentes diários, visite e invada as lojas dos amigos
• Chefe Mundial todo domingo e chefe diário: toque para causar dano, 5 níveis de prêmios
• Filiais: 17 cidades num mapa-múndi com eventos, missões, barracas e ranking
• Os níveis das filiais aumentam a renda da loja principal e são mantidos ao franquear
• Visuais mais suaves: popups com salto e efeitos de prêmio; golpes no chefe mais leves
```

#### 🇹🇭 ไทย (th)

```
ใหม่: เพื่อน, บอสโลก & สาขาเมืองต่างๆ!

• เพื่อน: ค้นหาด้วยชื่อเล่น ของขวัญรายวัน เยี่ยมและบุกร้านเพื่อน
• บอสโลกทุกวันอาทิตย์และบอสรายวัน: แตะเพื่อสร้างความเสียหาย รางวัล 5 ขั้น
• สาขาเมือง: 17 เมืองบนแผนที่โลก มีอีเวนต์ ภารกิจ แผงย่อย และอันดับ
• เลเวลสาขาเพิ่มรายได้ร้านหลักและคงอยู่หลังแฟรนไชส์
• ภาพลื่นขึ้น: ป๊อปอัปเด้ง เอฟเฟกต์รางวัล และบอสโดนตีนุ่มนวลขึ้น
```

---

## 1.0.11 (+25) — 2026-10-18

**Bản trước:** 1.0.10 (+24) trên iOS (nộp 2026-10-16). Android chưa có bản nào của 1.0.10 (Play production chờ duyệt) → người dùng Android nhận gộp cả 1.0.10 + 1.0.11; ghi chú cửa hàng đã viết theo phần MỚI so với 1.0.10, nếu muốn gộp cho Android thì thêm dòng "Pha theo đơn & Hồi 4" từ `whatsnew_1.0.10`.

**Nội dung (suy từ `git log d08735f..HEAD`):**
- **Thẻ Mùa** 28 ngày/30 bậc (XP có trần 150/ngày, đường Cao cấp 600💎), **Món của ngày**, phụ kiện độc quyền theo mùa (bậc 20/30), **BXH Thẻ Mùa** + thưởng cuối mùa (top 10: 1000/600/400/200💎, danh hiệu Quán Quân Mùa).
- **Phó bản Hội** (3 ải/tuần theo vai trò) + Boss Hội hoạt hình; **bộ trang bị**, **Tinh luyện phụ kiện**, **Tinh chất & Bí quyết**; **mốc sưu tập theo bộ**.
- **Đấu Trường:** PK Công thức, trận bóng ma, giải đấu tuần (top 10 thưởng 💎).
- **Hồ sơ của tôi:** avatar ảnh tải lên (Supabase Storage) + báo cáo ảnh vi phạm (3 báo cáo → tự ẩn chờ duyệt), danh hiệu hồ sơ. ⚠️ **Nội dung người dùng tạo → nêu trong App Review Notes** (đã soạn: `APP_REVIEW_NOTES_1.0.11.md`).
- Gia hạn tin đăng ở Chợ bằng QC; khách đi ngang gọi món; liên kết Facebook/TikTok/YouTube.
- **Gọn UI:** Nhiệm vụ ngày/tuần/Quà gộp một màn 3 tab; 8 bảng xếp hạng gom một màn; bỏ phụ kiện lơ lửng quanh nút pha trà; header giai đoạn 2 hàng có thanh tiến độ.

Soạn sẵn: `assets/store/whatsnew_1.0.11/` (7 ngôn ngữ, đều < 500 ký tự), hộp "Có gì mới" trong app (`whatsNewVersion` = `1.0.11`). Mô tả store chưa đổi (vẫn `description_1.0.10`; thêm dòng Thẻ Mùa/Phó bản nếu muốn).

**BẮT BUỘC trước khi nộp:**
- **Không có sản phẩm IAP mới.**
- **Supabase — chạy các file SQL** (idempotent; `scripts/deploy_supabase_sql.sh`): ngoài danh sách của 1.0.10, bản này cần `guild_schema`, `guild_dungeon_schema`, `arena_schema`, `arena_leaderboard_schema`, `season_leaderboard_schema`, `player_title_schema`, `player_avatar_schema`, `player_profile_schema`, `accessory_market_schema`, `leaderboard_rewards_schema`. **Chạy SQL TRƯỚC khi người chơi cập nhật.** `player_avatar_schema` tạo bucket Storage + policy — **chưa thử tay**, thử upload ảnh trên bản thật trước khi ship.
- Review Notes: dán `APP_REVIEW_NOTES_1.0.11.md`.
- Kiểm tra OTP email (Resend) còn hoạt động.

**Lệnh build:** iOS `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify` → Xcode Organizer. Android `flutter build appbundle --release` (versionCode +25; đổi +26 nếu Play đã nhận +25).

⚠️ Số cân bằng Thẻ Mùa / Phó bản / Tinh luyện / thưởng mùa là ước lượng, chưa playtest. Bản dịch máy (es/id/ko/pt/th) chưa có người bản ngữ duyệt.

### Có gì mới (dán vào console)

#### 🇻🇳 Tiếng Việt (vi)

```
Mới: THẺ MÙA & PHÓ BẢN HỘI!

• Thẻ Mùa 28 ngày/30 bậc, Món của ngày và bảng xếp hạng mùa có thưởng cuối mùa
• Phó bản Hội 3 ải mỗi tuần, Boss hoạt hình; bộ trang bị và tinh luyện phụ kiện
• Trang Hồ sơ của tôi: avatar ảnh, danh hiệu; mốc sưu tập theo bộ
• Đấu Trường: PK Công thức, trận bóng ma, giải đấu tuần; Nhiệm vụ & Quà gộp một màn
• Gia hạn tin đăng ở Chợ bằng quảng cáo; tính năng online cần liên kết email
```

#### 🇬🇧 English (en)

```
New: SEASON PASS & GUILD DUNGEON!

• 28-day Season Pass (30 tiers), Daily Item and a season leaderboard with end-of-season rewards
• Guild Dungeon (3 stages a week), animated Boss; loadouts and accessory refining
• My Profile page: photo avatar and titles; collection set rewards
• Arena: Recipe PK, ghost matches, weekly tournament; Quests & Gifts merged into one screen
• Extend Market listings with an ad; online features need a linked email
```

#### 🇪🇸 Español (es)

```
Nuevo: ¡PASE DE TEMPORADA Y MAZMORRA!

• Pase de Temporada 28 días (30 niveles), Objeto del día y ranking de temporada con premios
• Mazmorra del Gremio (3 etapas por semana), Jefe animado; equipamiento y refinado de accesorios
• Página Mi perfil: avatar con foto y títulos; premios por colecciones
• Arena: PK de recetas, partidas fantasma, torneo semanal; Misiones y Regalos en una sola pantalla
• Prolonga anuncios del Mercado con un anuncio; las funciones online requieren un correo vinculado
```

#### 🇮🇩 Bahasa Indonesia (id)

```
Baru: PASS MUSIM & DUNGEON GUILD!

• Pass Musim 28 hari (30 tingkat), Item Harian, dan papan peringkat musim dengan hadiah akhir musim
• Dungeon Guild (3 tahap per minggu), Boss beranimasi; perlengkapan dan penyempurnaan aksesori
• Halaman Profilku: avatar foto dan gelar; hadiah set koleksi
• Arena: PK Resep, pertandingan hantu, turnamen mingguan; Misi & Hadiah digabung jadi satu layar
• Perpanjang iklan Pasar dengan iklan video; fitur online perlu email tertaut
```

#### 🇰🇷 한국어 (ko)

```
신규: 시즌 패스 & 길드 던전!

• 28일 시즌 패스(30단계), 오늘의 아이템, 시즌 종료 보상이 있는 시즌 순위표
• 길드 던전(주 3단계), 움직이는 보스; 장비 세트와 액세서리 정제
• 내 프로필 페이지: 사진 아바타와 칭호; 세트 수집 보상
• 아레나: 레시피 PK, 고스트 매치, 주간 토너먼트; 퀘스트와 선물을 한 화면으로 통합
• 광고로 마켓 등록 기간 연장; 온라인 기능은 이메일 연동이 필요해요
```

#### 🇧🇷 Português (pt)

```
Novo: PASSE DE TEMPORADA E MASMORRA!

• Passe de Temporada de 28 dias (30 níveis), Item do dia e ranking da temporada com prêmios de fim de temporada
• Masmorra da Guilda (3 etapas por semana), Chefe animado; equipamentos e refino de acessórios
• Página Meu perfil: avatar com foto e títulos; prêmios por coleções
• Arena: PK de receitas, partidas fantasma, torneio semanal; Missões e Presentes numa só tela
• Prorrogue anúncios do Mercado com um anúncio; recursos online exigem e-mail vinculado
```

#### 🇹🇭 ไทย (th)

```
ใหม่: บัตรซีซัน & ดันเจี้ยนกิลด์!

• บัตรซีซัน 28 วัน (30 ขั้น), ไอเทมประจำวัน และอันดับซีซันพร้อมรางวัลปิดซีซัน
• ดันเจี้ยนกิลด์ (3 ด่านต่อสัปดาห์) บอสเคลื่อนไหว; ชุดสวมใส่และการเสริมพลังเครื่องประดับ
• หน้าโปรไฟล์ของฉัน: อวาตาร์รูปถ่ายและฉายา; รางวัลสะสมครบชุด
• สนามประลอง: PK สูตร, แมตช์ผี, ทัวร์นาเมนต์รายสัปดาห์; ภารกิจและของขวัญรวมเป็นหน้าเดียว
• ต่ออายุประกาศในตลาดด้วยโฆษณา; ฟีเจอร์ออนไลน์ต้องผูกอีเมล
```

---

## 1.0.10 (+24) — 2026-10-16

**Bản trước:** 1.0.9 (+23), đã lên App Store 2026-10-12. Nộp store bằng **+24**.

**Nội dung (suy từ `git log 89a249e..HEAD`; xin đối chiếu với bản 1.0.9 thực tế đã phát hành — nếu có mục nào đã nằm trong 1.0.9 thì bỏ khỏi ghi chú):**
- **Trò chơi nhỏ mới:** Công thức pha chế (ôn cách quãng 100 món, bậc Mới→Thạo, chuỗi ngày ôn, rương phụ kiện), **Pha theo đơn** (kéo-thả nguyên liệu, ly nhiều lớp, khách chibi, combo, Giờ cao điểm, đơn lễ hội, khoe ly, kệ trưng bày), **Thử thách hằng ngày** (đề chung, mỗi ngày một lần, bảng Hôm nay), hướng dẫn cách chơi cho từng trò.
- **Hồi 4 "Đại Hội Tay Nghề"** (Chương 37-46, mốc theo các trò nhỏ), tab Hồi 4 ở bảng Tốc độ; sửa perk Chương 36 (+8% hứa mà trước đây chưa áp).
- **Thưởng top tuần** cho các bảng (Thu nhập, Trân Châu, Sưu tập, VIP, Thợ pha chế, Pha theo đơn: top 3; Thử thách ngày: top 10 theo tổng điểm tuần trước).
- **Tự động chạm** (xem QC 10 phút / VIP 3+), trao đổi phụ kiện ở Chợ, nhiệm vụ Hội, nhiệm vụ ngày khó, hiệu ứng theo mức chất lượng máy, khách đi ngang cảnh quán.
- **Liên kết email BẮT BUỘC cho tính năng online** (bảng xếp hạng, Chợ, Hội, Đấu Trường) — ép cả ở app lẫn server. ⚠️ **Phải nói rõ trong App Review Notes** (đã soạn: `APP_REVIEW_NOTES_1.0.10.md`).
- Sửa: header màn chính không tràn ở chữ lớn, nhiều chỗ tràn chữ khác.

Soạn sẵn: `assets/store/whatsnew_1.0.10/` (7 ngôn ngữ, đều < 500 ký tự), `assets/store/description_1.0.10/` (đổi "36 chương" → 46, thêm mục "TRÒ CHƠI NHỎ"; thẻ force update `[:mav: 1.0.6]` giữ nguyên), hộp "Có gì mới" trong app (`whatsNewVersion` = `1.0.10`, nút "Chơi thử" mở hộp Trò chơi).

**BẮT BUỘC trước khi nộp:**
- **Không có sản phẩm IAP mới** (khác 1.0.9) — không cần tạo gì thêm ở mục In-App Purchases.
- **Supabase — chạy các file này** (idempotent, thứ tự tuỳ ý; hoặc `scripts/deploy_supabase_sql.sh`): `leaderboard_schema`, `m3_leaderboard_schema`, `accessory_leaderboard_schema`, `recipe_leaderboard_schema`, `recipe_order_leaderboard_schema`, `recipe_daily_schema`, `story_speedrun_schema`, `story_speedrun2_schema`, `story_speedrun3_schema`, `story_speedrun4_schema`, `event_leaderboard_schema`, `accessory_market_schema`, `leaderboard_rewards_schema`; và nếu chưa chạy từ các đợt trước: `guild_schema`, `accessory_swap_schema`, `player_profile_schema`, `referral_schema`. Bản app 1.0.10 gọi các RPC/bảng này nên **chạy SQL TRƯỚC khi người chơi cập nhật**. Sau khi chạy SQL, bản app CŨ (≤1.0.9) nộp điểm bằng tài khoản ẩn danh sẽ bị server từ chối (có chủ đích).
- Review Notes: dán `APP_REVIEW_NOTES_1.0.10.md` (có đoạn email bắt buộc cho tính năng online).
- Kiểm tra OTP email (Resend) còn hoạt động; reviewer cần nhận được mã.

**Lệnh build:** `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify` → upload bằng Xcode Organizer. Android: `flutter build appbundle --release` (versionCode lấy từ +24).

⚠️ Mọi số cân bằng của Pha theo đơn / combo / Giờ cao điểm / thử thách / Hồi 4 là ước lượng, chưa playtest diện rộng. Bản dịch do máy soạn (es/id/ko/pt/th), chưa có người bản ngữ duyệt. Chưa thử trên Android/máy thật.

### 🇻🇳 Tiếng Việt (vi)

```
Mới: PHA THEO ĐƠN & HỒI 4!

• Pha theo đơn: kéo-thả nguyên liệu, khách chibi, combo, Giờ cao điểm, đơn lễ hội
• Trò Công thức pha chế ôn cách quãng 100 món, mỗi trò có hướng dẫn
• Thử thách hằng ngày + bảng xếp hạng Hôm nay, thưởng top tuần
• Hồi 4 "Đại Hội Tay Nghề": 10 chương mới
• Tự động chạm, trao đổi phụ kiện ở Chợ; tính năng online cần liên kết email
```

### 🇬🇧 English (en)

```
New: BREW BY ORDER & ACT 4!

• Brew by order: drag ingredients, chibi customers, combos, Rush Hour, festival orders
• Recipe game with spaced review of 100 drinks; every mini-game has a guide
• Daily Challenge + Today leaderboard, weekly top rewards
• Act 4 "Grand Craft Festival": 10 new chapters
• Auto-tap, accessory swaps in the Market; online features need a linked email
```

### 🇪🇸 Español (es)

```
Novedad: PREPARAR PEDIDOS Y ACTO 4

• Preparar pedidos: arrastra ingredientes, clientes chibi, combos, Hora punta, pedidos de fiesta
• Juego de recetas con repaso espaciado de 100 bebidas; cada minijuego tiene guía
• Reto diario + clasificación de Hoy, recompensas semanales al top
• Acto 4 «Gran Festival del Oficio»: 10 capítulos nuevos
• Toque automático, intercambio de accesorios en el Mercado; las funciones en línea requieren correo vinculado
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: RACIK SESUAI PESANAN & BABAK 4!

• Racik sesuai pesanan: seret bahan, pelanggan chibi, combo, Jam sibuk, pesanan festival
• Game resep dengan ulangan berjeda 100 minuman; tiap mini-game punya panduan
• Tantangan harian + papan peringkat Hari ini, hadiah mingguan untuk top
• Babak 4 "Festival Keahlian Agung": 10 bab baru
• Ketuk otomatis, tukar aksesori di Pasar; fitur online memerlukan email tertaut
```

### 🇰🇷 한국어 (ko)

```
신규: 주문대로 만들기 & 4막!

• 주문대로 만들기: 재료 끌어놓기, 치비 손님, 콤보, 러시 아워, 축제 주문
• 100가지 음료 간격 반복 레시피 게임, 모든 미니게임에 안내 추가
• 일일 도전 + 오늘 순위, 주간 TOP 보상
• 4막 "장인 대축제": 새 10개 장
• 자동 터치, 마켓 액세서리 교환. 온라인 기능은 이메일 연결 필요
```

### 🇧🇷 Português (pt-BR)

```
Novo: PREPARAR PEDIDOS E ATO 4!

• Preparar pedidos: arraste ingredientes, clientes chibi, combos, Hora de pico, pedidos de festival
• Jogo de receitas com revisão espaçada de 100 bebidas; todo minijogo tem guia
• Desafio diário + ranking de Hoje, recompensas semanais ao top
• Ato 4 "Grande Festival do Ofício": 10 capítulos novos
• Toque automático, troca de acessórios no Mercado; recursos online exigem e-mail vinculado
```

### 🇹🇭 ไทย (th)

```
ใหม่: ชงตามออเดอร์ & ภาค 4!

• ชงตามออเดอร์: ลากวัตถุดิบ ลูกค้าชิบิ คอมโบ ชั่วโมงเร่งด่วน ออเดอร์เทศกาล
• เกมสูตรทบทวนแบบเว้นระยะ 100 เครื่องดื่ม ทุกมินิเกมมีวิธีเล่น
• ภารกิจประจำวัน + อันดับวันนี้ รางวัลท็อปรายสัปดาห์
• ภาค 4 "เทศกาลฝีมือยิ่งใหญ่": 10 บทใหม่
• แตะอัตโนมัติ แลกของตกแต่งในตลาด ฟีเจอร์ออนไลน์ต้องเชื่อมอีเมล
```

---

## 1.0.9 (+23) — 2026-10-11

**Bản trước:** 1.0.8 (+22). Nộp store bằng **+23**. Nội dung: VIP 10 cấp + quà ngày/tuần/tháng + BXH VIP + Cửa hàng VIP + nạp lần đầu x2 (cần email để nạp), Hội (Boss tuần, nhãn/khung VIP, tặng 💎), Nhiệm vụ tuần + rương, thưởng mốc chuỗi điểm danh + bonus VIP, Ưu đãi hôm nay, hồ sơ người chơi (bấm dòng BXH), liên kết app→web (BXH/hồ sơ/hướng dẫn), Mời bạn bè, gói 💎 lớn (huge 14.99$ / mega 19.99$), Kho lạnh 2.99$, combo Gỡ QC + x2 5.99$.

Soạn sẵn: `assets/store/whatsnew_1.0.9/` (7 ngôn ngữ, đều < 500 ký tự), `assets/store/description_1.0.9/` (thêm mục "VIP & HỘI"; thẻ force update giữ nguyên), hộp "Có gì mới" trong app (`whatsNewVersion` = `1.0.9`, nút mở hướng dẫn VIP).

**BẮT BUỘC trước khi nộp (Apple sẽ từ chối / nút mua hỏng nếu thiếu):**
- App Store Connect: tạo đủ **4 sản phẩm IAP mới** (`boba_gems_huge` 14.99$, `boba_gems_mega` 19.99$, `boba_cold_storage` 2.99$ non-consumable, `boba_combo_noads_x2` 5.99$ non-consumable — xem `IAP_APP_STORE_SETUP.md`), đính ảnh chụp review, rồi **chọn chúng trong mục "In-App Purchases and Subscriptions" của phiên bản 1.0.9** để gửi duyệt cùng bản app. (Lần trước bị chặn "maximum number of submissions allowed in review" → đợi bản đang duyệt xong, hoặc huỷ nộp.)
- Supabase đã chạy lại (xác nhận 2026-10-11): `guild_schema.sql`, `accessory_market_schema.sql`, `referral_schema.sql`, `player_profile_schema.sql`.
- Review Notes (đã soạn chung, nhắc kiểm tra thư mục Spam để nhận OTP email): dán lại vào mục App Review Information.

**Lệnh build:** `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=IAP_VERIFY_ENDPOINT=https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify` → upload bằng Xcode Organizer (Transporter từng báo "Processing failed").

⚠️ Mọi số cân bằng VIP/nhiệm vụ tuần/điểm danh là ước lượng, chưa playtest. Bản dịch do máy soạn.

### 🇻🇳 Tiếng Việt (vi)

```
Mới: HỆ THỐNG VIP & NHIỆM VỤ TUẦN!

• VIP 10 cấp: quà mỗi ngày/tuần/tháng, bảng xếp hạng VIP, Cửa hàng VIP, nạp lần đầu x2 Kim Cương
• Hội: Boss tuần, nhãn & khung VIP, tặng Kim Cương cho nhau
• Nhiệm vụ tuần có rương thưởng, thưởng mốc chuỗi điểm danh, Ưu đãi hôm nay
• Bấm dòng bảng xếp hạng để xem hồ sơ; xem & chia sẻ bảng xếp hạng trên web; mời bạn bè nhận Kim Cương
• Thêm gói Kim Cương lớn, Kho lạnh vĩnh viễn, combo Gỡ QC + x2 thu nhập
```

### 🇬🇧 English (en)

```
New: VIP SYSTEM & WEEKLY QUESTS!

• 10 VIP levels: daily/weekly/monthly gifts, a VIP leaderboard, a VIP Shop, 2x Gems on your first top-up
• Guilds: weekly Boss, VIP tags & frames, gift Gems to each other
• Weekly quests with a reward chest, streak milestone bonuses, Today's Deal
• Tap a leaderboard row to see a profile; view & share leaderboards on the web; invite friends for Gems
• New big Gem packs, permanent Cold Storage, No Ads + 2x income combo
```

### 🇧🇷 Português (pt-BR)

```
Novo: SISTEMA VIP E MISSÕES SEMANAIS!

• 10 níveis VIP: presentes diários/semanais/mensais, ranking VIP, Loja VIP e 2x gemas na primeira recarga
• Guildas: Chefe semanal, selos e molduras VIP, presentear gemas
• Missões semanais com baú, bônus de marcos da sequência e Oferta de hoje
• Toque numa linha do ranking para ver o perfil; veja e compartilhe rankings na web; convide amigos e ganhe gemas
• Novos pacotes grandes de gemas, Câmara fria permanente e combo Sem anúncios + renda 2x
```

### 🇪🇸 Español (es)

```
Nuevo: SISTEMA VIP Y MISIONES SEMANALES

• 10 niveles VIP: regalos diarios/semanales/mensuales, clasificación VIP, Tienda VIP y 2x gemas en la 1.ª recarga
• Gremios: jefe semanal, etiquetas y marcos VIP, regalo de gemas
• Misiones semanales con cofre, bonos de racha y Oferta de hoy
• Toca una fila de la clasificación para ver el perfil; compártela en la web; invita amigos y gana gemas
• Nuevos paquetes grandes de gemas, Almacén frío y combo Sin anuncios + ingresos x2
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: SISTEM VIP & MISI MINGGUAN!

• 10 level VIP: hadiah harian/mingguan/bulanan, peringkat VIP, Toko VIP, 2x Permata pada isi ulang pertama
• Guild: Boss mingguan, label & bingkai VIP, saling kirim Permata
• Misi mingguan dengan peti hadiah, bonus tonggak streak, Penawaran Hari Ini
• Ketuk baris peringkat untuk melihat profil; lihat & bagikan peringkat di web; undang teman untuk Permata
• Paket Permata besar baru, Cold Storage permanen, kombo Tanpa Iklan + pendapatan 2x
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: ระบบ VIP & ภารกิจประจำสัปดาห์!

• VIP 10 ระดับ: ของขวัญรายวัน/สัปดาห์/เดือน อันดับ VIP ร้านค้า VIP เติมครั้งแรกได้เพชร x2
• กิลด์: บอสประจำสัปดาห์ ป้ายและกรอบ VIP ส่งเพชรให้กัน
• ภารกิจประจำสัปดาห์พร้อมหีบรางวัล โบนัสสตรีค ดีลวันนี้
• แตะแถวในอันดับเพื่อดูโปรไฟล์ ดูและแชร์อันดับบนเว็บ ชวนเพื่อนรับเพชร
• แพ็กเพชรใหญ่ใหม่ ห้องเย็นถาวร คอมโบไม่มีโฆษณา + รายได้ x2
```

### 🇰🇷 한국어 (ko)

```
신규: VIP 시스템 & 주간 퀘스트!

• VIP 10단계: 일/주/월 선물, VIP 순위, VIP 상점, 첫 충전 보석 2배
• 길드: 주간 보스, VIP 태그와 프레임, 보석 선물
• 보상 상자가 있는 주간 퀘스트, 연속 출석 보너스, 오늘의 특가
• 순위 항목을 눌러 프로필 보기, 웹에서 순위 보기·공유, 친구 초대 시 보석
• 새 대용량 보석 팩, 영구 냉장 보관, 광고 제거 + 수입 2배 콤보
```

---

## 1.0.8 (+21) — 2026-10-07

**Bản trước:** 1.0.7 đã lên store. Nộp store bằng **+21**.

Mốc đáng chú ý (đủ cho cả App Store lẫn Play, đều dưới 500 ký tự):
- **Bộ sưu tập 80 → 160 phụ kiện** (75 thường · 46 hiếm · 30 sử thi · 9 huyền thoại); thêm **hướng dẫn sưu tầm** (nút `?` trong Kho) và **hiệu ứng nhận món** (vầng sáng, tia lấp lánh); ô Kho hiện dần.
- **Mốc sưu tập 80/100/120/140/160** (thưởng 300/500/800/1100/1500 Xu Chợ); dải mốc cuộn ngang, tự cuộn tới mốc kế tiếp chưa nhận.
- **Trân Châu Rơi 60 → 80 màn**, 25 nước/màn, mục tiêu tăng chậm hơn + trần 24.000 điểm, mốc sao thấp hơn. **Hết nước xem QC +5 nước, không giới hạn số lần.** Back giữa chừng giữ ván dở + hộp thoại xác nhận thoát.
- Sửa lỗi: danh sách Chợ bị co khi cuộn (Android); xem QC bị tính là rời game (popup "Chào mừng trở lại" giả); snackbar "QC chưa sẵn sàng" gây crash; crash khi đăng bán ở Chợ; chip "Nước còn" tràn ở en/es.

**Phía server / cấu hình (kiểm trước khi phát hành):**
- Supabase: đã chạy lại `supabase/accessory_market_schema.sql` (mốc 80–160 trong `claim_collection_milestone`) ngày 2026-10-07. Chưa chạy thì nhận mốc mới báo `invalid_milestone`.
- Firebase Remote Config `boba_remote_config`: `m3LevelCount` **80**, thêm `m3TargetCap` **24000** (khoá mới; giá trị cũ trên Firebase sẽ ghi đè bản mới nếu quên). `m3Moves` 25, `m3TargetGrowth` 1.08, `m3CollectGrowth` 1.07, `m3Star2Mult` 1.2, `m3Star3Mult` 1.45 đã đặt từ trước.
- CHECK `owned_count` của bảng xếp hạng Sưu tập là 200 → còn dư 40 món; vượt 200 phải nâng trần trước.

**Hộp "Có gì mới" trong app:** `whatsNewVersion` = `1.0.8`; chuỗi `whatsNewCollection/Milestones/Match3/Ads/Fixes` trong `lib/l10n/app_*.arb` (7 ngôn ngữ). Bản dài ở `assets/store/whatsnew_1.0.8/`, mô tả store ở `assets/store/description_1.0.8/` (chỉ đổi "80" → "160" phụ kiện ở dòng 15).

**Force update:** KHÔNG đổi (thẻ ở mô tả giữ nguyên).

⚠️ Mọi số cân bằng Ghép 3 (25 nước, trần 24k, QC +5 không giới hạn) và thưởng mốc là ước lượng, chưa playtest. Bản dịch do máy soạn — nên nhờ người bản ngữ soát.

### 🇻🇳 Tiếng Việt (vi)

```
Mới: 160 PHỤ KIỆN & 80 MÀN TRÂN CHÂU RƠI!

• Bộ sưu tập lên 160 phụ kiện, có hướng dẫn sưu tầm và hiệu ứng khi nhận món mới
• Thêm mốc sưu tập 80/100/120/140/160, thưởng Xu Chợ lớn hơn
• Trân Châu Rơi lên 80 màn, dễ chơi hơn
• Hết nước? Xem quảng cáo +5 nước, xem bao nhiêu lần tuỳ bạn; back giữa chừng vẫn giữ ván
• Sửa lỗi: danh sách Chợ bị co khi cuộn, xem quảng cáo bị tính là rời game, vài lỗi crash
```

### 🇬🇧 English (en)

```
New: 160 ACCESSORIES & 80 FALLING PEARLS LEVELS!

• Collection grows to 160 accessories, with a collecting guide and a reveal animation for new items
• New milestones at 80/100/120/140/160 with bigger Market Coin rewards
• Falling Pearls now has 80 levels and is easier to play
• Out of moves? Watch an ad for +5 moves, as many times as you like; backing out keeps your game
• Fixes: Market list squashing when scrolling, ads counted as leaving the game, a few crashes
```

### 🇧🇷 Português (pt-BR)

```
Novo: 160 ACESSÓRIOS E 80 FASES DE PÉROLAS CAINDO!

• A coleção sobe para 160 acessórios, com guia e animação ao ganhar um item novo
• Novos marcos em 80/100/120/140/160 com mais Moedas de Mercado
• Pérolas Caindo agora tem 80 fases e ficou mais fácil
• Sem jogadas? Veja um anúncio para +5, quantas vezes quiser; sair no meio mantém a partida
• Correções: lista do Mercado encolhia ao rolar, anúncios contavam como sair do jogo, alguns travamentos
```

### 🇪🇸 Español (es)

```
Nuevo: ¡160 ACCESORIOS Y 80 NIVELES DE PERLAS QUE CAEN!

• La colección sube a 160 accesorios, con guía y animación al conseguir uno nuevo
• Nuevos hitos en 80/100/120/140/160 con más Monedas de Mercado
• Perlas que caen ahora tiene 80 niveles y es más fácil
• ¿Sin movimientos? Mira un anuncio para +5, las veces que quieras; si sales a medias, conservas la partida
• Arreglos: la lista del Mercado se encogía al desplazar, los anuncios contaban como salir del juego, algunos cierres
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: 160 AKSESORI & 80 LEVEL MUTIARA JATUH!

• Koleksi jadi 160 aksesori, dengan panduan koleksi dan animasi saat dapat item baru
• Tonggak baru di 80/100/120/140/160 dengan hadiah Koin Pasar lebih besar
• Mutiara Jatuh kini 80 level dan lebih mudah
• Langkah habis? Tonton iklan untuk +5 langkah, sebanyak yang kamu mau; keluar di tengah main tetap menyimpan permainan
• Perbaikan: daftar Pasar menyusut saat digulir, iklan dihitung sebagai keluar game, beberapa crash
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: เครื่องประดับ 160 ชิ้น & ไข่มุกร่วง 80 ด่าน!

• คอลเลกชัน 160 ชิ้น มีคู่มือการสะสมและแอนิเมชันเมื่อได้ของใหม่
• หมุดหมายใหม่ที่ 80/100/120/140/160 รางวัลเหรียญตลาดมากขึ้น
• ไข่มุกร่วง 80 ด่าน เล่นง่ายขึ้น
• หมดตาเดิน? ดูโฆษณารับ +5 ดูกี่ครั้งก็ได้ ออกกลางคันก็ยังเก็บเกมไว้
• แก้ไข: รายการตลาดหดตอนเลื่อน โฆษณาถูกนับเป็นออกจากเกม และข้อผิดพลาดบางส่วน
```

### 🇰🇷 한국어 (ko)

```
신규: 액세서리 160종 & 떨어지는 펄 80레벨!

• 컬렉션 160종, 수집 가이드와 새 아이템 획득 애니메이션
• 80/100/120/140/160 이정표 추가, 더 큰 마켓 코인 보상
• 떨어지는 펄 80레벨, 더 쉬워졌어요
• 이동이 끝났나요? 광고를 보면 +5회, 횟수 제한 없음. 중간에 나가도 게임 유지
• 수정: 마켓 목록 찌그러짐, 광고가 이탈로 집계되던 문제, 일부 크래시
```

---

## 1.0.7 (+16) — 2026-10-04

**Bản trước:** 1.0.6 (+13), iOS đã live 2026-10-04 (Play chưa publish 1.0.6). Các build +14/+15 là build trung gian trong quá trình làm bản này; nộp store bằng +16.

Mốc đáng chú ý của bản này (đủ cho cả App Store lẫn Play, đều dưới 500 ký tự):
- **Bộ sưu tập 50 → 80 phụ kiện**, tỉ lệ rớt đồ hiếm giảm (66/24/8/2 thay vì 60/25/12/3).
- **Phụ kiện độc quyền theo dịp lễ** (7 dịp × 4 món): Halloween 24/10–2/11/2026, Giáng Sinh 18–27/12/2026, Tết Dương lịch 28/12/2026–3/1/2027, Tết Nguyên Đán 30/1–9/2/2027, Valentine 10–15/2/2027, 8/3 (4–9/3/2027), Trung Thu 8–17/9/2027. Mua bằng **Gói Lễ Hội** (80 💎) trong dịp, giữ mãi sau đó; không đăng bán Chợ, không tính vào bộ sưu tập/bảng xếp hạng.
- **Gói phụ kiện** mua bằng 💎 (30/80/200, công bố tỉ lệ rớt) và **vòng quay phụ kiện** (30 💎 hoặc xem QC, tối đa 10 lượt QC/ngày). Thêm 1 lượt rớt xem QC sau khi xong cả bộ nhiệm vụ ngày. Trong dịp lễ gói giảm 25% và tăng tỉ lệ Sử thi/Huyền thoại.
- **Cứu streak điểm danh**: lỡ đúng 1 ngày (chuỗi ≥ 2) cứu bằng 20 💎 hoặc xem QC.
- **Nhượng quyền xem QC** → thêm Xu khởi đầu (~10 phút thu nhập, không thưởng Sao). **VIP có thêm ô trưng bày thứ 4.**
- **Thêm tiếng Hàn** (7 ngôn ngữ).
- Sửa lỗi: số Xu cực lớn đè lên chip 💎 ở màn chính; hộp điểm danh tràn dọc ở máy hẹp (pt/es); nhắc kiểm tra thư mục Spam khi nhận mã sao lưu; báo "quảng cáo chưa sẵn sàng" thay vì im lặng.

**Phía server (kiểm trước khi phát hành):** đã chạy lại `supabase/accessory_leaderboard_schema.sql`
(nâng CHECK `owned_count` 50 → 200) ngày 2026-10-04 — nếu chưa chạy thì bảng xếp hạng Sưu tập từ chối
người có hơn 50 món. Không có SQL/Edge Function mới nào khác.

**Hạn cần chú ý:** iOS phải qua duyệt **trước 24/10/2026** thì Gói Lễ Hội Halloween mới có. Đổi mốc
dịp lễ ở `festivals` trong `lib/core/accessories.dart`.

**Force update:** KHÔNG đổi. Thẻ ở mô tả vẫn là `[:mav: 1.0.6]` (đổi thành `1.0.7` chỉ khi muốn ép mọi
người lên 1.0.7, và thẻ chỉ có tác dụng sau khi 1.0.7 live). Mô tả đầy đủ 7 ngôn ngữ ở
`assets/store/description_1.0.7/`, bản dài của "Có gì mới" ở `assets/store/whatsnew_1.0.7/`.

**Hộp "Có gì mới" trong app:** `whatsNewVersion` = `1.0.7`; hiện một lần cho người vừa cập nhật.
Chuỗi `whatsNewFestival/Packs/Streak/Vip/Korean` trong `lib/l10n/app_*.arb` (7 ngôn ngữ).

**Chưa làm:** mô tả/từ khoá/ảnh chụp store bằng tiếng Hàn; thêm ngôn ngữ Korean trong App Store Connect.

### 🇻🇳 Tiếng Việt (vi)

```
Mới: PHỤ KIỆN LỄ HỘI & VÒNG QUAY!

• 80 phụ kiện; thêm phụ kiện độc quyền 7 dịp lễ (Halloween, Giáng Sinh, Tết...), mua bằng Gói Lễ Hội trong dịp
• Gói phụ kiện và vòng quay (30 Kim Cương hoặc xem quảng cáo), công bố tỉ lệ rớt
• Lỡ điểm danh? Cứu chuỗi bằng Kim Cương hoặc quảng cáo
• VIP thêm 1 chỗ trưng bày; xem quảng cáo khi nhượng quyền để nhận thêm Xu
• Thêm tiếng Hàn
```

### 🇬🇧 English (en)

```
New: HOLIDAY ACCESSORIES & WHEEL!

• 80 accessories, plus exclusive accessories for 7 holidays (Halloween, Christmas, Lunar New Year...) via the Festival Pack during the event
• Accessory packs and a wheel (30 Gems or watch an ad), drop rates shown
• Missed a check-in? Save your streak with Gems or an ad
• VIP gets one more display slot; watch an ad when you Franchise for extra Coins
• Korean added
```

### 🇧🇷 Português (pt-BR)

```
Novo: ACESSÓRIOS DE FESTIVAIS E ROLETA!

• 80 acessórios, mais acessórios exclusivos de 7 festividades (Halloween, Natal, Ano Novo Lunar...) com o Pacote de Festival durante o evento
• Pacotes de acessórios e roleta (30 Gemas ou anúncio), chances à vista
• Perdeu o check-in? Salve a sequência com Gemas ou anúncio
• VIP ganha mais um espaço de exibição; veja um anúncio ao fazer Franquia para mais moedas
• Adicionado o coreano
```

### 🇪🇸 Español (es)

```
Nuevo: ¡ACCESORIOS DE FESTIVIDADES Y RULETA!

• 80 accesorios, más accesorios exclusivos de 7 festividades (Halloween, Navidad, Año Nuevo Lunar...) con el Paquete de Festividad durante el evento
• Paquetes de accesorios y ruleta (30 Gemas o un anuncio), probabilidades a la vista
• ¿Te saltaste el registro? Salva tu racha con Gemas o un anuncio
• VIP tiene un espacio de exhibición más; mira un anuncio al hacer Franquicia para más monedas
• Se añade el coreano
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: AKSESORI HARI RAYA & RODA!

• 80 aksesori, plus aksesori eksklusif 7 hari raya (Halloween, Natal, Imlek...) lewat Paket Festival selama acara
• Paket aksesori dan roda (30 Permata atau iklan), peluang ditampilkan
• Terlewat check-in? Selamatkan streak dengan Permata atau iklan
• VIP dapat satu slot pajangan lagi; tonton iklan saat Franchise untuk Koin tambahan
• Bahasa Korea ditambahkan
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: เครื่องประดับเทศกาลและวงล้อ!

• เครื่องประดับ 80 ชิ้น พร้อมเครื่องประดับเฉพาะกิจ 7 เทศกาล (ฮาโลวีน คริสต์มาส ตรุษจีน...) ซื้อด้วยแพ็กเทศกาลในช่วงงาน
• แพ็กเครื่องประดับและวงล้อ (30 เพชรหรือดูโฆษณา) แสดงโอกาสที่ได้
• พลาดเช็คอิน? กู้สตรีคด้วยเพชรหรือโฆษณา
• VIP ได้ช่องโชว์เพิ่ม ดูโฆษณาตอนแฟรนไชส์เพื่อรับเหรียญเพิ่ม
• เพิ่มภาษาเกาหลี
```

### 🇰🇷 한국어 (ko)

```
신규: 명절 액세서리 & 룰렛!

• 액세서리 80종, 그리고 7개 명절 한정 액세서리(할로윈, 크리스마스, 설날...)를 이벤트 기간 축제 팩으로 획득
• 액세서리 팩과 룰렛(보석 30개 또는 광고 시청), 드롭 확률 공개
• 출석을 놓쳤나요? 보석이나 광고로 연속 출석 지키기
• VIP는 전시 칸 +1, 프랜차이즈 시 광고를 보면 코인 추가
• 한국어 추가
```

---

## 1.0.6 (+13) — 2026-10-03

**Bản trước:** 1.0.5 (+10), đã lên store 2026-09-30 (+11 chưa lên store production).

Mốc đáng chú ý của bản này: **Bộ sưu tập + Chợ phụ kiện** (50 món, Kho, trưng bày quanh
cốc, huy hiệu bảng xếp hạng, mốc thưởng, Chợ mua bán bằng Xu Chợ có giá tham khảo, danh
sách muốn có, thông báo đẩy, Gói Khởi Nghiệp, sự kiện cuối tuần), **Hồi 3 cốt truyện**
(chương 29–36), giao diện pastel và tối ưu hiệu năng. Cùng nội dung dùng được cho cả
App Store lẫn Play (đều dưới 500 ký tự).

**Phía server (kiểm trước khi phát hành):** SQL Chợ/Sưu tập (`accessory_market_schema.sql`)
đã chạy 2026-10-03; Edge Function `notify-market-sale` đã deploy và trigger
`market_push_triggers.sql` đã tạo. Cần chắc là đã chạy `story_speedrun3_schema.sql` (bảng
xếp hạng Hồi 3).

### Bắt buộc người chơi cập nhật (force update) và hộp "Có gì mới"

**Force update — KHÔNG cần sửa code.** App đã dùng `upgrader` (`UpgradeAlert`, có từ 1.0.3+6) nên
mọi bản ≥ 1.0.3 đều tự hỏi store. `upgrader` đọc một **thẻ trong phần Mô tả** của bản đang live;
thấy thẻ thì mọi bản cũ hơn bị CHẶN: hộp cập nhật mất nút "Để sau/Bỏ qua" và không đóng được.

- **App Store Connect** → mô tả của phiên bản 1.0.6 (MỌI ngôn ngữ đang dùng: vi, en, es, id, pt, th), thêm một dòng cuối:
  `[:mav: 1.0.6]`
- **Play Console** → Mô tả đầy đủ (Full description), thêm một dòng cuối:
  `[Minimum supported app version: 1.0.6]`

Lưu ý: (1) thẻ chỉ có tác dụng khi bản 1.0.6 đã **live** trên store (lookup đọc mô tả bản
live) — trước đó không ép được và cũng không test được; (2) iOS lấy mô tả theo ngôn ngữ của
quốc gia máy, nên thẻ phải có ở từng bản địa hoá; (3) thẻ hiện trong trang store (chữ nhỏ ở
cuối mô tả) — chấp nhận được; gỡ đi ở lần phát hành sau nếu không muốn ép tiếp; (4) từ lần sau
muốn ép bản mới hơn thì đổi số trong thẻ.

**Hộp "Có gì mới":** `lib/core/whats_new.dart` + `lib/ui/whats_new_dialog.dart`. Hiện **một lần**
khi người chơi vừa cập nhật lên đúng `whatsNewVersion` (hiện = `1.0.6`); người cài mới thì không
hiện. Phát hành bản có nội dung mới khác: đổi `whatsNewVersion` và các chuỗi `whatsNew*` trong
`lib/l10n/app_*.arb` (6 ngôn ngữ).

### 🇻🇳 Tiếng Việt (vi)

```
Mới: BỘ SƯU TẬP & CHỢ PHỤ KIỆN!

• 50 phụ kiện sưu tầm: rớt từ nhiệm vụ ngày, vòng quay, Kỷ Nguyên, Trân Châu Rơi. Trưng bày quanh cốc, huy hiệu bảng xếp hạng, mốc thưởng
• Chợ: mua bán bằng Xu Chợ, giá tham khảo, danh sách muốn có, báo khi bán được. Cuối tuần phí 0% và dễ rớt đồ hiếm hơn
• Hồi 3 cốt truyện: 8 chương mới
• Giao diện pastel, mượt hơn, chia sẻ bộ sưu tập thành ảnh
```

### 🇬🇧 English (en)

```
New: COLLECTION & ACCESSORY MARKET!

• 50 collectible accessories from daily quests, the wheel, Ascension and Falling Pearls. Show them around your cup, leaderboard badges, milestone rewards
• Market: trade with Market Coins, price hints, wishlist, sale alerts. Weekends: 0% fee and better rare drops
• Story Act 3: 8 new chapters
• Pastel look, smoother play, share your collection as an image
```

### 🇧🇷 Português (pt-BR)

```
Novo: COLEÇÃO E MERCADO DE ACESSÓRIOS!

• 50 acessórios colecionáveis: missões diárias, roleta, Ascensão e Pérolas Caindo. Exiba ao redor do copo, emblema no ranking, recompensas por marcos
• Mercado: negocie com Moedas de Mercado, preço de referência, lista de desejos, aviso de venda. Fim de semana: taxa 0% e mais itens raros
• História Ato 3: 8 capítulos novos
• Visual pastel, mais fluido, compartilhe a coleção em imagem
```

### 🇪🇸 Español (es)

```
Nuevo: ¡COLECCIÓN Y MERCADO DE ACCESORIOS!

• 50 accesorios coleccionables: misiones diarias, ruleta, Ascensión y Perlas que Caen. Muéstralos junto al vaso, insignia en la clasificación, premios por hitos
• Mercado: compra y vende con Monedas de Mercado, precio de referencia, lista de deseos, aviso de ventas. Fines de semana: comisión 0% y más objetos raros
• Historia Acto 3: 8 capítulos nuevos
• Estilo pastel, más fluido, comparte tu colección como imagen
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: KOLEKSI & PASAR AKSESORI!

• 50 aksesori koleksi dari misi harian, roda, Ascension, dan Mutiara Jatuh. Pajang di sekitar gelas, lencana papan peringkat, hadiah pencapaian
• Pasar: jual beli dengan Koin Pasar, harga acuan, daftar keinginan, notifikasi terjual. Akhir pekan: biaya 0% dan item langka lebih sering
• Cerita Babak 3: 8 bab baru
• Tampilan pastel, lebih mulus, bagikan koleksi sebagai gambar
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: คอลเลกชันและตลาดเครื่องประดับ!

• เครื่องประดับสะสม 50 ชิ้น จากภารกิจรายวัน วงล้อ Ascension และไข่มุกร่วง จัดโชว์รอบแก้ว ตราบนกระดานจัดอันดับ รางวัลตามเป้าหมาย
• ตลาด: ซื้อขายด้วยเหรียญตลาด ราคาอ้างอิง รายการที่อยากได้ แจ้งเตือนเมื่อขายได้ สุดสัปดาห์ค่าธรรมเนียม 0% และมีโอกาสได้ของหายากสูงขึ้น
• เนื้อเรื่องภาค 3: เพิ่ม 8 ตอน
• ธีมพาสเทล ลื่นขึ้น แชร์คอลเลกชันเป็นรูปภาพ
```

---

## Play Store — bản đầu tiên (1.0.5 (+10)) — 2026-09-30

Play Store chưa từng phát hành trước đó (App Store thì đã ở 1.0.3+) — đây là
**bản nộp đầu tiên trên Play**, nên nội dung "What's new" viết kiểu giới
thiệu tính năng, KHÔNG nhắc bug/crash/mã xin lỗi (những cái đó chỉ áp dụng
cho người chơi iOS cũ, không liên quan người cài lần đầu trên Play). Đừng
lẫn với mục changelog "1.0.5 (+10)" ngay dưới đây — đó là nội dung dành cho
App Store (đã có người chơi từ trước).

### 🇻🇳 Tiếng Việt (vi)

```
🧋 Đế Chế Trà Sữa — xây quán trà sữa từ xe đẩy thành đế chế toàn cầu!

• Idle nhàn rỗi: chạm, nâng cấp, kiếm Xu cả khi không chơi
• Trân Châu Rơi: 60 màn ghép 3, kẹo đặc biệt, bảng xếp hạng riêng
• Đấu Trường: PK trực tiếp với người chơi khác
• Cốt truyện 28 chương, nhiều lựa chọn ảnh hưởng kết cục
• Đồng bộ đám mây, VIP Pass, nhiệm vụ ngày, vòng quay may mắn
```

### 🇬🇧 English (en-GB)

```
🧋 Boba Empire — grow your tea shop from a street cart into a global empire!

• Idle gameplay: tap, upgrade, earn even while away
• Falling Pearls: 60 match-3 levels, special candies, its own leaderboard
• Arena: live PvP against other players
• 28-chapter story with choices that shape the ending
• Cloud save, VIP Pass, daily quests, lucky wheel
```

### 🇧🇷 Português (pt-BR)

```
🧋 Boba Empire — transforme sua barraca de chá em um império global!

• Jogo idle: toque, evolua e ganhe mesmo offline
• Pérolas Caindo: 60 fases de match-3, doces especiais e ranking próprio
• Arena: PvP ao vivo contra outros jogadores
• História com 28 capítulos e escolhas que mudam o final
• Save na nuvem, VIP Pass, missões diárias, roleta da sorte
```

### 🇪🇸 Español (es-ES)

```
🧋 Boba Empire — ¡convierte tu carrito de té en un imperio global!

• Juego idle: toca, mejora y gana incluso sin estar conectado
• Perlas que Caen: 60 niveles de match-3, caramelos especiales y ranking propio
• Arena: PvP en vivo contra otros jugadores
• Historia de 28 capítulos con decisiones que cambian el final
• Guardado en la nube, VIP Pass, misiones diarias, ruleta de la suerte
```

### 🇮🇩 Bahasa Indonesia (id)

```
🧋 Boba Empire — ubah gerobak tehmu jadi kerajaan global!

• Gameplay idle: tap, upgrade, dan tetap dapat cuan walau offline
• Mutiara Jatuh: 60 level match-3, permen spesial, papan peringkat sendiri
• Arena: PvP langsung lawan pemain lain
• Cerita 28 bab dengan pilihan yang mengubah akhir cerita
• Save cloud, VIP Pass, misi harian, roda keberuntungan
```

### 🇹🇭 ภาษาไทย (th)

```
🧋 Boba Empire — เปลี่ยนรถเข็นชาไข่มุกให้กลายเป็นอาณาจักรระดับโลก!

• เกม Idle: แตะ อัปเกรด ได้เงินแม้ไม่ได้เล่น
• ไข่มุกร่วง: 60 ด่านจับคู่ 3 ลูกอมพิเศษ กระดานจัดอันดับของตัวเอง
• อารีน่า: PvP สดกับผู้เล่นคนอื่น
• เนื้อเรื่อง 28 ตอน มีตัวเลือกที่เปลี่ยนตอนจบ
• เซฟบนคลาวด์ VIP Pass ภารกิจรายวัน วงล้อนำโชค
```

---

## 1.0.5 (+10) — 2026-09-30

**Bản trước:** 1.0.5 (+8), cùng ngày.

Mốc đáng chú ý của bản này: vá 3 lỗi crash phát hiện qua Crashlytics (xem
QC thưởng, khôi phục save cloud, mất kết nối Đấu Trường) và thêm tính năng
**mã quà tặng** — mã xin lỗi `XINLOI2026` tặng 1.000 💎 cho người từng gặp
crash.

### 🇻🇳 Tiếng Việt (vi)

```
Mới: nhập mã quà tặng ở Cài đặt!

• SỬA NHIỀU LỖI CRASH: xem QC thưởng, khôi phục save từ cloud, mất kết nối ở Đấu Trường
• Mã xin lỗi các bạn từng gặp crash: XINLOI2026 (+1.000 💎) — vào Cài đặt > Nhập mã quà tặng
• Ổn định hạ tầng phía sau
```

### 🇬🇧 English (en)

```
New: redeem gift codes in Settings!

• FIXED SEVERAL CRASHES: rewarded ads, cloud save restore, Arena connection loss
• Sorry for the crashes some of you hit — redeem code XINLOI2026 for +1,000 💎 (Settings > Redeem gift code)
• Backend stability improvements
```

### 🇧🇷 Português (pt-BR)

```
Novo: resgate códigos de presente em Ajustes!

• VÁRIAS CORREÇÕES DE CRASH: anúncios de recompensa, restauração de save na nuvem, perda de conexão na Arena
• Desculpe pelos crashes — resgate o código XINLOI2026 e ganhe +1.000 💎 (Ajustes > Resgatar código de presente)
• Melhorias de estabilidade nos bastidores
```

### 🇪🇸 Español (es)

```
Nuevo: canjea códigos de regalo en Ajustes!

• VARIAS CORRECCIONES DE FALLOS: anuncios con recompensa, restauración de guardado en la nube, pérdida de conexión en la Arena
• Disculpa por los fallos — canjea el código XINLOI2026 y recibe +1.000 💎 (Ajustes > Canjear código de regalo)
• Mejoras de estabilidad internas
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: tukar kode hadiah di Pengaturan!

• PERBAIKAN BEBERAPA CRASH: iklan berhadiah, pemulihan save cloud, koneksi Arena terputus
• Maaf atas crash yang dialami — tukar kode XINLOI2026 untuk +1.000 💎 (Pengaturan > Tukar kode hadiah)
• Peningkatan stabilitas di balik layar
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: แลกโค้ดของขวัญในตั้งค่า!

• แก้ไขปัญหาแอปปิดกะทันหันหลายจุด: ดูโฆษณารับรางวัล, กู้คืนเซฟจากคลาวด์, การเชื่อมต่ออารีน่าหลุด
• ขออภัยที่ทำให้แอปปิดกะทันหัน — แลกโค้ด XINLOI2026 รับ 💎 1,000 (ตั้งค่า > แลกโค้ดของขวัญ)
• ปรับปรุงความเสถียรเบื้องหลัง
```

---

## 1.0.5 (+8) — 2026-09-30

**Bản trước:** 1.0.4 (+7), chưa được App Store duyệt xong tại thời điểm này.

Mốc đáng chú ý của bản này: **hỗ trợ iPad đầy đủ** và bản vá bảng xếp hạng
tốc độ hoàn thành cốt truyện bị sai thời gian với save cũ (xem
`test/state/story_controller_test.dart`).

### 🇻🇳 Tiếng Việt (vi)

```
Mới: hỗ trợ đầy đủ iPad!

• Sự kiện giới hạn thời gian theo đợt, thêm thu nhập cuối tuần
• Thông báo nhắc quay lại sau vài ngày vắng mặt
• SỬA LỖI: bảng xếp hạng tốc độ hoàn thành cốt truyện bị sai với save cũ — nay tính đúng thời gian thật
• Nhiều lỗi hiển thị và ổn định hạ tầng phía sau
```

### 🇬🇧 English (en)

```
New: full iPad support!

• Limited-time weekend income events
• Come-back reminders after a few days away
• FIX: the story speedrun leaderboard could show bogus times on old saves — now uses real elapsed time
• Various display fixes and backend stability work
```

### 🇧🇷 Português (pt-BR)

```
Novo: suporte completo a iPad!

• Eventos de renda por tempo limitado nos fins de semana
• Lembretes para voltar após alguns dias ausente
• CORREÇÃO: o ranking de velocidade da história podia mostrar tempos falsos em saves antigos — agora usa o tempo real
• Várias correções visuais e mais estabilidade nos bastidores
```

### 🇪🇸 Español (es)

```
Nuevo: soporte completo para iPad!

• Eventos de ingresos por tiempo limitado los fines de semana
• Avisos para volver tras unos días de ausencia
• CORRECCIÓN: la clasificación de velocidad de la historia podía mostrar tiempos falsos en partidas antiguas — ahora usa el tiempo real
• Varias correcciones visuales y más estabilidad interna
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: dukungan penuh iPad!

• Event pendapatan akhir pekan waktu terbatas
• Pengingat kembali bermain setelah beberapa hari absen
• PERBAIKAN: papan peringkat speedrun cerita bisa menampilkan waktu palsu pada save lama — kini pakai waktu asli
• Berbagai perbaikan tampilan dan stabilitas di balik layar
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: รองรับ iPad เต็มรูปแบบ!

• อีเวนต์รายได้ช่วงเวลาจำกัดวันหยุดสุดสัปดาห์
• แจ้งเตือนชวนกลับมาเล่นหลังหายไปหลายวัน
• แก้ไข: กระดานจัดอันดับความเร็วเนื้อเรื่องอาจแสดงเวลาผิดสำหรับเซฟเก่า — ตอนนี้ใช้เวลาจริงแล้ว
• แก้ไขการแสดงผลหลายจุดและเสถียรภาพเบื้องหลัง
```

---

## 1.0.4 (+7) — 2026-09-29

**Bản trước:** 1.0.3 (+6), phát hành App Store 2026-09-27.

Mốc đáng chú ý của bản này: chế độ chơi mới **Trân Châu Rơi** và bản vá **Sao
nhượng quyền bị kẹt** — lỗi tràn số làm người chơi cuối tuyến không tích thêm
được Sao nào nữa (xem `test/core/prestige_star_ceiling_test.dart`).

### 🇻🇳 Tiếng Việt (vi)

```
Mới: TRÂN CHÂU RƠI — chế độ ghép 3 với 60 màn, kẹo đặc biệt và bảng xếp hạng riêng!

• 12 giai đoạn 7-18 có cảnh nền riêng, không còn dùng chung
• Thông báo nhắc khi kho offline đã đầy, vòng quay miễn phí reset, có nhiệm vụ mới
• Đấu Trường tự xáo bàn khi hết nước đi
• SỬA LỖI QUAN TRỌNG: Sao nhượng quyền của người chơi cuối tuyến bị kẹt, không tăng nữa — nay đã tính đúng trở lại
• Khoá màn dọc, sửa nhiều lỗi hiển thị và tăng độ ổn định
```

### 🇬🇧 English (en)

```
New: FALLING PEARLS — a match-3 mode with 60 levels, special candies and its own leaderboard!

• Stages 7-18 now each have their own backdrop
• Reminders when your offline vault is full, the free wheel resets, or new quests arrive
• The Arena now reshuffles automatically when no moves are left
• IMPORTANT FIX: late-game Prestige Stars were stuck and stopped growing — they now count correctly again
• Portrait lock, many display fixes and better stability
```

### 🇧🇷 Português (pt-BR)

```
Novo: PÉROLAS CAINDO — modo match-3 com 60 fases, doces especiais e ranking próprio!

• As fases 7-18 agora têm cenário próprio
• Lembretes quando o cofre offline enche, a roleta grátis reinicia ou há missões novas
• A Arena embaralha sozinha quando não há mais jogadas
• CORREÇÃO IMPORTANTE: as Estrelas de prestígio travavam no fim de jogo e paravam de crescer — voltaram a contar certo
• Bloqueio de tela em retrato, várias correções visuais e mais estabilidade
```

### 🇪🇸 Español (es)

```
Nuevo: PERLAS QUE CAEN — modo match-3 con 60 niveles, caramelos especiales y su propia clasificación.

• Las etapas 7-18 ya tienen su propio fondo
• Avisos cuando la bóveda sin conexión se llena, la ruleta gratis se reinicia o hay misiones nuevas
• La Arena baraja sola cuando no quedan movimientos
• CORRECCIÓN IMPORTANTE: las Estrellas de prestigio se atascaban al final del juego y dejaban de crecer; ya cuentan bien
• Bloqueo en vertical, varias correcciones visuales y más estabilidad
```

### 🇮🇩 Bahasa Indonesia (id)

```
Baru: MUTIARA JATUH — mode match-3 dengan 60 level, permen spesial, dan papan peringkat sendiri!

• Tahap 7-18 kini punya latar masing-masing
• Pengingat saat brankas offline penuh, roda gratis ter-reset, atau ada misi baru
• Arena kini mengacak papan otomatis saat tidak ada langkah tersisa
• PERBAIKAN PENTING: Bintang prestise pemain akhir permainan macet dan berhenti bertambah — kini dihitung benar lagi
• Kunci mode potret, banyak perbaikan tampilan, dan lebih stabil
```

### 🇹🇭 ภาษาไทย (th)

```
ใหม่: ไข่มุกร่วง — โหมดจับคู่ 3 ที่มี 60 ด่าน ลูกอมพิเศษ และกระดานจัดอันดับของตัวเอง!

• ด่าน 7-18 มีฉากหลังเป็นของตัวเองแล้ว
• แจ้งเตือนเมื่อคลังออฟไลน์เต็ม วงล้อฟรีรีเซ็ต หรือมีภารกิจใหม่
• อารีน่าสับกระดานอัตโนมัติเมื่อไม่มีตาเดินเหลือ
• แก้ไขสำคัญ: ดาวชื่อเสียงของผู้เล่นปลายเกมค้างและหยุดเพิ่ม ตอนนี้นับถูกต้องแล้ว
• ล็อกแนวตั้ง แก้ไขการแสดงผลหลายจุด และเสถียรขึ้น
```
