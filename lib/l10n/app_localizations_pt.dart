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
  String get adNotReadySnack =>
      'Anúncio ainda não está pronto, tente novamente em instantes';

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
  String get gemTimeSkipName => 'Avançar';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Receba ${hours}h de produção na hora';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return 'Restam $remaining/$max hoje';
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
  String prestigeIntro(String percent) {
    return 'Cada ⭐ Estrela dá +$percent% de renda permanente.';
  }

  @override
  String get prestigeStarsNow => 'Estrelas atuais';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Franquear agora';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Bônus total depois';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Reinicia Moedas, níveis de melhoria e fase (bônus de Estrelas podem manter parte).';

  @override
  String get cancel => 'Cancelar';

  @override
  String prestigeConfirm(String stars) {
    return 'Franquear (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Insuficiente';

  @override
  String get prestigeAdConfirm => 'Assistir anúncio: moedas iniciais extras';

  @override
  String prestigeSuccess(String stars) {
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
  String get htpTap => 'Toque no copo para preparar chá e ganhar Moedas.';

  @override
  String get htpBuy =>
      'Compre melhorias para ter renda automática a cada segundo.';

  @override
  String get htpStage =>
      'Junte Moedas para desbloquear novas fases com bebidas melhores.';

  @override
  String get htpCat =>
      'Toque no gato da sorte para uma Chuva de Ouro ×3 rápida.';

  @override
  String get htpVip => 'Atenda o cliente VIP para ganhar Gemas 💎.';

  @override
  String get htpGems => 'Gaste Gemas na Loja em melhorias permanentes.';

  @override
  String get htpPrestige =>
      'Franquie para recomeçar e ganhar Estrelas — bônus de renda permanente.';

  @override
  String get htpOffline =>
      'A loja continua vendendo enquanto você está fora — volte para pegar o dinheiro offline.';

  @override
  String get htpNumberFormat =>
      'Números grandes usam sufixos: K=mil, M=milhão, B=bilhão, T=trilhão, depois aa, bb, cc... — cada nível é 1.000× o anterior.';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get dailyTitle => 'Check-in diário';

  @override
  String get dailyPrompt => 'Resgate o presente de hoje!';

  @override
  String get adNotReady =>
      'O anúncio ainda não está pronto, tente novamente em alguns segundos.';

  @override
  String get accessoryBat => 'Morcego noturno';

  @override
  String get accessoryJackOLantern => 'Abóbora de Halloween';

  @override
  String get accessoryGhost => 'Fantasminha';

  @override
  String get accessoryWitch => 'Bruxinha';

  @override
  String get accessorySnowman => 'Boneco de neve';

  @override
  String get accessoryChristmasTree => 'Árvore de Natal';

  @override
  String get accessoryReindeer => 'Rena';

  @override
  String get accessorySanta => 'Papai Noel';

  @override
  String get accessoryFirecracker => 'Rojão';

  @override
  String get accessoryRedEnvelope => 'Envelope vermelho';

  @override
  String get accessoryApricotBlossom => 'Flor de damasco';

  @override
  String get accessoryGoldenGoat => 'Cabra dourada';

  @override
  String get festivalHalloween => 'Halloween';

  @override
  String get festivalChristmas => 'Natal';

  @override
  String get festivalTet => 'Ano Novo Lunar';

  @override
  String get festivalSection => 'Acessórios de festivais (exclusivos)';

  @override
  String festivalPackTitle(String name) {
    return 'Pacote de $name';
  }

  @override
  String festivalPackDesc(int gems) {
    return 'Cada pacote dá 1 item exclusivo que você ainda não tem, vendido só durante o festival. Se já tiver todos, recebe $gems 💎. Não negociável.';
  }

  @override
  String get accessoryChampagne => 'Brinde de champanhe';

  @override
  String get accessoryPartyPopper => 'Estalinho de festa';

  @override
  String get accessoryFireworks => 'Fogos de artifício';

  @override
  String get accessoryGoldenSparkler => 'Estrelinha dourada';

  @override
  String get accessoryLoveLetter => 'Carta de amor';

  @override
  String get accessoryRose => 'Rosa vermelha';

  @override
  String get accessoryChocolate => 'Chocolate';

  @override
  String get accessoryCupidArrow => 'Flecha do Cupido';

  @override
  String get accessoryTulip => 'Tulipa';

  @override
  String get accessoryBouquet => 'Buquê';

  @override
  String get accessoryLipstick => 'Batom';

  @override
  String get accessoryPrincess => 'Princesa';

  @override
  String get accessoryMooncake => 'Bolo lunar';

  @override
  String get accessoryRabbit => 'Coelho da lua';

  @override
  String get accessoryFullMoon => 'Lua cheia';

  @override
  String get accessoryLionDance => 'Dança do leão';

  @override
  String get festivalNewYear => 'Ano Novo';

  @override
  String get festivalValentine => 'Dia dos Namorados';

  @override
  String get festivalWomensDay => 'Dia da Mulher';

  @override
  String get festivalMidAutumn => 'Festival da Lua';

  @override
  String get dailyClaim => 'Resgatar';

  @override
  String get accessoryWheelTitle => 'Roleta de acessórios';

  @override
  String accessoryWheelAd(int n) {
    return 'Girar: ver anúncio ($n restantes)';
  }

  @override
  String accessoryWheelGems(int gems) {
    return 'Girar $gems 💎';
  }

  @override
  String get accessoryPackButton => 'Pacotes de acessórios';

  @override
  String get accessoryPackTitle => 'Pacotes de acessórios';

  @override
  String get accessoryPackBasic => 'Pacote Básico';

  @override
  String get accessoryPackRare => 'Pacote Raro (Raro ou melhor)';

  @override
  String get accessoryPackEpic => 'Pacote Épico (Épico ou melhor)';

  @override
  String get accessoryPackSeason =>
      'Evento sazonal: 25% de desconto e chance Épico/Lendário ×2!';

  @override
  String get accessoryAdDropButton => 'Assistir anúncio: +1 acessório';

  @override
  String dailyStreakAtRisk(int days) {
    return 'Você perdeu um dia: sua sequência de $days dias está prestes a acabar!';
  }

  @override
  String dailyRestoreGems(int gems) {
    return 'Salvar sequência ($gems 💎)';
  }

  @override
  String get dailyRestoreAd => 'Assistir a um anúncio para salvar a sequência';

  @override
  String get dailySkipRestore => 'Pular e recomeçar';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Sequência de $days dias 🔥';
  }

  @override
  String dailyMilestoneBonus(String gems) {
    return 'Bônus de marco da sequência: +$gems 💎';
  }

  @override
  String dailyVipBonus(int percent) {
    return 'Bônus VIP: +$percent% 💎';
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
  String prestigeShopSpendable(String stars) {
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
  String prestigeStarCost(String cost) {
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
  String get iapColdStorageTitle => 'Câmara fria (permanente)';

  @override
  String iapColdStorageDesc(Object hours) {
    return 'Soma $hours horas ao limite de ganhos offline, para sempre';
  }

  @override
  String iapColdStorageSnack(Object hours) {
    return 'Limite offline aumentado em $hours horas!';
  }

  @override
  String get iapComboTitle => 'Combo: Sem anúncios + x2 renda';

  @override
  String get iapComboDesc =>
      'Remove todos os anúncios e dobra a renda passiva para sempre, mais barato que comprar separado';

  @override
  String get iapComboSnack =>
      'Anúncios removidos e x2 de renda permanente ativado!';

  @override
  String get topupTitle => 'Recompensas de recarga e VIP';

  @override
  String get topupOpen => '👑 Recarga e VIP';

  @override
  String topupSummary(Object points) {
    return '$points EXP VIP';
  }

  @override
  String topupBuff(Object now, Object percent) {
    return 'Cada nível VIP: +$percent% de renda (agora +$now%)';
  }

  @override
  String get topupNote =>
      'Compras na loja: ~100 EXP por USD (pacotes grandes dão mais). Comprar EXP com 💎 custa bem mais e tem limite. Cada recompensa é resgatada uma vez.';

  @override
  String topupTier(Object points) {
    return '$points EXP';
  }

  @override
  String get topupAccessory => '+ acessório';

  @override
  String get topupClaim => 'Resgatar';

  @override
  String get topupClaimed => 'Resgatado';

  @override
  String topupClaimSnack(Object gems) {
    return 'Resgatado +$gems 💎';
  }

  @override
  String get vipName1 => 'Cliente fiel';

  @override
  String get vipName2 => 'Amante de chá';

  @override
  String get vipName3 => 'Conhecedor de chá';

  @override
  String get vipName4 => 'Convidado de honra';

  @override
  String get vipName5 => 'Dono da loja';

  @override
  String get vipName6 => 'Bilionário do boba';

  @override
  String get vipName7 => 'Magnata';

  @override
  String get vipName8 => 'Realeza';

  @override
  String get vipName9 => 'Lenda';

  @override
  String get vipName10 => 'Imperador do boba';

  @override
  String vipBuyExp(Object exp, Object gems) {
    return 'Comprar $exp EXP · $gems 💎';
  }

  @override
  String vipBuyExpSnack(Object exp) {
    return '+$exp EXP VIP';
  }

  @override
  String vipBuyExpCapped(Object cap) {
    return 'A EXP comprada com 💎 atingiu o limite ($cap). Níveis mais altos exigem recargas reais.';
  }

  @override
  String get vipBenefitsTitle => 'Benefícios VIP';

  @override
  String get vipBenefitsLocked =>
      'Chegue ao VIP 1 para liberar presentes diários/semanais/mensais.';

  @override
  String get vipDaily => 'Diário';

  @override
  String get vipWeekly => 'Semanal';

  @override
  String get vipMonthly => 'Mensal';

  @override
  String get vipHowToTitle => 'Guia VIP';

  @override
  String get vipHtp1 =>
      '👑 O VIP tem 10 níveis, cada um com um título. Seu nível aparece como etiqueta \"VIP n\" ao lado do seu nome nos rankings e na sua Guilda. A partir do VIP 5, seu nome ganha uma linha de título em todos os rankings, um ponto verde enquanto estiver online e todos veem um banner quando você entra.';

  @override
  String vipHtp2(Object cap, Object exp, Object gems) {
    return '⭐ EXP VIP: compras com dinheiro real na loja (~100 EXP por USD, pacotes grandes de 💎 dão extra) ou compre com 💎 ($gems 💎 → $exp EXP, até $cap EXP — por isso VIP 7–10 exigem recargas reais).';
  }

  @override
  String vipHtp3(Object percent) {
    return '📈 Vantagens: +$percent% de renda passiva por nível (permanente) e uma recompensa única por nível (💎, e um acessório em alguns).';
  }

  @override
  String get vipHtp4 =>
      '🎁 Presentes diários / semanais / mensais: os 💎 crescem com o nível; os semanais e mensais incluem um acessório. Reiniciam às 00:00 UTC (semanas começam na segunda, meses pelo calendário).';

  @override
  String get vipHtp5 =>
      '♻️ Não é o Passe VIP de 30 dias: o Passe VIP (sem anúncios, x2 de renda…) é temporário; este nível VIP nunca expira e os dois se somam.';

  @override
  String get vipHtp6 => '📍 Abra em Loja 💎 → botão 👑.';

  @override
  String get vipLbTitle => 'Ranking VIP';

  @override
  String get vipLbEmpty => 'Ninguém no ranking VIP ainda.';

  @override
  String get vipLbNoVip => 'Chegue ao VIP 1 para entrar no ranking VIP.';

  @override
  String vipLbExp(Object exp) {
    return '$exp EXP';
  }

  @override
  String vipOnlineBanner(Object nickname, Object title) {
    return '👑 $title $nickname acabou de ficar online!';
  }

  @override
  String get emailGateTitle => 'Vincule seu e-mail para recarregar';

  @override
  String get emailGateBody =>
      'As compras ficam ligadas à sua conta para poderem ser recuperadas se você trocar de celular ou algo der errado. Vincule um e-mail primeiro (grátis, leva um minuto).';

  @override
  String get emailGateOnlineTitle => 'Vincule seu e-mail para jogar online';

  @override
  String get emailGateOnlineBody =>
      'Guildas, Mercado, Arena e rankings exigem uma conta vinculada a um e-mail, para seus dados ficarem seguros e poderem ser restaurados se você trocar de celular ou reinstalar. É grátis e leva cerca de um minuto.';

  @override
  String get emailGateLink => 'Vincular e-mail';

  @override
  String iapGemsFirstSnack(Object amount) {
    return 'Recebeu +$amount 💎 — bônus dobrado da primeira compra!';
  }

  @override
  String get iapFirstBuyNote => '🎉 Primeira compra: 💎 em dobro!';

  @override
  String get guildGiftTooltip => 'Presentear 💎';

  @override
  String guildGiftTitle(Object nickname) {
    return 'Presentear $nickname com 💎';
  }

  @override
  String guildGiftHint(Object cap, Object days) {
    return 'Até $cap 💎 por dia. O destinatário tem $days dias para resgatar.';
  }

  @override
  String guildGiftSent(Object amount, Object nickname) {
    return 'Enviou $amount 💎 para $nickname';
  }

  @override
  String guildGiftInboxTitle(Object count) {
    return '🎁 Presentes da guilda ($count)';
  }

  @override
  String guildGiftFrom(Object amount, Object nickname) {
    return '$nickname · +$amount 💎';
  }

  @override
  String guildGiftClaimed(Object amount) {
    return 'Resgatou +$amount 💎';
  }

  @override
  String guildErrGiftLimit(Object receive, Object send) {
    return 'Limite de presentes de hoje atingido (você envia até $send 💎/dia; uma pessoa recebe até $receive 💎/dia).';
  }

  @override
  String get vipTitlePick => 'Título abaixo do seu nome';

  @override
  String get vipTitleAuto => 'Auto (o mais alto)';

  @override
  String get vipTitleHide => 'Ocultar';

  @override
  String get marketFilterWish => 'Desejos';

  @override
  String get guildErrGemsSpend => '💎 insuficientes.';

  @override
  String guildCreateVipDiscount(Object percent) {
    return 'Vantagem VIP: $percent% de desconto na criação de guilda';
  }

  @override
  String get guildLbTabVip => 'VIP';

  @override
  String get guildLbVipEmpty =>
      'Nenhuma guilda tem membros VIP no ranking ainda.';

  @override
  String get guildLbVipNote =>
      'EXP VIP total dos membros (só contam quem definiu apelido).';

  @override
  String guildVipExpTotal(Object exp) {
    return '$exp EXP';
  }

  @override
  String guildVipBonusLine(Object members, Object pct) {
    return 'Bônus VIP: $members membros VIP → +$pct% de renda para toda a guilda';
  }

  @override
  String guildVipBonusHint(Object cap, Object level, Object per) {
    return 'Cada membro VIP $level+ soma +$per% de renda para toda a guilda (máx. +$cap%)';
  }

  @override
  String get reminderVipTitle => '👑 Seu presente VIP está esperando';

  @override
  String get reminderVipDailyBody =>
      'Seu presente VIP diário, o check-in e as missões estão prontos — venha resgatar!';

  @override
  String get reminderVipWeeklyBody =>
      'Seu presente VIP semanal (com um acessório) está pronto!';

  @override
  String get reminderVipMonthlyBody =>
      'Seu presente VIP mensal chegou — um grande te espera!';

  @override
  String get reminderVipUnclaimedBody =>
      'Você ainda tem presentes VIP para resgatar hoje.';

  @override
  String get dealTitle => 'Oferta de hoje';

  @override
  String dealResets(Object time) {
    return 'Muda às 00:00 UTC · faltam $time';
  }

  @override
  String get dealClaimed => 'Comprada hoje — volte amanhã';

  @override
  String dealGotAccessory(Object name) {
    return 'Você recebeu $name!';
  }

  @override
  String get dealUnavailable => 'Esta oferta não pode ser comprada agora.';

  @override
  String get guildBossTitle => 'Chefe semanal da guilda';

  @override
  String guildBossTier(Object tier) {
    return 'Nível $tier';
  }

  @override
  String guildBossProgress(Object damage, Object hp) {
    return '$damage / $hp de dano';
  }

  @override
  String guildBossClaim(Object coins, Object gems) {
    return 'Resgatar baú: +$gems 💎 +$coins Moedas da Guilda';
  }

  @override
  String get guildBossClaimedLabel => 'Baú resgatado';

  @override
  String guildBossClaimedSnack(Object coins, Object gems) {
    return 'Baú do chefe: +$gems 💎 +$coins Moedas da Guilda';
  }

  @override
  String get guildBossErrAlive => 'O chefe ainda está vivo.';

  @override
  String get guildBossName1 => 'Dragão de Pérolas';

  @override
  String get guildBossName2 => 'Titã de Gelo Raspado';

  @override
  String get guildBossName3 => 'Kraken de Chá Preto';

  @override
  String get guildBossName4 => 'Urso Pudim';

  @override
  String get guildBossName5 => 'Tigre Matcha';

  @override
  String get guildBossName6 => 'Fênix de Espuma de Queijo';

  @override
  String get accessoryVipWatch => 'Relógio de luxo';

  @override
  String get accessoryVipLuggage => 'Mala de luxo';

  @override
  String get accessoryVipBriefcase => 'Pasta executiva';

  @override
  String get accessoryVipTophat => 'Cartola';

  @override
  String get accessoryVipRacecar => 'Supercarro';

  @override
  String get accessoryVipHeli => 'Helicóptero';

  @override
  String get accessoryVipYacht => 'Iate';

  @override
  String get accessoryVipJet => 'Jato particular';

  @override
  String get vipShopOpen => '🛍️ Loja VIP';

  @override
  String get vipShopTitle => 'Loja VIP';

  @override
  String vipCoinsLabel(Object n) {
    return 'Moedas VIP: $n';
  }

  @override
  String vipShopLocked(Object level) {
    return 'Requer VIP $level';
  }

  @override
  String get vipShopOwned => 'Obtido';

  @override
  String get vipShopNeedCoins => 'Moedas VIP insuficientes';

  @override
  String vipShopBoughtSnack(Object name) {
    return 'Você recebeu $name!';
  }

  @override
  String get vipShopHint =>
      'Ganhe Moedas VIP resgatando seus presentes VIP diários, semanais e mensais.';

  @override
  String vipBenefitSnack(Object coins, Object gems) {
    return 'Resgatou +$gems 💎 +$coins Moedas VIP';
  }

  @override
  String get vipItemsTitle => 'Exclusivos VIP';

  @override
  String vipShopPrice(Object n) {
    return '$n Moedas VIP';
  }

  @override
  String get vipEntryHint =>
      'Recarregue para liberar presentes VIP diários, semanais e mensais';

  @override
  String get settingsWebsite => 'Site';

  @override
  String get settingsWebGuide => 'Guia de jogo (web)';

  @override
  String get guideOnWeb => 'Guia completo no site';

  @override
  String get webOpenFailed =>
      'Não foi possível abrir o site. Verifique sua conexão e tente de novo.';

  @override
  String get webBoardOpenTip => 'Ver este ranking na web';

  @override
  String get webBoardShareTip => 'Compartilhar link do ranking';

  @override
  String webBoardShareText(Object url) {
    return 'Veja o ranking do Boba Empire: $url';
  }

  @override
  String get settingsShareProfile => 'Compartilhar meu perfil de ranking';

  @override
  String profileShareText(String name, String url) {
    return 'Veja as posições de $name no Boba Empire: $url';
  }

  @override
  String profileTitle(String name) {
    return 'Perfil: $name';
  }

  @override
  String get profileBoardIncome => 'Renda';

  @override
  String get profileBoardPearls => 'Pérolas';

  @override
  String get profileBoardCollection => 'Coleção';

  @override
  String get profileBoardSpeed => 'Speedrun da história';

  @override
  String get profileBoardVip => 'VIP';

  @override
  String get profileNoRanks => 'Ainda não está em nenhum ranking.';

  @override
  String get profileViewButton => 'Perfil';

  @override
  String get profileOpenWeb => 'Ver na web';

  @override
  String get refEntry => '👥 Convidar amigos';

  @override
  String refEntryNote(Object gems) {
    return 'Ganhe $gems 💎 por cada amigo que entrar';
  }

  @override
  String get refTitle => 'Convidar amigos';

  @override
  String get refYourCode => 'Seu código de convite';

  @override
  String get refCopy => 'Copiar código';

  @override
  String get refCopied => 'Código copiado';

  @override
  String get refShare => 'Compartilhar';

  @override
  String refShareText(Object code) {
    return 'Jogue Boba Empire comigo! Use meu código $code para ganhar 💎 extra: https://bobaempiregame.com';
  }

  @override
  String refStats(Object invited, Object max, Object reached) {
    return 'Convidados: $invited/$max · atingiram a meta: $reached';
  }

  @override
  String refRule(Object gems, Object stage) {
    return 'Você ganha $gems 💎 por cada amigo que chegar à fase $stage. Seu amigo também ganha 💎 ao digitar seu código.';
  }

  @override
  String refClaim(Object gems) {
    return 'Resgatar +$gems 💎';
  }

  @override
  String refClaimedSnack(Object gems) {
    return 'Resgatou +$gems 💎';
  }

  @override
  String get refEnterTitle => 'Tem o código de um amigo?';

  @override
  String get refEnterHint => 'Código de convite';

  @override
  String get refRedeem => 'Resgatar código';

  @override
  String refRedeemedSnack(Object gems) {
    return 'Código aceito: +$gems 💎';
  }

  @override
  String get refErrEmail => 'Vincule seu e-mail primeiro.';

  @override
  String get refErrNotFound => 'Código não encontrado.';

  @override
  String get refErrInvalid => 'Você não pode usar este código.';

  @override
  String get refErrAlready => 'Você já usou um código de convite.';

  @override
  String get refErrFull => 'Este código atingiu o limite de convites.';

  @override
  String get refErrNothing => 'Ainda não há nada para resgatar.';

  @override
  String get refErrNetwork => 'Problema de rede, tente de novo.';

  @override
  String get vipLbOpen => 'Ranking VIP';

  @override
  String get rewardsTitle => 'Ganhe mais 🎁';

  @override
  String get rewardsChip => 'Ganhe mais';

  @override
  String rewardAutoTapName(int m) {
    return 'Toque automático $m min';
  }

  @override
  String rewardAutoTapActive(String t) {
    return 'Ativo · restam $t';
  }

  @override
  String rewardAutoTapVip(int n) {
    return 'VIP $n+ tem toque automático permanente';
  }

  @override
  String rewardAutoTapHint(int n) {
    return 'Assista a um anúncio para tocar o copo sozinho (VIP $n+ libera para sempre)';
  }

  @override
  String get rewardAutoTapSnack =>
      'Toque automático ativado! Só rende moedas, sem pontos de Guilda ou missões.';

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
  String get genQuantumTea => 'Chá com Leite Quântico';

  @override
  String get genAiTea => 'Chá com Leite IA';

  @override
  String get genParallelTea => 'Chá com Leite Universo Paralelo';

  @override
  String get genNftTea => 'Chá com Leite NFT';

  @override
  String get genTimeTea => 'Chá com Leite Viagem no Tempo';

  @override
  String get genMultidimTea => 'Chá com Leite Multidimensional';

  @override
  String get genBlackholeTea => 'Chá com Leite Buraco Negro';

  @override
  String get genLightTea => 'Chá com Leite Velocidade da Luz';

  @override
  String get genRobotTea => 'Chá com Leite Robô';

  @override
  String get genHologramTea => 'Chá com Leite Holograma';

  @override
  String get genLegendTea => 'Chá com Leite Lendário';

  @override
  String get genEternalTea => 'Chá com Leite Eterno';

  @override
  String get stage4 => 'Oficina Brûlée';

  @override
  String get stage5 => 'Fábrica de Espuma de Queijo';

  @override
  String get stage6 => 'Império Global';

  @override
  String get stage7 => 'Abertura de Capital (IPO)';

  @override
  String get stage8 => 'Conglomerado';

  @override
  String get stage9 => 'Fundo de Investimento Global';

  @override
  String get stage10 => 'Cadeia de Suprimentos Agrícola';

  @override
  String get stage11 => 'Império Tecnológico de IA';

  @override
  String get stage12 => 'Lenda do Chá com Leite';

  @override
  String get stage13 => 'Academia do Chá com Leite';

  @override
  String get stage14 => 'Cidade do Chá com Leite';

  @override
  String get stage15 => 'Nação do Chá com Leite';

  @override
  String get stage16 => 'Aliança Mundial';

  @override
  String get stage17 => 'Planeta do Chá com Leite';

  @override
  String get stage18 => 'A Verdade do Chá com Leite';

  @override
  String get genAcademyTea => 'Chá com Leite Acadêmico';

  @override
  String get genScholarTea => 'Chá com Leite do Erudito';

  @override
  String get genCityTea => 'Chá com Leite Urbano';

  @override
  String get genMetroTea => 'Chá com Leite Metrópole';

  @override
  String get genNationTea => 'Chá com Leite Nacional';

  @override
  String get genTreatyTea => 'Chá com Leite do Tratado';

  @override
  String get genUnionTea => 'Chá com Leite da Aliança';

  @override
  String get genWorldTea => 'Chá com Leite Paz Mundial';

  @override
  String get genPlanetTea => 'Chá com Leite Planetário';

  @override
  String get genTerraformTea => 'Chá com Leite Terraformado';

  @override
  String get genTruthTea => 'Chá com Leite da Verdade';

  @override
  String get genUltimateTea => 'Chá com Leite Supremo';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSound => 'Som';

  @override
  String recipeGroupLocked(String name, int need, int learned) {
    return '🔒 $name — desbloqueia ao aprender $need receitas do grupo anterior ($learned/$need)';
  }

  @override
  String recipeGroupLockedFar(String name) {
    return '🔒 $name';
  }

  @override
  String recipeGroupOpened(String name) {
    return '🔓 Novo grupo desbloqueado: $name!';
  }

  @override
  String recipeStreak(int n) {
    return '🔥 Sequência de revisão: $n dias';
  }

  @override
  String get recipeStreakToday => 'Revisado hoje ✓';

  @override
  String get recipeStreakPending =>
      'Hoje ainda não revisou — faça uma sessão para manter a sequência';

  @override
  String recipeRescueTitle(int n) {
    return 'Você perdeu um dia — sua sequência de $n dias está prestes a acabar!';
  }

  @override
  String recipeRescueGems(int n) {
    return 'Salvar por $n 💎';
  }

  @override
  String get recipeRescueAd => 'Assistir anúncio para salvar';

  @override
  String get recipeRescued => 'Sequência salva!';

  @override
  String get recipeRescueNoGems => '💎 insuficientes para salvar a sequência.';

  @override
  String recipeStreakGems(int n, int gems) {
    return '🔥 Sequência de $n dias! +$gems 💎';
  }

  @override
  String recipeStreakFeedback(int n) {
    return '🔥 Sequência de revisão: $n dias';
  }

  @override
  String get recipeNotifyTitle => 'Receitas de bebidas';

  @override
  String recipeNotifyStreak(int n) {
    return 'Sua sequência de revisão de $n dias está acabando! Faça uma sessão para mantê-la';
  }

  @override
  String recipeNotifyDue(int n) {
    return '$n receitas para revisar hoje';
  }

  @override
  String get rlbTitle => 'Mestres de receitas';

  @override
  String get lbrBoardRecipes => 'Mestres de receitas';

  @override
  String get rlbEmpty =>
      'Ninguém no ranking ainda. Seja o primeiro a dominar uma receita!';

  @override
  String get rlbNoMastered =>
      'Você ainda não dominou nenhuma receita, então não está no ranking.';

  @override
  String rlbMastered(int n) {
    return '$n dominadas';
  }

  @override
  String get rlbError =>
      'Não foi possível carregar o ranking, tente novamente mais tarde.';

  @override
  String recipeMilestone(int n) {
    return '$n receitas dominadas — você ganhou um acessório!';
  }

  @override
  String get dqRecipe => 'Conclua 1 sessão de prática de receitas';

  @override
  String wqRecipeSessions(int n) {
    return 'Conclua $n sessões de prática de receitas';
  }

  @override
  String wqRecipeLevels(int n) {
    return 'Suba de nível $n receitas';
  }

  @override
  String get recipeHint => 'Dica (assistir anúncio)';

  @override
  String get recipeHintNoCount =>
      'Você usou uma dica, então esta pergunta não conta para os níveis.';

  @override
  String get recipeDouble => 'Assistir anúncio para dobrar as moedas';

  @override
  String get recipeDoubled => 'Recompensa em moedas dobrada!';

  @override
  String get recipeTitle => 'Receitas de bebidas';

  @override
  String get recipeEntryNote => 'Memorize receitas e ganhe recompensas';

  @override
  String get recipeEntryButton => 'Jogar';

  @override
  String recipeMastered(int n, int total) {
    return 'Dominadas $n/$total';
  }

  @override
  String recipeDueToday(int n) {
    return '$n receitas para revisar hoje';
  }

  @override
  String get recipeAllDone =>
      'Tudo revisado por hoje! Você ainda pode praticar (não conta para os níveis).';

  @override
  String get recipePractice => 'Praticar';

  @override
  String get recipeBox0 => 'Nova';

  @override
  String get recipeBox1 => 'Conhecida';

  @override
  String get recipeBox2 => 'Aprendida';

  @override
  String get recipeBox3 => 'Dominada';

  @override
  String get recipeReviewToday => 'Revisão: hoje';

  @override
  String recipeReviewIn(int n) {
    return 'Revisão em $n dias';
  }

  @override
  String recipeQMissing(String name) {
    return 'Qual ingrediente falta em $name?';
  }

  @override
  String recipeQQuantity(String drink, String ingredient) {
    return '$drink: quanto de $ingredient?';
  }

  @override
  String recipeQFull(String name) {
    return 'Qual é a receita correta de $name?';
  }

  @override
  String get recipeCorrect => 'Correto!';

  @override
  String get recipeWrongShort => 'Quase — a resposta certa está destacada.';

  @override
  String recipeLevelUp(String box, String name) {
    return '$name chegou a $box!';
  }

  @override
  String get recipePracticeOnly =>
      'Ainda não é hora de revisar — só prática, sem mudar de nível.';

  @override
  String get recipeNext => 'Próxima';

  @override
  String get recipeSeeResult => 'Ver resultados';

  @override
  String get recipeResultTitle => 'Resultados';

  @override
  String recipeScore(int correct, int total) {
    return '$correct/$total corretas';
  }

  @override
  String recipeLevelUps(int n) {
    return '$n receitas subiram de nível';
  }

  @override
  String recipeRewardCash(String cash) {
    return 'Recompensa: +$cash moedas';
  }

  @override
  String recipeRewardBoth(String cash, int gems) {
    return 'Recompensa: +$cash moedas, +$gems 💎';
  }

  @override
  String get recipeAgain => 'Praticar de novo';

  @override
  String get recipeDone => 'Concluir';

  @override
  String get recipeDisclaimer =>
      'As receitas são apenas referência para o jogo, não a receita oficial de nenhuma marca.';

  @override
  String get recipeIngredients => 'Ingredientes';

  @override
  String walkerTipSnack(String amount) {
    return 'Um cliente deixou +$amount moedas de gorjeta 🧋';
  }

  @override
  String get settingsEffects => 'Efeitos visuais';

  @override
  String get settingsEffectsAuto => 'Automático (conforme o aparelho)';

  @override
  String get settingsEffectsHigh => 'Alto';

  @override
  String get settingsEffectsMedium => 'Médio';

  @override
  String get settingsEffectsLow => 'Baixo (poupa bateria)';

  @override
  String get settingsEffectsOff => 'Desativado';

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
  String storyUnlockWhen(String cond) {
    return 'Desbloqueia ao: $cond';
  }

  @override
  String storyUnlockAfter(String chapter) {
    return 'Desbloqueia após $chapter';
  }

  @override
  String storyCondFirst(String name) {
    return 'Primeiro $name';
  }

  @override
  String get storyCondRival => 'Derrote o rival';

  @override
  String storyCondAscension(int n, String name) {
    return '$name n.º $n';
  }

  @override
  String storyCondM3(int n, String game) {
    return 'Passe o nível $n de $game';
  }

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

  @override
  String get navArena => 'Arena';

  @override
  String get navCompete => 'Competir';

  @override
  String get arenaTitle => 'Arena';

  @override
  String get arenaIntro =>
      'Duelo 1x1 de 60 segundos — quem ganhar mais Moedas vence!';

  @override
  String get arenaStartButton => 'Procurar rival';

  @override
  String get arenaModeTap => 'Corrida de toques';

  @override
  String get arenaModeMatch3 => 'Pérolas Caindo';

  @override
  String get arenaMatch3Intro =>
      'Combine 3 iguais por 60 segundos — vence quem pontuar mais que o adversário!';

  @override
  String get arenaMatch3Stuck => 'Sem jogadas!';

  @override
  String get arenaQueueWaiting => 'Procurando rival…';

  @override
  String get arenaCancelButton => 'Cancelar';

  @override
  String get arenaTapButton => 'Toque no copo';

  @override
  String get arenaResolving => 'Encerrando a partida…';

  @override
  String arenaTierButton(String cost) {
    return 'Melhorar ×2 ($cost Moedas)';
  }

  @override
  String get arenaModeRecipe => 'Duelo de Receitas';

  @override
  String get arenaRecipeIntro =>
      'Preparem os mesmos 5 pedidos — vence quem somar mais pontos. Se os dois terminarem antes, o duelo acaba na hora!';

  @override
  String get arenaRecipeStart => 'Começar a preparar';

  @override
  String arenaRecipeProgress(int done, int theirs) {
    return 'Você: $done/5 pedidos · Rival: $theirs/5';
  }

  @override
  String get arenaRecipeWaiting => 'Pronto! Aguardando o adversário…';

  @override
  String arenaTimeLeft(int seconds) {
    return 'Faltam ${seconds}s';
  }

  @override
  String arenaOnlineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogadores online',
      one: '1 jogador online',
    );
    return '$_temp0';
  }

  @override
  String get arenaYourScore => 'Sua pontuação';

  @override
  String get arenaOpponentScore => 'Rival';

  @override
  String get arenaResultWin => 'Você venceu! 🎉';

  @override
  String get arenaResultLose => 'Você perdeu';

  @override
  String get arenaResultDraw => 'Empate';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => 'Fechar';

  @override
  String get redeemTitle => 'Resgatar código de presente';

  @override
  String get redeemHint => 'Digite o código';

  @override
  String get redeemButton => 'Resgatar';

  @override
  String redeemSuccess(int gems) {
    return 'Resgatado +$gems 💎!';
  }

  @override
  String get redeemAlreadyClaimed => 'Você já resgatou este código';

  @override
  String get redeemInvalid => 'Código inválido';

  @override
  String get cloudSaveMenuTitle => 'Backup do progresso';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'Vinculado: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'Não vinculado — pode perder o progresso ao desinstalar';

  @override
  String get cloudSaveTitle => 'Backup do progresso';

  @override
  String get cloudSaveIntro =>
      'Vincule um email para recuperar seu progresso ao desinstalar ou trocar de aparelho.';

  @override
  String get cloudSaveEmailHint => 'Seu email';

  @override
  String get cloudSaveSendCode => 'Enviar código';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'Código de confirmação enviado para $email';
  }

  @override
  String get cloudSaveCheckSpam =>
      'Não encontrou o e-mail? Verifique também a pasta de Spam / Lixo eletrônico.';

  @override
  String get cloudSaveCodeHint => 'Código de confirmação';

  @override
  String get cloudSaveVerify => 'Verificar';

  @override
  String get cloudSaveChangeEmail => 'Usar outro email';

  @override
  String get cloudSaveResend => 'Reenviar código';

  @override
  String cloudSaveResendIn(int seconds) {
    return 'Reenviar código (${seconds}s)';
  }

  @override
  String get cloudSaveConflictTitle => 'Encontramos outro salvamento na nuvem';

  @override
  String cloudSaveConflictLocal(String amount) {
    return 'Este aparelho: $amount Moedas totais';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return 'Na nuvem: $amount Moedas totais';
  }

  @override
  String get cloudSaveRestoreButton => 'Restaurar da nuvem';

  @override
  String get cloudSaveKeepLocalButton => 'Manter este aparelho';

  @override
  String cloudSaveLinkedStatus(String email) {
    return 'Vinculado: $email';
  }

  @override
  String get cloudSaveDisconnect => 'Desvincular';

  @override
  String get cloudSaveRetry => 'Tentar de novo';

  @override
  String get leaderboardMenuTitle => 'Classificação';

  @override
  String get leaderboardTitle => 'Classificação';

  @override
  String get leaderboardNicknameIntro =>
      'Escolha um nome para a classificação (pode mudar depois):';

  @override
  String get leaderboardNicknameHint => 'Seu nome';

  @override
  String get leaderboardSubmit => 'Confirmar';

  @override
  String leaderboardYourRank(int rank) {
    return 'Sua posição: #$rank';
  }

  @override
  String leaderboardStars(String stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty => 'Ainda ninguém na classificação — é você!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 Você está em uma posição alta! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return 'Top 1: $top1💎 · Top 2-3: $top23💎 · Top 4-10: $top410💎 — a cada 24h enquanto estiver classificado';
  }

  @override
  String get leaderboardChangeName => 'Mudar nome';

  @override
  String get leaderboardRetry => 'Tentar de novo';

  @override
  String get storySpeedrunMenuTitle => 'Speedrun';

  @override
  String get storySpeedrunTitle => 'Classificação de Speedrun';

  @override
  String get storySpeedrunNotCompletedYet =>
      'Você ainda não terminou a história — complete o Capítulo 18 para entrar na classificação.';

  @override
  String get storySpeedrunTabMain => 'Ato 1';

  @override
  String get storySpeedrunTabExt => 'Ato 2';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      'Você ainda não concluiu o Ato 2 — conclua o Capítulo 28 para entrar no ranking.';

  @override
  String get storySpeedrunTabExt2 => 'Ato 3';

  @override
  String get storySpeedrunExt2NotCompletedYet =>
      'Você ainda não concluiu o Ato 3 — conclua o Capítulo 36 para entrar no ranking.';

  @override
  String get accessoryMenuTitle => 'Coleção';

  @override
  String get collectionChip => 'Coleção';

  @override
  String get accessoryInventoryTitle => 'Coleção de acessórios';

  @override
  String accessoryInventoryOwned(int owned, int total) {
    return '$owned/$total coletados';
  }

  @override
  String get accessoryRarityCommon => 'Comum';

  @override
  String get accessoryRarityRare => 'Raro';

  @override
  String get accessoryRarityEpic => 'Épico';

  @override
  String get accessoryRarityLegendary => 'Lendário';

  @override
  String get accessoryLbTitle => 'Ranking de coleção';

  @override
  String accessoryLbCount(int n) {
    return '$n acessórios';
  }

  @override
  String get accessoryLbTopTitle => 'Colecionador';

  @override
  String get accessoryLbTitleKing => 'Rei dos Acessórios';

  @override
  String get accessoryLbTitleMaster => 'Mestre Colecionador';

  @override
  String get accessoryLbEmpty =>
      'Ainda ninguém no ranking. Colecione um acessório e o primeiro lugar é seu!';

  @override
  String get accessoryLbNoOwned =>
      'Você ainda não tem nenhum acessório — complete as 3 missões diárias para ter uma chance.';

  @override
  String get accessoryLbError =>
      'Não foi possível carregar o ranking. Tente novamente mais tarde.';

  @override
  String get accessoryMintLeaf => 'Folha de Hortelã';

  @override
  String get accessoryCupcake => 'Cupcake';

  @override
  String get accessoryCookie => 'Biscoito';

  @override
  String get accessoryPottedPlant => 'Planta em Vaso';

  @override
  String get accessoryCandle => 'Vela Aromática';

  @override
  String get accessoryScarf => 'Cachecol';

  @override
  String get accessoryKite => 'Pipa de Papel';

  @override
  String get accessoryCap => 'Boné';

  @override
  String get accessorySeashell => 'Concha do Mar';

  @override
  String get accessoryMask => 'Máscara';

  @override
  String get accessoryDrum => 'Tamborzinho';

  @override
  String get accessoryPalette => 'Paleta de Cores';

  @override
  String get accessoryCrystalBall => 'Bola de Cristal';

  @override
  String get accessoryLantern => 'Lanterna Antiga';

  @override
  String get accessoryUnicorn => 'Unicórnio Pequeno';

  @override
  String get accessoryDragon => 'Dragão Pequeno';

  @override
  String get accessoryBalloon => 'Balão';

  @override
  String get accessoryBowtie => 'Laço';

  @override
  String get accessorySunglasses => 'Óculos de Sol';

  @override
  String get accessoryUmbrella => 'Guarda-chuva Pequeno';

  @override
  String get accessoryTeapot => 'Bule Pequeno';

  @override
  String get accessoryBell => 'Sininho';

  @override
  String get accessoryRibbon => 'Fita';

  @override
  String get accessoryBookmark => 'Marcador de Página';

  @override
  String get accessoryWindChime => 'Sino de Vento';

  @override
  String get accessoryClover => 'Trevo de Quatro Folhas';

  @override
  String get accessoryBubble => 'Bolha de Sabão';

  @override
  String get accessorySticker => 'Adesivo';

  @override
  String get accessoryYarn => 'Novelo de Lã';

  @override
  String get accessoryFan => 'Leque de Papel';

  @override
  String get accessoryBasket => 'Cesta de Vime';

  @override
  String get accessoryBead => 'Pulseira de Contas';

  @override
  String get accessoryLadybug => 'Joaninha Pequena';

  @override
  String get accessoryKey => 'Chave Antiga';

  @override
  String get accessoryDiamondStone => 'Pedra de Diamante';

  @override
  String get accessoryMusicNote => 'Nota Musical';

  @override
  String get accessoryTelescope => 'Telescópio';

  @override
  String get accessoryAnchor => 'Âncora';

  @override
  String get accessoryFeather => 'Pena';

  @override
  String get accessoryHourglass => 'Ampulheta';

  @override
  String get accessoryMap => 'Mapa Antigo';

  @override
  String get accessoryRing => 'Anelzinho';

  @override
  String get accessoryMagicWand => 'Varinha Mágica';

  @override
  String get accessoryTrident => 'Tridente';

  @override
  String get accessoryPeacock => 'Pavão Pequeno';

  @override
  String get accessoryComet => 'Cometa';

  @override
  String get accessoryButterfly => 'Borboleta de Cristal';

  @override
  String get accessoryAngelWing => 'Asa de Anjo';

  @override
  String get accessoryPhoenix => 'Fênix';

  @override
  String get accessoryGalaxy => 'Galáxia';

  @override
  String get accessoryDonut => 'Donut';

  @override
  String get accessoryLollipop => 'Pirulito';

  @override
  String get accessoryPretzel => 'Pretzel';

  @override
  String get accessoryIceCream => 'Casquinha de sorvete';

  @override
  String get accessoryStrawberry => 'Morango';

  @override
  String get accessoryCherry => 'Cerejas';

  @override
  String get accessoryLemon => 'Limão-siciliano';

  @override
  String get accessoryPeach => 'Pêssego';

  @override
  String get accessoryPopcorn => 'Pipoca';

  @override
  String get accessoryHoneyPot => 'Pote de mel';

  @override
  String get accessoryMilkGlass => 'Copo de leite';

  @override
  String get accessoryTangerine => 'Tangerina';

  @override
  String get accessoryChestnut => 'Castanha';

  @override
  String get accessoryMapleLeaf => 'Folha de bordo';

  @override
  String get accessoryCompass => 'Bússola';

  @override
  String get accessoryRocket => 'Foguete';

  @override
  String get accessoryViolin => 'Violino';

  @override
  String get accessoryScroll => 'Pergaminho';

  @override
  String get accessoryMicrophone => 'Microfone';

  @override
  String get accessoryLotus => 'Lótus';

  @override
  String get accessoryJellyfish => 'Água-viva';

  @override
  String get accessoryCamera => 'Câmera';

  @override
  String get accessoryShield => 'Escudo';

  @override
  String get accessoryAmphora => 'Vaso antigo';

  @override
  String get accessoryRainbow => 'Arco-íris';

  @override
  String get accessoryFairy => 'Fada';

  @override
  String get accessoryDiscoBall => 'Globo de discoteca';

  @override
  String get accessoryShiningStar => 'Estrela brilhante';

  @override
  String get accessoryKraken => 'Kraken';

  @override
  String get accessoryThunderbolt => 'Raio divino';

  @override
  String get accessoryIceCube => 'Cubo de gelo';

  @override
  String get accessoryCroissant => 'Croissant';

  @override
  String get accessoryPancakes => 'Panquecas';

  @override
  String get accessoryWaffle => 'Waffle';

  @override
  String get accessoryBagel => 'Bagel';

  @override
  String get accessoryCakeSlice => 'Fatia de bolo';

  @override
  String get accessoryPie => 'Torta';

  @override
  String get accessoryCandy => 'Bala';

  @override
  String get accessoryGrapes => 'Uvas';

  @override
  String get accessoryWatermelon => 'Melancia';

  @override
  String get accessoryPineapple => 'Abacaxi';

  @override
  String get accessoryMango => 'Manga';

  @override
  String get accessoryKiwi => 'Kiwi';

  @override
  String get accessoryBanana => 'Banana';

  @override
  String get accessoryApple => 'Maçã';

  @override
  String get accessoryTeddy => 'Ursinho de pelúcia';

  @override
  String get accessoryCrayon => 'Giz de cera';

  @override
  String get accessoryBucket => 'Balde';

  @override
  String get accessoryGuitar => 'Violão';

  @override
  String get accessoryTrumpet => 'Trompete';

  @override
  String get accessoryPiano => 'Piano';

  @override
  String get accessorySaxophone => 'Saxofone';

  @override
  String get accessoryBanjo => 'Banjo';

  @override
  String get accessoryMicroscope => 'Microscópio';

  @override
  String get accessoryRingedPlanet => 'Planeta com anéis';

  @override
  String get accessoryCrescentMoon => 'Lua crescente';

  @override
  String get accessoryBowArrow => 'Arco e flecha';

  @override
  String get accessoryMirror => 'Espelho';

  @override
  String get accessoryFerrisWheel => 'Roda-gigante';

  @override
  String get accessoryCarousel => 'Carrossel';

  @override
  String get accessorySwan => 'Cisne';

  @override
  String get accessoryFlamingo => 'Flamingo';

  @override
  String get accessoryOwl => 'Coruja';

  @override
  String get accessoryWhale => 'Baleia';

  @override
  String get accessoryCrown => 'Coroa';

  @override
  String get accessoryCircusTent => 'Tenda de circo';

  @override
  String get accessoryPinata => 'Piñata';

  @override
  String get accessoryCastle => 'Castelo';

  @override
  String get accessoryGenie => 'Gênio';

  @override
  String get accessoryVolcano => 'Vulcão';

  @override
  String get accessoryCarrot => 'Cenoura';

  @override
  String get accessoryCorn => 'Milho';

  @override
  String get accessoryTomato => 'Tomate';

  @override
  String get accessoryAvocado => 'Abacate';

  @override
  String get accessoryCoconut => 'Coco';

  @override
  String get accessoryBlueberries => 'Mirtilos';

  @override
  String get accessoryPear => 'Pera';

  @override
  String get accessoryRiceBall => 'Onigiri';

  @override
  String get accessoryDumpling => 'Pastel chinês';

  @override
  String get accessorySushi => 'Sushi';

  @override
  String get accessoryRamen => 'Ramen';

  @override
  String get accessoryTaco => 'Taco';

  @override
  String get accessoryPizza => 'Pizza';

  @override
  String get accessoryHotDog => 'Cachorro-quente';

  @override
  String get accessoryFries => 'Batata frita';

  @override
  String get accessoryEgg => 'Ovo';

  @override
  String get accessoryBread => 'Pão';

  @override
  String get accessoryButter => 'Manteiga';

  @override
  String get accessoryPuzzle => 'Peça de quebra-cabeça';

  @override
  String get accessoryDice => 'Dado';

  @override
  String get accessoryChessPawn => 'Peão de xadrez';

  @override
  String get accessoryDart => 'Alvo de dardos';

  @override
  String get accessoryBowling => 'Boliche';

  @override
  String get accessoryYoYo => 'Ioiô';

  @override
  String get accessoryRollerSkate => 'Patim';

  @override
  String get accessorySkateboard => 'Skate';

  @override
  String get accessorySatellite => 'Satélite';

  @override
  String get accessoryAlembic => 'Alambique';

  @override
  String get accessoryDna => 'DNA';

  @override
  String get accessoryTrophy => 'Troféu';

  @override
  String get accessoryLeopard => 'Leopardo';

  @override
  String get accessoryElephant => 'Elefante';

  @override
  String get accessoryPanda => 'Panda';

  @override
  String get accessoryGiraffe => 'Girafa';

  @override
  String get accessoryTurtle => 'Tartaruga';

  @override
  String get accessoryKoala => 'Coala';

  @override
  String get accessoryPenguin => 'Pinguim';

  @override
  String get accessorySauropod => 'Saurópode';

  @override
  String get accessoryMermaid => 'Sereia';

  @override
  String get accessoryEagle => 'Águia';

  @override
  String get marketTitle => 'Mercado de Acessórios';

  @override
  String get marketTabBrowse => 'Mercado';

  @override
  String get marketTabMine => 'Meus';

  @override
  String get marketRecentSalesHeader => 'Vendido recentemente';

  @override
  String get marketMerchantTitle => 'Comerciante da semana';

  @override
  String get marketFilterAll => 'Todos';

  @override
  String get marketFilterMissing => 'Faltando';

  @override
  String get marketSortPriceAsc => 'Menor preço';

  @override
  String get marketBadgeNew => 'NOVO';

  @override
  String marketNeedMore(int n) {
    return 'Faltam $n Moedas de Mercado';
  }

  @override
  String get marketNoFilterResults => 'Nenhum item corresponde ao filtro.';

  @override
  String accessoryRevealNew(String name) {
    return 'Novo acessório: $name!';
  }

  @override
  String accessoryRevealDuplicate(String name, int gems) {
    return '$name repetido: +$gems 💎 e uma cópia extra para vender no Mercado';
  }

  @override
  String accessoryEquipHint(int n, int max) {
    return 'Em exibição $n/$max — toque num item que você tem para mostrá-lo ao redor do copo';
  }

  @override
  String accessoryEquipFull(int max) {
    return 'Exibição cheia ($max) — remova um primeiro';
  }

  @override
  String get accessoryFlairHint =>
      'Pressione e segure um item para usá-lo como emblema do ranking';

  @override
  String accessoryFlairSet(String name) {
    return '$name agora é seu emblema do ranking';
  }

  @override
  String get accessoryFlairCleared => 'Emblema do ranking removido';

  @override
  String get accessoryFlairFailed =>
      'Não foi possível definir o emblema: item não sincronizado ou sem conexão';

  @override
  String get marketStarterTitle => 'Pacote Inicial do Mercado';

  @override
  String get marketStarterBody =>
      'Ganhe 1 acessório Comum + 1 repetido para vender + 10 Moedas de Mercado. Apenas uma vez.';

  @override
  String get marketStarterClaim => 'Resgatar';

  @override
  String get marketStarterDone => 'Pacote Inicial resgatado! Veja sua Coleção.';

  @override
  String get marketStarterErrCap =>
      'Os presentes de hoje acabaram em todo o servidor — volte amanhã.';

  @override
  String get marketStarterErrNet =>
      'Não foi possível resgatar: verifique a conexão e tente de novo.';

  @override
  String get marketIntroTitle => 'Bem-vindo ao Mercado!';

  @override
  String get marketIntroStep1 =>
      '1. Converta 💎 ou moedas em Moedas de Mercado (botão Converter): só valem no Mercado e não voltam.';

  @override
  String get marketIntroStep2 =>
      '2. Compre acessórios que outros jogadores anunciam para completar sua coleção.';

  @override
  String get marketIntroStep3 =>
      '3. Venda repetidos na aba Meus itens. A taxa é de apenas 1%.';

  @override
  String get marketIntroOk => 'Entendi';

  @override
  String get collectionTitle10 => 'Colecionador';

  @override
  String get collectionTitle25 => 'Apreciador';

  @override
  String get collectionTitle40 => 'Colecionador especialista';

  @override
  String get collectionTitle50 => 'Lenda das coleções';

  @override
  String get collectionTitle80 => 'Mestre colecionador';

  @override
  String get collectionTitle100 => 'Grande colecionador';

  @override
  String get collectionTitle120 => 'Rei da coleção';

  @override
  String get collectionTitle140 => 'Sábio colecionador';

  @override
  String get collectionTitle160 => 'Divindade da coleção';

  @override
  String collectionTitleLabel(String title) {
    return 'Título: $title';
  }

  @override
  String collectionMilestoneClaim(int coins) {
    return 'Resgatar +$coins';
  }

  @override
  String collectionMilestoneLocked(int count, int coins) {
    return '$count itens · $coins Moedas de Mercado';
  }

  @override
  String collectionMilestoneDone(int coins) {
    return 'Você ganhou $coins Moedas de Mercado e um novo título!';
  }

  @override
  String get collectionMilestoneErrNet =>
      'Não foi possível resgatar: verifique a conexão e tente de novo.';

  @override
  String marketPriceLast(int n) {
    return 'Última venda: $n';
  }

  @override
  String marketPriceLowest(int n) {
    return 'Mais barato agora: $n';
  }

  @override
  String marketPriceAvg(int n) {
    return 'Média de 7 dias: $n';
  }

  @override
  String get marketWishAdd => 'Adicionar à lista de desejos';

  @override
  String get marketWishRemove => 'Remover da lista de desejos';

  @override
  String marketWishFull(int max) {
    return 'Lista de desejos cheia ($max itens)';
  }

  @override
  String marketFeeFreeNote(int proceeds) {
    return 'Grátis no fim de semana: você recebe as $proceeds Moedas de Mercado completas';
  }

  @override
  String get marketWeekendBanner =>
      '🎉 Fim de semana: taxa 0% e mais chance de acessórios raros!';

  @override
  String collectionPeekTitle(String name) {
    return 'Coleção de $name';
  }

  @override
  String get collectionPeekError =>
      'Não foi possível carregar a coleção — tente mais tarde.';

  @override
  String get collectionShareTooltip => 'Mostrar coleção';

  @override
  String collectionShareText(int owned, int total, String items) {
    return 'Colecionei $owned/$total acessórios no Boba Empire! $items';
  }

  @override
  String get collectionShareCopied => 'Copiado — cole em um chat para mostrar!';

  @override
  String get collectionCardTitle => 'Cartão da coleção';

  @override
  String get collectionShareImage => 'Compartilhar imagem';

  @override
  String get collectionShareCopy => 'Copiar texto';

  @override
  String get collectionShareFailed =>
      'Não foi possível compartilhar — tente copiar o texto.';

  @override
  String whatsNewTitle(String version) {
    return 'Novidades da $version';
  }

  @override
  String get whatsNewOrders =>
      '🧋 Preparar pedidos: arraste ingredientes ao copo, clientes chibi fofos, combos, Hora de pico e pedidos de festival';

  @override
  String get whatsNewRecipes =>
      '📖 Jogo de receitas: revisão espaçada de 100 bebidas e sequência diária; todo minijogo tem guia de como jogar';

  @override
  String get whatsNewDaily =>
      '📅 Desafio diário: os mesmos pedidos para todos, ranking de Hoje e recompensas semanais ao top';

  @override
  String get whatsNewAct4 =>
      '📜 Ato 4 \"Grande Festival do Ofício\": 10 capítulos, cada um liberado por um marco dos minijogos';

  @override
  String get whatsNewMore =>
      '🤝 Toque automático, troca de acessórios no Mercado, missões de guilda; recursos online (rankings, Mercado, Guildas) exigem e-mail vinculado';

  @override
  String get whatsNewLater => 'Depois';

  @override
  String get whatsNewOpen => 'Experimentar';

  @override
  String marketWallet(int n) {
    return '$n Moedas de Mercado';
  }

  @override
  String get marketError =>
      'Não foi possível carregar o mercado. Tente novamente mais tarde.';

  @override
  String get marketEmptyBrowse => 'Ainda ninguém colocou nada à venda.';

  @override
  String get marketBuyButton => 'Comprar';

  @override
  String get marketBoughtToast => 'Comprado!';

  @override
  String marketConfirmBuy(int price) {
    return 'Comprar por $price Moedas de Mercado?';
  }

  @override
  String marketPriceTag(int price) {
    return '$price Moedas de Mercado';
  }

  @override
  String get marketMyListingsHeader => 'Seus anúncios';

  @override
  String get marketEmptyMine => 'Você ainda não colocou nada à venda.';

  @override
  String marketExpiresIn(String t) {
    return 'Expira em $t';
  }

  @override
  String marketListExpiryNote(int days) {
    return 'Os anúncios duram no máximo $days dias; ao expirar, o item volta ao seu inventário.';
  }

  @override
  String marketExpiredToast(int n) {
    return '$n anúncio(s) expirado(s) devolvido(s) ao seu inventário.';
  }

  @override
  String get swapTab => 'Trocas';

  @override
  String get swapCreate => 'Criar oferta';

  @override
  String get swapCreateOk => 'Publicar oferta';

  @override
  String swapIntro(int days) {
    return 'Troque um item por outro com outros jogadores, sem Moedas do Mercado. Seu item fica guardado até alguém aceitar (até $days dias; se expirar, volta ao seu inventário).';
  }

  @override
  String get swapEmpty => 'Ainda não há ofertas de troca. Crie a primeira!';

  @override
  String get swapMine => 'Minhas ofertas de troca';

  @override
  String get swapMineEmpty => 'Você não publicou ofertas.';

  @override
  String get swapGive => 'Dá';

  @override
  String get swapWant => 'Quer';

  @override
  String get swapAccept => 'Trocar';

  @override
  String get swapNeedItem => 'Falta o item';

  @override
  String get swapCancel => 'Cancelar';

  @override
  String get swapPickGive => 'Escolha o item que você dá';

  @override
  String get swapPickWant => 'Escolha o item que você quer';

  @override
  String get swapPickSearch => 'Buscar por nome';

  @override
  String get swapPickNone => 'Nenhum item.';

  @override
  String swapMaxNote(int n) {
    return 'Até $n ofertas ao mesmo tempo.';
  }

  @override
  String get swapConfirmTitle => 'Confirmar troca';

  @override
  String swapConfirmBody(String give, String want) {
    return 'Você recebe $give e dá $want?';
  }

  @override
  String get swapCreatedToast => 'Oferta de troca publicada!';

  @override
  String swapDoneToast(String name) {
    return 'Troca feita! Você recebeu $name.';
  }

  @override
  String get swapCancelledToast =>
      'Oferta cancelada, o item voltou ao seu inventário.';

  @override
  String swapCollectedToast(int n) {
    return '$n item(ns) de trocas voltaram ao seu inventário.';
  }

  @override
  String get swapErrNotOwned =>
      'Você não tem este item (reabra o Mercado para sincronizar).';

  @override
  String get swapErrNotOwnedWant => 'Você não tem o item que pedem.';

  @override
  String swapErrTooMany(int n) {
    return 'Você tem ofertas abertas demais (máx. $n).';
  }

  @override
  String get swapErrNotOpen =>
      'Esta oferta acabou de ser aceita ou cancelada; a lista foi atualizada.';

  @override
  String get swapErrOwn => 'Você não pode aceitar a própria oferta.';

  @override
  String get swapErrInvalid => 'Oferta inválida.';

  @override
  String get swapErrNetwork => 'Não foi possível conectar, tente mais tarde.';

  @override
  String get marketCancelButton => 'Cancelar anúncio';

  @override
  String get marketCancelledToast => 'Anúncio cancelado.';

  @override
  String get marketSellableHeader => 'Acessórios que você pode vender';

  @override
  String get marketEmptySellable =>
      'Você ainda não tem acessórios para vender.';

  @override
  String get marketListedToast => 'Anunciado!';

  @override
  String get marketListButton => 'Colocar à venda';

  @override
  String get marketPriceLabel => 'Preço (Moedas de Mercado)';

  @override
  String marketListFeeNote(int proceeds, int fee) {
    return 'Você receberá $proceeds Moedas de Mercado após a taxa de 1% (−$fee)';
  }

  @override
  String get marketConvertButton => 'Trocar';

  @override
  String get marketConvertTitle => 'Trocar por Moedas de Mercado';

  @override
  String get marketConvertAmountLabel => 'Moedas de Mercado desejadas';

  @override
  String marketConvertCostGems(String cost) {
    return 'Custo: $cost 💎';
  }

  @override
  String marketConvertCostMoney(String cost) {
    return 'Custo: $cost 💰';
  }

  @override
  String get marketConvertSuccessToast => 'Trocado!';

  @override
  String get marketConvertFailToast =>
      'Troca falhou, saldo insuficiente ou erro de rede.';

  @override
  String get storySpeedrunEmpty =>
      'Ninguém terminou a história ainda — seja o primeiro!';

  @override
  String get arenaLeaderboardMenuTitle => 'Ranking PK';

  @override
  String get arenaLeaderboardTitle => 'Ranking PK';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      'Você ainda não jogou nenhuma partida na Arena — vença uma para aparecer aqui.';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '${wins}V - ${losses}D';
  }

  @override
  String get ascensionTitle => 'Ascensão';

  @override
  String get ascensionOpen => 'Ascensão ⏳';

  @override
  String get ascensionIntro =>
      'Troque todas as Estrelas e melhorias da Loja de Estrelas por ⏳ Pontos de Ascensão — melhorias permanentes mais fortes. Você recomeça.';

  @override
  String ascensionProgress(int percent) {
    return 'Progresso para desbloquear: $percent%';
  }

  @override
  String get ascensionPointsNow => 'Pontos atuais';

  @override
  String get ascensionPointsGain => 'Ganha se ascender';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ Reinicia Estrelas, todas as melhorias da Loja de Estrelas, Moedas, níveis e etapa. Mantém 💎, conquistas e história. Suas Estrelas no ranking voltam a 0 (a posição por ganhos totais não muda).';

  @override
  String ascensionConfirm(int points) {
    return 'Ascender (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => 'Ainda indisponível';

  @override
  String ascensionSuccess(int points) {
    return 'Uma nova era começa! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => 'Melhorias de Ascensão ⏳';

  @override
  String ascensionShopSpendable(int points) {
    return '$points ⏳ para gastar';
  }

  @override
  String ascensionCost(int cost) {
    return '$cost ⏳';
  }

  @override
  String get ascensionMaxed => 'Máx.';

  @override
  String get ascensionIncomeName => 'Fonte de energia';

  @override
  String ascensionIncomeDesc(int percent) {
    return '+$percent% de renda por nível';
  }

  @override
  String get ascensionStarBonusName => 'Estrelas radiantes';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '+$percent% de poder por Estrela, por nível';
  }

  @override
  String get ascensionStarGainName => 'Estrelas abundantes';

  @override
  String ascensionStarGainDesc(int percent) {
    return '+$percent% de ganho de Estrelas, por nível';
  }

  @override
  String get achAscend => 'Ascenda pela primeira vez';

  @override
  String get dailyQuestsTitle => 'Missões diárias';

  @override
  String get dailyQuestsChip => 'Missões';

  @override
  String get chHeader => '🔥 Desafios (difíceis — grandes recompensas)';

  @override
  String chCat(int n) {
    return 'Pegue $n gatos da Chuva Dourada';
  }

  @override
  String chVip(int n) {
    return 'Atenda $n clientes VIP';
  }

  @override
  String get chBonusLabel => 'Conclua os dois desafios';

  @override
  String get lbrTitle => 'Recompensas do top semanal';

  @override
  String lbrIntro(int first, int second, int third) {
    return 'Toda semana o top 3 de cada ranking acumulado (Renda, Pérola Caindo, Coleção, VIP, Mestres de receitas, Preparar pedidos) recebe $first / $second / $third 💎. Os rankings fecham no início da semana (segunda, UTC); dá para resgatar por mais uma semana.';
  }

  @override
  String get lbrEmpty =>
      'Ainda não há recompensas — suba para o top 3 dos rankings!';

  @override
  String lbrRow(String board, String week) {
    return '$board · semana $week';
  }

  @override
  String lbrClaim(int n) {
    return 'Resgatar $n 💎';
  }

  @override
  String lbrGot(int n) {
    return 'Você resgatou $n 💎 da recompensa do top semanal!';
  }

  @override
  String get lbrErrGone =>
      'Esta recompensa expirou ou não está mais disponível.';

  @override
  String get lbrBoardIncome => 'Renda';

  @override
  String get lbrBoardPearls => 'Pérola Caindo';

  @override
  String get lbrBoardCollection => 'Coleção';

  @override
  String get lbrBoardVip => 'VIP';

  @override
  String get dailyQuestsBonusLabel => 'Conclua as 3 missões';

  @override
  String dailyQuestsResetsIn(Object time) {
    return 'Novas missões em $time';
  }

  @override
  String get dailyQuestClaimed => 'Recebido';

  @override
  String dqTap(int n) {
    return 'Toque no copo $n vezes';
  }

  @override
  String dqBuy(int n) {
    return 'Compre $n melhorias';
  }

  @override
  String dqEarn(Object amount) {
    return 'Ganhe $amount Moedas';
  }

  @override
  String get dqCat => 'Pegue o Gato Dourado';

  @override
  String get dqVip => 'Atenda um cliente VIP';

  @override
  String get dqSpin => 'Gire a Roda da Sorte';

  @override
  String get weeklyQuestsTitle => 'Missões semanais';

  @override
  String get weeklyQuestsOpen => 'Missões semanais 🗓️';

  @override
  String wqPrestige(int n) {
    return 'Prestigie $n vezes';
  }

  @override
  String wqM3Win(int n) {
    return 'Vença $n fases de Pérolas Caindo';
  }

  @override
  String wqTrade(int n) {
    return 'Faça $n negociações no Mercado (vender ou comprar)';
  }

  @override
  String wqDailyDone(int n) {
    return 'Resgate $n recompensas de missões diárias';
  }

  @override
  String wqSpin(int n) {
    return 'Gire a roleta $n vezes';
  }

  @override
  String wqBuy(int n) {
    return 'Compre $n melhorias';
  }

  @override
  String get weeklyChestLabel =>
      'Baú semanal: conclua as 3 → +1 acessório Raro ou melhor';

  @override
  String weeklyResetsIn(String time) {
    return 'Reinicia em $time';
  }

  @override
  String get notifyOfflineFullTitle => 'Seu caixa está cheio! 🧋';

  @override
  String get notifyOfflineFullBody =>
      'A loja parou de acumular Moedas — venha recolher e abrir um novo turno.';

  @override
  String get notifyDailyTitle => 'Novo dia, novas missões 📋';

  @override
  String get notifyDailyBody =>
      'A recompensa diária, um giro grátis e 3 missões estão à espera.';

  @override
  String get notifyD3Title => 'Sua loja sente sua falta 🧋';

  @override
  String get notifyD3Body =>
      'Já se passaram 3 dias — o caixa está cheio há tempos, venha recolher.';

  @override
  String get notifyD7Title => 'Já faz uma semana! 🧋';

  @override
  String get notifyD7Body =>
      'Ascensão, Pérolas Caindo e muitas novidades estão à sua espera.';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 Evento: ×$mult de renda! Faltam $timeLeft';
  }

  @override
  String get navMatch3 => 'Jogos';

  @override
  String get m3Title => 'Pérolas Caindo';

  @override
  String m3Level(int n) {
    return 'Nível $n';
  }

  @override
  String get m3Locked => 'Bloqueado';

  @override
  String m3MovesLeft(int n) {
    return '$n jogadas restantes';
  }

  @override
  String get m3Score => 'Pontos';

  @override
  String get m3Win => 'Nível concluído!';

  @override
  String get m3Lose => 'Meta não alcançada';

  @override
  String get m3Retry => 'Tentar de novo';

  @override
  String get m3Next => 'Próximo nível';

  @override
  String get m3Back => 'Lista de níveis';

  @override
  String get m3Reward => 'Recompensa';

  @override
  String get m3NoReward => 'Você já recebeu a recompensa deste nível';

  @override
  String get m3LeaveTitle => 'Sair desta partida?';

  @override
  String get m3LeaveBody => 'Sua partida é mantida até você fechar o app.';

  @override
  String get m3LeaveStay => 'Continuar jogando';

  @override
  String get m3LeaveConfirm => 'Sair';

  @override
  String get accessoryHowToTitle => 'Guia de coleção';

  @override
  String get accessoryHowToButton => 'Guia';

  @override
  String get accessoryHtp1 =>
      '🎯 Objetivo: juntar todos os itens. Acessórios são só decorativos (não aumentam a renda), mas dá para exibi-los ao redor do copo, compartilhar e subir no ranking de Coleção.';

  @override
  String get accessoryHtp2 =>
      '🎁 Como obter: concluir as 3 missões diárias · passar das fases marco de Pérolas Caindo (10/30/60) · a casa de baú da roleta principal · a cada Ascensão · comprar Pacotes de acessórios com 💎.';

  @override
  String get accessoryHtp3 =>
      '🎰 Roleta de acessórios: cada giro custa ver um anúncio ou 💎. Giros por anúncio têm limite diário.';

  @override
  String get accessoryHtp4 =>
      '✨ Raridade: Comum → Raro → Épico → Lendário. Fins de semana e feriados aumentam a chance de Épico/Lendário; Pacotes Raro/Épico garantem raridade mínima; em feriados há um Pacote de Festival com itens exclusivos.';

  @override
  String accessoryHtp5(int gems) {
    return '♻️ Item repetido: você recebe $gems 💎 e 1 cópia extra para vender no Mercado.';
  }

  @override
  String get accessoryHtp6 =>
      '🏬 Mercado: venda cópias extras por Moedas de Mercado e compre o que falta de outros jogadores (taxa de 1%). Moedas de Mercado são compradas com Moedas ou 💎 e não podem ser convertidas de volta.';

  @override
  String get accessoryHtp7 =>
      '🏅 Marcos de coleção (10/25/40/50/80/100/120/140/160 itens) dão Moedas de Mercado. Adicione itens desejados à lista de desejos; o ranking conta itens distintos.';

  @override
  String get accessoryHtp8 =>
      '👆 Toque num item que você tem para exibi-lo ao redor do copo na tela principal.';

  @override
  String m3AdMoves(int n) {
    return 'Ver anúncio: +$n jogadas';
  }

  @override
  String get m3KeepPlaying => 'Continuar jogando';

  @override
  String get m3Pause => 'Fazer uma pausa';

  @override
  String get m3GoalReached => 'Meta alcançada!';

  @override
  String m3NeedScore(String n, int star) {
    return 'Faltam $n pontos para $star★';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return 'Faltam $n $icon para $star★';
  }

  @override
  String get m3HowToTitle => 'Como jogar Pérolas Caindo';

  @override
  String get m3HtpSwap =>
      '🔄 Troque duas peças VIZINHAS (toque numa e depois na outra, ou arraste) para alinhar 3 ou mais iguais. Trocas que não formam linha não contam.';

  @override
  String get m3HtpGoal =>
      '🎯 Cada nível tem um objetivo: atingir pontos ou juntar peças de um tipo. O objetivo aparece na barra do topo.';

  @override
  String get m3HtpMoves =>
      '👣 As jogadas são limitadas. Quando acabam o nível termina — prefira jogadas que limpem mais peças.';

  @override
  String get m3HtpChain =>
      '⛓️ Peças removidas fazem cair as de cima; se formarem nova linha há reação em cadeia, e os passos seguintes valem muito mais.';

  @override
  String get m3HtpSpecial =>
      '💥 Alinhe 4 para criar uma BOMBA EM CRUZ (limpa a linha e a coluna). Com 5 ou mais surge uma BOMBA DE COR 🌈 (limpa todas as peças daquele tipo). Combine-as como peças normais para detonar.';

  @override
  String get m3HtpStars =>
      '⭐ As três estrelas na barra são três níveis. Chegar à primeira já conclui o nível; toque em \"Continuar jogando\" para gastar as jogadas restantes e buscar mais estrelas.';

  @override
  String get m3HtpReward =>
      '🎁 A recompensa é paga só na PRIMEIRA vez que você alcança cada estrela. Repetir o nível não dá nada extra.';

  @override
  String get m3LbTitle => 'Ranking Pérolas Caindo';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty =>
      'Ainda não há ninguém. Conclua alguns níveis e o topo é seu!';

  @override
  String get m3LbNoStars =>
      'Você ainda não tem estrelas — conclua um nível para entrar no ranking.';

  @override
  String m3LbLevels(int n) {
    return '$n níveis';
  }

  @override
  String get m3LbError =>
      'Não foi possível carregar o ranking. Tente mais tarde.';

  @override
  String eventBanner(String name) {
    return '🎉 Evento de $name';
  }

  @override
  String eventTitle(String name) {
    return 'Evento de $name';
  }

  @override
  String eventEndsIn(String time) {
    return 'Termina em $time';
  }

  @override
  String eventPoints(int n) {
    return 'Pontos do evento: $n';
  }

  @override
  String get eventRedeemHint =>
      'Conclua missões para ganhar pontos e trocar itens exclusivos de graça. Os pontos não cobrem o conjunto todo — escolha os seus favoritos!';

  @override
  String eventRedeemCost(int cost) {
    return '$cost pts';
  }

  @override
  String get eventLbTitle => 'Ranking do evento';

  @override
  String get eventLbEmpty =>
      'Ninguém no ranking ainda. Alguns toques e você é o primeiro!';

  @override
  String get eventLbNoScore =>
      'Você ainda não tem pontos — toque no copo, pegue gatos e atenda VIPs para entrar.';

  @override
  String eventLbMyScore(int n) {
    return 'Sua pontuação: $n';
  }

  @override
  String eventLbScore(int n) {
    return '$n pts';
  }

  @override
  String eventBuff(String mult) {
    return 'Receita ×$mult durante o evento';
  }

  @override
  String get guildTitle => 'Guilda';

  @override
  String get guildIntro =>
      'Crie ou entre numa guilda para cumprir metas semanais juntos e ganhar recompensas.';

  @override
  String get guildCreate => 'Criar guilda';

  @override
  String get guildJoin => 'Entrar';

  @override
  String guildMembersCount(int n, int max) {
    return '$n/$max membros';
  }

  @override
  String guildWeekTotal(int n) {
    return 'Esta semana: $n pts';
  }

  @override
  String get guildNameLabel => 'Nome da guilda (3-20 caracteres)';

  @override
  String get guildTagLabel => 'Tag (2-4 letras/dígitos)';

  @override
  String get guildLeave => 'Sair da guilda';

  @override
  String get guildLeaveConfirm =>
      'Sair desta guilda? Seus pontos semanais deixarão de contar.';

  @override
  String get guildKick => 'Remover';

  @override
  String guildKickConfirm(String name) {
    return 'Remover $name da guilda?';
  }

  @override
  String get guildReport => 'Denunciar guilda';

  @override
  String get guildReportSent => 'Denúncia enviada, obrigado.';

  @override
  String get guildGoalTitle => 'Meta semanal';

  @override
  String get guildClaim => 'Resgatar';

  @override
  String get guildHowToTitle => 'Como ganhar pontos da Guilda';

  @override
  String guildHowTo(int n) {
    return '⭐ Os pontos da Guilda vêm da SUA atividade nesta semana: tocar num copo +1, pegar um gato +50, atender um cliente VIP +50.\n🎯 Os pontos de todos somam para liberar recompensas de marco; a semana reinicia na segunda 00:00 UTC.\n🎁 Você precisa contribuir com ≥$n pontos pessoais para resgatar uma recompensa de marco.';
  }

  @override
  String guildNeedPoints(int n) {
    return 'Contribua ≥$n pts para resgatar';
  }

  @override
  String guildYourPoints(int n) {
    return 'Sua contribuição: $n pts';
  }

  @override
  String get guildOwner => 'Líder';

  @override
  String get guildEmpty => 'Ainda não há guildas públicas. Crie a primeira!';

  @override
  String get guildErrNameTaken => 'Esse nome de guilda já existe.';

  @override
  String get guildErrFull => 'Esta guilda está cheia.';

  @override
  String guildExpandButton(int cost, int max) {
    return 'Ampliar para $max vagas · $cost 💎';
  }

  @override
  String guildExpandConfirm(int cost, int max) {
    return 'Ampliar a guilda para $max membros por $cost 💎?';
  }

  @override
  String get guildExpandAction => 'Ampliar';

  @override
  String guildExpandDone(int max) {
    return 'A guilda agora comporta até $max membros!';
  }

  @override
  String get guildExpandMaxed => 'A guilda já está na capacidade máxima.';

  @override
  String get guildErrAlready => 'Você já está numa guilda.';

  @override
  String get guildErrInvalid => 'Nome ou tag inválidos.';

  @override
  String get guildErrNotFound =>
      'Guilda não encontrada (pode ter sido encerrada).';

  @override
  String get guildErrContribution =>
      'Você precisa contribuir mais pontos esta semana.';

  @override
  String get guildErrNetwork => 'Não foi possível conectar, tente de novo.';

  @override
  String get guildLbTitle => 'Ranking de guildas';

  @override
  String get guildLbEmpty => 'Nenhuma guilda tem pontos esta semana.';

  @override
  String guildRewardGot(int gems) {
    return 'Recebeu +$gems 💎';
  }

  @override
  String guildRewardGotAccessory(int gems, String name) {
    return 'Recebeu +$gems 💎 e $name';
  }

  @override
  String guildPoints(int n) {
    return '$n pts';
  }

  @override
  String guildCreateCost(int n) {
    return 'Custo para criar guilda: $n 💎';
  }

  @override
  String guildErrGems(int n) {
    return 'Você precisa de $n 💎 para criar uma guilda.';
  }

  @override
  String get guildApprovalSwitch => 'O líder precisa aprovar os pedidos';

  @override
  String get guildRequestJoin => 'Solicitar';

  @override
  String get guildRequestSent =>
      'Pedido enviado, aguardando aprovação do líder.';

  @override
  String get guildRequestPending => 'Pendente';

  @override
  String guildRequestsTitle(int n) {
    return 'Pedidos de entrada ($n)';
  }

  @override
  String get guildAccept => 'Aprovar';

  @override
  String get guildReject => 'Recusar';

  @override
  String get guildErrApproval =>
      'Esta guilda precisa da aprovação do líder — toque em \"Solicitar\".';

  @override
  String get guildErrNicknameTaken =>
      'Já existe alguém com esse nome nesta guilda; escolha outro.';

  @override
  String get guildErrRequestsFull =>
      'Esta guilda tem pedidos pendentes demais.';

  @override
  String cloudSaveConflictGems(String local, String cloud) {
    return '💎 Este dispositivo: $local · Na nuvem: $cloud';
  }

  @override
  String get cloudRemindTitle => 'Proteja seu progresso';

  @override
  String get cloudRemindBody =>
      'Você ainda não vinculou um e-mail. Se trocar de celular ou reinstalar, seu progresso (moedas, 💎, acessórios, moedas do mercado) será PERDIDO. Vincular leva um minuto e é grátis.';

  @override
  String get cloudRemindLink => 'Vincular agora';

  @override
  String get cloudRemindLater => 'Depois';

  @override
  String get ftueTap => 'Toque no copo para preparar chá e ganhar moedas!';

  @override
  String get ftueBuy =>
      'Moedas suficientes! Compre seu primeiro upgrade para ganhar moedas a cada segundo.';

  @override
  String get ftueExplain =>
      'Ótimo! Suas moedas agora crescem a cada segundo, mesmo com o app fechado. Continue melhorando para ganhar mais rápido, liberar etapas e resgatar recompensas.';

  @override
  String get ftueOk => 'Entendi';

  @override
  String get ftueSkip => 'Pular';

  @override
  String get accessoryGuildFlag => 'Bandeira da guilda';

  @override
  String get accessoryGuildCastle => 'Castelo da guilda';

  @override
  String get accessoryGuildWolf => 'Lobo da guilda';

  @override
  String get accessoryGuildDragon => 'Dragão da guilda';

  @override
  String get accessoryGuildFox => 'Raposa da guilda';

  @override
  String get accessoryGuildTiger => 'Tigre da guilda';

  @override
  String get accessoryGuildShark => 'Tubarão da guilda';

  @override
  String get accessoryGuildTrex => 'T-Rex da guilda';

  @override
  String get accessoryGuildBoar => 'Javali da guilda';

  @override
  String get accessoryGuildBear => 'Urso da guilda';

  @override
  String get accessoryGuildScorpion => 'Escorpião da guilda';

  @override
  String get accessoryGuildMoai => 'Moai da guilda';

  @override
  String get guildChatTitle => 'Chat da guilda';

  @override
  String get guildChatEmpty =>
      'Nenhuma mensagem ainda. Seja o primeiro a falar!';

  @override
  String get guildChatHint => 'Mensagem para a guilda…';

  @override
  String get guildChatSend => 'Enviar';

  @override
  String get guildChatPinned => 'Aviso';

  @override
  String get guildChatPin => 'Fixar';

  @override
  String get guildChatUnpin => 'Desafixar';

  @override
  String get guildChatDelete => 'Apagar mensagem';

  @override
  String get guildChatReport => 'Denunciar mensagem';

  @override
  String get guildChatReported => 'Mensagem denunciada. Você não a verá mais.';

  @override
  String get guildMembersHeader => 'Membros';

  @override
  String get guildMemberSearchHint => 'Buscar membros';

  @override
  String get guildMemberNoMatch => 'Nenhum membro encontrado.';

  @override
  String get guildRoleOwner => 'Líder';

  @override
  String get guildRoleOfficer => 'Oficial';

  @override
  String get guildRoleMember => 'Membro';

  @override
  String get guildMemberMention => 'Mencionar no chat';

  @override
  String get guildMemberProfile => 'Ver perfil';

  @override
  String get guildQuestsSection => 'Missões da Guilda';

  @override
  String get guildQuestsSectionHint =>
      'Reiniciam toda segunda 00:00 UTC · dão Moedas da Guilda';

  @override
  String get guildManage => 'Gerenciar';

  @override
  String get guildPromote => 'Nomear oficial';

  @override
  String get guildDemote => 'Remover oficial';

  @override
  String get guildTransfer => 'Transferir liderança';

  @override
  String get guildTeamTitle => 'Missão de equipe da semana';

  @override
  String guildTeamProgress(int active, int need) {
    return '$active / $need membros concluíram';
  }

  @override
  String guildTeamHint(int n) {
    return 'Se metade da guilda (mínimo 2) chegar a $n pontos semanais, todos que chegaram recebem a recompensa. Joguem juntos!';
  }

  @override
  String guildTeamClaim(int n) {
    return 'Receber $n Moedas da Guilda';
  }

  @override
  String guildTeamGot(int n) {
    return 'Você recebeu $n Moedas da Guilda da missão de equipe!';
  }

  @override
  String get guildErrTeamNotReached =>
      'Ainda não há membros suficientes com esses pontos.';

  @override
  String guildErrTeamLow(int n) {
    return 'Você precisa de pelo menos $n pontos semanais para receber.';
  }

  @override
  String get guildFundTitle => 'Fundo da guilda desta semana';

  @override
  String guildFundMine(int n) {
    return 'Você contribuiu com $n 💎';
  }

  @override
  String guildFundClaim(int n) {
    return 'Receber $n Moedas da Guilda';
  }

  @override
  String guildFundHint(int min) {
    return 'Todos doam 💎 juntos para atingir a meta (cresce com o número de membros). Cada membro precisa doar pelo menos $min 💎 para receber a recompensa.';
  }

  @override
  String guildFundGot(int n) {
    return 'Você recebeu $n Moedas da Guilda do fundo!';
  }

  @override
  String get guildErrFundNotReached =>
      'O fundo da guilda ainda não atingiu a meta.';

  @override
  String guildErrFundLow(int n) {
    return 'Você precisa doar pelo menos $n 💎 ao fundo para receber a recompensa.';
  }

  @override
  String guildFundProgress(int progress, int target) {
    return '$progress / $target 💎';
  }

  @override
  String guildTransferConfirm(String name) {
    return 'Transferir a liderança para $name? Você se tornará um membro comum.';
  }

  @override
  String get guildErrNotAllowed => 'Você não tem permissão sobre este membro.';

  @override
  String guildErrOfficersFull(int n) {
    return 'A guilda já tem $n oficiais.';
  }

  @override
  String get guildActivityTitle => 'Registro da guilda';

  @override
  String get guildActivityEmpty => 'Nenhuma atividade ainda.';

  @override
  String guildEvJoined(String name) {
    return '$name entrou na guilda';
  }

  @override
  String guildEvLeft(String name) {
    return '$name saiu da guilda';
  }

  @override
  String guildEvKicked(String actor, String target) {
    return '$actor removeu $target da guilda';
  }

  @override
  String guildEvPromoted(String actor, String target) {
    return '$actor nomeou $target oficial';
  }

  @override
  String guildEvDemoted(String actor, String target) {
    return '$actor removeu $target do cargo de oficial';
  }

  @override
  String guildEvTransferred(String actor, String target) {
    return '$actor transferiu a liderança para $target';
  }

  @override
  String get guildErrChatRate =>
      'Você está enviando rápido demais, aguarde alguns segundos.';

  @override
  String get guildErrTextBlocked =>
      'Sua mensagem contém uma palavra bloqueada.';

  @override
  String guildErrDailyLimit(int n) {
    return 'Hoje você já doou o máximo de $n 💎.';
  }

  @override
  String get guildErrCoins => 'Moedas da guilda insuficientes.';

  @override
  String get guildErrOwned => 'Você já tem este item.';

  @override
  String get guildErrBuffMaxed =>
      'O bônus da guilda está no máximo, aguarde um pouco.';

  @override
  String get guildErrClaimed => 'Você já resgatou esta recompensa.';

  @override
  String get guildErrInvalidInput => 'Ação inválida.';

  @override
  String get guildShopButton => 'Loja da guilda';

  @override
  String get guildShopTitle => 'Loja da guilda';

  @override
  String guildCoinsLabel(int n) {
    return 'Moedas da guilda: $n';
  }

  @override
  String get guildDonateTitle => 'Doe 💎 por moedas da guilda';

  @override
  String guildDonateHint(int used, int cap) {
    return 'Hoje: $used/$cap 💎 · 1 💎 = 1 moeda da guilda';
  }

  @override
  String guildDonateGems(int n) {
    return '$n 💎';
  }

  @override
  String guildDonated(int n) {
    return 'Doado, você recebeu +$n moedas da guilda';
  }

  @override
  String get guildQuestsTitle => 'Missões semanais da guilda';

  @override
  String guildQuestProgress(int have, int need) {
    return 'Contribua $need pontos esta semana ($have/$need)';
  }

  @override
  String guildQuestReward(int n) {
    return '+$n moedas da guilda';
  }

  @override
  String guildQuestGot(int n) {
    return 'Recebeu +$n moedas da guilda';
  }

  @override
  String get guildItemsTitle => 'Acessórios exclusivos da guilda';

  @override
  String guildItemPrice(int n) {
    return '$n moedas';
  }

  @override
  String get guildItemOwned => 'Possui';

  @override
  String get guildItemBought => 'Trocado! O acessório está na sua coleção.';

  @override
  String get guildBuffTitle => 'Bônus de renda da guilda';

  @override
  String guildBuffDesc(int pct, int hours) {
    return '+$pct% de moedas por $hours horas para todos (não vale offline)';
  }

  @override
  String guildBuffLeft(String time) {
    return 'Restam $time';
  }

  @override
  String get guildBuffBought => 'Bônus da guilda ativado!';

  @override
  String guildStreakLine(int n) {
    return '🔥 $n semanas seguidas com as 3 metas';
  }

  @override
  String guildBuffLine(int pct, String time) {
    return '⚡ Bônus da guilda +$pct% · restam $time';
  }

  @override
  String get guildLbTabTotal => 'Total';

  @override
  String get guildLbTabAvg => 'Média';

  @override
  String get guildLbTabStreak => 'Sequência';

  @override
  String guildLbAvgNote(int n) {
    return 'Só guildas com $n+ membros entram no ranking';
  }

  @override
  String guildAvgPerMember(int n) {
    return '$n/membro';
  }

  @override
  String guildStreakWeeks(int n) {
    return '$n semanas';
  }

  @override
  String get guildLbStreakNote =>
      'Semanas seguidas em que a guilda atingiu as 3 metas';

  @override
  String get guildLbStreakEmpty => 'Nenhuma guilda tem sequência ainda.';

  @override
  String get guildLbAvgEmpty =>
      'Nenhuma guilda se qualifica para o ranking de média ainda.';

  @override
  String get recipeOrderOrders => 'Preparar pedidos';

  @override
  String recipeOrderAsk(String drink) {
    return 'O cliente pede: $drink';
  }

  @override
  String get recipeOrderGuideFull => 'Receita de exemplo';

  @override
  String get recipeOrderGuideNames =>
      'Ingredientes a usar (lembre as quantidades)';

  @override
  String recipeOrderGuideCount(int n) {
    return 'Esta bebida tem $n ingredientes — lembre-se deles!';
  }

  @override
  String get recipeOrderGuideNone => 'Sem dicas — prepare de memória!';

  @override
  String get recipeOrderTray =>
      'Bandeja de ingredientes — arraste para o copo ou toque para escolher';

  @override
  String get recipeOrderCupEmpty => 'O copo está vazio';

  @override
  String recipeOrderSetAmount(String name) {
    return 'Quantidade de $name';
  }

  @override
  String get recipeOrderPour => 'Pôr no copo';

  @override
  String get recipeOrderRemove => 'Remover';

  @override
  String get recipeOrderServe => 'Servir';

  @override
  String get recipeOrderPerfect => 'Perfeito! Todas as quantidades certas';

  @override
  String get recipeOrderGood => 'Aprovado — quantidades um pouco fora';

  @override
  String get recipeOrderFail => 'Não é a bebida certa';

  @override
  String recipeOrderMissing(String amount, String name) {
    return 'Falta $name ($amount)';
  }

  @override
  String recipeOrderExtra(String name) {
    return 'Sobrou $name — não está na receita';
  }

  @override
  String recipeOrderOff(String mine, String name, String right) {
    return '$name: você pôs $mine, o certo é $right';
  }

  @override
  String get recipeOrderHint =>
      'Dica: toque num ingrediente adicionado para mudar a quantidade';

  @override
  String get rlbTabQuiz => 'Quiz';

  @override
  String get rlbOrderEmpty =>
      'Ninguém está no ranking ainda. Seja o primeiro a preparar uma bebida perfeita sem a receita de exemplo!';

  @override
  String get rlbNoPerfect =>
      'Você ainda não preparou nenhuma bebida perfeita (sem a receita de exemplo), então não está no ranking.';

  @override
  String rlbPerfect(int n) {
    return '$n bebidas perfeitas';
  }

  @override
  String get recipeOrderHold => 'Segure para servir';

  @override
  String get recipeOrderPourAgain => 'Recomeçar';

  @override
  String recipeOrderCombo(int n) {
    return '🔥 Combo ×$n';
  }

  @override
  String recipeOrderComboTip(String cash, int combo) {
    return 'Combo ×$combo: gorjeta +$cash moedas!';
  }

  @override
  String get rlbTabDaily => 'Hoje';

  @override
  String get rlbDailyEmpty =>
      'Ninguém postou pontos hoje. Faça o desafio para ser o primeiro!';

  @override
  String get rlbNoDaily => 'Faça o desafio de hoje para aparecer no ranking.';

  @override
  String rlbDailyScore(Object n) {
    return '$n pts';
  }

  @override
  String get recipeDailyTitle => 'Desafio de hoje';

  @override
  String get recipeDailyOpen =>
      '3 pedidos difíceis, sem dicas — uma vez por dia';

  @override
  String recipeDailyDone(Object score) {
    return 'Hoje você fez $score/300';
  }

  @override
  String recipeDailyOrderScore(Object n) {
    return 'Este pedido: $n/100';
  }

  @override
  String recipeDailyTotal(Object n) {
    return '$n/300 pts';
  }

  @override
  String get recipeDailyAlready =>
      'Você já fez o desafio de hoje. Volte amanhã — pedidos novos todo dia!';

  @override
  String get recipeDailyBoard => 'Ver o ranking de hoje';

  @override
  String get recipeDailyIntro =>
      'Os mesmos pedidos para todos, sem dicas, com quantidades exatas. Uma tentativa por dia.';

  @override
  String get recipeOrderRush => 'Hora de pico';

  @override
  String get recipeOrderRushSub =>
      'Os clientes não esperam muito: sirva uma bebida perfeita a tempo e ganhe gorjeta extra. Se o tempo acabar, o copo é avaliado como está.';

  @override
  String get recipeOrderTimeUp =>
      '⏰ Tempo esgotado! O cliente foi embora e o copo é avaliado como está.';

  @override
  String recipeOrderRushTip(String cash) {
    return '⏱ Servido a tempo! Gorjeta +$cash moedas!';
  }

  @override
  String recipeOrderFestival(String name) {
    return 'Pedido do festival: $name';
  }

  @override
  String recipeOrderFestivalTip(String cash) {
    return '🎁 Pedido do festival perfeito! Gorjeta +$cash moedas!';
  }

  @override
  String get recipeOrderShare => 'Mostrar este copo';

  @override
  String get cupShareTitle => 'Copo perfeito';

  @override
  String get cupSharePerfect => 'Preparo perfeito!';

  @override
  String cupShareText(String name) {
    return 'Acabei de fazer um $name perfeito no Boba Empire! 🧋';
  }

  @override
  String recipeCounterNext(int count) {
    return 'Domine $count receitas para liberar mais 1 espaço de exibição';
  }

  @override
  String get lbrBoardOrders => 'Preparar pedidos';

  @override
  String get storySpeedrunTabExt3 => 'Ato 4';

  @override
  String get storySpeedrunExt3NotCompletedYet =>
      'Você ainda não concluiu o Ato 4 — conclua o Capítulo 46 para entrar no ranking.';

  @override
  String storyCondRecipes(int n, String game) {
    return 'Domine $n receitas em $game';
  }

  @override
  String storyCondOrders(int n, String game) {
    return 'Faça $n bebidas perfeitas em $game';
  }

  @override
  String storyCondDaily(int n, String game) {
    return 'Conclua $game em $n dias';
  }

  @override
  String get lbrBoardDaily => 'Desafio diário';

  @override
  String lbrDailyNote(int rest) {
    return 'Desafio diário: o top 10 pela pontuação TOTAL da semana passada também ganha: posições 1-3 como acima, posições 4-10 recebem $rest 💎.';
  }

  @override
  String get rlbDailyWeeklyHint =>
      'Toda semana o top 10 pela pontuação total do Desafio diário da semana inteira recebe 💎 (fecha no início da semana seguinte, UTC).';

  @override
  String get howToTooltip => 'Como jogar';

  @override
  String get howToRecipesTitle => 'Como jogar: Receitas';

  @override
  String get howToRecipes1 =>
      'Aprenda receitas com REVISÃO ESPAÇADA: todo dia o jogo escolhe as bebidas a revisar e você responde algumas perguntas.';

  @override
  String howToRecipes2(int a, int b, int c) {
    return 'Cada bebida tem 4 níveis: Nova → Conhecida → Aprendida → Dominada. Acertar sobe de nível e agenda a revisão em $a / $b / $c dias; errar desce um nível e volta logo.';
  }

  @override
  String get howToRecipes3 =>
      'As perguntas ficam mais difíceis com o nível: Nova completa o ingrediente que falta, Conhecida adivinha a quantidade, Aprendida/Dominada escolhe a receita completa certa.';

  @override
  String get howToRecipes4 =>
      'Revisar uma bebida que ainda não venceu é só treino: sem mudar de nível e sem recompensa. Você pode ver um anúncio para uma dica (essa pergunta não conta).';

  @override
  String get howToRecipes5 =>
      'Alcançar cada nível pela primeira vez dá moedas; o primeiro Dominada dá também 💎. Marcos de bebidas dominadas (5, 10, 20…) dão baús de acessórios.';

  @override
  String howToRecipes6(int n) {
    return 'Revise todo dia para manter a 🔥 sequência e ganhar 💎 em 3 / 7 / 14 / 30 dias; uma sequência quebrada pode ser salva com 💎. Aprenda $n bebidas de um grupo para liberar o próximo.';
  }

  @override
  String get howToOrdersTitle => 'Como jogar: Preparar pedidos';

  @override
  String get howToOrders1 =>
      'Um cliente pede uma bebida: arraste (ou toque) os ingredientes da bandeja para o copo e defina a quantidade.';

  @override
  String get howToOrders2 =>
      'Na folha de quantidade, toque na régua ou SEGURE o botão de despejar para aumentar; níveis baixos mostram marcas-guia.';

  @override
  String get howToOrders3 =>
      'Toque em Servir: o copo é fechado e sacudido, e cada ingrediente é avaliado: exato, a um passo, quantidade errada, faltando ou sobrando.';

  @override
  String get howToOrders4 =>
      'Quanto mais você conhece uma bebida, menos dicas: Nova mostra a receita de exemplo e uma marca verde, Conhecida só os nomes, Aprendida só quantos, Dominada nada. Nova/Conhecida aceitam um passo de erro; Aprendida/Dominada precisam ser exatas.';

  @override
  String get howToOrders5 =>
      'O resultado conta para o nível da bebida como uma resposta de quiz. Veja um anúncio para revelar a receita de exemplo (esse pedido não conta).';

  @override
  String get howToOrders6 =>
      'Faça vários pedidos perfeitos seguidos sem dicas para um combo 🔥 e gorjetas de moedas (só bebidas a revisar).';

  @override
  String get howToOrders7 =>
      'Ative ⏱ Hora de pico no primeiro pedido: os clientes não esperam muito. Sirva uma bebida perfeita a tempo para gorjeta extra; se o tempo acabar, o copo é avaliado como está.';

  @override
  String get howToOrders8 =>
      'Durante um festival aparece um pedido de festival extra no fim (gorjeta maior). Após uma bebida perfeita, toque em “Mostrar este copo” para compartilhar a imagem. Bebidas perfeitas sem receita de exemplo contam para o ranking.';

  @override
  String get howToDailyTitle => 'Como jogar: Desafio diário';

  @override
  String get howToDaily1 =>
      'Todo dia há 3 pedidos difíceis, IGUAIS para todos os jogadores do mundo.';

  @override
  String get howToDaily2 =>
      'Sem dicas, com muitos ingredientes de distração e cada quantidade precisa ser exata. Não altera o nível de nenhuma bebida.';

  @override
  String howToDaily3(int max) {
    return 'Cada pedido vale até 100 pontos (exato 1, a um passo metade, faltando 0, sobrando desconta). Total máximo: $max pontos.';
  }

  @override
  String howToDaily4(int gems) {
    return 'Apenas UMA tentativa por dia: ao terminar você ganha $gems 💎 e moedas conforme a pontuação; a pontuação enviada não pode ser alterada.';
  }

  @override
  String get howToDaily5 =>
      'A aba “Hoje” do ranking ordena as pontuações de hoje. Toda semana o top 10 pela pontuação TOTAL da semana recebe 💎 (requer vincular o e-mail).';
}
