// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Boba Empire';

  @override
  String get tapBrew => 'Toque para preparar';

  @override
  String get coinsSuffix => ' Moedas';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / seg';
  }

  @override
  String get instantCashButton => 'Dinheiro instantâneo';

  @override
  String instantCashSnack(String amount) {
    return 'Dinheiro instantâneo! +$amount Moedas';
  }

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Desbloquear $cost Moedas';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount Moedas/seg por nível';
  }

  @override
  String buyButton(String cost) {
    return '$cost Moedas';
  }

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · ${seconds}s';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'Cliente VIP! +$cash Moedas, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'Recebido +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'Anúncios removidos. Obrigado!';

  @override
  String iapStarterSnack(String amount) {
    return 'Pacote inicial: +$amount 💎';
  }

  @override
  String get genTraDen => 'Chá Preto';

  @override
  String get genTranChau => 'Pérolas de Tapioca';

  @override
  String get genThach => 'Geleia de Ervas';

  @override
  String get genPudding => 'Pudim';

  @override
  String get genKemNuong => 'Chá com Leite Crème Brûlée';

  @override
  String get genMatcha => 'Balde de Matchá';

  @override
  String get stage1 => 'Carrinho de Rua';

  @override
  String get stage2 => 'Quiosque Pequeno';

  @override
  String get stage3 => 'Rede de Cafés de Luxo';

  @override
  String gemShopTitle(String gems) {
    return 'Loja 💎 (você tem $gems)';
  }

  @override
  String get gemBoostName => 'Aumento de renda';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% de renda permanente por nível';
  }

  @override
  String get offlineCapName => 'Refrigerador offline';

  @override
  String offlineCapDesc(int hours) {
    return '+${hours}h de limite offline por nível';
  }

  @override
  String gemItemLevel(String name, int level) {
    return '$name  Nv.$level';
  }

  @override
  String gemCost(int cost) {
    return '$cost 💎';
  }

  @override
  String get iapSectionTitle => 'Comprar com dinheiro real';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get close => 'Fechar';

  @override
  String get iapGemsTitle => 'Bolsa de Gemas';

  @override
  String get iapGemsDesc => 'Recarregue Gemas para comprar itens na Loja.';

  @override
  String get iapRemoveAdsTitle => 'Remover anúncios';

  @override
  String get iapRemoveAdsDesc =>
      'Pule todos os anúncios — você ainda recebe todas as recompensas, sem precisar assistir.';

  @override
  String get iapStarterTitle => 'Pacote inicial';

  @override
  String get iapStarterDesc =>
      'Única vez: receba uma grande bolsa de Gemas na hora.';

  @override
  String get prestigeTitle => 'Franquia 🏪';

  @override
  String prestigeIntro(int percent) {
    return 'Cada ⭐ Estrela dá +$percent% de renda permanente.';
  }

  @override
  String get prestigeStarsNow => 'Estrelas atuais';

  @override
  String prestigeStarsValue(int stars, int percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Franquear agora';

  @override
  String prestigeGain(int stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Bônus total depois';

  @override
  String prestigeTotalValue(int percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Isso redefine todas as suas Moedas e níveis de melhoria atuais.';

  @override
  String get cancel => 'Cancelar';

  @override
  String prestigeConfirm(int stars) {
    return 'Franquear (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Insuficiente';

  @override
  String prestigeSuccess(int stars) {
    return 'Franquia bem-sucedida! +$stars ⭐';
  }

  @override
  String get offlineTitle => 'Bem-vindo de volta! 🧋';

  @override
  String offlineBody(String amount) {
    return 'A loja continuou vendendo enquanto você estava fora.\nVocê ganhou $amount Moedas.';
  }

  @override
  String get offlineClaim => 'Receber';

  @override
  String get offlineDoubleButton => 'Ver anúncio ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return 'Dobrado! +$amount Moedas';
  }
}
