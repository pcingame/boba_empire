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
  String get rewardsTitle => 'Ganhe mais 🎁';

  @override
  String get rewardsChip => 'Ganhe mais';

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
  String get whatsNewCollection =>
      '🎀 Coleção: 50 acessórios, exiba ao redor do copo, emblemas no ranking, recompensas por marcos';

  @override
  String get whatsNewMarket =>
      '🛒 Mercado de acessórios: negocie com Moedas de Mercado, preço de referência, lista de desejos, aviso de venda';

  @override
  String get whatsNewWheel =>
      '🎡 A roleta tem baú de acessórios. Fim de semana: taxa 0% e mais itens raros';

  @override
  String get whatsNewStory => '📖 História Ato 3: 8 capítulos novos';

  @override
  String get whatsNewLook =>
      '🎨 Visual pastel, mais fluido, compartilhe a coleção em imagem';

  @override
  String get whatsNewLater => 'Depois';

  @override
  String get whatsNewOpen => 'Ver coleção';

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
  String get navMatch3 => 'Pérolas';

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
}
