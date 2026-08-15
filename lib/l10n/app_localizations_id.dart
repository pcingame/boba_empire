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
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Buka $cost Koin';
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
  String prestigeIntro(int percent) {
    return 'Setiap ⭐ Bintang memberi +$percent% pendapatan permanen.';
  }

  @override
  String get prestigeStarsNow => 'Bintang saat ini';

  @override
  String prestigeStarsValue(int stars, int percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Waralabakan sekarang';

  @override
  String prestigeGain(int stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Total bonus setelahnya';

  @override
  String prestigeTotalValue(int percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Ini mereset semua Koin dan level peningkatan kamu saat ini.';

  @override
  String get cancel => 'Batal';

  @override
  String prestigeConfirm(int stars) {
    return 'Waralabakan (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Tidak cukup';

  @override
  String prestigeSuccess(int stars) {
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
  String prestigeShopSpendable(int stars) {
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
  String prestigeStarCost(int cost) {
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
}
