// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Boba Empire';

  @override
  String get tapBrew => 'Ketuk untuk menyeduh';

  @override
  String get coinsSuffix => ' Koin';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / dtk';
  }

  @override
  String get instantCashButton => 'Uang instan';

  @override
  String instantCashSnack(String amount) {
    return 'Uang instan! +$amount Koin';
  }

  @override
  String get adNotReadySnack => 'Iklan belum siap, coba lagi sebentar lagi';

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Buka $cost Koin';
  }

  @override
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount Koin/dtk per level';
  }

  @override
  String buyButton(String cost) {
    return '$cost Koin';
  }

  @override
  String get buyModeMax => 'MAX';

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · ${seconds}s';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'Pelanggan VIP! +$cash Koin, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'Menerima +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'Iklan dihapus. Terima kasih!';

  @override
  String iapStarterSnack(String amount) {
    return 'Paket awal: +$amount 💎';
  }

  @override
  String get genTraDen => 'Teh Hitam';

  @override
  String get genTranChau => 'Mutiara Boba';

  @override
  String get genThach => 'Cincau';

  @override
  String get genPudding => 'Puding';

  @override
  String get genKemNuong => 'Teh Susu Crème Brûlée';

  @override
  String get genMatcha => 'Matcha Seember';

  @override
  String get stage1 => 'Gerobak Kaki Lima';

  @override
  String get stage2 => 'Kios Kecil';

  @override
  String get stage3 => 'Jaringan Kafe Mewah';

  @override
  String gemShopTitle(String gems) {
    return 'Toko 💎 (punya $gems)';
  }

  @override
  String get gemBoostName => 'Peningkatan pendapatan';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% pendapatan permanen per level';
  }

  @override
  String get offlineCapName => 'Pendingin offline';

  @override
  String offlineCapDesc(int hours) {
    return '+$hours jam batas offline per level';
  }

  @override
  String gemItemLevel(String name, int level) {
    return '$name  Lv.$level';
  }

  @override
  String gemCost(int cost) {
    return '$cost 💎';
  }

  @override
  String get gemInstantStageName => 'Buka tahap instan';

  @override
  String gemInstantStageDesc(String stage) {
    return 'Buka $stage sekarang, lewati biaya Koin';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return '$stage terbuka!';
  }

  @override
  String get gemTimeSkipName => 'Percepat';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Dapat $hours jam produksi seketika';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return 'Tersisa $remaining/$max hari ini';
  }

  @override
  String get iapSectionTitle => 'Beli dengan uang asli';

  @override
  String get restorePurchases => 'Pulihkan pembelian';

  @override
  String get close => 'Tutup';

  @override
  String get iapGemsDesc => 'Isi Permata untuk membeli item di Toko.';

  @override
  String get iapRemoveAdsTitle => 'Hapus iklan';

  @override
  String get iapRemoveAdsDesc =>
      'Lewati semua iklan — kamu tetap dapat semua hadiah tanpa menonton.';

  @override
  String get iapStarterTitle => 'Paket awal';

  @override
  String get iapStarterDesc =>
      'Sekali saja: langsung dapat sekantong besar Permata.';

  @override
  String get prestigeTitle => 'Waralaba 🏪';

  @override
  String prestigeIntro(String percent) {
    return 'Setiap ⭐ Bintang memberi +$percent% pendapatan permanen.';
  }

  @override
  String get prestigeStarsNow => 'Bintang saat ini';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Waralabakan sekarang';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Total bonus setelahnya';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Reset Koin, level upgrade, dan tahap (perk Bintang bisa menyimpan sebagian).';

  @override
  String get cancel => 'Batal';

  @override
  String prestigeConfirm(String stars) {
    return 'Waralabakan (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Tidak cukup';

  @override
  String prestigeSuccess(String stars) {
    return 'Waralaba berhasil! +$stars ⭐';
  }

  @override
  String get offlineTitle => 'Selamat datang kembali! 🧋';

  @override
  String offlineBody(String amount) {
    return 'Toko tetap berjualan saat kamu pergi.\nKamu mendapat $amount Koin.';
  }

  @override
  String get offlineClaim => 'Ambil';

  @override
  String get offlineDoubleButton => 'Tonton iklan ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return 'Digandakan! +$amount Koin';
  }

  @override
  String get howToPlayTitle => 'Cara bermain';

  @override
  String get htpTap =>
      '🧋 Ketuk gelas untuk menyeduh teh dan mendapatkan Koin.';

  @override
  String get htpBuy =>
      '🛒 Beli peningkatan untuk pendapatan otomatis setiap detik.';

  @override
  String get htpStage =>
      '🏪 Kumpulkan Koin untuk membuka tahap baru dengan minuman lebih mewah.';

  @override
  String get htpCat =>
      '🐱 Ketuk kucing keberuntungan untuk Hujan Emas ×3 sesaat.';

  @override
  String get htpVip => '🚗 Layani pelanggan VIP untuk mendapatkan Permata 💎.';

  @override
  String get htpGems =>
      '💎 Gunakan Permata di Toko untuk peningkatan permanen.';

  @override
  String get htpPrestige =>
      '⭐ Waralabakan untuk mengulang dan dapat Bintang — bonus pendapatan permanen.';

  @override
  String get htpOffline =>
      '😴 Toko tetap berjualan saat kamu pergi — kembali untuk mengambil uang offline.';

  @override
  String get htpNumberFormat =>
      '🔢 Angka besar pakai singkatan: K=ribu, M=juta, B=miliar, T=triliun, lalu aa, bb, cc... — tiap tingkat 1.000× dari sebelumnya.';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSystem => 'Bawaan sistem';

  @override
  String get dailyTitle => 'Check-in harian';

  @override
  String get dailyPrompt => 'Ambil hadiah login hari ini!';

  @override
  String get dailyClaim => 'Ambil';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Streak $days hari 🔥';
  }

  @override
  String get achievementsTitle => 'Pencapaian';

  @override
  String achEarn(String amount) {
    return 'Kumpulkan total $amount Koin';
  }

  @override
  String achStage(int n) {
    return 'Capai tahap $n';
  }

  @override
  String achLevels(int n) {
    return 'Miliki total $n level peningkatan';
  }

  @override
  String achPrestige(int n) {
    return 'Waralaba ($n★ atau lebih)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 Pencapaian terbuka! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => 'Toko Bintang ⭐';

  @override
  String prestigeShopSpendable(String stars) {
    return '$stars ⭐ untuk dibelanjakan';
  }

  @override
  String get prestigeIncomeName => 'Mega pendapatan';

  @override
  String prestigeIncomeDesc(int percent) {
    return '+$percent% pendapatan permanen per level';
  }

  @override
  String get prestigeTapName => 'Mega ketuk';

  @override
  String prestigeTapDesc(int percent) {
    return '+$percent% nilai ketukan per level';
  }

  @override
  String get prestigeOfflineName => 'Super offline';

  @override
  String prestigeOfflineDesc(int percent) {
    return '+$percent% penghasilan saat pergi per level';
  }

  @override
  String get prestigeStartCashName => 'Modal awal';

  @override
  String get prestigeStartCashDesc =>
      'Dapat Koin langsung setelah Waralaba (naik per level)';

  @override
  String get prestigeKeepStageName => 'Simpan tahap';

  @override
  String get prestigeKeepStageDesc =>
      'Simpan 1 tahap lagi setelah Waralaba per level';

  @override
  String get prestigeDiscountName => 'Beli borongan';

  @override
  String prestigeDiscountDesc(int percent) {
    return '-$percent% biaya upgrade per level';
  }

  @override
  String get prestigeAutoBuyName => 'Beli otomatis';

  @override
  String get prestigeAutoBuyDesc =>
      'Buka sakelar yang otomatis beli sumber terbaik';

  @override
  String get autoBuyLabel => 'Otomatis';

  @override
  String prestigeStarCost(String cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return 'Ketuk untuk menyeduh $n kali';
  }

  @override
  String questBuy(int n) {
    return 'Beli $n peningkatan';
  }

  @override
  String questRepeatEarn(String amount) {
    return 'Dapatkan $amount Koin lagi';
  }

  @override
  String get questClaim => 'Ambil';

  @override
  String get iapDoubleTitle => 'x2 Pendapatan (permanen)';

  @override
  String get iapDoubleDesc => 'Gandakan semua pendapatan pasif, selamanya';

  @override
  String get iapDoubleSnack => 'x2 pendapatan permanen aktif!';

  @override
  String get rewardsTitle => 'Dapat lebih 🎁';

  @override
  String get rewardX2Name => 'x2 pendapatan 24 jam';

  @override
  String rewardX2Active(int hours) {
    return 'Aktif · sisa ${hours}j';
  }

  @override
  String get rewardX2Snack => 'x2 pendapatan 24 jam aktif!';

  @override
  String rewardGemsName(int gems) {
    return 'Dapatkan $gems 💎';
  }

  @override
  String rewardTimeSkip(int hours) {
    return 'Percepat $hours jam';
  }

  @override
  String get watchAd => 'Tonton iklan';

  @override
  String get piggyName => 'Celengan';

  @override
  String get piggyBreak => 'Pecahkan';

  @override
  String piggySnack(String gems) {
    return 'Celengan: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'VIP Pass (30 hari) 👑';

  @override
  String get iapVipDesc =>
      'Tanpa iklan + x2 pendapatan + 50💎/hari + batas offline+';

  @override
  String get iapVipSnack => 'VIP aktif 30 hari! 👑';

  @override
  String get genDuongDen => 'Susu Gula Aren';

  @override
  String get genBrulee => 'Teh Susu Brûlée';

  @override
  String get genCheeseFoam => 'Cheese Foam';

  @override
  String get genTraTraiCay => 'Teh Buah';

  @override
  String get genBobaVang => 'Boba Emas';

  @override
  String get genGalaxy => 'Teh Susu Galaksi';

  @override
  String get genQuantumTea => 'Teh Susu Kuantum';

  @override
  String get genAiTea => 'Teh Susu AI';

  @override
  String get genParallelTea => 'Teh Susu Alam Semesta Paralel';

  @override
  String get genNftTea => 'Teh Susu NFT';

  @override
  String get genTimeTea => 'Teh Susu Lintas Waktu';

  @override
  String get genMultidimTea => 'Teh Susu Multidimensi';

  @override
  String get genBlackholeTea => 'Teh Susu Lubang Hitam';

  @override
  String get genLightTea => 'Teh Susu Kecepatan Cahaya';

  @override
  String get genRobotTea => 'Teh Susu Robot';

  @override
  String get genHologramTea => 'Teh Susu Hologram';

  @override
  String get genLegendTea => 'Teh Susu Legendaris';

  @override
  String get genEternalTea => 'Teh Susu Abadi';

  @override
  String get stage4 => 'Bengkel Brûlée';

  @override
  String get stage5 => 'Pabrik Cheese Foam';

  @override
  String get stage6 => 'Imperium Global';

  @override
  String get stage7 => 'Penawaran Umum Saham';

  @override
  String get stage8 => 'Konglomerat';

  @override
  String get stage9 => 'Dana Investasi Global';

  @override
  String get stage10 => 'Rantai Pasok Pertanian';

  @override
  String get stage11 => 'Imperium Teknologi AI';

  @override
  String get stage12 => 'Legenda Teh Susu';

  @override
  String get stage13 => 'Akademi Teh Susu';

  @override
  String get stage14 => 'Kota Teh Susu';

  @override
  String get stage15 => 'Negara Teh Susu';

  @override
  String get stage16 => 'Aliansi Dunia';

  @override
  String get stage17 => 'Planet Teh Susu';

  @override
  String get stage18 => 'Kebenaran Teh Susu';

  @override
  String get genAcademyTea => 'Teh Susu Akademi';

  @override
  String get genScholarTea => 'Teh Susu Cendekia';

  @override
  String get genCityTea => 'Teh Susu Kota';

  @override
  String get genMetroTea => 'Teh Susu Metropolis';

  @override
  String get genNationTea => 'Teh Susu Nasional';

  @override
  String get genTreatyTea => 'Teh Susu Perjanjian';

  @override
  String get genUnionTea => 'Teh Susu Aliansi';

  @override
  String get genWorldTea => 'Teh Susu Perdamaian Dunia';

  @override
  String get genPlanetTea => 'Teh Susu Planet';

  @override
  String get genTerraformTea => 'Teh Susu Terraforming';

  @override
  String get genTruthTea => 'Teh Susu Kebenaran';

  @override
  String get genUltimateTea => 'Teh Susu Tertinggi';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsSound => 'Suara';

  @override
  String get settingsReset => 'Mulai ulang';

  @override
  String get settingsResetConfirm => 'Hapus semua progres dan mulai dari awal?';

  @override
  String get navHome => 'Beranda';

  @override
  String get navShop => 'Toko';

  @override
  String get navPrestige => 'Prestise';

  @override
  String get navAchievements => 'Prestasi';

  @override
  String get wheelName => 'Roda Keberuntungan 🎡';

  @override
  String get spinFree => 'Putar gratis';

  @override
  String get spinAd => 'Tonton iklan untuk memutar';

  @override
  String storyChapterLabel(int n) {
    return 'Bab $n';
  }

  @override
  String get storyContinue => 'Lanjut';

  @override
  String get storyChoosePrompt => 'Pilih jalanmu — tidak bisa dibatalkan:';

  @override
  String get storyLogTitle => 'Cerita';

  @override
  String get storyLogLocked => 'Belum terbuka';

  @override
  String get rivalEventTitle => 'Pesaing menyerang!';

  @override
  String get rivalEventIgnore => 'Abaikan';

  @override
  String get rivalMeterAhead => 'Unggul';

  @override
  String get rivalMeterEven => 'Seimbang';

  @override
  String get rivalMeterBehind => 'Tertinggal';

  @override
  String get rivalResolvedSnack => 'Ditangani. Pesaing mundur.';

  @override
  String get rivalIgnoredSnack => 'Kamu biarkan saja — pesaing makin unggul.';

  @override
  String get navArena => 'Arena';

  @override
  String get navCompete => 'Kompetisi';

  @override
  String get arenaTitle => 'Arena';

  @override
  String get arenaIntro =>
      'Duel 1v1, 60 detik — siapa dapat Koin terbanyak menang!';

  @override
  String get arenaStartButton => 'Cari lawan';

  @override
  String get arenaModeTap => 'Balap ketuk';

  @override
  String get arenaModeMatch3 => 'Mutiara Jatuh';

  @override
  String get arenaMatch3Intro =>
      'Cocokkan 3 gambar sama selama 60 detik — raih skor lebih tinggi dari lawan untuk menang!';

  @override
  String get arenaMatch3Stuck => 'Tidak ada langkah lagi!';

  @override
  String get arenaQueueWaiting => 'Mencari lawan…';

  @override
  String get arenaCancelButton => 'Batal';

  @override
  String get arenaTapButton => 'Ketuk gelas';

  @override
  String get arenaResolving => 'Menutup pertandingan…';

  @override
  String arenaTierButton(String cost) {
    return 'Tingkatkan ×2 ($cost Koin)';
  }

  @override
  String arenaTimeLeft(int seconds) {
    return 'Sisa ${seconds}s';
  }

  @override
  String arenaOnlineCount(int count) {
    return '$count pemain online';
  }

  @override
  String get arenaYourScore => 'Skor kamu';

  @override
  String get arenaOpponentScore => 'Lawan';

  @override
  String get arenaResultWin => 'Kamu menang! 🎉';

  @override
  String get arenaResultLose => 'Kamu kalah';

  @override
  String get arenaResultDraw => 'Seri';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => 'Tutup';

  @override
  String get cloudSaveMenuTitle => 'Cadangkan progres';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'Terhubung: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'Belum terhubung — progres bisa hilang jika uninstall';

  @override
  String get cloudSaveTitle => 'Cadangkan progres';

  @override
  String get cloudSaveIntro =>
      'Hubungkan email untuk memulihkan progres jika uninstall atau ganti perangkat.';

  @override
  String get cloudSaveEmailHint => 'Email kamu';

  @override
  String get cloudSaveSendCode => 'Kirim kode';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'Kode konfirmasi terkirim ke $email';
  }

  @override
  String get cloudSaveCodeHint => 'Kode konfirmasi';

  @override
  String get cloudSaveVerify => 'Verifikasi';

  @override
  String get cloudSaveChangeEmail => 'Pakai email lain';

  @override
  String get cloudSaveResend => 'Kirim ulang kode';

  @override
  String cloudSaveResendIn(int seconds) {
    return 'Kirim ulang kode (${seconds}d)';
  }

  @override
  String get cloudSaveConflictTitle => 'Ditemukan save lain di cloud';

  @override
  String cloudSaveConflictLocal(String amount) {
    return 'Perangkat ini: $amount Koin seumur hidup';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return 'Di cloud: $amount Koin seumur hidup';
  }

  @override
  String get cloudSaveRestoreButton => 'Pulihkan dari cloud';

  @override
  String get cloudSaveKeepLocalButton => 'Pakai perangkat ini';

  @override
  String cloudSaveLinkedStatus(String email) {
    return 'Terhubung: $email';
  }

  @override
  String get cloudSaveDisconnect => 'Putuskan';

  @override
  String get cloudSaveRetry => 'Coba lagi';

  @override
  String get leaderboardMenuTitle => 'Papan Peringkat';

  @override
  String get leaderboardTitle => 'Papan Peringkat';

  @override
  String get leaderboardNicknameIntro =>
      'Pilih nama tampilan untuk papan peringkat (bisa diganti nanti):';

  @override
  String get leaderboardNicknameHint => 'Nama kamu';

  @override
  String get leaderboardSubmit => 'Konfirmasi';

  @override
  String leaderboardYourRank(int rank) {
    return 'Peringkat kamu: #$rank';
  }

  @override
  String leaderboardStars(String stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty =>
      'Belum ada siapa-siapa di papan peringkat — itu kamu!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 Anda berada di peringkat atas! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return 'Top 1: $top1💎 · Top 2-3: $top23💎 · Top 4-10: $top410💎 — tiap 24 jam selama masih peringkat';
  }

  @override
  String get leaderboardChangeName => 'Ganti nama';

  @override
  String get leaderboardRetry => 'Coba lagi';

  @override
  String get storySpeedrunMenuTitle => 'Speedrun';

  @override
  String get storySpeedrunTitle => 'Papan Peringkat Speedrun';

  @override
  String get storySpeedrunNotCompletedYet =>
      'Anda belum menyelesaikan cerita — selesaikan Bab 18 untuk masuk peringkat.';

  @override
  String get storySpeedrunTabMain => 'Babak 1';

  @override
  String get storySpeedrunTabExt => 'Babak 2';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      'Kamu belum menyelesaikan Babak 2 — selesaikan Bab 28 untuk masuk peringkat.';

  @override
  String get storySpeedrunEmpty =>
      'Belum ada yang menyelesaikan cerita — jadilah yang pertama!';

  @override
  String get arenaLeaderboardMenuTitle => 'Papan Peringkat PK';

  @override
  String get arenaLeaderboardTitle => 'Papan Peringkat PK';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      'Kamu belum bertanding di Arena — menangkan satu pertandingan untuk muncul di sini.';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '${wins}M - ${losses}K';
  }

  @override
  String get ascensionTitle => 'Ascension';

  @override
  String get ascensionOpen => 'Ascension ⏳';

  @override
  String get ascensionIntro =>
      'Tukar semua Bintang dan perk Toko Bintang dengan ⏳ Poin Ascension — perk permanen yang lebih kuat. Kamu mulai dari awal.';

  @override
  String ascensionProgress(int percent) {
    return 'Progres untuk membuka: $percent%';
  }

  @override
  String get ascensionPointsNow => 'Poin dimiliki';

  @override
  String get ascensionPointsGain => 'Didapat jika ascend';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ Reset Bintang, semua perk Toko Bintang, Koin, level upgrade, dan tahap. Menyimpan 💎, pencapaian, dan cerita. Bintang di papan peringkat jadi 0 (peringkat total pendapatan tidak berubah).';

  @override
  String ascensionConfirm(int points) {
    return 'Ascend (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => 'Belum tersedia';

  @override
  String ascensionSuccess(int points) {
    return 'Era baru dimulai! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => 'Perk Ascension ⏳';

  @override
  String ascensionShopSpendable(int points) {
    return '$points ⏳ untuk dibelanjakan';
  }

  @override
  String ascensionCost(int cost) {
    return '$cost ⏳';
  }

  @override
  String get ascensionMaxed => 'Maks';

  @override
  String get ascensionIncomeName => 'Sumber energi';

  @override
  String ascensionIncomeDesc(int percent) {
    return '+$percent% pendapatan per level';
  }

  @override
  String get ascensionStarBonusName => 'Bintang gemilang';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '+$percent% kekuatan per Bintang, per level';
  }

  @override
  String get ascensionStarGainName => 'Bintang melimpah';

  @override
  String ascensionStarGainDesc(int percent) {
    return '+$percent% kecepatan dapat Bintang, per level';
  }

  @override
  String get achAscend => 'Ascend untuk pertama kali';

  @override
  String get dailyQuestsTitle => 'Misi harian';

  @override
  String get dailyQuestsChip => 'Misi';

  @override
  String get dailyQuestsBonusLabel => 'Selesaikan ketiga misi';

  @override
  String dailyQuestsResetsIn(Object time) {
    return 'Misi baru dalam $time';
  }

  @override
  String get dailyQuestClaimed => 'Diambil';

  @override
  String dqTap(int n) {
    return 'Ketuk gelas $n kali';
  }

  @override
  String dqBuy(int n) {
    return 'Beli $n upgrade';
  }

  @override
  String dqEarn(Object amount) {
    return 'Dapatkan $amount Koin';
  }

  @override
  String get dqCat => 'Tangkap Kucing Emas';

  @override
  String get dqVip => 'Layani pelanggan VIP';

  @override
  String get dqSpin => 'Putar Roda Keberuntungan';

  @override
  String get notifyOfflineFullTitle => 'Kas Koin sudah penuh! 🧋';

  @override
  String get notifyOfflineFullBody =>
      'Kedai berhenti mengumpulkan Koin — ambil sekarang dan mulai giliran baru.';

  @override
  String get notifyDailyTitle => 'Hari baru, misi baru 📋';

  @override
  String get notifyDailyBody =>
      'Hadiah harian, 1 putaran gratis, dan 3 misi sedang menunggu.';

  @override
  String get notifyD3Title => 'Kedaimu merindukanmu 🧋';

  @override
  String get notifyD3Body =>
      'Sudah 3 hari — kas Koin sudah penuh sejak lama, ayo ambil.';

  @override
  String get notifyD7Title => 'Sudah seminggu! 🧋';

  @override
  String get notifyD7Body =>
      'Ascension, Mutiara Jatuh, dan banyak hal baru menantimu.';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 Event: ×$mult pendapatan! Sisa $timeLeft';
  }

  @override
  String get navMatch3 => 'Mutiara';

  @override
  String get m3Title => 'Mutiara Jatuh';

  @override
  String m3Level(int n) {
    return 'Level $n';
  }

  @override
  String get m3Locked => 'Terkunci';

  @override
  String m3MovesLeft(int n) {
    return 'Sisa $n langkah';
  }

  @override
  String get m3Score => 'Skor';

  @override
  String get m3Win => 'Level selesai!';

  @override
  String get m3Lose => 'Target belum tercapai';

  @override
  String get m3Retry => 'Ulangi';

  @override
  String get m3Next => 'Level berikutnya';

  @override
  String get m3Back => 'Daftar level';

  @override
  String get m3Reward => 'Hadiah';

  @override
  String get m3NoReward => 'Hadiah level ini sudah diambil';

  @override
  String m3AdMoves(int n) {
    return 'Tonton iklan: +$n langkah';
  }

  @override
  String get m3KeepPlaying => 'Lanjut main';

  @override
  String get m3Pause => 'Istirahat';

  @override
  String get m3GoalReached => 'Target tercapai!';

  @override
  String m3NeedScore(String n, int star) {
    return 'Kurang $n poin lagi untuk $star★';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return 'Kurang $n $icon lagi untuk $star★';
  }

  @override
  String get m3HowToTitle => 'Cara main Mutiara Jatuh';

  @override
  String get m3HtpSwap =>
      '🔄 Tukar dua kotak BERSEBELAHAN (ketuk satu lalu yang lain, atau geser) untuk membuat barisan 3 kotak sejenis atau lebih. Tukaran yang tidak membentuk barisan tidak dihitung.';

  @override
  String get m3HtpGoal =>
      '🎯 Tiap level punya satu target: mencapai skor, atau mengumpulkan kotak jenis tertentu. Target tampil di bilah atas.';

  @override
  String get m3HtpMoves =>
      '👣 Langkah terbatas. Kalau habis, level berakhir — utamakan langkah yang menghapus banyak kotak.';

  @override
  String get m3HtpChain =>
      '⛓️ Kotak yang hilang membuat kotak di atasnya jatuh; kalau membentuk barisan baru terjadi rantai, dan langkah berikutnya bernilai jauh lebih besar.';

  @override
  String get m3HtpSpecial =>
      '💥 Susun 4 untuk membuat BOM SILANG (menghapus satu baris dan satu kolom). Susun 5 atau lebih untuk BOM WARNA 🌈 (menghapus semua kotak sejenis). Cocokkan seperti kotak biasa untuk meledakkannya.';

  @override
  String get m3HtpStars =>
      '⭐ Tiga bintang di bilah adalah tiga tingkat. Tingkat pertama berarti lolos; tekan \"Lanjut main\" untuk memakai sisa langkah mengejar bintang berikutnya.';

  @override
  String get m3HtpReward =>
      '🎁 Hadiah hanya diberikan saat PERTAMA kali mencapai tiap bintang. Mengulang level tidak menambah hadiah.';

  @override
  String get m3LbTitle => 'Peringkat Mutiara Jatuh';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty =>
      'Belum ada siapa pun. Selesaikan beberapa level dan kamu jadi nomor satu!';

  @override
  String get m3LbNoStars =>
      'Kamu belum punya bintang — selesaikan satu level untuk masuk papan.';

  @override
  String m3LbLevels(int n) {
    return '$n level';
  }

  @override
  String get m3LbError => 'Tidak bisa memuat peringkat. Coba lagi nanti.';
}
