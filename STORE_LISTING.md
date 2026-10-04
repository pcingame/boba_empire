# Store Listing — nội dung sẵn để dán vào Play Console / App Store Connect

Đây là **metadata cửa hàng** (không phải code). Dán vào đúng trường trong console.
Bản dịch do máy soạn — **nên nhờ người bản ngữ soát** trước khi phát hành.

**Cập nhật 2026-10-04 (bản 1.0.7):** thêm tiếng Hàn (7 ngôn ngữ). Mô tả mới ở
`assets/store/description_1.0.7/{vi,en,es,id,pt,th,ko}.txt` (80 phụ kiện, phụ kiện lễ hội, cứu
streak, "7 ngôn ngữ"); nội dung "Có gì mới" ở `assets/store/whatsnew_1.0.7/*.txt` (App Store,
không emoji). Dòng cuối mô tả GIỮ `[:mav: 1.0.6]` — đổi thành `1.0.7` chỉ khi muốn ÉP mọi người
cập nhật. Play giới hạn "What's new" 500 ký tự/ngôn ngữ nên phải rút gọn khi dán.

**Cập nhật 2026-09-26:** viết lại cho khớp game hiện tại (18 giai đoạn, cốt truyện 28
chương, Kỷ Nguyên, nhiệm vụ hằng ngày, Đấu Trường + bảng xếp hạng, sao lưu email). Mọi tính
năng nêu trong mô tả đều có trong code; **không** nêu số lượng người chơi hay đánh giá.

**Cập nhật 2026-09-29:** Keywords + Promotional Text 6 ngôn ngữ — 2 việc cùng lúc:
1. Sửa mô tả sai: Trân Châu Rơi đã tách thành chế độ riêng (60 màn + bảng xếp hạng
   riêng, xem `b195d32`), không còn là "một dạng của Đấu Trường" như bản cũ ghi.
2. Thêm từ khóa theo trend trà sữa thật 2026 (matcha, cheese foam/phô mai, trà trái
   cây) — đúng từ khách hàng boba thật đang tìm. Nhường chỗ bằng cách bỏ vài từ đã
   trùng nghĩa với tên app/subtitle (vi/en/pt/es/id — nơi "idle"/"tycoon" xuất hiện
   ĐÚNG CHỮ đó ở tên app, nhồi lại vào Keywords là phí ký tự theo "Mẹo ASO" bên
   dưới). Riêng th GIỮ nguyên idle/tycoon/clicker vì tên app ở đó dùng chữ Thái
   phiên âm (ไอเดิลไทคูน), không trùng ký tự với "idle"/"tycoon" tiếng Anh trong
   Keywords. Promotional Text đổi được không cần nộp bản mới.

## Giới hạn ký tự

| Trường | Google Play | App Store |
| --- | --- | --- |
| Tên app | ≤ 30 | ≤ 30 |
| Mô tả ngắn / Subtitle | ≤ 80 (short description) | ≤ 30 (subtitle) |
| Promotional text | — | ≤ 170 |
| Mô tả đầy đủ | ≤ 4000 | ≤ 4000 |
| Keywords | — (Play không có; dùng từ khóa trong mô tả) | ≤ 100, phân cách bằng dấu phẩy |

Mọi trường dưới đây đã được kiểm tra tự động ≤ giới hạn.

## Mẹo ASO
- Nhồi từ khóa chính (idle, tycoon, clicker, boba/bubble tea) vào **tên + mô tả ngắn** — trọng số cao nhất.
- Đừng bịa "hàng triệu người chơi" khi mới ra mắt (vi phạm + mất uy tín).
- **Screenshot + icon ảnh hưởng lượt cài hơn cả chữ** — chữ ở đây chỉ là một nửa việc. Gợi ý thứ
  tự ảnh: (1) màn chính đang chạm pha trà, (2) chọn nhánh cốt truyện, (3) đổi giai đoạn lên
  cảnh mới, (4) Nhiệm vụ ngày/Vòng quay, (5) Đấu Trường/bảng xếp hạng.
- App Store: mỗi từ khóa chỉ cần 1 lần, không lặp từ đã có ở tên/subtitle.
- Promotional Text đổi được KHÔNG cần nộp bản mới — dùng để báo tính năng mới theo từng đợt.

---

**Lưu ý ASC (2026-10-03):** ô Description của App Store Connect báo "invalid characters" với emoji — mô tả đã được accept trước đó KHÔNG có emoji nhưng vẫn giữ dấu "—" và "×". Vì vậy 6 mô tả dưới đây đã bỏ emoji (tiêu đề mục chỉ còn chữ in hoa). Bản có emoji, nếu cần cho Play: xem lịch sử git (`be72600`).

**Cập nhật 2026-10-03 (bản 1.0.6):** cốt truyện 28 → 36 chương (Hồi 3), thêm mục "Bộ sưu tập & Chợ
phụ kiện" ở cả 6 mô tả, và dòng cuối `[:mav: 1.0.6]` — **thẻ force update** của `upgrader` (xem
`RELEASE_NOTES.md`). Thẻ này CHỈ để trong **Description (App Store)**; bản Play dùng thẻ khác:
`[Minimum supported app version: 1.0.6]` (thay dòng cuối khi dán vào Play Console). Chưa cập nhật:
Keywords/Promotional Text/Mô tả ngắn (vẫn đúng).

## 🇻🇳 Tiếng Việt (vi)

**Tên app:** `Đế Chế Trà Sữa`
**Mô tả ngắn (Play):** `Chạm pha trà, xây đế chế trà sữa qua 18 giai đoạn! Idle tycoon có cốt truyện.`
**Subtitle (App Store):** `Idle tycoon trà sữa`
**Keywords (App Store):** `boba,trân châu,matcha,phô mai,trà trái cây,trà sữa,cafe,tap,thư giãn,nhàn rỗi,cốt truyện`
**Promotional Text (App Store):** `Mới: Trân Châu Rơi 60 màn, Kỷ Nguyên, nhiệm vụ ngày! Matcha, phô mai, trà trái cây — như quán thật. Xây đế chế từ xe đẩy tới huyền thoại, kiếm Xu cả khi offline.`

**Mô tả đầy đủ:**
```
Gây dựng đế chế trà sữa của riêng bạn, từng ly một!

Đế Chế Trà Sữa là game idle tycoon thư giãn có cốt truyện: chạm để pha trà, mua nâng cấp và nhìn cửa hàng lớn dần từ chiếc xe đẩy vỉa hè tới đế chế toàn cầu — kể cả khi bạn thoát game.

CHẠM & PHA TRÀ
Chạm để bán trà sữa và kiếm Xu. Mua nâng cấp để có thu nhập tự động mỗi giây, đạt mốc để nhân bội thu nhập.

18 GIAI ĐOẠN
Từ xe đẩy vỉa hè, kiosk, chuỗi cafe sang trọng, sàn chứng khoán, học viện, thành phố, tới hành tinh trà sữa. Mỗi giai đoạn có món mới và bầu không khí riêng.

CỐT TRUYỆN 36 CHƯƠNG
Cùng Bà Tư xây quán, đối đầu đối thủ, đưa ra những lựa chọn rẽ nhánh ảnh hưởng tới sức mạnh của bạn.

BỘ SƯU TẬP & CHỢ PHỤ KIỆN
Sưu tầm 50 phụ kiện, trưng bày quanh cốc và khoe huy hiệu trên bảng xếp hạng. Mua bán với người chơi khác ở Chợ bằng Xu Chợ, xem giá tham khảo, lập danh sách muốn có. Cuối tuần phí Chợ 0%.

NHƯỢNG QUYỀN & KỶ NGUYÊN
Chơi lại để nhận Sao và bonus vĩnh viễn. Khi đã đi hết tuyến, Kỷ Nguyên mở ra vòng chơi mới với perk mạnh hơn nữa.

MỖI NGÀY MỘT LÝ DO
Nhiệm vụ hằng ngày, điểm danh, vòng quay may mắn — quay lại mỗi ngày để nhận Kim Cương.

MƯA VÀNG & KHÁCH VIP
Chạm mèo may mắn để nhận Mưa vàng ×3, đón khách VIP để thu Kim Cương.

ĐẤU TRƯỜNG & BẢNG XẾP HẠNG
Đấu 1v1 trong 60 giây với hai dạng: Đua chạm và Trân Châu Rơi (ghép 3). Leo bảng xếp hạng thu nhập và tốc độ phá đảo cốt truyện.

SAO LƯU TIẾN TRÌNH
Liên kết email để giữ tiến trình khi đổi máy hoặc gỡ app.

KIẾM TIỀN OFFLINE
Quán vẫn bán khi bạn vắng mặt. Quay lại và nhận cả đống Xu!

Có 6 ngôn ngữ. Hợp với ai mê game idle clicker, tycoon, incremental. Dễ chơi, thư giãn.

Bắt đầu pha ly trà đầu tiên ngay hôm nay!

[:mav: 1.0.6]
```

---

## 🇬🇧 English (en)

**App name:** `Boba Empire: Idle Tycoon`
**Short description (Play):** `Tap, brew & grow a bubble tea empire across 18 stages! Idle tycoon with a story.`
**Subtitle (App Store):** `Relaxing bubble tea tycoon`
**Keywords (App Store):** `boba,pearls,matcha,cheese foam,fruit tea,bubble tea,cafe,incremental,tap,business,relaxing,story`
**Promotional Text (App Store):** `New: Falling Pearls now standalone (60 levels), plus Ascension & daily quests! Matcha, cheese foam, fruit tea — just like a real shop. Cart to legend, earn even offline.`

**Full description:**
```
Build your bubble tea empire one cup at a time!

Boba Empire is a relaxing idle tycoon with a story: tap to brew tea, buy upgrades, and watch your business grow from a street cart to a global empire — even while you're away.

TAP & BREW
Tap to serve bubble tea and earn coins. Buy upgrades for automatic income every second, and hit milestones to multiply it.

18 STAGES
From a street cart to a kiosk, luxury cafés, the stock market, an academy, a city and a whole milk-tea planet. Every stage brings new drinks and a new feel.

A 36-CHAPTER STORY
Build the shop alongside Grandma Tư, face your rival, and make branching choices that change your power.

COLLECTION & ACCESSORY MARKET
Collect 50 accessories, show them around your cup and flaunt a badge on the leaderboards. Trade with other players in the Market using Market Coins, check price hints, build a wishlist. Weekends: 0% Market fee.

FRANCHISE & ASCENSION
Reset to earn Stars and permanent bonuses. Once you've reached the end, Ascension opens a whole new loop with even stronger perks.

A REASON TO COME BACK
Daily quests, daily check-in and a lucky wheel — return every day to collect Gems.

GOLDEN RUSH & VIP GUESTS
Tap the lucky cat for a x3 Golden Rush, and serve VIP customers to collect Gems.

ARENA & LEADERBOARDS
Duel 1v1 in 60 seconds in two modes: Tap race and Falling Pearls (match-3). Climb the earnings and story speedrun leaderboards.

BACK UP YOUR PROGRESS
Link an email to keep your progress when you switch devices or reinstall.

EARN OFFLINE
Your shop keeps selling while you're away. Come back to a pile of coins!

Available in 6 languages. Perfect for fans of idle clicker, tycoon and incremental games. Easy to play, relaxing to master.

Start brewing your Boba Empire today!

[:mav: 1.0.6]
```

---

## 🇧🇷 Português (pt-BR)

**Nome do app:** `Boba Empire: Idle Tycoon`
**Descrição curta (Play):** `Toque, prepare e expanda seu império de bubble tea em 18 fases! Idle e história.`
**Subtítulo (App Store):** `Império de bubble tea`
**Keywords (App Store):** `boba,perolas,matcha,espuma queijo,cha frutas,bubble tea,cafe,incremental,negocio,relaxante,historia`
**Promotional Text (App Store):** `Novo: Pérolas Caindo agora solo (60 fases), Ascensão e missões diárias! Matcha, espuma de queijo, chá de frutas: como uma loja real. Do carrinho à lenda, ganhe offline.`

**Descrição completa:**
```
Construa seu império de bubble tea, um copo de cada vez!

Boba Empire é um idle tycoon relaxante com história: toque para preparar chá, compre melhorias e veja seu negócio crescer de um carrinho de rua a um império global — até enquanto você está fora.

TOQUE E PREPARE
Toque para servir bubble tea e ganhar moedas. Compre melhorias para ter renda automática a cada segundo e atinja marcos para multiplicá-la.

18 FASES
De um carrinho de rua a quiosque, cafés de luxo, bolsa de valores, academia, cidade e até um planeta de chá com leite. Cada fase traz novas bebidas e um clima novo.

HISTÓRIA DE 36 CAPÍTULOS
Construa a loja ao lado da Vovó Tư, enfrente seu rival e faça escolhas que mudam seu poder.

COLEÇÃO E MERCADO DE ACESSÓRIOS
Colecione 50 acessórios, exiba-os ao redor do copo e mostre um emblema nos rankings. Negocie com outros jogadores no Mercado com Moedas de Mercado, veja preços de referência e crie sua lista de desejos. Fim de semana: taxa 0%.

FRANQUIA E ASCENSÃO
Reinicie para ganhar Estrelas e bônus permanentes. Ao chegar ao fim, a Ascensão abre um novo ciclo com melhorias ainda mais fortes.

MOTIVO PARA VOLTAR
Missões diárias, check-in diário e roda da sorte — volte todo dia para ganhar Gemas.

CHUVA DOURADA E CLIENTES VIP
Toque no gato da sorte para uma Chuva Dourada ×3 e atenda clientes VIP para ganhar Gemas.

ARENA E RANKINGS
Duelos 1v1 de 60 segundos em dois modos: Corrida de toques e Pérolas Caindo (combine 3). Suba nos rankings de ganhos e de velocidade da história.

BACKUP DO PROGRESSO
Vincule um e-mail para manter seu progresso ao trocar de aparelho ou reinstalar.

GANHE OFFLINE
Sua loja continua vendendo quando você está fora. Volte e receba uma pilha de moedas!

Disponível em 6 idiomas. Ideal para fãs de idle clicker, tycoon e incremental. Fácil de jogar, relaxante de dominar.

Comece a preparar seu Boba Empire hoje!

[:mav: 1.0.6]
```

---

## 🇪🇸 Español (es)

**Nombre de la app:** `Boba Empire: Idle Tycoon`
**Descripción corta (Play):** `¡Toca, prepara y crea tu imperio de bubble tea en 18 etapas! Idle con historia.`
**Subtítulo (App Store):** `Imperio de bubble tea`
**Keywords (App Store):** `boba,perlas,matcha,espuma queso,te frutas,bubble tea,cafe,incremental,negocio,relajante,historia`
**Promotional Text (App Store):** `Nuevo: Perlas que Caen ahora solo (60 niveles), Ascensión, misiones diarias! Matcha, espuma queso, té frutas: como una tienda real. Del carrito a leyenda, gana offline.`

**Descripción completa:**
```
¡Construye tu imperio de bubble tea, una taza a la vez!

Boba Empire es un idle tycoon relajante con historia: toca para preparar té, compra mejoras y mira crecer tu negocio de un carrito callejero a un imperio global, incluso cuando no estás.

TOCA Y PREPARA
Toca para servir bubble tea y ganar monedas. Compra mejoras para tener ingresos automáticos cada segundo y alcanza hitos para multiplicarlos.

18 ETAPAS
De un carrito callejero a un quiosco, cafés de lujo, la bolsa, una academia, una ciudad y hasta un planeta de té con leche. Cada etapa trae bebidas y ambiente nuevos.

HISTORIA DE 36 CAPÍTULOS
Construye la tienda junto a la Abuela Tư, enfréntate a tu rival y toma decisiones que cambian tu poder.

COLECCIÓN Y MERCADO DE ACCESORIOS
Colecciona 50 accesorios, muéstralos junto al vaso y presume una insignia en las clasificaciones. Compra y vende con otros jugadores en el Mercado usando Monedas de Mercado, mira precios de referencia y crea tu lista de deseos. Fines de semana: comisión 0%.

FRANQUICIA Y ASCENSIÓN
Reinicia para ganar Estrellas y bonos permanentes. Al llegar al final, la Ascensión abre un nuevo ciclo con mejoras aún más fuertes.

UN MOTIVO PARA VOLVER
Misiones diarias, registro diario y ruleta de la suerte: vuelve cada día para reclamar Gemas.

LLUVIA DORADA Y CLIENTES VIP
Toca al gato de la suerte para una Lluvia Dorada ×3 y atiende clientes VIP para conseguir Gemas.

ARENA Y CLASIFICACIONES
Duelos 1v1 de 60 segundos en dos modos: Carrera de toques y Perlas que caen (combina 3). Sube en las clasificaciones de ganancias y de velocidad de la historia.

COPIA DE SEGURIDAD
Vincula un correo para conservar tu progreso al cambiar de dispositivo o reinstalar.

GANA OFFLINE
Tu tienda sigue vendiendo cuando no estás. ¡Vuelve y recibe un montón de monedas!

Disponible en 6 idiomas. Ideal para fans de idle clicker, tycoon e incremental. Fácil de jugar, relajante de dominar.

¡Empieza a preparar tu Boba Empire hoy!

[:mav: 1.0.6]
```

---

## 🇮🇩 Bahasa Indonesia (id)

**Nama aplikasi:** `Boba Empire: Idle Tycoon`
**Deskripsi singkat (Play):** `Ketuk, seduh & bangun kerajaan bubble tea di 18 tahap! Idle tycoon berkisah.`
**Subjudul (App Store):** `Kerajaan bubble tea`
**Keywords (App Store):** `boba,mutiara,matcha,busa keju,teh buah,bubble tea,kafe,incremental,bisnis,santai,cerita`
**Promotional Text (App Store):** `Baru: mode solo Mutiara Jatuh (60 level), Ascension, misi harian! Matcha, busa keju, teh buah - seperti kedai asli. Dari gerobak sampai legenda, cuan meski offline.`

**Deskripsi lengkap:**
```
Bangun kerajaan bubble tea-mu, satu gelas demi satu gelas!

Boba Empire adalah idle tycoon santai dengan cerita: ketuk untuk menyeduh teh, beli upgrade, dan lihat bisnismu tumbuh dari gerobak kaki lima jadi kerajaan global — bahkan saat kamu tidak main.

KETUK & SEDUH
Ketuk untuk menyajikan bubble tea dan dapatkan koin. Beli upgrade untuk pendapatan otomatis tiap detik, capai milestone untuk melipatgandakannya.

18 TAHAP
Dari gerobak kaki lima ke kios, kafe mewah, bursa saham, akademi, kota, sampai planet teh susu. Setiap tahap punya minuman dan suasana baru.

CERITA 36 BAB
Bangun toko bersama Nenek Tư, hadapi saingan, dan buat pilihan bercabang yang mengubah kekuatanmu.

KOLEKSI & PASAR AKSESORI
Koleksi 50 aksesori, pajang di sekitar gelas, dan pamerkan lencana di papan peringkat. Jual beli dengan pemain lain di Pasar memakai Koin Pasar, lihat harga acuan, buat daftar keinginan. Akhir pekan: biaya Pasar 0%.

WARALABA & ASCENSION
Reset untuk mendapat Bintang dan bonus permanen. Setelah sampai akhir, Ascension membuka putaran baru dengan perk yang lebih kuat.

ALASAN UNTUK KEMBALI
Misi harian, check-in harian, dan roda keberuntungan — kembali tiap hari untuk ambil Permata.

HUJAN EMAS & TAMU VIP
Ketuk kucing keberuntungan untuk Hujan Emas ×3 dan layani pelanggan VIP untuk mendapat Permata.

ARENA & PAPAN PERINGKAT
Duel 1v1 selama 60 detik dengan dua mode: Balap ketuk dan Mutiara Jatuh (cocokkan 3). Naik di papan peringkat pendapatan dan kecepatan tamat cerita.

CADANGKAN PROGRES
Hubungkan email agar progres aman saat ganti perangkat atau install ulang.

CUAN SAAT OFFLINE
Tokomu tetap berjualan saat kamu pergi. Kembali dan terima tumpukan koin!

Tersedia dalam 6 bahasa. Cocok untuk penggemar idle clicker, tycoon, dan incremental. Mudah dimainkan, santai untuk dikuasai.

Mulai seduh Boba Empire-mu hari ini!

[:mav: 1.0.6]
```

---

## 🇹🇭 ภาษาไทย (th)

**ชื่อแอป:** `Boba Empire: ไอเดิลไทคูน`
**คำอธิบายสั้น (Play):** `แตะ ชง และสร้างอาณาจักรชานมไข่มุก 18 ด่าน! เกมไอเดิลไทคูนมีเนื้อเรื่อง`
**คำบรรยาย (App Store):** `ไทคูนชานมไข่มุก`
**Keywords (App Store):** `idle,tycoon,clicker,boba,ไข่มุก,มัทฉะ,ชีสโฟม,ชาผลไม้,ชานม,คาเฟ่,ธุรกิจ,เนื้อเรื่อง`
**Promotional Text (App Store):** `ใหม่: โหมดไข่มุกร่วงแยกเดี่ยว 60 ด่าน ระบบยุคใหม่ ภารกิจรายวัน! มัทฉะ ชีสโฟม ชาผลไม้ เหมือนร้านจริง ขยายอาณาจักรชานมจากรถเข็นสู่ตำนาน หาเงินได้แม้ออฟไลน์`

**คำอธิบายแบบเต็ม:**
```
สร้างอาณาจักรชานมไข่มุกของคุณ ทีละแก้ว!

Boba Empire คือเกมไอเดิลไทคูนผ่อนคลายที่มีเนื้อเรื่อง: แตะเพื่อชงชา ซื้ออัปเกรด และดูธุรกิจเติบโตจากรถเข็นริมทางสู่อาณาจักรระดับโลก — แม้ตอนที่คุณไม่ได้เล่น

แตะและชง
แตะเพื่อเสิร์ฟชานมไข่มุกและรับเหรียญ ซื้ออัปเกรดเพื่อรับรายได้อัตโนมัติทุกวินาที และทำถึงเป้าหมายเพื่อคูณรายได้

18 ด่าน
จากรถเข็นริมทาง คีออสก์ คาเฟ่หรู ตลาดหลักทรัพย์ สถาบัน เมือง ไปจนถึงดาวเคราะห์ชานม แต่ละด่านมีเครื่องดื่มและบรรยากาศใหม่

เนื้อเรื่อง 36 บท
สร้างร้านไปกับคุณยาย Tư เผชิญหน้าคู่แข่ง และเลือกเส้นทางที่เปลี่ยนพลังของคุณ

คอลเลกชันและตลาดเครื่องประดับ
สะสมเครื่องประดับ 50 ชิ้น จัดโชว์รอบแก้ว และอวดตราบนกระดานจัดอันดับ ซื้อขายกับผู้เล่นอื่นในตลาดด้วยเหรียญตลาด ดูราคาอ้างอิง สร้างรายการที่อยากได้ สุดสัปดาห์ค่าธรรมเนียม 0%

แฟรนไชส์และยุคใหม่
เริ่มใหม่เพื่อรับดาวและโบนัสถาวร เมื่อไปถึงจุดจบ ระบบยุคใหม่จะเปิดรอบใหม่พร้อมเพิร์กที่แรงขึ้น

เหตุผลให้กลับมา
ภารกิจรายวัน เช็คอินรายวัน และวงล้อนำโชค — กลับมาทุกวันเพื่อรับเพชร

โกลเด้นรัชและลูกค้า VIP
แตะแมวนำโชคเพื่อรับโกลเด้นรัช ×3 และบริการลูกค้า VIP เพื่อเก็บเพชร

สนามประลองและอันดับ
ดวล 1 ต่อ 1 ใน 60 วินาที 2 โหมด: แข่งแตะและไข่มุกร่วง (จับคู่ 3) ไต่อันดับรายได้และความเร็วจบเนื้อเรื่อง

สำรองความคืบหน้า
ผูกอีเมลเพื่อเก็บความคืบหน้าไว้เมื่อเปลี่ยนเครื่องหรือลบแอป

รับรายได้ออฟไลน์
ร้านยังขายต่อขณะที่คุณไม่อยู่ กลับมารับเหรียญกองโต!

รองรับ 6 ภาษา เหมาะสำหรับแฟนเกมไอเดิลคลิกเกอร์ ไทคูน และ incremental เล่นง่าย ผ่อนคลาย

เริ่มชงชาอาณาจักร Boba Empire ของคุณวันนี้!

[:mav: 1.0.6]
```

---
