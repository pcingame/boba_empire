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
  String get adNotReadySnack =>
      'El anuncio aún no está listo, inténtalo de nuevo en un momento';

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
  String get gemTimeSkipName => 'Avanzar';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Recibe ${hours}h de producción al instante';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return 'Quedan $remaining/$max hoy';
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
  String prestigeIntro(String percent) {
    return 'Cada ⭐ Estrella da +$percent% de ingresos permanentes.';
  }

  @override
  String get prestigeStarsNow => 'Estrellas actuales';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Franquiciar ahora';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Bono total después';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Reinicia Monedas, niveles de mejora y fase (las mejoras de Estrellas pueden conservar algo).';

  @override
  String get cancel => 'Cancelar';

  @override
  String prestigeConfirm(String stars) {
    return 'Franquiciar (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Insuficiente';

  @override
  String get prestigeAdConfirm => 'Ver anuncio: monedas iniciales extra';

  @override
  String prestigeSuccess(String stars) {
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
  String get htpTap => 'Toca el vaso para preparar té y ganar Monedas.';

  @override
  String get htpBuy =>
      'Compra mejoras para tener ingresos automáticos cada segundo.';

  @override
  String get htpStage =>
      'Junta Monedas para desbloquear nuevas etapas con bebidas mejores.';

  @override
  String get htpCat =>
      'Toca el gato de la suerte para una Lluvia Dorada ×3 breve.';

  @override
  String get htpVip => 'Atiende al cliente VIP para ganar Gemas 💎.';

  @override
  String get htpGems => 'Gasta Gemas en la Tienda en mejoras permanentes.';

  @override
  String get htpPrestige =>
      'Franquicia para reiniciar y ganar Estrellas — un bono de ingresos permanente.';

  @override
  String get htpOffline =>
      'La tienda sigue vendiendo mientras no estás — vuelve por el dinero sin conexión.';

  @override
  String get htpNumberFormat =>
      'Los números grandes usan sufijos: K=mil, M=millón, B=mil millones, T=billón, luego aa, bb, cc... — cada paso es 1.000× el anterior.';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get dailyTitle => 'Registro diario';

  @override
  String get dailyPrompt => '¡Reclama el regalo de hoy!';

  @override
  String get adNotReady =>
      'El anuncio aún no está listo, inténtalo de nuevo en unos segundos.';

  @override
  String get accessoryBat => 'Murciélago nocturno';

  @override
  String get accessoryJackOLantern => 'Calabaza de Halloween';

  @override
  String get accessoryGhost => 'Fantasma amistoso';

  @override
  String get accessoryWitch => 'Brujita';

  @override
  String get accessorySnowman => 'Muñeco de nieve';

  @override
  String get accessoryChristmasTree => 'Árbol de Navidad';

  @override
  String get accessoryReindeer => 'Reno';

  @override
  String get accessorySanta => 'Papá Noel';

  @override
  String get accessoryFirecracker => 'Petardo';

  @override
  String get accessoryRedEnvelope => 'Sobre rojo';

  @override
  String get accessoryApricotBlossom => 'Flor de albaricoque';

  @override
  String get accessoryGoldenGoat => 'Cabra dorada';

  @override
  String get festivalHalloween => 'Halloween';

  @override
  String get festivalChristmas => 'Navidad';

  @override
  String get festivalTet => 'Año Nuevo Lunar';

  @override
  String get festivalSection => 'Accesorios de festividades (exclusivos)';

  @override
  String festivalPackTitle(String name) {
    return 'Paquete de $name';
  }

  @override
  String festivalPackDesc(int gems) {
    return 'Cada paquete da 1 objeto exclusivo que aún no tienes, solo durante el evento. Si ya los tienes todos, recibes $gems 💎. No se puede intercambiar.';
  }

  @override
  String get accessoryChampagne => 'Brindis de champán';

  @override
  String get accessoryPartyPopper => 'Cañón de confeti';

  @override
  String get accessoryFireworks => 'Fuegos artificiales';

  @override
  String get accessoryGoldenSparkler => 'Bengala dorada';

  @override
  String get accessoryLoveLetter => 'Carta de amor';

  @override
  String get accessoryRose => 'Rosa roja';

  @override
  String get accessoryChocolate => 'Chocolate';

  @override
  String get accessoryCupidArrow => 'Flecha de Cupido';

  @override
  String get accessoryTulip => 'Tulipán';

  @override
  String get accessoryBouquet => 'Ramo de flores';

  @override
  String get accessoryLipstick => 'Pintalabios';

  @override
  String get accessoryPrincess => 'Princesa';

  @override
  String get accessoryMooncake => 'Pastel de luna';

  @override
  String get accessoryRabbit => 'Conejo lunar';

  @override
  String get accessoryFullMoon => 'Luna llena';

  @override
  String get accessoryLionDance => 'Danza del león';

  @override
  String get festivalNewYear => 'Año Nuevo';

  @override
  String get festivalValentine => 'San Valentín';

  @override
  String get festivalWomensDay => 'Día de la Mujer';

  @override
  String get festivalMidAutumn => 'Festival de Medio Otoño';

  @override
  String get dailyClaim => 'Reclamar';

  @override
  String get accessoryWheelTitle => 'Ruleta de accesorios';

  @override
  String accessoryWheelAd(int n) {
    return 'Girar: ver anuncio ($n restantes)';
  }

  @override
  String accessoryWheelGems(int gems) {
    return 'Girar $gems 💎';
  }

  @override
  String get accessoryPackButton => 'Paquetes de accesorios';

  @override
  String get accessoryPackTitle => 'Paquetes de accesorios';

  @override
  String get accessoryPackBasic => 'Paquete Básico';

  @override
  String get accessoryPackRare => 'Paquete Raro (Raro o mejor)';

  @override
  String get accessoryPackEpic => 'Paquete Épico (Épico o mejor)';

  @override
  String get accessoryPackSeason =>
      '¡Evento de temporada: 25% de descuento y probabilidad Épico/Legendario ×2!';

  @override
  String get accessoryAdDropButton => 'Ver anuncio: +1 accesorio';

  @override
  String dailyStreakAtRisk(int days) {
    return 'Te saltaste un día: ¡tu racha de $days días está a punto de perderse!';
  }

  @override
  String dailyRestoreGems(int gems) {
    return 'Salvar racha ($gems 💎)';
  }

  @override
  String get dailyRestoreAd => 'Ver un anuncio para salvar la racha';

  @override
  String get dailySkipRestore => 'Omitir y empezar de nuevo';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Racha de $days días 🔥';
  }

  @override
  String dailyMilestoneBonus(String gems) {
    return 'Bono por hito de racha: +$gems 💎';
  }

  @override
  String dailyVipBonus(int percent) {
    return 'Bono VIP: +$percent% 💎';
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
  String prestigeShopSpendable(String stars) {
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
  String prestigeStarCost(String cost) {
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
  String get iapColdStorageTitle => 'Cámara fría (permanente)';

  @override
  String iapColdStorageDesc(Object hours) {
    return 'Suma $hours horas al límite de ganancias sin conexión, para siempre';
  }

  @override
  String iapColdStorageSnack(Object hours) {
    return '¡Límite sin conexión aumentado en $hours horas!';
  }

  @override
  String get iapComboTitle => 'Combo: Sin anuncios + x2 ingresos';

  @override
  String get iapComboDesc =>
      'Quita todos los anuncios y duplica los ingresos pasivos para siempre, más barato que por separado';

  @override
  String get iapComboSnack =>
      '¡Anuncios eliminados y x2 ingresos permanente activado!';

  @override
  String get topupTitle => 'Recompensas de recarga y VIP';

  @override
  String get topupOpen => '👑 Recarga y VIP';

  @override
  String topupSummary(Object points) {
    return '$points EXP VIP';
  }

  @override
  String topupBuff(Object now, Object percent) {
    return 'Cada nivel VIP: +$percent% de ingresos (ahora +$now%)';
  }

  @override
  String get topupNote =>
      'Compras en la tienda: ~100 EXP por USD (los paquetes grandes dan más). Comprar EXP con 💎 cuesta mucho más y tiene límite. Cada recompensa se reclama una vez.';

  @override
  String topupTier(Object points) {
    return '$points EXP';
  }

  @override
  String get topupAccessory => '+ accesorio';

  @override
  String get topupClaim => 'Reclamar';

  @override
  String get topupClaimed => 'Reclamado';

  @override
  String topupClaimSnack(Object gems) {
    return '¡Reclamado +$gems 💎!';
  }

  @override
  String get vipName1 => 'Cliente fiel';

  @override
  String get vipName2 => 'Amante del té';

  @override
  String get vipName3 => 'Sibarita del té';

  @override
  String get vipName4 => 'Invitado de honor';

  @override
  String get vipName5 => 'Dueño de tienda';

  @override
  String get vipName6 => 'Multimillonario del boba';

  @override
  String get vipName7 => 'Magnate';

  @override
  String get vipName8 => 'Realeza';

  @override
  String get vipName9 => 'Leyenda';

  @override
  String get vipName10 => 'Emperador del boba';

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
    return 'La EXP comprada con 💎 llegó al límite ($cap). Los niveles altos requieren recargas reales.';
  }

  @override
  String get vipBenefitsTitle => 'Beneficios VIP';

  @override
  String get vipBenefitsLocked =>
      'Alcanza VIP 1 para desbloquear regalos diarios/semanales/mensuales.';

  @override
  String get vipDaily => 'Diario';

  @override
  String get vipWeekly => 'Semanal';

  @override
  String get vipMonthly => 'Mensual';

  @override
  String get vipHowToTitle => 'Guía VIP';

  @override
  String get vipHtp1 =>
      '👑 VIP tiene 10 niveles, cada uno con un título. Tu nivel aparece como etiqueta \"VIP n\" junto a tu nombre en las clasificaciones y en tu Gremio. Desde VIP 5, tu nombre muestra una línea de título en todas las clasificaciones, un punto verde mientras estés en línea y todos ven un banner cuando te conectas.';

  @override
  String vipHtp2(Object cap, Object exp, Object gems) {
    return '⭐ EXP VIP: compras con dinero real en la tienda (~100 EXP por USD, los paquetes grandes de 💎 dan extra) o cómprala con 💎 ($gems 💎 → $exp EXP, hasta $cap EXP; por eso VIP 7–10 requieren recargas reales).';
  }

  @override
  String vipHtp3(Object percent) {
    return '📈 Ventajas: +$percent% de ingresos pasivos por nivel (permanente) y una recompensa única por cada nivel (💎, y un accesorio en algunos).';
  }

  @override
  String get vipHtp4 =>
      '🎁 Regalos diarios / semanales / mensuales: los 💎 crecen con tu nivel; los semanales y mensuales añaden un accesorio. Se reinician a las 00:00 UTC (las semanas empiezan el lunes, los meses según el calendario).';

  @override
  String get vipHtp5 =>
      '♻️ No es el Pase VIP de 30 días: el Pase VIP (sin anuncios, x2 ingresos…) es temporal; este nivel VIP nunca caduca y ambos se acumulan.';

  @override
  String get vipHtp6 => '📍 Ábrelo en la Tienda 💎 → botón 👑.';

  @override
  String get vipLbTitle => 'Clasificación VIP';

  @override
  String get vipLbEmpty => 'Aún no hay nadie en la clasificación VIP.';

  @override
  String get vipLbNoVip =>
      'Alcanza VIP 1 para aparecer en la clasificación VIP.';

  @override
  String vipLbExp(Object exp) {
    return '$exp EXP';
  }

  @override
  String vipOnlineBanner(Object nickname, Object title) {
    return '👑 ¡$title $nickname acaba de conectarse!';
  }

  @override
  String get emailGateTitle => 'Vincula tu correo para recargar';

  @override
  String get emailGateBody =>
      'Las compras se asocian a tu cuenta para poder recuperarlas si cambias de teléfono o algo falla. Vincula primero un correo (gratis, tarda un minuto).';

  @override
  String get emailGateOnlineTitle => 'Vincula tu correo para jugar en línea';

  @override
  String get emailGateOnlineBody =>
      'Los gremios, el Mercado, la Arena y las clasificaciones requieren una cuenta vinculada a un correo, para que tus datos estén a salvo y se puedan recuperar si cambias de móvil o reinstalas. Es gratis y toma un minuto.';

  @override
  String get emailGateLink => 'Vincular correo';

  @override
  String iapGemsFirstSnack(Object amount) {
    return '¡Recibiste +$amount 💎 — bono doble de primera compra!';
  }

  @override
  String get iapFirstBuyNote => '🎉 Primera compra: ¡doble 💎!';

  @override
  String get guildGiftTooltip => 'Regalar 💎';

  @override
  String guildGiftTitle(Object nickname) {
    return 'Regalar 💎 a $nickname';
  }

  @override
  String guildGiftHint(Object cap, Object days) {
    return 'Hasta $cap 💎 al día. El destinatario tiene $days días para reclamarlo.';
  }

  @override
  String guildGiftSent(Object amount, Object nickname) {
    return 'Enviaste $amount 💎 a $nickname';
  }

  @override
  String guildGiftInboxTitle(Object count) {
    return '🎁 Regalos del gremio ($count)';
  }

  @override
  String guildGiftFrom(Object amount, Object nickname) {
    return '$nickname · +$amount 💎';
  }

  @override
  String guildGiftClaimed(Object amount) {
    return 'Reclamaste +$amount 💎';
  }

  @override
  String guildErrGiftLimit(Object receive, Object send) {
    return 'Límite de regalos alcanzado hoy (puedes enviar hasta $send 💎/día; una persona puede recibir hasta $receive 💎/día).';
  }

  @override
  String get vipTitlePick => 'Título bajo tu nombre';

  @override
  String get vipTitleAuto => 'Auto (el más alto)';

  @override
  String get vipTitleHide => 'Ocultar';

  @override
  String get marketFilterWish => 'Deseos';

  @override
  String get guildErrGemsSpend => 'No tienes suficientes 💎.';

  @override
  String guildCreateVipDiscount(Object percent) {
    return 'Ventaja VIP: $percent% de descuento en la creación de gremio';
  }

  @override
  String get guildLbTabVip => 'VIP';

  @override
  String get guildLbVipEmpty =>
      'Aún ningún gremio tiene miembros VIP en la clasificación.';

  @override
  String get guildLbVipNote =>
      'EXP VIP total de los miembros (solo cuentan quienes tienen apodo).';

  @override
  String guildVipExpTotal(Object exp) {
    return '$exp EXP';
  }

  @override
  String guildVipBonusLine(Object members, Object pct) {
    return 'Bono VIP: $members miembros VIP → +$pct% de ingresos para todo el gremio';
  }

  @override
  String guildVipBonusHint(Object cap, Object level, Object per) {
    return 'Cada miembro con VIP $level+ suma +$per% de ingresos a todo el gremio (máx. +$cap%)';
  }

  @override
  String get reminderVipTitle => '👑 Tu regalo VIP te espera';

  @override
  String get reminderVipDailyBody =>
      'Tu regalo VIP diario, la asistencia y las misiones ya están listos, ¡ven a reclamarlos!';

  @override
  String get reminderVipWeeklyBody =>
      '¡Tu regalo VIP semanal (con un accesorio) está listo!';

  @override
  String get reminderVipMonthlyBody =>
      '¡Llegó tu regalo VIP mensual, uno grande te espera!';

  @override
  String get reminderVipUnclaimedBody =>
      'Aún tienes regalos VIP sin reclamar hoy.';

  @override
  String get dealTitle => 'Oferta de hoy';

  @override
  String dealResets(Object time) {
    return 'Cambia a las 00:00 UTC · quedan $time';
  }

  @override
  String get dealClaimed => 'Comprada hoy: vuelve mañana';

  @override
  String dealGotAccessory(Object name) {
    return '¡Obtuviste $name!';
  }

  @override
  String get dealUnavailable => 'Esta oferta no se puede comprar ahora.';

  @override
  String get guildBossTitle => 'Jefe semanal del gremio';

  @override
  String guildBossTier(Object tier) {
    return 'Nivel $tier';
  }

  @override
  String guildBossProgress(Object damage, Object hp) {
    return '$damage / $hp de daño';
  }

  @override
  String guildBossClaim(Object coins, Object gems) {
    return 'Reclamar cofre: +$gems 💎 +$coins Monedas del Gremio';
  }

  @override
  String get guildBossClaimedLabel => 'Cofre reclamado';

  @override
  String guildBossClaimedSnack(Object coins, Object gems) {
    return 'Cofre del jefe: +$gems 💎 +$coins Monedas del Gremio';
  }

  @override
  String get guildBossErrAlive => 'El jefe sigue vivo.';

  @override
  String get guildBossName1 => 'Dragón de Perlas';

  @override
  String get guildBossName2 => 'Titán de Hielo Raspado';

  @override
  String get guildBossName3 => 'Kraken de Té Negro';

  @override
  String get guildBossName4 => 'Oso Pudín';

  @override
  String get guildBossName5 => 'Tigre Matcha';

  @override
  String get guildBossName6 => 'Fénix de Espuma de Queso';

  @override
  String get accessoryVipWatch => 'Reloj de lujo';

  @override
  String get accessoryVipLuggage => 'Equipaje de lujo';

  @override
  String get accessoryVipBriefcase => 'Maletín ejecutivo';

  @override
  String get accessoryVipTophat => 'Sombrero de copa';

  @override
  String get accessoryVipRacecar => 'Superdeportivo';

  @override
  String get accessoryVipHeli => 'Helicóptero';

  @override
  String get accessoryVipYacht => 'Yate';

  @override
  String get accessoryVipJet => 'Jet privado';

  @override
  String get vipShopOpen => '🛍️ Tienda VIP';

  @override
  String get vipShopTitle => 'Tienda VIP';

  @override
  String vipCoinsLabel(Object n) {
    return 'Monedas VIP: $n';
  }

  @override
  String vipShopLocked(Object level) {
    return 'Requiere VIP $level';
  }

  @override
  String get vipShopOwned => 'Obtenido';

  @override
  String get vipShopNeedCoins => 'Monedas VIP insuficientes';

  @override
  String vipShopBoughtSnack(Object name) {
    return '¡Obtuviste $name!';
  }

  @override
  String get vipShopHint =>
      'Gana Monedas VIP reclamando tus regalos VIP diarios, semanales y mensuales.';

  @override
  String vipBenefitSnack(Object coins, Object gems) {
    return 'Reclamaste +$gems 💎 +$coins Monedas VIP';
  }

  @override
  String get vipItemsTitle => 'Exclusivos VIP';

  @override
  String vipShopPrice(Object n) {
    return '$n Monedas VIP';
  }

  @override
  String get vipEntryHint =>
      'Recarga para desbloquear regalos VIP diarios, semanales y mensuales';

  @override
  String get settingsWebsite => 'Sitio web';

  @override
  String get settingsWebGuide => 'Guía de juego (web)';

  @override
  String get guideOnWeb => 'Guía completa en la web';

  @override
  String get webOpenFailed =>
      'No se pudo abrir el sitio web. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get webBoardOpenTip => 'Ver esta clasificación en la web';

  @override
  String get webBoardShareTip => 'Compartir enlace de la clasificación';

  @override
  String webBoardShareText(Object url) {
    return 'Mira la clasificación de Boba Empire: $url';
  }

  @override
  String get settingsShareProfile => 'Compartir mi perfil de clasificación';

  @override
  String profileShareText(String name, String url) {
    return 'Mira las posiciones de $name en Boba Empire: $url';
  }

  @override
  String profileTitle(String name) {
    return 'Perfil: $name';
  }

  @override
  String get profileBoardIncome => 'Ingresos';

  @override
  String get profileBoardPearls => 'Perlas';

  @override
  String get profileBoardCollection => 'Colección';

  @override
  String get profileBoardSpeed => 'Speedrun de historia';

  @override
  String get profileBoardVip => 'VIP';

  @override
  String get profileNoRanks => 'Aún no está en ninguna clasificación.';

  @override
  String get profileViewButton => 'Perfil';

  @override
  String get profileOpenWeb => 'Ver en la web';

  @override
  String get refEntry => '👥 Invitar amigos';

  @override
  String refEntryNote(Object gems) {
    return 'Gana $gems 💎 por cada amigo que se una';
  }

  @override
  String get refTitle => 'Invitar amigos';

  @override
  String get refYourCode => 'Tu código de invitación';

  @override
  String get refCopy => 'Copiar código';

  @override
  String get refCopied => 'Código copiado';

  @override
  String get refShare => 'Compartir';

  @override
  String refShareText(Object code) {
    return '¡Juega Boba Empire conmigo! Usa mi código $code para ganar 💎 extra: https://bobaempiregame.com';
  }

  @override
  String refStats(Object invited, Object max, Object reached) {
    return 'Invitados: $invited/$max · llegaron a la meta: $reached';
  }

  @override
  String refRule(Object gems, Object stage) {
    return 'Ganas $gems 💎 por cada amigo que llegue a la etapa $stage. Tu amigo también recibe 💎 al ingresar tu código.';
  }

  @override
  String refClaim(Object gems) {
    return 'Reclamar +$gems 💎';
  }

  @override
  String refClaimedSnack(Object gems) {
    return 'Reclamaste +$gems 💎';
  }

  @override
  String get refEnterTitle => '¿Tienes el código de un amigo?';

  @override
  String get refEnterHint => 'Código de invitación';

  @override
  String get refRedeem => 'Canjear';

  @override
  String refRedeemedSnack(Object gems) {
    return 'Código aceptado: +$gems 💎';
  }

  @override
  String get refErrEmail => 'Vincula primero tu correo.';

  @override
  String get refErrNotFound => 'Código no encontrado.';

  @override
  String get refErrInvalid => 'No puedes usar este código.';

  @override
  String get refErrAlready => 'Ya usaste un código de invitación.';

  @override
  String get refErrFull => 'Este código alcanzó su límite de invitaciones.';

  @override
  String get refErrNothing => 'Aún no hay nada que reclamar.';

  @override
  String get refErrNetwork => 'Problema de red, inténtalo de nuevo.';

  @override
  String get vipLbOpen => 'Clasificación VIP';

  @override
  String get rewardsTitle => 'Gana más 🎁';

  @override
  String get rewardsChip => 'Gana más';

  @override
  String rewardAutoTapName(int m) {
    return 'Toque automático $m min';
  }

  @override
  String rewardAutoTapActive(String t) {
    return 'Activo · quedan $t';
  }

  @override
  String rewardAutoTapVip(int n) {
    return 'VIP $n+ tiene toque automático permanente';
  }

  @override
  String rewardAutoTapHint(int n) {
    return 'Mira un anuncio para tocar el vaso solo (VIP $n+ lo desbloquea para siempre)';
  }

  @override
  String get rewardAutoTapSnack =>
      '¡Toque automático activado! Solo da monedas, sin puntos de Gremio ni misiones.';

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
  String get genQuantumTea => 'Té con Leche Cuántico';

  @override
  String get genAiTea => 'Té con Leche IA';

  @override
  String get genParallelTea => 'Té con Leche Universo Paralelo';

  @override
  String get genNftTea => 'Té con Leche NFT';

  @override
  String get genTimeTea => 'Té con Leche Viaje en el Tiempo';

  @override
  String get genMultidimTea => 'Té con Leche Multidimensional';

  @override
  String get genBlackholeTea => 'Té con Leche Agujero Negro';

  @override
  String get genLightTea => 'Té con Leche Velocidad de la Luz';

  @override
  String get genRobotTea => 'Té con Leche Robot';

  @override
  String get genHologramTea => 'Té con Leche Holograma';

  @override
  String get genLegendTea => 'Té con Leche Legendario';

  @override
  String get genEternalTea => 'Té con Leche Eterno';

  @override
  String get stage4 => 'Taller Brûlée';

  @override
  String get stage5 => 'Fábrica de Espuma de Queso';

  @override
  String get stage6 => 'Imperio Global';

  @override
  String get stage7 => 'Salida a Bolsa';

  @override
  String get stage8 => 'Conglomerado';

  @override
  String get stage9 => 'Fondo de Inversión Global';

  @override
  String get stage10 => 'Cadena de Suministro Agrícola';

  @override
  String get stage11 => 'Imperio Tecnológico IA';

  @override
  String get stage12 => 'Leyenda del Té con Leche';

  @override
  String get stage13 => 'Academia del Té con Leche';

  @override
  String get stage14 => 'Ciudad del Té con Leche';

  @override
  String get stage15 => 'Nación del Té con Leche';

  @override
  String get stage16 => 'Alianza Mundial';

  @override
  String get stage17 => 'Planeta del Té con Leche';

  @override
  String get stage18 => 'La Verdad del Té con Leche';

  @override
  String get genAcademyTea => 'Té con Leche Académico';

  @override
  String get genScholarTea => 'Té con Leche del Erudito';

  @override
  String get genCityTea => 'Té con Leche Urbano';

  @override
  String get genMetroTea => 'Té con Leche Metrópolis';

  @override
  String get genNationTea => 'Té con Leche Nacional';

  @override
  String get genTreatyTea => 'Té con Leche del Tratado';

  @override
  String get genUnionTea => 'Té con Leche de la Alianza';

  @override
  String get genWorldTea => 'Té con Leche Paz Mundial';

  @override
  String get genPlanetTea => 'Té con Leche Planetario';

  @override
  String get genTerraformTea => 'Té con Leche Terraformado';

  @override
  String get genTruthTea => 'Té con Leche de la Verdad';

  @override
  String get genUltimateTea => 'Té con Leche Supremo';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSound => 'Sonido';

  @override
  String walkerTipSnack(String amount) {
    return 'Un cliente dejó +$amount monedas de propina 🧋';
  }

  @override
  String get settingsEffects => 'Efectos visuales';

  @override
  String get settingsEffectsAuto => 'Automático (según el dispositivo)';

  @override
  String get settingsEffectsHigh => 'Alto';

  @override
  String get settingsEffectsMedium => 'Medio';

  @override
  String get settingsEffectsLow => 'Bajo (ahorra batería)';

  @override
  String get settingsEffectsOff => 'Desactivado';

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
  String storyUnlockWhen(String cond) {
    return 'Se desbloquea al: $cond';
  }

  @override
  String storyUnlockAfter(String chapter) {
    return 'Se desbloquea tras $chapter';
  }

  @override
  String storyCondFirst(String name) {
    return 'Primer $name';
  }

  @override
  String get storyCondRival => 'Derrota al rival';

  @override
  String storyCondAscension(int n, String name) {
    return '$name n.º $n';
  }

  @override
  String storyCondM3(int n, String game) {
    return 'Supera el nivel $n de $game';
  }

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
  String get navCompete => 'Competir';

  @override
  String get arenaTitle => 'Arena';

  @override
  String get arenaIntro =>
      'Duelo 1v1 de 60 segundos — ¡gana quien consiga más Monedas!';

  @override
  String get arenaStartButton => 'Buscar rival';

  @override
  String get arenaModeTap => 'Carrera de toques';

  @override
  String get arenaModeMatch3 => 'Perlas que caen';

  @override
  String get arenaMatch3Intro =>
      'Combina 3 iguales durante 60 segundos: ¡gana quien puntúe más que su rival!';

  @override
  String get arenaMatch3Stuck => '¡No quedan movimientos!';

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
  String arenaOnlineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jugadores en línea',
      one: '1 jugador en línea',
    );
    return '$_temp0';
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
  String get redeemTitle => 'Canjear código de regalo';

  @override
  String get redeemHint => 'Ingresa el código';

  @override
  String get redeemButton => 'Canjear';

  @override
  String redeemSuccess(int gems) {
    return '¡Canjeado +$gems 💎!';
  }

  @override
  String get redeemAlreadyClaimed => 'Ya canjeaste este código';

  @override
  String get redeemInvalid => 'Código no válido';

  @override
  String get cloudSaveMenuTitle => 'Copia de seguridad';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'Vinculado: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'Sin vincular — podrías perder tu progreso si desinstalas';

  @override
  String get cloudSaveTitle => 'Copia de seguridad';

  @override
  String get cloudSaveIntro =>
      'Vincula un email para recuperar tu progreso si desinstalas o cambias de dispositivo.';

  @override
  String get cloudSaveEmailHint => 'Tu email';

  @override
  String get cloudSaveSendCode => 'Enviar código';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'Código de confirmación enviado a $email';
  }

  @override
  String get cloudSaveCheckSpam =>
      '¿No ves el correo? Revisa también la carpeta de Spam / Correo no deseado.';

  @override
  String get cloudSaveCodeHint => 'Código de confirmación';

  @override
  String get cloudSaveVerify => 'Verificar';

  @override
  String get cloudSaveChangeEmail => 'Usar otro email';

  @override
  String get cloudSaveResend => 'Reenviar código';

  @override
  String cloudSaveResendIn(int seconds) {
    return 'Reenviar código (${seconds}s)';
  }

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

  @override
  String get leaderboardMenuTitle => 'Clasificación';

  @override
  String get leaderboardTitle => 'Clasificación';

  @override
  String get leaderboardNicknameIntro =>
      'Elige un nombre para la clasificación (puedes cambiarlo después):';

  @override
  String get leaderboardNicknameHint => 'Tu nombre';

  @override
  String get leaderboardSubmit => 'Confirmar';

  @override
  String leaderboardYourRank(int rank) {
    return 'Tu puesto: #$rank';
  }

  @override
  String leaderboardStars(String stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty =>
      'Aún no hay nadie en la clasificación — ¡eres tú!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 ¡Estás en un puesto alto! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return 'Top 1: $top1💎 · Top 2-3: $top23💎 · Top 4-10: $top410💎 — cada 24h mientras estés en el ranking';
  }

  @override
  String get leaderboardChangeName => 'Cambiar nombre';

  @override
  String get leaderboardRetry => 'Reintentar';

  @override
  String get storySpeedrunMenuTitle => 'Speedrun';

  @override
  String get storySpeedrunTitle => 'Clasificación de Speedrun';

  @override
  String get storySpeedrunNotCompletedYet =>
      'Aún no has terminado la historia — completa el Capítulo 18 para entrar en la clasificación.';

  @override
  String get storySpeedrunTabMain => 'Acto 1';

  @override
  String get storySpeedrunTabExt => 'Acto 2';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      'Aún no has completado el Acto 2: termina el Capítulo 28 para entrar en la clasificación.';

  @override
  String get storySpeedrunTabExt2 => 'Acto 3';

  @override
  String get storySpeedrunExt2NotCompletedYet =>
      'Aún no has completado el Acto 3: termina el Capítulo 36 para entrar en la clasificación.';

  @override
  String get accessoryMenuTitle => 'Colección';

  @override
  String get collectionChip => 'Colección';

  @override
  String get accessoryInventoryTitle => 'Colección de accesorios';

  @override
  String accessoryInventoryOwned(int owned, int total) {
    return '$owned/$total conseguidos';
  }

  @override
  String get accessoryRarityCommon => 'Común';

  @override
  String get accessoryRarityRare => 'Raro';

  @override
  String get accessoryRarityEpic => 'Épico';

  @override
  String get accessoryRarityLegendary => 'Legendario';

  @override
  String get accessoryLbTitle => 'Clasificación de colección';

  @override
  String accessoryLbCount(int n) {
    return '$n accesorios';
  }

  @override
  String get accessoryLbTopTitle => 'Coleccionista';

  @override
  String get accessoryLbTitleKing => 'Rey de los Accesorios';

  @override
  String get accessoryLbTitleMaster => 'Maestro Coleccionista';

  @override
  String get accessoryLbEmpty =>
      'Nadie en la tabla todavía. ¡Consigue un accesorio y el primer puesto es tuyo!';

  @override
  String get accessoryLbNoOwned =>
      'Aún no tienes ningún accesorio — completa las 3 misiones diarias para tener una oportunidad.';

  @override
  String get accessoryLbError =>
      'No se pudo cargar la clasificación. Inténtalo más tarde.';

  @override
  String get accessoryMintLeaf => 'Hoja de menta';

  @override
  String get accessoryCupcake => 'Cupcake';

  @override
  String get accessoryCookie => 'Galleta';

  @override
  String get accessoryPottedPlant => 'Planta en maceta';

  @override
  String get accessoryCandle => 'Vela aromática';

  @override
  String get accessoryScarf => 'Bufanda';

  @override
  String get accessoryKite => 'Cometa de papel';

  @override
  String get accessoryCap => 'Gorra';

  @override
  String get accessorySeashell => 'Concha marina';

  @override
  String get accessoryMask => 'Máscara';

  @override
  String get accessoryDrum => 'Tamborcito';

  @override
  String get accessoryPalette => 'Paleta de colores';

  @override
  String get accessoryCrystalBall => 'Bola de cristal';

  @override
  String get accessoryLantern => 'Farol antiguo';

  @override
  String get accessoryUnicorn => 'Unicornio pequeño';

  @override
  String get accessoryDragon => 'Dragón pequeño';

  @override
  String get accessoryBalloon => 'Globo';

  @override
  String get accessoryBowtie => 'Lazo';

  @override
  String get accessorySunglasses => 'Gafas de sol';

  @override
  String get accessoryUmbrella => 'Paraguas pequeño';

  @override
  String get accessoryTeapot => 'Tetera pequeña';

  @override
  String get accessoryBell => 'Campanita';

  @override
  String get accessoryRibbon => 'Cinta';

  @override
  String get accessoryBookmark => 'Marcapáginas';

  @override
  String get accessoryWindChime => 'Campanilla de viento';

  @override
  String get accessoryClover => 'Trébol de cuatro hojas';

  @override
  String get accessoryBubble => 'Burbuja de jabón';

  @override
  String get accessorySticker => 'Pegatina';

  @override
  String get accessoryYarn => 'Ovillo de lana';

  @override
  String get accessoryFan => 'Abanico de papel';

  @override
  String get accessoryBasket => 'Cesta de mimbre';

  @override
  String get accessoryBead => 'Pulsera de cuentas';

  @override
  String get accessoryLadybug => 'Mariquita pequeña';

  @override
  String get accessoryKey => 'Llave antigua';

  @override
  String get accessoryDiamondStone => 'Piedra de diamante';

  @override
  String get accessoryMusicNote => 'Nota musical';

  @override
  String get accessoryTelescope => 'Telescopio';

  @override
  String get accessoryAnchor => 'Ancla';

  @override
  String get accessoryFeather => 'Pluma';

  @override
  String get accessoryHourglass => 'Reloj de arena';

  @override
  String get accessoryMap => 'Mapa antiguo';

  @override
  String get accessoryRing => 'Anillo pequeño';

  @override
  String get accessoryMagicWand => 'Varita mágica';

  @override
  String get accessoryTrident => 'Tridente';

  @override
  String get accessoryPeacock => 'Pavo real pequeño';

  @override
  String get accessoryComet => 'Cometa';

  @override
  String get accessoryButterfly => 'Mariposa de cristal';

  @override
  String get accessoryAngelWing => 'Ala de ángel';

  @override
  String get accessoryPhoenix => 'Fénix';

  @override
  String get accessoryGalaxy => 'Galaxia';

  @override
  String get accessoryDonut => 'Dona';

  @override
  String get accessoryLollipop => 'Piruleta';

  @override
  String get accessoryPretzel => 'Pretzel';

  @override
  String get accessoryIceCream => 'Cono de helado';

  @override
  String get accessoryStrawberry => 'Fresa';

  @override
  String get accessoryCherry => 'Cerezas';

  @override
  String get accessoryLemon => 'Limón';

  @override
  String get accessoryPeach => 'Durazno';

  @override
  String get accessoryPopcorn => 'Palomitas';

  @override
  String get accessoryHoneyPot => 'Tarro de miel';

  @override
  String get accessoryMilkGlass => 'Vaso de leche';

  @override
  String get accessoryTangerine => 'Mandarina';

  @override
  String get accessoryChestnut => 'Castaña';

  @override
  String get accessoryMapleLeaf => 'Hoja de arce';

  @override
  String get accessoryCompass => 'Brújula';

  @override
  String get accessoryRocket => 'Cohete';

  @override
  String get accessoryViolin => 'Violín';

  @override
  String get accessoryScroll => 'Pergamino';

  @override
  String get accessoryMicrophone => 'Micrófono';

  @override
  String get accessoryLotus => 'Loto';

  @override
  String get accessoryJellyfish => 'Medusa';

  @override
  String get accessoryCamera => 'Cámara';

  @override
  String get accessoryShield => 'Escudo';

  @override
  String get accessoryAmphora => 'Jarrón antiguo';

  @override
  String get accessoryRainbow => 'Arcoíris';

  @override
  String get accessoryFairy => 'Hada';

  @override
  String get accessoryDiscoBall => 'Bola disco';

  @override
  String get accessoryShiningStar => 'Estrella brillante';

  @override
  String get accessoryKraken => 'Kraken';

  @override
  String get accessoryThunderbolt => 'Rayo divino';

  @override
  String get accessoryIceCube => 'Cubito de hielo';

  @override
  String get accessoryCroissant => 'Cruasán';

  @override
  String get accessoryPancakes => 'Panqueques';

  @override
  String get accessoryWaffle => 'Gofre';

  @override
  String get accessoryBagel => 'Bagel';

  @override
  String get accessoryCakeSlice => 'Trozo de tarta';

  @override
  String get accessoryPie => 'Pastel';

  @override
  String get accessoryCandy => 'Caramelo';

  @override
  String get accessoryGrapes => 'Uvas';

  @override
  String get accessoryWatermelon => 'Sandía';

  @override
  String get accessoryPineapple => 'Piña';

  @override
  String get accessoryMango => 'Mango';

  @override
  String get accessoryKiwi => 'Kiwi';

  @override
  String get accessoryBanana => 'Plátano';

  @override
  String get accessoryApple => 'Manzana';

  @override
  String get accessoryTeddy => 'Osito de peluche';

  @override
  String get accessoryCrayon => 'Crayón';

  @override
  String get accessoryBucket => 'Cubo';

  @override
  String get accessoryGuitar => 'Guitarra';

  @override
  String get accessoryTrumpet => 'Trompeta';

  @override
  String get accessoryPiano => 'Piano';

  @override
  String get accessorySaxophone => 'Saxofón';

  @override
  String get accessoryBanjo => 'Banjo';

  @override
  String get accessoryMicroscope => 'Microscopio';

  @override
  String get accessoryRingedPlanet => 'Planeta con anillos';

  @override
  String get accessoryCrescentMoon => 'Luna creciente';

  @override
  String get accessoryBowArrow => 'Arco y flecha';

  @override
  String get accessoryMirror => 'Espejo';

  @override
  String get accessoryFerrisWheel => 'Noria';

  @override
  String get accessoryCarousel => 'Tiovivo';

  @override
  String get accessorySwan => 'Cisne';

  @override
  String get accessoryFlamingo => 'Flamenco';

  @override
  String get accessoryOwl => 'Búho';

  @override
  String get accessoryWhale => 'Ballena';

  @override
  String get accessoryCrown => 'Corona';

  @override
  String get accessoryCircusTent => 'Carpa de circo';

  @override
  String get accessoryPinata => 'Piñata';

  @override
  String get accessoryCastle => 'Castillo';

  @override
  String get accessoryGenie => 'Genio';

  @override
  String get accessoryVolcano => 'Volcán';

  @override
  String get accessoryCarrot => 'Zanahoria';

  @override
  String get accessoryCorn => 'Maíz';

  @override
  String get accessoryTomato => 'Tomate';

  @override
  String get accessoryAvocado => 'Aguacate';

  @override
  String get accessoryCoconut => 'Coco';

  @override
  String get accessoryBlueberries => 'Arándanos';

  @override
  String get accessoryPear => 'Pera';

  @override
  String get accessoryRiceBall => 'Onigiri';

  @override
  String get accessoryDumpling => 'Empanadilla';

  @override
  String get accessorySushi => 'Sushi';

  @override
  String get accessoryRamen => 'Ramen';

  @override
  String get accessoryTaco => 'Taco';

  @override
  String get accessoryPizza => 'Pizza';

  @override
  String get accessoryHotDog => 'Perrito caliente';

  @override
  String get accessoryFries => 'Patatas fritas';

  @override
  String get accessoryEgg => 'Huevo';

  @override
  String get accessoryBread => 'Pan';

  @override
  String get accessoryButter => 'Mantequilla';

  @override
  String get accessoryPuzzle => 'Pieza de puzle';

  @override
  String get accessoryDice => 'Dado';

  @override
  String get accessoryChessPawn => 'Peón de ajedrez';

  @override
  String get accessoryDart => 'Diana';

  @override
  String get accessoryBowling => 'Bolos';

  @override
  String get accessoryYoYo => 'Yoyó';

  @override
  String get accessoryRollerSkate => 'Patín';

  @override
  String get accessorySkateboard => 'Monopatín';

  @override
  String get accessorySatellite => 'Satélite';

  @override
  String get accessoryAlembic => 'Alambique';

  @override
  String get accessoryDna => 'ADN';

  @override
  String get accessoryTrophy => 'Trofeo';

  @override
  String get accessoryLeopard => 'Leopardo';

  @override
  String get accessoryElephant => 'Elefante';

  @override
  String get accessoryPanda => 'Panda';

  @override
  String get accessoryGiraffe => 'Jirafa';

  @override
  String get accessoryTurtle => 'Tortuga';

  @override
  String get accessoryKoala => 'Koala';

  @override
  String get accessoryPenguin => 'Pingüino';

  @override
  String get accessorySauropod => 'Saurópodo';

  @override
  String get accessoryMermaid => 'Sirena';

  @override
  String get accessoryEagle => 'Águila';

  @override
  String get marketTitle => 'Mercado de accesorios';

  @override
  String get marketTabBrowse => 'Mercado';

  @override
  String get marketTabMine => 'Mío';

  @override
  String get marketRecentSalesHeader => 'Vendido recientemente';

  @override
  String get marketMerchantTitle => 'Comerciante semanal';

  @override
  String get marketFilterAll => 'Todos';

  @override
  String get marketFilterMissing => 'Faltan';

  @override
  String get marketSortPriceAsc => 'Menor precio';

  @override
  String get marketBadgeNew => 'NUEVO';

  @override
  String marketNeedMore(int n) {
    return 'Faltan $n Monedas de Mercado';
  }

  @override
  String get marketNoFilterResults => 'Ningún artículo coincide con el filtro.';

  @override
  String accessoryRevealNew(String name) {
    return '¡Nuevo accesorio: $name!';
  }

  @override
  String accessoryRevealDuplicate(String name, int gems) {
    return '$name repetido: +$gems 💎 y una copia extra para vender en el Mercado';
  }

  @override
  String accessoryEquipHint(int n, int max) {
    return 'Exhibidos $n/$max: toca un objeto que tengas para mostrarlo junto a la taza';
  }

  @override
  String accessoryEquipFull(int max) {
    return 'Exhibición llena ($max): quita uno primero';
  }

  @override
  String get accessoryFlairHint =>
      'Mantén pulsado un objeto para usarlo como insignia del ranking';

  @override
  String accessoryFlairSet(String name) {
    return '$name es ahora tu insignia del ranking';
  }

  @override
  String get accessoryFlairCleared => 'Insignia del ranking quitada';

  @override
  String get accessoryFlairFailed =>
      'No se pudo poner la insignia: objeto sin sincronizar o sin conexión';

  @override
  String get marketStarterTitle => 'Pack inicial del Mercado';

  @override
  String get marketStarterBody =>
      'Recibe 1 accesorio Común + 1 repetido para vender + 10 Monedas de Mercado. Solo una vez.';

  @override
  String get marketStarterClaim => 'Reclamar';

  @override
  String get marketStarterDone => '¡Pack inicial reclamado! Mira tu Colección.';

  @override
  String get marketStarterErrCap =>
      'Hoy se agotaron los regalos en todo el servidor — vuelve mañana.';

  @override
  String get marketStarterErrNet =>
      'No se pudo reclamar: revisa tu conexión e inténtalo de nuevo.';

  @override
  String get marketIntroTitle => '¡Bienvenido al Mercado!';

  @override
  String get marketIntroStep1 =>
      '1. Convierte 💎 o monedas en Monedas de Mercado (botón Convertir): solo sirven en el Mercado y no se pueden convertir de vuelta.';

  @override
  String get marketIntroStep2 =>
      '2. Compra accesorios que otros jugadores pongan a la venta para completar tu colección.';

  @override
  String get marketIntroStep3 =>
      '3. Vende repetidos en la pestaña Mis objetos. La comisión es solo del 1%.';

  @override
  String get marketIntroOk => 'Entendido';

  @override
  String get collectionTitle10 => 'Coleccionista';

  @override
  String get collectionTitle25 => 'Aficionado';

  @override
  String get collectionTitle40 => 'Coleccionista experto';

  @override
  String get collectionTitle50 => 'Leyenda del coleccionismo';

  @override
  String get collectionTitle80 => 'Maestro coleccionista';

  @override
  String get collectionTitle100 => 'Gran coleccionista';

  @override
  String get collectionTitle120 => 'Rey de la colección';

  @override
  String get collectionTitle140 => 'Sabio coleccionista';

  @override
  String get collectionTitle160 => 'Deidad de la colección';

  @override
  String collectionTitleLabel(String title) {
    return 'Título: $title';
  }

  @override
  String collectionMilestoneClaim(int coins) {
    return 'Reclamar +$coins';
  }

  @override
  String collectionMilestoneLocked(int count, int coins) {
    return '$count objetos · $coins Monedas de Mercado';
  }

  @override
  String collectionMilestoneDone(int coins) {
    return '¡Recibiste $coins Monedas de Mercado y un nuevo título!';
  }

  @override
  String get collectionMilestoneErrNet =>
      'No se pudo reclamar: revisa tu conexión e inténtalo de nuevo.';

  @override
  String marketPriceLast(int n) {
    return 'Última venta: $n';
  }

  @override
  String marketPriceLowest(int n) {
    return 'Más barato ahora: $n';
  }

  @override
  String marketPriceAvg(int n) {
    return 'Prom. 7 días: $n';
  }

  @override
  String get marketWishAdd => 'Añadir a la lista de deseos';

  @override
  String get marketWishRemove => 'Quitar de la lista de deseos';

  @override
  String marketWishFull(int max) {
    return 'Lista de deseos llena ($max objetos)';
  }

  @override
  String marketFeeFreeNote(int proceeds) {
    return 'Gratis en fin de semana: recibes las $proceeds Monedas de Mercado completas';
  }

  @override
  String get marketWeekendBanner =>
      '🎉 Fin de semana: ¡comisión 0% y más probabilidad de accesorios raros!';

  @override
  String collectionPeekTitle(String name) {
    return 'Colección de $name';
  }

  @override
  String get collectionPeekError =>
      'No se pudo cargar la colección — inténtalo más tarde.';

  @override
  String get collectionShareTooltip => 'Presumir colección';

  @override
  String collectionShareText(int owned, int total, String items) {
    return '¡He coleccionado $owned/$total accesorios en Boba Empire! $items';
  }

  @override
  String get collectionShareCopied =>
      'Copiado — ¡pégalo en un chat para presumir!';

  @override
  String get collectionCardTitle => 'Tarjeta de colección';

  @override
  String get collectionShareImage => 'Compartir imagen';

  @override
  String get collectionShareCopy => 'Copiar texto';

  @override
  String get collectionShareFailed =>
      'No se pudo compartir: prueba a copiar el texto.';

  @override
  String whatsNewTitle(String version) {
    return 'Novedades de $version';
  }

  @override
  String get whatsNewVip =>
      '👑 Sistema VIP: 10 niveles, regalos diarios/semanales/mensuales, clasificación VIP, Tienda VIP y 2x 💎 en tu primera recarga';

  @override
  String get whatsNewGuild =>
      '🛡️ Gremios: Jefe semanal, etiquetas y marcos VIP, regalar 💎 y clasificación de gremios por VIP';

  @override
  String get whatsNewQuests =>
      '📋 Misiones semanales con cofre, bonos por hitos de racha (7/14/30/60/100 días) y la Oferta de hoy';

  @override
  String get whatsNewSocial =>
      '🏆 Toca una fila de la clasificación para ver el perfil; mira y comparte clasificaciones en la web; invita amigos y gana 💎';

  @override
  String get whatsNewShop =>
      '💎 Nuevos paquetes grandes de gemas, Almacén frío permanente y combo Sin anuncios + ingresos x2 (se requiere correo para recargar)';

  @override
  String get whatsNewLater => 'Después';

  @override
  String get whatsNewOpen => 'Descubrir VIP';

  @override
  String marketWallet(int n) {
    return '$n Monedas de Mercado';
  }

  @override
  String get marketError =>
      'No se pudo cargar el mercado. Inténtalo más tarde.';

  @override
  String get marketEmptyBrowse => 'Todavía nadie ha puesto nada a la venta.';

  @override
  String get marketBuyButton => 'Comprar';

  @override
  String get marketBoughtToast => '¡Comprado!';

  @override
  String marketConfirmBuy(int price) {
    return '¿Comprar por $price Monedas de Mercado?';
  }

  @override
  String marketPriceTag(int price) {
    return '$price Monedas de Mercado';
  }

  @override
  String get marketMyListingsHeader => 'Tus publicaciones';

  @override
  String get marketEmptyMine => 'Aún no has puesto nada a la venta.';

  @override
  String marketExpiresIn(String t) {
    return 'Caduca en $t';
  }

  @override
  String marketListExpiryNote(int days) {
    return 'Los anuncios duran como máximo $days días; al caducar, el objeto vuelve a tu inventario.';
  }

  @override
  String marketExpiredToast(int n) {
    return '$n anuncio(s) caducado(s) devuelto(s) a tu inventario.';
  }

  @override
  String get swapTab => 'Trueques';

  @override
  String get swapCreate => 'Crear oferta';

  @override
  String get swapCreateOk => 'Publicar oferta';

  @override
  String swapIntro(int days) {
    return 'Cambia un objeto por otro con otros jugadores, sin Monedas del Mercado. Tu objeto se guarda hasta que alguien acepte (hasta $days días; si caduca vuelve a tu inventario).';
  }

  @override
  String get swapEmpty => 'Aún no hay ofertas de trueque. ¡Crea la primera!';

  @override
  String get swapMine => 'Mis ofertas de trueque';

  @override
  String get swapMineEmpty => 'No has publicado ofertas.';

  @override
  String get swapGive => 'Das';

  @override
  String get swapWant => 'Quieres';

  @override
  String get swapAccept => 'Cambiar';

  @override
  String get swapNeedItem => 'Falta el objeto';

  @override
  String get swapCancel => 'Cancelar';

  @override
  String get swapPickGive => 'Elige el objeto que das';

  @override
  String get swapPickWant => 'Elige el objeto que quieres';

  @override
  String get swapPickSearch => 'Buscar por nombre';

  @override
  String get swapPickNone => 'No hay objetos.';

  @override
  String swapMaxNote(int n) {
    return 'Hasta $n ofertas a la vez.';
  }

  @override
  String get swapConfirmTitle => 'Confirmar trueque';

  @override
  String swapConfirmBody(String give, String want) {
    return '¿Recibes $give y das $want?';
  }

  @override
  String get swapCreatedToast => '¡Oferta de trueque publicada!';

  @override
  String swapDoneToast(String name) {
    return '¡Trueque hecho! Recibiste $name.';
  }

  @override
  String get swapCancelledToast =>
      'Oferta cancelada, el objeto volvió a tu inventario.';

  @override
  String swapCollectedToast(int n) {
    return '$n objeto(s) de trueques volvieron a tu inventario.';
  }

  @override
  String get swapErrNotOwned =>
      'No tienes este objeto (reabre el Mercado para sincronizar).';

  @override
  String get swapErrNotOwnedWant => 'No tienes el objeto que piden.';

  @override
  String swapErrTooMany(int n) {
    return 'Tienes demasiadas ofertas abiertas (máx. $n).';
  }

  @override
  String get swapErrNotOpen =>
      'Esta oferta acaba de aceptarse o cancelarse; la lista se actualizó.';

  @override
  String get swapErrOwn => 'No puedes aceptar tu propia oferta.';

  @override
  String get swapErrInvalid => 'Oferta no válida.';

  @override
  String get swapErrNetwork => 'No se pudo conectar, inténtalo más tarde.';

  @override
  String get marketCancelButton => 'Cancelar publicación';

  @override
  String get marketCancelledToast => 'Publicación cancelada.';

  @override
  String get marketSellableHeader => 'Accesorios que puedes vender';

  @override
  String get marketEmptySellable => 'Todavía no tienes accesorios para vender.';

  @override
  String get marketListedToast => '¡Publicado!';

  @override
  String get marketListButton => 'Poner a la venta';

  @override
  String get marketPriceLabel => 'Precio (Monedas de Mercado)';

  @override
  String marketListFeeNote(int proceeds, int fee) {
    return 'Recibirás $proceeds Monedas de Mercado tras la comisión del 1% (−$fee)';
  }

  @override
  String get marketConvertButton => 'Cambiar';

  @override
  String get marketConvertTitle => 'Cambiar por Monedas de Mercado';

  @override
  String get marketConvertAmountLabel => 'Monedas de Mercado deseadas';

  @override
  String marketConvertCostGems(String cost) {
    return 'Costo: $cost 💎';
  }

  @override
  String marketConvertCostMoney(String cost) {
    return 'Costo: $cost 💰';
  }

  @override
  String get marketConvertSuccessToast => '¡Cambiado!';

  @override
  String get marketConvertFailToast =>
      'Cambio fallido, saldo insuficiente o error de red.';

  @override
  String get storySpeedrunEmpty =>
      'Nadie ha terminado la historia todavía — ¡sé el primero!';

  @override
  String get arenaLeaderboardMenuTitle => 'Clasificación PK';

  @override
  String get arenaLeaderboardTitle => 'Clasificación PK';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      'Aún no has jugado ninguna partida de la Arena — gana una para aparecer aquí.';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '${wins}V - ${losses}D';
  }

  @override
  String get ascensionTitle => 'Ascensión';

  @override
  String get ascensionOpen => 'Ascensión ⏳';

  @override
  String get ascensionIntro =>
      'Cambia todas tus Estrellas y mejoras de la Tienda de Estrellas por ⏳ Puntos de Ascensión: mejoras permanentes más fuertes. Empiezas de nuevo.';

  @override
  String ascensionProgress(int percent) {
    return 'Progreso para desbloquear: $percent%';
  }

  @override
  String get ascensionPointsNow => 'Puntos actuales';

  @override
  String get ascensionPointsGain => 'Ganas si asciendes';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ Reinicia Estrellas, todas las mejoras de la Tienda de Estrellas, Monedas, niveles y etapa. Conserva 💎, logros e historia. Tus Estrellas del ranking bajan a 0 (el puesto por ganancias totales no cambia).';

  @override
  String ascensionConfirm(int points) {
    return 'Ascender (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => 'Aún no disponible';

  @override
  String ascensionSuccess(int points) {
    return '¡Comienza una nueva era! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => 'Mejoras de Ascensión ⏳';

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
  String get ascensionIncomeName => 'Fuente de energía';

  @override
  String ascensionIncomeDesc(int percent) {
    return '+$percent% de ingresos por nivel';
  }

  @override
  String get ascensionStarBonusName => 'Estrellas radiantes';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '+$percent% de poder por Estrella, por nivel';
  }

  @override
  String get ascensionStarGainName => 'Estrellas abundantes';

  @override
  String ascensionStarGainDesc(int percent) {
    return '+$percent% de ritmo de Estrellas, por nivel';
  }

  @override
  String get achAscend => 'Asciende por primera vez';

  @override
  String get dailyQuestsTitle => 'Misiones diarias';

  @override
  String get dailyQuestsChip => 'Misiones';

  @override
  String get chHeader => '🔥 Desafíos (difíciles — gran recompensa)';

  @override
  String chCat(int n) {
    return 'Atrapa $n gatos de Lluvia Dorada';
  }

  @override
  String chVip(int n) {
    return 'Atiende a $n clientes VIP';
  }

  @override
  String get chBonusLabel => 'Completa ambos desafíos';

  @override
  String get lbrTitle => 'Recompensas top semanales';

  @override
  String lbrIntro(int first, int second, int third) {
    return 'Cada semana el top 3 de cuatro clasificaciones (Ingresos, Perla Caída, Colección, VIP) recibe $first / $second / $third 💎. Se cierran al inicio de la semana (lunes, UTC); puedes reclamar una semana más.';
  }

  @override
  String get lbrEmpty =>
      'Aún no hay recompensas: ¡sube al top 3 de las clasificaciones!';

  @override
  String lbrRow(String board, String week) {
    return '$board · semana $week';
  }

  @override
  String lbrClaim(int n) {
    return 'Reclamar $n 💎';
  }

  @override
  String lbrGot(int n) {
    return '¡Reclamaste $n 💎 de la recompensa top semanal!';
  }

  @override
  String get lbrErrGone => 'Esta recompensa expiró o ya no está disponible.';

  @override
  String get lbrBoardIncome => 'Ingresos';

  @override
  String get lbrBoardPearls => 'Perla Caída';

  @override
  String get lbrBoardCollection => 'Colección';

  @override
  String get lbrBoardVip => 'VIP';

  @override
  String get dailyQuestsBonusLabel => 'Completa las 3 misiones';

  @override
  String dailyQuestsResetsIn(Object time) {
    return 'Nuevas misiones en $time';
  }

  @override
  String get dailyQuestClaimed => 'Reclamado';

  @override
  String dqTap(int n) {
    return 'Toca la taza $n veces';
  }

  @override
  String dqBuy(int n) {
    return 'Compra $n mejoras';
  }

  @override
  String dqEarn(Object amount) {
    return 'Gana $amount Monedas';
  }

  @override
  String get dqCat => 'Atrapa al Gato Dorado';

  @override
  String get dqVip => 'Atiende a un cliente VIP';

  @override
  String get dqSpin => 'Gira la Rueda de la Suerte';

  @override
  String get weeklyQuestsTitle => 'Misiones semanales';

  @override
  String get weeklyQuestsOpen => 'Misiones semanales 🗓️';

  @override
  String wqPrestige(int n) {
    return 'Prestigia $n veces';
  }

  @override
  String wqM3Win(int n) {
    return 'Gana $n niveles de Perlas Cayendo';
  }

  @override
  String wqTrade(int n) {
    return 'Haz $n operaciones en el Mercado (vender o comprar)';
  }

  @override
  String wqDailyDone(int n) {
    return 'Reclama $n recompensas de misiones diarias';
  }

  @override
  String wqSpin(int n) {
    return 'Gira la rueda $n veces';
  }

  @override
  String wqBuy(int n) {
    return 'Compra $n mejoras';
  }

  @override
  String get weeklyChestLabel =>
      'Cofre semanal: completa las 3 → +1 accesorio Raro o mejor';

  @override
  String weeklyResetsIn(String time) {
    return 'Se reinicia en $time';
  }

  @override
  String get notifyOfflineFullTitle => '¡Tu caja está llena! 🧋';

  @override
  String get notifyOfflineFullBody =>
      'La tienda dejó de acumular monedas: pasa a recogerlas y abre otro turno.';

  @override
  String get notifyDailyTitle => 'Nuevo día, nuevas misiones 📋';

  @override
  String get notifyDailyBody =>
      'Te esperan la recompensa diaria, un giro gratis y 3 misiones.';

  @override
  String get notifyD3Title => 'Tu tienda te extraña 🧋';

  @override
  String get notifyD3Body =>
      'Han pasado 3 días — la caja se llenó hace tiempo, ven a recogerla.';

  @override
  String get notifyD7Title => '¡Ya pasó una semana! 🧋';

  @override
  String get notifyD7Body =>
      'El Ascenso, Perlas que caen y muchas cosas nuevas te esperan.';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 ¡Evento: ×$mult de ingresos! Quedan $timeLeft';
  }

  @override
  String get navMatch3 => 'Perlas';

  @override
  String get m3Title => 'Perlas que caen';

  @override
  String m3Level(int n) {
    return 'Nivel $n';
  }

  @override
  String get m3Locked => 'Bloqueado';

  @override
  String m3MovesLeft(int n) {
    return '$n movimientos';
  }

  @override
  String get m3Score => 'Puntos';

  @override
  String get m3Win => '¡Nivel superado!';

  @override
  String get m3Lose => 'Meta no alcanzada';

  @override
  String get m3Retry => 'Reintentar';

  @override
  String get m3Next => 'Siguiente nivel';

  @override
  String get m3Back => 'Lista de niveles';

  @override
  String get m3Reward => 'Recompensa';

  @override
  String get m3NoReward => 'Ya reclamaste la recompensa de este nivel';

  @override
  String get m3LeaveTitle => '¿Salir de esta partida?';

  @override
  String get m3LeaveBody => 'Tu partida se conserva hasta que cierres la app.';

  @override
  String get m3LeaveStay => 'Seguir jugando';

  @override
  String get m3LeaveConfirm => 'Salir';

  @override
  String get accessoryHowToTitle => 'Guía de colección';

  @override
  String get accessoryHowToButton => 'Guía';

  @override
  String get accessoryHtp1 =>
      '🎯 Objetivo: reunir todos los objetos. Los accesorios son solo decorativos (no dan ingresos), pero puedes lucirlos junto a tu vaso, compartirlos y subir en el ranking de Colección.';

  @override
  String get accessoryHtp2 =>
      '🎁 Cómo conseguirlos: completar las 3 misiones diarias · superar los niveles hito de Perlas que Caen (10/30/60) · la casilla de cofre de la ruleta principal · cada Ascensión · comprar Paquetes de accesorios con 💎.';

  @override
  String get accessoryHtp3 =>
      '🎰 Ruleta de accesorios: cada giro cuesta ver un anuncio o 💎. Los giros con anuncio tienen límite diario.';

  @override
  String get accessoryHtp4 =>
      '✨ Rareza: Común → Raro → Épico → Legendario. Los fines de semana y festivos suben la probabilidad de Épico/Legendario; los Paquetes Raro/Épico garantizan una rareza mínima; en festivos hay un Paquete Festivo con objetos exclusivos.';

  @override
  String accessoryHtp5(int gems) {
    return '♻️ Si te toca uno repetido: recibes $gems 💎 y 1 copia extra para vender en el Mercado.';
  }

  @override
  String get accessoryHtp6 =>
      '🏬 Mercado: vende copias extra por Monedas de Mercado y compra lo que te falta a otros jugadores (comisión 1%). Las Monedas de Mercado se compran con Monedas o 💎 y no se pueden convertir de vuelta.';

  @override
  String get accessoryHtp7 =>
      '🏅 Los hitos de colección (10/25/40/50/80/100/120/140/160 objetos) dan Monedas de Mercado. Añade objetos a tu lista de deseos; el ranking cuenta objetos distintos.';

  @override
  String get accessoryHtp8 =>
      '👆 Toca un objeto que tengas para mostrarlo junto a tu vaso en la pantalla principal.';

  @override
  String m3AdMoves(int n) {
    return 'Ver anuncio: +$n movimientos';
  }

  @override
  String get m3KeepPlaying => 'Seguir jugando';

  @override
  String get m3Pause => 'Descansar';

  @override
  String get m3GoalReached => '¡Meta alcanzada!';

  @override
  String m3NeedScore(String n, int star) {
    return 'Faltan $n puntos para $star★';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return 'Faltan $n $icon para $star★';
  }

  @override
  String get m3HowToTitle => 'Cómo jugar a Perlas que caen';

  @override
  String get m3HtpSwap =>
      '🔄 Intercambia dos fichas CONTIGUAS (toca una y luego la otra, o desliza) para alinear 3 o más iguales. Si no se forma línea, el movimiento no cuenta.';

  @override
  String get m3HtpGoal =>
      '🎯 Cada nivel tiene una meta: alcanzar puntos o recoger suficientes fichas de un tipo. La meta aparece en la barra superior.';

  @override
  String get m3HtpMoves =>
      '👣 Los movimientos son limitados. Cuando se acaban, el nivel termina: prioriza los que eliminen más fichas.';

  @override
  String get m3HtpChain =>
      '⛓️ Las fichas eliminadas hacen caer las de arriba; si forman otra línea se encadena y los pasos siguientes puntúan mucho más.';

  @override
  String get m3HtpSpecial =>
      '💥 Alinea 4 para crear una BOMBA EN CRUZ (limpia su fila y su columna). Con 5 o más sale una BOMBA DE COLOR 🌈 (limpia todas las fichas de ese tipo). Combínalas como fichas normales para activarlas.';

  @override
  String get m3HtpStars =>
      '⭐ Las tres estrellas de la barra son tres niveles. Al llegar a la primera superas el nivel; pulsa \"Seguir jugando\" para gastar los movimientos restantes y ganar más estrellas.';

  @override
  String get m3HtpReward =>
      '🎁 La recompensa se paga solo la PRIMERA vez que alcanzas cada estrella. Repetir un nivel no da nada extra.';

  @override
  String get m3LbTitle => 'Ranking Perlas que caen';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty =>
      'Aún no hay nadie. ¡Supera unos niveles y serás el primero!';

  @override
  String get m3LbNoStars =>
      'Aún no tienes estrellas: supera un nivel para entrar en el ranking.';

  @override
  String m3LbLevels(int n) {
    return '$n niveles';
  }

  @override
  String get m3LbError => 'No se pudo cargar el ranking. Inténtalo más tarde.';

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
    return 'Termina en $time';
  }

  @override
  String eventPoints(int n) {
    return 'Puntos de evento: $n';
  }

  @override
  String get eventRedeemHint =>
      'Completa misiones para ganar puntos y canjear objetos exclusivos gratis. No alcanzan para todo el set: ¡elige tus favoritos!';

  @override
  String eventRedeemCost(int cost) {
    return '$cost pts';
  }

  @override
  String get eventLbTitle => 'Clasificación del evento';

  @override
  String get eventLbEmpty =>
      'Nadie en la tabla todavía. ¡Unos toques y serás el primero!';

  @override
  String get eventLbNoScore =>
      'Aún no tienes puntos: toca la taza, atrapa gatos y atiende VIP para entrar.';

  @override
  String eventLbMyScore(int n) {
    return 'Tu puntuación: $n';
  }

  @override
  String eventLbScore(int n) {
    return '$n pts';
  }

  @override
  String eventBuff(String mult) {
    return 'Ingresos ×$mult durante el evento';
  }

  @override
  String get guildTitle => 'Gremio';

  @override
  String get guildIntro =>
      'Crea o únete a un gremio para cumplir metas semanales juntos y ganar recompensas.';

  @override
  String get guildCreate => 'Crear gremio';

  @override
  String get guildJoin => 'Unirse';

  @override
  String guildMembersCount(int n, int max) {
    return '$n/$max miembros';
  }

  @override
  String guildWeekTotal(int n) {
    return 'Esta semana: $n pts';
  }

  @override
  String get guildNameLabel => 'Nombre del gremio (3-20 caracteres)';

  @override
  String get guildTagLabel => 'Etiqueta (2-4 letras/dígitos)';

  @override
  String get guildLeave => 'Salir del gremio';

  @override
  String get guildLeaveConfirm =>
      '¿Salir de este gremio? Tus puntos semanales dejarán de contar.';

  @override
  String get guildKick => 'Expulsar';

  @override
  String guildKickConfirm(String name) {
    return '¿Expulsar a $name del gremio?';
  }

  @override
  String get guildReport => 'Denunciar gremio';

  @override
  String get guildReportSent => 'Denuncia enviada, gracias.';

  @override
  String get guildGoalTitle => 'Meta semanal';

  @override
  String get guildClaim => 'Reclamar';

  @override
  String get guildHowToTitle => 'Cómo ganar puntos de Gremio';

  @override
  String guildHowTo(int n) {
    return '⭐ Los puntos de Gremio salen de TU actividad esta semana: tocar un vaso +1, atrapar un gato +50, atender a un cliente VIP +50.\n🎯 Los puntos de todos suman para desbloquear recompensas de hito; la semana se reinicia el lunes 00:00 UTC.\n🎁 Debes aportar ≥$n puntos personales para reclamar una recompensa de hito.';
  }

  @override
  String guildNeedPoints(int n) {
    return 'Aporta ≥$n pts para reclamar';
  }

  @override
  String guildYourPoints(int n) {
    return 'Tu aporte: $n pts';
  }

  @override
  String get guildOwner => 'Líder';

  @override
  String get guildEmpty => 'Aún no hay gremios públicos. ¡Crea el primero!';

  @override
  String get guildErrNameTaken => 'Ese nombre de gremio ya existe.';

  @override
  String get guildErrFull => 'Este gremio está lleno.';

  @override
  String guildExpandButton(int cost, int max) {
    return 'Ampliar a $max plazas · $cost 💎';
  }

  @override
  String guildExpandConfirm(int cost, int max) {
    return '¿Ampliar el gremio a $max miembros por $cost 💎?';
  }

  @override
  String get guildExpandAction => 'Ampliar';

  @override
  String guildExpandDone(int max) {
    return '¡El gremio ahora admite hasta $max miembros!';
  }

  @override
  String get guildExpandMaxed => 'El gremio ya está en su capacidad máxima.';

  @override
  String get guildErrAlready => 'Ya estás en un gremio.';

  @override
  String get guildErrInvalid => 'Nombre o etiqueta no válidos.';

  @override
  String get guildErrNotFound =>
      'Gremio no encontrado (puede que haya cerrado).';

  @override
  String get guildErrContribution =>
      'Necesitas aportar más puntos esta semana.';

  @override
  String get guildErrNetwork => 'No se pudo conectar, inténtalo de nuevo.';

  @override
  String get guildLbTitle => 'Ranking de gremios';

  @override
  String get guildLbEmpty => 'Ningún gremio tiene puntos esta semana.';

  @override
  String guildRewardGot(int gems) {
    return 'Recibiste +$gems 💎';
  }

  @override
  String guildRewardGotAccessory(int gems, String name) {
    return 'Recibiste +$gems 💎 y $name';
  }

  @override
  String guildPoints(int n) {
    return '$n pts';
  }

  @override
  String guildCreateCost(int n) {
    return 'Costo de crear gremio: $n 💎';
  }

  @override
  String guildErrGems(int n) {
    return 'Necesitas $n 💎 para crear un gremio.';
  }

  @override
  String get guildApprovalSwitch => 'El líder debe aprobar las solicitudes';

  @override
  String get guildRequestJoin => 'Solicitar';

  @override
  String get guildRequestSent =>
      'Solicitud enviada, esperando la aprobación del líder.';

  @override
  String get guildRequestPending => 'Pendiente';

  @override
  String guildRequestsTitle(int n) {
    return 'Solicitudes ($n)';
  }

  @override
  String get guildAccept => 'Aprobar';

  @override
  String get guildReject => 'Rechazar';

  @override
  String get guildErrApproval =>
      'Este gremio requiere aprobación del líder: pulsa \"Solicitar\".';

  @override
  String get guildErrNicknameTaken =>
      'Alguien en este gremio ya usa ese nombre; elige otro.';

  @override
  String get guildErrRequestsFull =>
      'Este gremio tiene demasiadas solicitudes pendientes.';

  @override
  String cloudSaveConflictGems(String local, String cloud) {
    return '💎 Este dispositivo: $local · En la nube: $cloud';
  }

  @override
  String get cloudRemindTitle => 'Protege tu progreso';

  @override
  String get cloudRemindBody =>
      'No has vinculado un correo. Si cambias de teléfono o reinstalas, tu progreso (monedas, 💎, accesorios, monedas del mercado) se PERDERÁ. Vincularlo lleva un minuto y es gratis.';

  @override
  String get cloudRemindLink => 'Vincular ahora';

  @override
  String get cloudRemindLater => 'Más tarde';

  @override
  String get ftueTap => '¡Toca la taza para preparar té y ganar monedas!';

  @override
  String get ftueBuy =>
      '¡Ya tienes monedas! Compra tu primera mejora para ganar monedas cada segundo.';

  @override
  String get ftueExplain =>
      '¡Genial! Tus monedas ahora crecen cada segundo, incluso con la app cerrada. Sigue mejorando para ganar más rápido, desbloquear etapas y reclamar recompensas.';

  @override
  String get ftueOk => 'Entendido';

  @override
  String get ftueSkip => 'Omitir';

  @override
  String get accessoryGuildFlag => 'Bandera del gremio';

  @override
  String get accessoryGuildCastle => 'Castillo del gremio';

  @override
  String get accessoryGuildWolf => 'Lobo del gremio';

  @override
  String get accessoryGuildDragon => 'Dragón del gremio';

  @override
  String get accessoryGuildFox => 'Zorro del gremio';

  @override
  String get accessoryGuildTiger => 'Tigre del gremio';

  @override
  String get accessoryGuildShark => 'Tiburón del gremio';

  @override
  String get accessoryGuildTrex => 'T-Rex del gremio';

  @override
  String get accessoryGuildBoar => 'Jabalí del gremio';

  @override
  String get accessoryGuildBear => 'Oso del gremio';

  @override
  String get accessoryGuildScorpion => 'Escorpión del gremio';

  @override
  String get accessoryGuildMoai => 'Moai del gremio';

  @override
  String get guildChatTitle => 'Chat del gremio';

  @override
  String get guildChatEmpty => 'Aún no hay mensajes. ¡Sé el primero en hablar!';

  @override
  String get guildChatHint => 'Escribe a tu gremio…';

  @override
  String get guildChatSend => 'Enviar';

  @override
  String get guildChatPinned => 'Aviso';

  @override
  String get guildChatPin => 'Fijar';

  @override
  String get guildChatUnpin => 'Quitar fijado';

  @override
  String get guildChatDelete => 'Borrar mensaje';

  @override
  String get guildChatReport => 'Denunciar mensaje';

  @override
  String get guildChatReported => 'Mensaje denunciado. Ya no lo verás.';

  @override
  String get guildMembersHeader => 'Miembros';

  @override
  String get guildMemberSearchHint => 'Buscar miembros';

  @override
  String get guildMemberNoMatch => 'Ningún miembro coincide.';

  @override
  String get guildRoleOwner => 'Líder';

  @override
  String get guildRoleOfficer => 'Oficial';

  @override
  String get guildRoleMember => 'Miembro';

  @override
  String get guildMemberMention => 'Mencionar en el chat';

  @override
  String get guildMemberProfile => 'Ver perfil';

  @override
  String get guildQuestsSection => 'Misiones del Gremio';

  @override
  String get guildQuestsSectionHint =>
      'Se reinician cada lunes 00:00 UTC · dan Monedas del Gremio';

  @override
  String get guildManage => 'Gestionar';

  @override
  String get guildPromote => 'Nombrar oficial';

  @override
  String get guildDemote => 'Quitar oficial';

  @override
  String get guildTransfer => 'Ceder el liderazgo';

  @override
  String get guildTeamTitle => 'Misión de equipo de la semana';

  @override
  String guildTeamProgress(int active, int need) {
    return '$active / $need miembros listos';
  }

  @override
  String guildTeamHint(int n) {
    return 'Si la mitad del gremio (mínimo 2) llega a $n puntos semanales, todos los que lo lograron reciben la recompensa. ¡Jueguen juntos!';
  }

  @override
  String guildTeamClaim(int n) {
    return 'Reclamar $n Monedas del Gremio';
  }

  @override
  String guildTeamGot(int n) {
    return '¡Obtuviste $n Monedas del Gremio de la misión de equipo!';
  }

  @override
  String get guildErrTeamNotReached =>
      'Aún no hay suficientes miembros con esos puntos.';

  @override
  String guildErrTeamLow(int n) {
    return 'Necesitas al menos $n puntos semanales para reclamar.';
  }

  @override
  String get guildFundTitle => 'Fondo del gremio de esta semana';

  @override
  String guildFundMine(int n) {
    return 'Has aportado $n 💎';
  }

  @override
  String guildFundClaim(int n) {
    return 'Reclamar $n Monedas del Gremio';
  }

  @override
  String guildFundHint(int min) {
    return 'Todos donan 💎 juntos para alcanzar la meta (crece con el número de miembros). Cada miembro debe aportar al menos $min 💎 para reclamar la recompensa.';
  }

  @override
  String guildFundGot(int n) {
    return '¡Has reclamado $n Monedas del Gremio del fondo!';
  }

  @override
  String get guildErrFundNotReached =>
      'El fondo del gremio aún no alcanza la meta.';

  @override
  String guildErrFundLow(int n) {
    return 'Debes aportar al menos $n 💎 al fondo para reclamar la recompensa.';
  }

  @override
  String guildFundProgress(int progress, int target) {
    return '$progress / $target 💎';
  }

  @override
  String guildTransferConfirm(String name) {
    return '¿Ceder el liderazgo a $name? Pasarás a ser miembro normal.';
  }

  @override
  String get guildErrNotAllowed => 'No tienes permiso sobre este miembro.';

  @override
  String guildErrOfficersFull(int n) {
    return 'El gremio ya tiene $n oficiales.';
  }

  @override
  String get guildActivityTitle => 'Registro del gremio';

  @override
  String get guildActivityEmpty => 'Aún no hay actividad.';

  @override
  String guildEvJoined(String name) {
    return '$name se unió al gremio';
  }

  @override
  String guildEvLeft(String name) {
    return '$name salió del gremio';
  }

  @override
  String guildEvKicked(String actor, String target) {
    return '$actor expulsó a $target del gremio';
  }

  @override
  String guildEvPromoted(String actor, String target) {
    return '$actor nombró oficial a $target';
  }

  @override
  String guildEvDemoted(String actor, String target) {
    return '$actor quitó el cargo de oficial a $target';
  }

  @override
  String guildEvTransferred(String actor, String target) {
    return '$actor cedió el liderazgo a $target';
  }

  @override
  String get guildErrChatRate =>
      'Envías demasiado rápido, espera unos segundos.';

  @override
  String get guildErrTextBlocked =>
      'Tu mensaje contiene una palabra bloqueada.';

  @override
  String guildErrDailyLimit(int n) {
    return 'Hoy ya donaste el máximo de $n 💎.';
  }

  @override
  String get guildErrCoins => 'Monedas de gremio insuficientes.';

  @override
  String get guildErrOwned => 'Ya tienes este objeto.';

  @override
  String get guildErrBuffMaxed =>
      'El beneficio del gremio está al máximo, espera un poco.';

  @override
  String get guildErrClaimed => 'Ya reclamaste esta recompensa.';

  @override
  String get guildErrInvalidInput => 'Acción no válida.';

  @override
  String get guildShopButton => 'Tienda del gremio';

  @override
  String get guildShopTitle => 'Tienda del gremio';

  @override
  String guildCoinsLabel(int n) {
    return 'Monedas de gremio: $n';
  }

  @override
  String get guildDonateTitle => 'Dona 💎 por monedas de gremio';

  @override
  String guildDonateHint(int used, int cap) {
    return 'Hoy: $used/$cap 💎 · 1 💎 = 1 moneda de gremio';
  }

  @override
  String guildDonateGems(int n) {
    return '$n 💎';
  }

  @override
  String guildDonated(int n) {
    return 'Donado, recibes +$n monedas de gremio';
  }

  @override
  String get guildQuestsTitle => 'Misiones semanales del gremio';

  @override
  String guildQuestProgress(int have, int need) {
    return 'Aporta $need puntos esta semana ($have/$need)';
  }

  @override
  String guildQuestReward(int n) {
    return '+$n monedas de gremio';
  }

  @override
  String guildQuestGot(int n) {
    return 'Recibiste +$n monedas de gremio';
  }

  @override
  String get guildItemsTitle => 'Accesorios exclusivos del gremio';

  @override
  String guildItemPrice(int n) {
    return '$n monedas';
  }

  @override
  String get guildItemOwned => 'Tienes';

  @override
  String get guildItemBought => '¡Canjeado! El accesorio está en tu colección.';

  @override
  String get guildBuffTitle => 'Beneficio de ingresos del gremio';

  @override
  String guildBuffDesc(int pct, int hours) {
    return '+$pct% de monedas durante $hours horas para todos (no aplica sin conexión)';
  }

  @override
  String guildBuffLeft(String time) {
    return 'Quedan $time';
  }

  @override
  String get guildBuffBought => '¡Beneficio del gremio activado!';

  @override
  String guildStreakLine(int n) {
    return '🔥 $n semanas seguidas con los 3 hitos';
  }

  @override
  String guildBuffLine(int pct, String time) {
    return '⚡ Beneficio del gremio +$pct% · quedan $time';
  }

  @override
  String get guildLbTabTotal => 'Total';

  @override
  String get guildLbTabAvg => 'Promedio';

  @override
  String get guildLbTabStreak => 'Racha';

  @override
  String guildLbAvgNote(int n) {
    return 'Solo se clasifican gremios con $n+ miembros';
  }

  @override
  String guildAvgPerMember(int n) {
    return '$n/miembro';
  }

  @override
  String guildStreakWeeks(int n) {
    return '$n semanas';
  }

  @override
  String get guildLbStreakNote =>
      'Semanas seguidas en que el gremio logró los 3 hitos';

  @override
  String get guildLbStreakEmpty => 'Ningún gremio tiene racha aún.';

  @override
  String get guildLbAvgEmpty =>
      'Ningún gremio cumple aún para el ranking de promedio.';
}
