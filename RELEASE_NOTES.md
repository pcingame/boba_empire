# Release Notes — nội dung "Có gì mới" để dán vào console

Mỗi mục dưới đây dán vào **What's New** (App Store Connect) / **What's new in
this release** (Play Console), đúng ngôn ngữ.

**Giới hạn:** Play **≤ 500 ký tự**, App Store ≤ 4000. Mọi bản dưới đây viết
dưới 500 để dùng chung được cho cả hai store. Bản dịch do máy soạn — nên nhờ
người bản ngữ soát.

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
