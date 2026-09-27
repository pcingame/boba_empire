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
  String get htpNumberFormat =>
      '🔢 Números grandes usam sufixos: K=mil, M=milhão, B=bilhão, T=trilhão, depois aa, bb, cc... — cada nível é 1.000× o anterior.';

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
  String leaderboardStars(int stars) {
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
  String get navMatch3 => 'Match 3';

  @override
  String get m3Title => 'Jornada Match-3';

  @override
  String m3Level(int n) {
    return 'Nível $n';
  }

  @override
  String get m3Locked => 'Bloqueado';

  @override
  String m3Target(String n) {
    return 'Meta $n';
  }

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
  String m3Collect(String icon) {
    return 'Colete $icon';
  }

  @override
  String m3CollectShort(String icon) {
    return 'Junte $icon';
  }
}
