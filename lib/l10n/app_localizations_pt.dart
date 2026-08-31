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
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
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
  String get buyModeMax => 'MAX';

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
  String get gemInstantStageName => 'Desbloqueio de fase instantâneo';

  @override
  String gemInstantStageDesc(String stage) {
    return 'Desbloqueie $stage já, sem custo de Moedas';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return '$stage desbloqueada!';
  }

  @override
  String get gemTimeSkipName => 'Avançar 💎';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Receba ${hours}h de produção na hora';
  }

  @override
  String get iapSectionTitle => 'Comprar com dinheiro real';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get close => 'Fechar';

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
      '⚠️ Reinicia Moedas, níveis de melhoria e fase (bônus de Estrelas podem manter parte).';

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

  @override
  String get howToPlayTitle => 'Como jogar';

  @override
  String get htpTap => '🧋 Toque no copo para preparar chá e ganhar Moedas.';

  @override
  String get htpBuy =>
      '🛒 Compre melhorias para ter renda automática a cada segundo.';

  @override
  String get htpStage =>
      '🏪 Junte Moedas para desbloquear novas fases com bebidas melhores.';

  @override
  String get htpCat =>
      '🐱 Toque no gato da sorte para uma Chuva de Ouro ×3 rápida.';

  @override
  String get htpVip => '🚗 Atenda o cliente VIP para ganhar Gemas 💎.';

  @override
  String get htpGems => '💎 Gaste Gemas na Loja em melhorias permanentes.';

  @override
  String get htpPrestige =>
      '⭐ Franquie para recomeçar e ganhar Estrelas — bônus de renda permanente.';

  @override
  String get htpOffline =>
      '😴 A loja continua vendendo enquanto você está fora — volte para pegar o dinheiro offline.';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get dailyTitle => 'Check-in diário';

  @override
  String get dailyPrompt => 'Resgate o presente de hoje!';

  @override
  String get dailyClaim => 'Resgatar';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Sequência de $days dias 🔥';
  }

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String achEarn(String amount) {
    return 'Ganhe $amount Moedas no total';
  }

  @override
  String achStage(int n) {
    return 'Alcance o estágio $n';
  }

  @override
  String achLevels(int n) {
    return 'Tenha $n níveis de melhoria no total';
  }

  @override
  String achPrestige(int n) {
    return 'Franquia ($n★ ou mais)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 Conquista desbloqueada! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => 'Loja de Estrelas ⭐';

  @override
  String prestigeShopSpendable(int stars) {
    return '$stars ⭐ para gastar';
  }

  @override
  String get prestigeIncomeName => 'Megarrenda';

  @override
  String prestigeIncomeDesc(int percent) {
    return '+$percent% de renda permanente por nível';
  }

  @override
  String get prestigeTapName => 'Megatoque';

  @override
  String prestigeTapDesc(int percent) {
    return '+$percent% de valor de toque por nível';
  }

  @override
  String get prestigeOfflineName => 'Super offline';

  @override
  String prestigeOfflineDesc(int percent) {
    return '+$percent% de ganhos ausente por nível';
  }

  @override
  String get prestigeStartCashName => 'Capital inicial';

  @override
  String get prestigeStartCashDesc =>
      'Receba Moedas logo após Franquear (mais por nível)';

  @override
  String get prestigeKeepStageName => 'Manter fase';

  @override
  String get prestigeKeepStageDesc => 'Mantém +1 fase após Franquear por nível';

  @override
  String get prestigeDiscountName => 'Compra no atacado';

  @override
  String prestigeDiscountDesc(int percent) {
    return '-$percent% de custo de melhoria por nível';
  }

  @override
  String get prestigeAutoBuyName => 'Compra automática';

  @override
  String get prestigeAutoBuyDesc =>
      'Desbloqueia um botão que compra a melhor fonte';

  @override
  String get autoBuyLabel => 'Auto';

  @override
  String prestigeStarCost(int cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return 'Toque para preparar $n vezes';
  }

  @override
  String questBuy(int n) {
    return 'Compre $n melhorias';
  }

  @override
  String questRepeatEarn(String amount) {
    return 'Ganhe mais $amount Moedas';
  }

  @override
  String get questClaim => 'Resgatar';

  @override
  String get iapDoubleTitle => 'x2 Renda (permanente)';

  @override
  String get iapDoubleDesc => 'Dobre toda a renda passiva, para sempre';

  @override
  String get iapDoubleSnack => 'x2 renda permanente ativado!';

  @override
  String get rewardsTitle => 'Ganhe mais 🎁';

  @override
  String get rewardX2Name => 'x2 renda por 24h';

  @override
  String rewardX2Active(int hours) {
    return 'Ativo · restam ${hours}h';
  }

  @override
  String get rewardX2Snack => 'x2 renda por 24h ativado!';

  @override
  String rewardGemsName(int gems) {
    return 'Ganhe $gems 💎';
  }

  @override
  String rewardTimeSkip(int hours) {
    return 'Avançar ${hours}h';
  }

  @override
  String get watchAd => 'Ver anúncio';

  @override
  String get piggyName => 'Cofrinho';

  @override
  String get piggyBreak => 'Quebrar';

  @override
  String piggySnack(String gems) {
    return 'Cofrinho: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'Passe VIP (30 dias) 👑';

  @override
  String get iapVipDesc =>
      'Sem anúncios + x2 renda + 50💎/dia + limite offline+';

  @override
  String get iapVipSnack => 'VIP ativado por 30 dias! 👑';

  @override
  String get genDuongDen => 'Leite com Açúcar Mascavo';

  @override
  String get genBrulee => 'Chá com Leite Brûlée';

  @override
  String get genCheeseFoam => 'Espuma de Queijo';

  @override
  String get genTraTraiCay => 'Chá de Frutas';

  @override
  String get genBobaVang => 'Boba Dourada';

  @override
  String get genGalaxy => 'Chá com Leite Galáxia';

  @override
  String get stage4 => 'Oficina Brûlée';

  @override
  String get stage5 => 'Fábrica de Espuma de Queijo';

  @override
  String get stage6 => 'Império Global';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSound => 'Som';

  @override
  String get settingsReset => 'Recomeçar';

  @override
  String get settingsResetConfirm => 'Apagar todo o progresso e recomeçar?';

  @override
  String get navHome => 'Início';

  @override
  String get navShop => 'Loja';

  @override
  String get navPrestige => 'Prestígio';

  @override
  String get navAchievements => 'Prêmios';

  @override
  String get wheelName => 'Roleta da Sorte 🎡';

  @override
  String get spinFree => 'Giro grátis';

  @override
  String get spinAd => 'Ver anúncio para girar';

  @override
  String storyChapterLabel(int n) {
    return 'Capítulo $n';
  }

  @override
  String get storyContinue => 'Continuar';

  @override
  String get storyChoosePrompt => 'Escolha seu caminho — não dá para desfazer:';

  @override
  String get storyLogTitle => 'História';

  @override
  String get storyLogLocked => 'Ainda não desbloqueado';

  @override
  String get rivalEventTitle => 'O rival ataca!';

  @override
  String get rivalEventIgnore => 'Ignorar';

  @override
  String get rivalMeterAhead => 'À frente';

  @override
  String get rivalMeterEven => 'Empatados';

  @override
  String get rivalMeterBehind => 'Perdendo terreno';

  @override
  String get rivalResolvedSnack => 'Resolvido. O rival recua.';

  @override
  String get rivalIgnoredSnack => 'Você deixa passar — o rival ganha terreno.';
}
