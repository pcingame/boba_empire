// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Boba Empire';

  @override
  String get tapBrew => 'Toca para preparar';

  @override
  String get coinsSuffix => ' Monedas';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / seg';
  }

  @override
  String get instantCashButton => 'Dinero instantáneo';

  @override
  String instantCashSnack(String amount) {
    return '¡Dinero instantáneo! +$amount Monedas';
  }

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Desbloquear $cost Monedas';
  }

  @override
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount Monedas/seg por nivel';
  }

  @override
  String buyButton(String cost) {
    return '$cost Monedas';
  }

  @override
  String get buyModeMax => 'MAX';

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · ${seconds}s';
  }

  @override
  String vipSnack(String cash, int gems) {
    return '¡Cliente VIP! +$cash Monedas, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'Recibido +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'Anuncios eliminados. ¡Gracias!';

  @override
  String iapStarterSnack(String amount) {
    return 'Paquete inicial: +$amount 💎';
  }

  @override
  String get genTraDen => 'Té Negro';

  @override
  String get genTranChau => 'Perlas de Tapioca';

  @override
  String get genThach => 'Gelatina de Hierbas';

  @override
  String get genPudding => 'Pudín';

  @override
  String get genKemNuong => 'Té con Leche Crème Brûlée';

  @override
  String get genMatcha => 'Cubo de Matcha';

  @override
  String get stage1 => 'Carrito Callejero';

  @override
  String get stage2 => 'Quiosco Pequeño';

  @override
  String get stage3 => 'Cadena de Cafés de Lujo';

  @override
  String gemShopTitle(String gems) {
    return 'Tienda 💎 (tienes $gems)';
  }

  @override
  String get gemBoostName => 'Aumento de ingresos';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% de ingresos permanentes por nivel';
  }

  @override
  String get offlineCapName => 'Refrigerador sin conexión';

  @override
  String offlineCapDesc(int hours) {
    return '+${hours}h de límite sin conexión por nivel';
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
  String get gemInstantStageName => 'Desbloqueo de fase instantáneo';

  @override
  String gemInstantStageDesc(String stage) {
    return 'Desbloquea $stage ya, sin coste en Monedas';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return '¡$stage desbloqueada!';
  }

  @override
  String get gemTimeSkipName => 'Avanzar 💎';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Recibe ${hours}h de producción al instante';
  }

  @override
  String get iapSectionTitle => 'Comprar con dinero real';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get close => 'Cerrar';

  @override
  String get iapGemsDesc => 'Recarga Gemas para comprar objetos en la Tienda.';

  @override
  String get iapRemoveAdsTitle => 'Quitar anuncios';

  @override
  String get iapRemoveAdsDesc =>
      'Omite todos los anuncios: sigues recibiendo todas las recompensas, sin verlos.';

  @override
  String get iapStarterTitle => 'Paquete inicial';

  @override
  String get iapStarterDesc =>
      'Una vez: recibe una gran bolsa de Gemas al instante.';

  @override
  String get prestigeTitle => 'Franquicia 🏪';

  @override
  String prestigeIntro(int percent) {
    return 'Cada ⭐ Estrella da +$percent% de ingresos permanentes.';
  }

  @override
  String get prestigeStarsNow => 'Estrellas actuales';

  @override
  String prestigeStarsValue(int stars, int percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Franquiciar ahora';

  @override
  String prestigeGain(int stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Bono total después';

  @override
  String prestigeTotalValue(int percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Reinicia Monedas, niveles de mejora y fase (las mejoras de Estrellas pueden conservar algo).';

  @override
  String get cancel => 'Cancelar';

  @override
  String prestigeConfirm(int stars) {
    return 'Franquiciar (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Insuficiente';

  @override
  String prestigeSuccess(int stars) {
    return '¡Franquicia exitosa! +$stars ⭐';
  }

  @override
  String get offlineTitle => '¡Bienvenido de vuelta! 🧋';

  @override
  String offlineBody(String amount) {
    return 'La tienda siguió vendiendo mientras no estabas.\nGanaste $amount Monedas.';
  }

  @override
  String get offlineClaim => 'Reclamar';

  @override
  String get offlineDoubleButton => 'Ver anuncio ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return '¡Duplicado! +$amount Monedas';
  }

  @override
  String get howToPlayTitle => 'Cómo jugar';

  @override
  String get htpTap => '🧋 Toca el vaso para preparar té y ganar Monedas.';

  @override
  String get htpBuy =>
      '🛒 Compra mejoras para tener ingresos automáticos cada segundo.';

  @override
  String get htpStage =>
      '🏪 Junta Monedas para desbloquear nuevas etapas con bebidas mejores.';

  @override
  String get htpCat =>
      '🐱 Toca el gato de la suerte para una Lluvia Dorada ×3 breve.';

  @override
  String get htpVip => '🚗 Atiende al cliente VIP para ganar Gemas 💎.';

  @override
  String get htpGems => '💎 Gasta Gemas en la Tienda en mejoras permanentes.';

  @override
  String get htpPrestige =>
      '⭐ Franquicia para reiniciar y ganar Estrellas — un bono de ingresos permanente.';

  @override
  String get htpOffline =>
      '😴 La tienda sigue vendiendo mientras no estás — vuelve por el dinero sin conexión.';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get dailyTitle => 'Registro diario';

  @override
  String get dailyPrompt => '¡Reclama el regalo de hoy!';

  @override
  String get dailyClaim => 'Reclamar';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Racha de $days días 🔥';
  }

  @override
  String get achievementsTitle => 'Logros';

  @override
  String achEarn(String amount) {
    return 'Gana $amount Monedas en total';
  }

  @override
  String achStage(int n) {
    return 'Alcanza la etapa $n';
  }

  @override
  String achLevels(int n) {
    return 'Ten $n niveles de mejora en total';
  }

  @override
  String achPrestige(int n) {
    return 'Franquicia ($n★ o más)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 ¡Logro desbloqueado! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => 'Tienda de Estrellas ⭐';

  @override
  String prestigeShopSpendable(int stars) {
    return '$stars ⭐ para gastar';
  }

  @override
  String get prestigeIncomeName => 'Megaingresos';

  @override
  String prestigeIncomeDesc(int percent) {
    return '+$percent% de ingresos permanentes por nivel';
  }

  @override
  String get prestigeTapName => 'Megatoque';

  @override
  String prestigeTapDesc(int percent) {
    return '+$percent% de valor de toque por nivel';
  }

  @override
  String get prestigeOfflineName => 'Súper offline';

  @override
  String prestigeOfflineDesc(int percent) {
    return '+$percent% de ganancias ausente por nivel';
  }

  @override
  String get prestigeStartCashName => 'Capital inicial';

  @override
  String get prestigeStartCashDesc =>
      'Recibe Monedas justo tras Franquiciar (más por nivel)';

  @override
  String get prestigeKeepStageName => 'Conservar fase';

  @override
  String get prestigeKeepStageDesc =>
      'Conserva 1 fase más tras Franquiciar por nivel';

  @override
  String get prestigeDiscountName => 'Compra al por mayor';

  @override
  String prestigeDiscountDesc(int percent) {
    return '-$percent% coste de mejora por nivel';
  }

  @override
  String get prestigeAutoBuyName => 'Compra automática';

  @override
  String get prestigeAutoBuyDesc =>
      'Desbloquea un interruptor que compra la mejor fuente';

  @override
  String get autoBuyLabel => 'Auto';

  @override
  String prestigeStarCost(int cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return 'Toca para preparar $n veces';
  }

  @override
  String questBuy(int n) {
    return 'Compra $n mejoras';
  }

  @override
  String questRepeatEarn(String amount) {
    return 'Gana $amount Monedas más';
  }

  @override
  String get questClaim => 'Reclamar';

  @override
  String get iapDoubleTitle => 'x2 Ingresos (permanente)';

  @override
  String get iapDoubleDesc =>
      'Duplica todos los ingresos pasivos, para siempre';

  @override
  String get iapDoubleSnack => '¡x2 ingresos permanentes activado!';

  @override
  String get rewardsTitle => 'Gana más 🎁';

  @override
  String get rewardX2Name => 'x2 ingresos por 24h';

  @override
  String rewardX2Active(int hours) {
    return 'Activo · quedan ${hours}h';
  }

  @override
  String get rewardX2Snack => '¡x2 ingresos por 24h activado!';

  @override
  String rewardGemsName(int gems) {
    return 'Consigue $gems 💎';
  }

  @override
  String rewardTimeSkip(int hours) {
    return 'Avanzar ${hours}h';
  }

  @override
  String get watchAd => 'Ver anuncio';

  @override
  String get piggyName => 'Alcancía';

  @override
  String get piggyBreak => 'Romper';

  @override
  String piggySnack(String gems) {
    return 'Alcancía: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'Pase VIP (30 días) 👑';

  @override
  String get iapVipDesc =>
      'Sin anuncios + x2 ingresos + 50💎/día + límite offline+';

  @override
  String get iapVipSnack => '¡VIP activado por 30 días! 👑';

  @override
  String get genDuongDen => 'Leche con Azúcar Moreno';

  @override
  String get genBrulee => 'Té con Leche Brûlée';

  @override
  String get genCheeseFoam => 'Espuma de Queso';

  @override
  String get genTraTraiCay => 'Té de Frutas';

  @override
  String get genBobaVang => 'Boba Dorada';

  @override
  String get genGalaxy => 'Té con Leche Galaxia';

  @override
  String get stage4 => 'Taller Brûlée';

  @override
  String get stage5 => 'Fábrica de Espuma de Queso';

  @override
  String get stage6 => 'Imperio Global';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSound => 'Sonido';

  @override
  String get settingsReset => 'Reiniciar juego';

  @override
  String get settingsResetConfirm =>
      '¿Borrar todo el progreso y empezar de nuevo?';

  @override
  String get navHome => 'Inicio';

  @override
  String get navShop => 'Tienda';

  @override
  String get navPrestige => 'Prestigio';

  @override
  String get navAchievements => 'Logros';

  @override
  String get wheelName => 'Ruleta de la suerte 🎡';

  @override
  String get spinFree => 'Giro gratis';

  @override
  String get spinAd => 'Ver anuncio para girar';

  @override
  String storyChapterLabel(int n) {
    return 'Capítulo $n';
  }

  @override
  String get storyContinue => 'Continuar';

  @override
  String get storyChoosePrompt => 'Elige tu camino — no se puede deshacer:';

  @override
  String get storyLogTitle => 'Historia';

  @override
  String get storyLogLocked => 'Aún no desbloqueado';

  @override
  String get rivalEventTitle => '¡El rival ataca!';

  @override
  String get rivalEventIgnore => 'Ignorar';

  @override
  String get rivalMeterAhead => 'Por delante';

  @override
  String get rivalMeterEven => 'Cara a cara';

  @override
  String get rivalMeterBehind => 'Perdiendo terreno';

  @override
  String get rivalResolvedSnack => 'Resuelto. El rival retrocede.';

  @override
  String get rivalIgnoredSnack => 'Lo dejas pasar — el rival gana terreno.';

  @override
  String get navArena => 'Arena';

  @override
  String get arenaTitle => 'Arena';

  @override
  String get arenaIntro =>
      'Duelo 1v1 de 60 segundos — ¡gana quien consiga más Monedas!';

  @override
  String get arenaStartButton => 'Buscar rival';

  @override
  String get arenaQueueWaiting => 'Buscando rival…';

  @override
  String get arenaCancelButton => 'Cancelar';

  @override
  String get arenaTapButton => 'Toca el vaso';

  @override
  String get arenaResolving => 'Cerrando la partida…';

  @override
  String arenaTierButton(String cost) {
    return 'Mejorar ×2 ($cost Monedas)';
  }

  @override
  String arenaTimeLeft(int seconds) {
    return 'Quedan ${seconds}s';
  }

  @override
  String get arenaYourScore => 'Tu puntuación';

  @override
  String get arenaOpponentScore => 'Rival';

  @override
  String get arenaResultWin => '¡Ganaste! 🎉';

  @override
  String get arenaResultLose => 'Perdiste';

  @override
  String get arenaResultDraw => 'Empate';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => 'Cerrar';

  @override
  String get cloudSaveMenuTitle => 'Guardado en la nube';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'Vinculado: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'Sin vincular — podrías perder tu progreso si desinstalas';

  @override
  String get cloudSaveTitle => 'Guardado en la nube';

  @override
  String get cloudSaveIntro =>
      'Vincula un email para recuperar tu progreso si desinstalas o cambias de dispositivo.';

  @override
  String get cloudSaveEmailHint => 'Tu email';

  @override
  String get cloudSaveSendCode => 'Enviar código';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'Código de 6 dígitos enviado a $email';
  }

  @override
  String get cloudSaveCodeHint => 'Código de 6 dígitos';

  @override
  String get cloudSaveVerify => 'Verificar';

  @override
  String get cloudSaveChangeEmail => 'Usar otro email';

  @override
  String get cloudSaveConflictTitle => 'Se encontró otro guardado en la nube';

  @override
  String cloudSaveConflictLocal(String amount) {
    return 'Este dispositivo: $amount Monedas de por vida';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return 'En la nube: $amount Monedas de por vida';
  }

  @override
  String get cloudSaveRestoreButton => 'Restaurar desde la nube';

  @override
  String get cloudSaveKeepLocalButton => 'Conservar este dispositivo';

  @override
  String cloudSaveLinkedStatus(String email) {
    return 'Vinculado: $email';
  }

  @override
  String get cloudSaveDisconnect => 'Desvincular';

  @override
  String get cloudSaveRetry => 'Reintentar';
}
