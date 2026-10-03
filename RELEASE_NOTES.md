# Release Notes — nội dung "Có gì mới" để dán vào console

Mỗi mục dưới đây dán vào **What's New** (App Store Connect) / **What's new in
this release** (Play Console), đúng ngôn ngữ.

**Giới hạn:** Play **≤ 500 ký tự**, App Store ≤ 4000. Mọi bản dưới đây viết
dưới 500 để dùng chung được cho cả hai store. Bản dịch do máy soạn — nên nhờ
người bản ngữ soát.

---

## 1.0.6 (+12) — 2026-10-03

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
