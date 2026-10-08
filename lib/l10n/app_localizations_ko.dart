// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '보바 엠파이어';

  @override
  String get tapBrew => '탭해서 만들기';

  @override
  String get coinsSuffix => ' 코인';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / 초';
  }

  @override
  String get instantCashButton => '즉시 현금';

  @override
  String instantCashSnack(String amount) {
    return '즉시 현금! +$amount 코인';
  }

  @override
  String get adNotReadySnack => '광고가 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요';

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return '$cost 코인으로 해금';
  }

  @override
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
  }

  @override
  String generatorSubtitle(String amount) {
    return '레벨당 초당 +$amount 코인';
  }

  @override
  String buyButton(String cost) {
    return '$cost 코인';
  }

  @override
  String get buyModeMax => 'MAX';

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · $seconds초';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'VIP 손님! +$cash 코인, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return '+$amount 💎 획득';
  }

  @override
  String get iapRemoveAdsSnack => '광고가 제거되었어요. 감사합니다!';

  @override
  String iapStarterSnack(String amount) {
    return '스타터 팩: +$amount 💎';
  }

  @override
  String get genTraDen => '홍차';

  @override
  String get genTranChau => '타피오카 펄';

  @override
  String get genThach => '그래스 젤리';

  @override
  String get genPudding => '푸딩';

  @override
  String get genKemNuong => '크렘 브륄레 밀크티';

  @override
  String get genMatcha => '양동이 말차';

  @override
  String get stage1 => '길거리 포장마차';

  @override
  String get stage2 => '작은 키오스크';

  @override
  String get stage3 => '프리미엄 카페 체인';

  @override
  String gemShopTitle(String gems) {
    return '상점 💎 (보유 $gems)';
  }

  @override
  String get gemBoostName => '수입 부스트';

  @override
  String gemBoostDesc(int percent) {
    return '레벨당 영구 수입 +$percent%';
  }

  @override
  String get offlineCapName => '오프라인 냉장고';

  @override
  String offlineCapDesc(int hours) {
    return '레벨당 오프라인 한도 +$hours시간';
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
  String get gemInstantStageName => '단계 즉시 해금';

  @override
  String gemInstantStageDesc(String stage) {
    return '코인 없이 $stage을(를) 지금 해금';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return '$stage 해금!';
  }

  @override
  String get gemTimeSkipName => '빨리 감기';

  @override
  String gemTimeSkipDesc(int hours) {
    return '$hours시간 분량의 생산을 즉시 획득';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return '오늘 $remaining/$max 남음';
  }

  @override
  String get iapSectionTitle => '현금으로 구매';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get close => '닫기';

  @override
  String get iapGemsDesc => '상점에서 아이템을 사려면 보석을 충전하세요.';

  @override
  String get iapRemoveAdsTitle => '광고 제거';

  @override
  String get iapRemoveAdsDesc => '모든 광고를 건너뛰어요. 보상은 그대로 받고, 시청은 필요 없어요.';

  @override
  String get iapStarterTitle => '스타터 팩';

  @override
  String get iapStarterDesc => '1회 한정: 보석을 한꺼번에 받아요.';

  @override
  String get prestigeTitle => '프랜차이즈 🏪';

  @override
  String prestigeIntro(String percent) {
    return '⭐ 별 1개당 영구 수입 +$percent%.';
  }

  @override
  String get prestigeStarsNow => '현재 별';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => '지금 프랜차이즈';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => '이후 총 보너스';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ 코인, 업그레이드 레벨, 단계가 초기화돼요 (별 상점 혜택으로 일부는 유지 가능).';

  @override
  String get cancel => '취소';

  @override
  String prestigeConfirm(String stars) {
    return '프랜차이즈 (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => '부족해요';

  @override
  String get prestigeAdConfirm => '광고 시청: 시작 코인 보너스';

  @override
  String prestigeSuccess(String stars) {
    return '프랜차이즈 성공! +$stars ⭐';
  }

  @override
  String get offlineTitle => '다시 오신 걸 환영해요! 🧋';

  @override
  String offlineBody(String amount) {
    return '자리를 비운 동안에도 가게는 계속 팔렸어요.\n$amount 코인을 벌었어요.';
  }

  @override
  String get offlineClaim => '받기';

  @override
  String get offlineDoubleButton => '광고 보고 ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return '두 배! +$amount 코인';
  }

  @override
  String get howToPlayTitle => '플레이 방법';

  @override
  String get htpTap => '🧋 컵을 탭해서 차를 만들고 코인을 벌어요.';

  @override
  String get htpBuy => '🛒 업그레이드를 사면 매초 자동으로 수입이 들어와요.';

  @override
  String get htpStage => '🏪 코인을 모아 더 멋진 음료가 있는 새 단계를 해금하세요.';

  @override
  String get htpCat => '🐱 복고양이를 탭하면 잠시 ×3 골든 러시가 시작돼요.';

  @override
  String get htpVip => '🚗 VIP 손님을 응대하면 보석 💎을 얻어요.';

  @override
  String get htpGems => '💎 상점에서 보석으로 영구 업그레이드를 사요.';

  @override
  String get htpPrestige => '⭐ 프랜차이즈로 다시 시작하고 별을 얻어요. 영구 수입 보너스예요.';

  @override
  String get htpOffline => '😴 자리를 비워도 가게는 계속 팔려요. 돌아와서 오프라인 현금을 받으세요.';

  @override
  String get htpNumberFormat =>
      '🔢 큰 숫자는 약어를 써요: K=천, M=백만, B=십억, T=조, 그다음 aa, bb, cc... — 한 단계마다 1,000배예요.';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get dailyTitle => '일일 출석';

  @override
  String get dailyPrompt => '오늘의 로그인 선물을 받으세요!';

  @override
  String get adNotReady => '광고가 아직 준비되지 않았어요. 몇 초 뒤에 다시 시도해 주세요.';

  @override
  String get accessoryBat => '밤박쥐';

  @override
  String get accessoryJackOLantern => '잭오랜턴';

  @override
  String get accessoryGhost => '친절한 유령';

  @override
  String get accessoryWitch => '꼬마 마녀';

  @override
  String get accessorySnowman => '눈사람';

  @override
  String get accessoryChristmasTree => '크리스마스 트리';

  @override
  String get accessoryReindeer => '순록';

  @override
  String get accessorySanta => '산타클로스';

  @override
  String get accessoryFirecracker => '폭죽';

  @override
  String get accessoryRedEnvelope => '빨간 봉투';

  @override
  String get accessoryApricotBlossom => '살구꽃';

  @override
  String get accessoryGoldenGoat => '황금 염소';

  @override
  String get festivalHalloween => '할로윈';

  @override
  String get festivalChristmas => '크리스마스';

  @override
  String get festivalTet => '설날';

  @override
  String get festivalSection => '축제 액세서리 (한정)';

  @override
  String festivalPackTitle(String name) {
    return '$name 팩';
  }

  @override
  String festivalPackDesc(int gems) {
    return '팩 1개당 아직 없는 한정 아이템 1개를 얻어요. 축제 기간에만 판매해요. 모두 보유 중이면 대신 $gems 💎을 받아요. 거래 불가.';
  }

  @override
  String get accessoryChampagne => '샴페인 건배';

  @override
  String get accessoryPartyPopper => '파티 폭죽';

  @override
  String get accessoryFireworks => '불꽃놀이';

  @override
  String get accessoryGoldenSparkler => '황금 불꽃';

  @override
  String get accessoryLoveLetter => '러브레터';

  @override
  String get accessoryRose => '빨간 장미';

  @override
  String get accessoryChocolate => '초콜릿';

  @override
  String get accessoryCupidArrow => '큐피드의 화살';

  @override
  String get accessoryTulip => '튤립';

  @override
  String get accessoryBouquet => '꽃다발';

  @override
  String get accessoryLipstick => '립스틱';

  @override
  String get accessoryPrincess => '공주';

  @override
  String get accessoryMooncake => '월병';

  @override
  String get accessoryRabbit => '달토끼';

  @override
  String get accessoryFullMoon => '보름달';

  @override
  String get accessoryLionDance => '사자춤';

  @override
  String get festivalNewYear => '새해';

  @override
  String get festivalValentine => '발렌타인데이';

  @override
  String get festivalWomensDay => '여성의 날';

  @override
  String get festivalMidAutumn => '추석';

  @override
  String get dailyClaim => '받기';

  @override
  String get accessoryWheelTitle => '액세서리 룰렛';

  @override
  String accessoryWheelAd(int n) {
    return '돌리기: 광고 시청 ($n회 남음)';
  }

  @override
  String accessoryWheelGems(int gems) {
    return '$gems 💎로 돌리기';
  }

  @override
  String get accessoryPackButton => '액세서리 팩';

  @override
  String get accessoryPackTitle => '액세서리 팩';

  @override
  String get accessoryPackBasic => '일반 팩';

  @override
  String get accessoryPackRare => '희귀 팩 (희귀 이상 보장)';

  @override
  String get accessoryPackEpic => '영웅 팩 (영웅 이상 보장)';

  @override
  String get accessoryPackSeason => '시즌 이벤트: 팩 25% 할인, 영웅/전설 확률 ×2!';

  @override
  String get accessoryAdDropButton => '광고 시청: 액세서리 +1';

  @override
  String dailyStreakAtRisk(int days) {
    return '하루를 놓쳤어요 — $days일 연속 출석이 곧 사라져요!';
  }

  @override
  String dailyRestoreGems(int gems) {
    return '연속 출석 지키기 ($gems 💎)';
  }

  @override
  String get dailyRestoreAd => '광고 보고 연속 출석 지키기';

  @override
  String get dailySkipRestore => '건너뛰고 처음부터';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return '$days일 연속 🔥';
  }

  @override
  String get achievementsTitle => '업적';

  @override
  String achEarn(String amount) {
    return '누적 $amount 코인 벌기';
  }

  @override
  String achStage(int n) {
    return '$n단계 도달';
  }

  @override
  String achLevels(int n) {
    return '업그레이드 레벨 합계 $n 보유';
  }

  @override
  String achPrestige(int n) {
    return '프랜차이즈 ($n★ 이상)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 업적 달성! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => '별 상점 ⭐';

  @override
  String prestigeShopSpendable(String stars) {
    return '사용 가능한 ⭐ $stars';
  }

  @override
  String get prestigeIncomeName => '메가 수입';

  @override
  String prestigeIncomeDesc(int percent) {
    return '레벨당 영구 수입 +$percent%';
  }

  @override
  String get prestigeTapName => '메가 탭';

  @override
  String prestigeTapDesc(int percent) {
    return '레벨당 탭 수익 +$percent%';
  }

  @override
  String get prestigeOfflineName => '슈퍼 오프라인';

  @override
  String prestigeOfflineDesc(int percent) {
    return '레벨당 부재 중 수입 +$percent%';
  }

  @override
  String get prestigeStartCashName => '시드 머니';

  @override
  String get prestigeStartCashDesc => '프랜차이즈 직후 코인 지급 (레벨이 오를수록 증가)';

  @override
  String get prestigeKeepStageName => '단계 유지';

  @override
  String get prestigeKeepStageDesc => '레벨당 프랜차이즈 후 1단계 더 유지';

  @override
  String get prestigeDiscountName => '대량 구매';

  @override
  String prestigeDiscountDesc(int percent) {
    return '레벨당 업그레이드 비용 -$percent%';
  }

  @override
  String get prestigeAutoBuyName => '자동 구매';

  @override
  String get prestigeAutoBuyDesc => '가성비 최고의 항목을 자동으로 사는 스위치 해금';

  @override
  String get autoBuyLabel => '자동 구매';

  @override
  String prestigeStarCost(String cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return '$n번 탭해서 만들기';
  }

  @override
  String questBuy(int n) {
    return '업그레이드 $n개 구매';
  }

  @override
  String questRepeatEarn(String amount) {
    return '코인 $amount 더 벌기';
  }

  @override
  String get questClaim => '받기';

  @override
  String get iapDoubleTitle => '수입 x2 (영구)';

  @override
  String get iapDoubleDesc => '모든 자동 수입을 영원히 두 배로';

  @override
  String get iapDoubleSnack => '영구 수입 x2 적용!';

  @override
  String get rewardsTitle => '더 벌기 🎁';

  @override
  String get rewardsChip => '더 벌기';

  @override
  String get rewardX2Name => '24시간 수입 x2';

  @override
  String rewardX2Active(int hours) {
    return '적용 중 · $hours시간 남음';
  }

  @override
  String get rewardX2Snack => '24시간 수입 x2 적용!';

  @override
  String rewardGemsName(int gems) {
    return '$gems 💎 받기';
  }

  @override
  String rewardTimeSkip(int hours) {
    return '$hours시간 빨리 감기';
  }

  @override
  String get watchAd => '광고 보기';

  @override
  String get piggyName => '돼지 저금통';

  @override
  String get piggyBreak => '깨기';

  @override
  String piggySnack(String gems) {
    return '저금통: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'VIP 패스 (30일) 👑';

  @override
  String get iapVipDesc => '광고 없음 + 수입 x2 + 매일 50💎 + 오프라인 한도 증가';

  @override
  String get iapVipSnack => 'VIP 30일 활성화! 👑';

  @override
  String get genDuongDen => '흑당 밀크티';

  @override
  String get genBrulee => '브륄레 밀크티';

  @override
  String get genCheeseFoam => '치즈폼';

  @override
  String get genTraTraiCay => '과일차';

  @override
  String get genBobaVang => '황금 보바';

  @override
  String get genGalaxy => '갤럭시 밀크티';

  @override
  String get genQuantumTea => '양자 밀크티';

  @override
  String get genAiTea => 'AI 밀크티';

  @override
  String get genParallelTea => '평행우주 밀크티';

  @override
  String get genNftTea => 'NFT 밀크티';

  @override
  String get genTimeTea => '시간여행 밀크티';

  @override
  String get genMultidimTea => '다차원 밀크티';

  @override
  String get genBlackholeTea => '블랙홀 밀크티';

  @override
  String get genLightTea => '광속 밀크티';

  @override
  String get genRobotTea => '로봇 밀크티';

  @override
  String get genHologramTea => '홀로그램 밀크티';

  @override
  String get genLegendTea => '전설의 밀크티';

  @override
  String get genEternalTea => '영원의 밀크티';

  @override
  String get stage4 => '브륄레 공방';

  @override
  String get stage5 => '치즈폼 공장';

  @override
  String get stage6 => '글로벌 제국';

  @override
  String get stage7 => '증시 상장(IPO)';

  @override
  String get stage8 => '대기업 그룹';

  @override
  String get stage9 => '글로벌 투자 펀드';

  @override
  String get stage10 => '농장 공급망';

  @override
  String get stage11 => 'AI 테크 제국';

  @override
  String get stage12 => '밀크티 전설';

  @override
  String get stage13 => '밀크티 아카데미';

  @override
  String get stage14 => '밀크티 시티';

  @override
  String get stage15 => '밀크티 왕국';

  @override
  String get stage16 => '세계 연합';

  @override
  String get stage17 => '밀크티 행성';

  @override
  String get stage18 => '밀크티의 진리';

  @override
  String get genAcademyTea => '아카데미 밀크티';

  @override
  String get genScholarTea => '학자 밀크티';

  @override
  String get genCityTea => '도시 밀크티';

  @override
  String get genMetroTea => '대도시 밀크티';

  @override
  String get genNationTea => '국민 밀크티';

  @override
  String get genTreatyTea => '조약 밀크티';

  @override
  String get genUnionTea => '동맹 밀크티';

  @override
  String get genWorldTea => '세계 평화 밀크티';

  @override
  String get genPlanetTea => '행성 밀크티';

  @override
  String get genTerraformTea => '테라포밍 밀크티';

  @override
  String get genTruthTea => '진리의 밀크티';

  @override
  String get genUltimateTea => '궁극의 밀크티';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSound => '소리';

  @override
  String get settingsReset => '게임 초기화';

  @override
  String get settingsResetConfirm => '모든 진행 상황을 지우고 처음부터 시작할까요?';

  @override
  String get navHome => '홈';

  @override
  String get navShop => '상점';

  @override
  String get navPrestige => '프랜차이즈';

  @override
  String get navAchievements => '업적';

  @override
  String get wheelName => '럭키 룰렛 🎡';

  @override
  String get spinFree => '무료 돌리기';

  @override
  String get spinAd => '광고 보고 돌리기';

  @override
  String storyChapterLabel(int n) {
    return '$n장';
  }

  @override
  String get storyContinue => '계속';

  @override
  String get storyChoosePrompt => '길을 선택하세요 — 되돌릴 수 없어요:';

  @override
  String get storyLogTitle => '스토리';

  @override
  String get storyLogLocked => '아직 해금되지 않았어요';

  @override
  String storyUnlockWhen(String cond) {
    return '해금 조건: $cond';
  }

  @override
  String storyUnlockAfter(String chapter) {
    return '$chapter 이후 해금';
  }

  @override
  String storyCondFirst(String name) {
    return '첫 $name';
  }

  @override
  String get storyCondRival => '라이벌 물리치기';

  @override
  String storyCondAscension(int n, String name) {
    return '$name #$n';
  }

  @override
  String storyCondM3(int n, String game) {
    return '$game $n단계 클리어';
  }

  @override
  String get rivalEventTitle => '라이벌의 공격!';

  @override
  String get rivalEventIgnore => '무시하기';

  @override
  String get rivalMeterAhead => '앞서는 중';

  @override
  String get rivalMeterEven => '막상막하';

  @override
  String get rivalMeterBehind => '밀리는 중';

  @override
  String get rivalResolvedSnack => '해결했어요. 라이벌이 물러났어요.';

  @override
  String get rivalIgnoredSnack => '그냥 넘겼어요 — 라이벌이 따라붙었어요.';

  @override
  String get navArena => '아레나';

  @override
  String get navCompete => '대결';

  @override
  String get arenaTitle => '아레나';

  @override
  String get arenaIntro => '1대1 대결, 60초 — 코인을 더 많이 번 쪽이 승리!';

  @override
  String get arenaStartButton => '상대 찾기';

  @override
  String get arenaModeTap => '탭 레이스';

  @override
  String get arenaModeMatch3 => '떨어지는 펄';

  @override
  String get arenaMatch3Intro => '60초 동안 3개를 맞춰요 — 상대보다 높은 점수를 얻으면 승리!';

  @override
  String get arenaMatch3Stuck => '더 이상 움직일 수 없어요!';

  @override
  String get arenaQueueWaiting => '상대를 찾는 중…';

  @override
  String get arenaCancelButton => '취소';

  @override
  String get arenaTapButton => '컵을 탭하세요';

  @override
  String get arenaResolving => '경기를 마무리하는 중…';

  @override
  String arenaTierButton(String cost) {
    return '업그레이드 ×2 ($cost 코인)';
  }

  @override
  String arenaTimeLeft(int seconds) {
    return '$seconds초 남음';
  }

  @override
  String arenaOnlineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명 접속 중',
    );
    return '$_temp0';
  }

  @override
  String get arenaYourScore => '내 점수';

  @override
  String get arenaOpponentScore => '상대';

  @override
  String get arenaResultWin => '승리! 🎉';

  @override
  String get arenaResultLose => '패배';

  @override
  String get arenaResultDraw => '무승부';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => '닫기';

  @override
  String get redeemTitle => '선물 코드 입력';

  @override
  String get redeemHint => '코드 입력';

  @override
  String get redeemButton => '사용하기';

  @override
  String redeemSuccess(int gems) {
    return '사용 완료 +$gems 💎!';
  }

  @override
  String get redeemAlreadyClaimed => '이미 사용한 코드예요';

  @override
  String get redeemInvalid => '유효하지 않은 코드예요';

  @override
  String get cloudSaveMenuTitle => '진행 상황 백업';

  @override
  String cloudSaveMenuLinked(String email) {
    return '연결됨: $email';
  }

  @override
  String get cloudSaveMenuUnlinked => '연결 안 됨 — 앱을 삭제하면 진행 상황을 잃을 수 있어요';

  @override
  String get cloudSaveTitle => '진행 상황 백업';

  @override
  String get cloudSaveIntro => '이메일을 연결하면 앱을 삭제하거나 기기를 바꿔도 진행 상황을 복구할 수 있어요.';

  @override
  String get cloudSaveEmailHint => '이메일';

  @override
  String get cloudSaveSendCode => '코드 보내기';

  @override
  String cloudSaveCodeSentTo(String email) {
    return '$email(으)로 인증 코드를 보냈어요';
  }

  @override
  String get cloudSaveCheckSpam => '이메일이 보이지 않나요? 스팸/정크 메일함도 확인해 보세요.';

  @override
  String get cloudSaveCodeHint => '인증 코드';

  @override
  String get cloudSaveVerify => '확인';

  @override
  String get cloudSaveChangeEmail => '다른 이메일 사용';

  @override
  String get cloudSaveResend => '코드 다시 보내기';

  @override
  String cloudSaveResendIn(int seconds) {
    return '코드 다시 보내기 ($seconds초)';
  }

  @override
  String get cloudSaveConflictTitle => '클라우드에서 다른 저장 데이터를 찾았어요';

  @override
  String cloudSaveConflictLocal(String amount) {
    return '이 기기: 누적 $amount 코인';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return '클라우드: 누적 $amount 코인';
  }

  @override
  String get cloudSaveRestoreButton => '클라우드에서 복원';

  @override
  String get cloudSaveKeepLocalButton => '이 기기 데이터 유지';

  @override
  String cloudSaveLinkedStatus(String email) {
    return '연결됨: $email';
  }

  @override
  String get cloudSaveDisconnect => '연결 해제';

  @override
  String get cloudSaveRetry => '다시 시도';

  @override
  String get leaderboardMenuTitle => '리더보드';

  @override
  String get leaderboardTitle => '리더보드';

  @override
  String get leaderboardNicknameIntro => '리더보드에 표시할 이름을 정하세요 (나중에 바꿀 수 있어요):';

  @override
  String get leaderboardNicknameHint => '내 이름';

  @override
  String get leaderboardSubmit => '확인';

  @override
  String leaderboardYourRank(int rank) {
    return '내 순위: #$rank';
  }

  @override
  String leaderboardStars(String stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty => '아직 리더보드에 아무도 없어요 — 바로 당신이에요!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 상위 순위를 지키고 있어요! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return '1위: $top1💎 · 2~3위: $top23💎 · 4~10위: $top410💎 — 순위 유지 중 24시간마다 지급';
  }

  @override
  String get leaderboardChangeName => '이름 변경';

  @override
  String get leaderboardRetry => '다시 시도';

  @override
  String get storySpeedrunMenuTitle => '스피드런';

  @override
  String get storySpeedrunTitle => '스피드런 리더보드';

  @override
  String get storySpeedrunNotCompletedYet =>
      '아직 스토리를 완료하지 않았어요 — 18장을 클리어하면 순위에 올라요.';

  @override
  String get storySpeedrunTabMain => '1막';

  @override
  String get storySpeedrunTabExt => '2막';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      '아직 2막을 완료하지 않았어요 — 28장을 클리어하면 순위에 올라요.';

  @override
  String get storySpeedrunTabExt2 => '3막';

  @override
  String get storySpeedrunExt2NotCompletedYet =>
      '아직 3막을 완료하지 않았어요 — 36장을 클리어하면 순위에 올라요.';

  @override
  String get accessoryMenuTitle => '컬렉션';

  @override
  String get collectionChip => '컬렉션';

  @override
  String get accessoryInventoryTitle => '액세서리 컬렉션';

  @override
  String accessoryInventoryOwned(int owned, int total) {
    return '$owned/$total 수집';
  }

  @override
  String get accessoryRarityCommon => '일반';

  @override
  String get accessoryRarityRare => '희귀';

  @override
  String get accessoryRarityEpic => '영웅';

  @override
  String get accessoryRarityLegendary => '전설';

  @override
  String get accessoryLbTitle => '컬렉션 순위';

  @override
  String accessoryLbCount(int n) {
    return '액세서리 $n개';
  }

  @override
  String get accessoryLbTopTitle => '수집가';

  @override
  String get accessoryLbTitleKing => '액세서리 왕';

  @override
  String get accessoryLbTitleMaster => '컬렉션 마스터';

  @override
  String get accessoryLbEmpty => '아직 순위에 아무도 없어요. 액세서리를 모으면 1위는 당신이에요!';

  @override
  String get accessoryLbNoOwned =>
      '아직 모은 게 없어요 — 일일 퀘스트 3개를 모두 완료하면 얻을 기회가 있어요.';

  @override
  String get accessoryLbError => '순위를 불러오지 못했어요. 나중에 다시 시도해 주세요.';

  @override
  String get accessoryMintLeaf => '민트 잎';

  @override
  String get accessoryCupcake => '컵케이크';

  @override
  String get accessoryCookie => '쿠키';

  @override
  String get accessoryPottedPlant => '화분';

  @override
  String get accessoryCandle => '향초';

  @override
  String get accessoryScarf => '목도리';

  @override
  String get accessoryKite => '종이 연';

  @override
  String get accessoryCap => '모자';

  @override
  String get accessorySeashell => '조개껍데기';

  @override
  String get accessoryMask => '가면';

  @override
  String get accessoryDrum => '작은 북';

  @override
  String get accessoryPalette => '팔레트';

  @override
  String get accessoryCrystalBall => '수정구';

  @override
  String get accessoryLantern => '골동품 등불';

  @override
  String get accessoryUnicorn => '아기 유니콘';

  @override
  String get accessoryDragon => '아기 용';

  @override
  String get accessoryBalloon => '풍선';

  @override
  String get accessoryBowtie => '리본';

  @override
  String get accessorySunglasses => '선글라스';

  @override
  String get accessoryUmbrella => '작은 우산';

  @override
  String get accessoryTeapot => '작은 찻주전자';

  @override
  String get accessoryBell => '작은 종';

  @override
  String get accessoryRibbon => '리본 띠';

  @override
  String get accessoryBookmark => '귀여운 책갈피';

  @override
  String get accessoryWindChime => '풍경';

  @override
  String get accessoryClover => '네잎클로버';

  @override
  String get accessoryBubble => '비눗방울';

  @override
  String get accessorySticker => '스티커';

  @override
  String get accessoryYarn => '털실 뭉치';

  @override
  String get accessoryFan => '부채';

  @override
  String get accessoryBasket => '고리버들 바구니';

  @override
  String get accessoryBead => '구슬 팔찌';

  @override
  String get accessoryLadybug => '작은 무당벌레';

  @override
  String get accessoryKey => '골동품 열쇠';

  @override
  String get accessoryDiamondStone => '다이아몬드 원석';

  @override
  String get accessoryMusicNote => '음표';

  @override
  String get accessoryTelescope => '망원경';

  @override
  String get accessoryAnchor => '닻';

  @override
  String get accessoryFeather => '깃털';

  @override
  String get accessoryHourglass => '모래시계';

  @override
  String get accessoryMap => '낡은 지도';

  @override
  String get accessoryRing => '작은 반지';

  @override
  String get accessoryMagicWand => '마법 지팡이';

  @override
  String get accessoryTrident => '삼지창';

  @override
  String get accessoryPeacock => '아기 공작';

  @override
  String get accessoryComet => '혜성';

  @override
  String get accessoryButterfly => '수정 나비';

  @override
  String get accessoryAngelWing => '천사의 날개';

  @override
  String get accessoryPhoenix => '불사조';

  @override
  String get accessoryGalaxy => '은하수';

  @override
  String get accessoryDonut => '도넛';

  @override
  String get accessoryLollipop => '막대사탕';

  @override
  String get accessoryPretzel => '프레첼';

  @override
  String get accessoryIceCream => '아이스크림 콘';

  @override
  String get accessoryStrawberry => '딸기';

  @override
  String get accessoryCherry => '체리';

  @override
  String get accessoryLemon => '레몬';

  @override
  String get accessoryPeach => '복숭아';

  @override
  String get accessoryPopcorn => '팝콘';

  @override
  String get accessoryHoneyPot => '꿀단지';

  @override
  String get accessoryMilkGlass => '우유 한 잔';

  @override
  String get accessoryTangerine => '귤';

  @override
  String get accessoryChestnut => '밤';

  @override
  String get accessoryMapleLeaf => '단풍잎';

  @override
  String get accessoryCompass => '나침반';

  @override
  String get accessoryRocket => '로켓';

  @override
  String get accessoryViolin => '바이올린';

  @override
  String get accessoryScroll => '고대 두루마리';

  @override
  String get accessoryMicrophone => '마이크';

  @override
  String get accessoryLotus => '연꽃';

  @override
  String get accessoryJellyfish => '해파리';

  @override
  String get accessoryCamera => '카메라';

  @override
  String get accessoryShield => '방패';

  @override
  String get accessoryAmphora => '고대 항아리';

  @override
  String get accessoryRainbow => '무지개';

  @override
  String get accessoryFairy => '요정';

  @override
  String get accessoryDiscoBall => '디스코볼';

  @override
  String get accessoryShiningStar => '빛나는 별';

  @override
  String get accessoryKraken => '크라켄';

  @override
  String get accessoryThunderbolt => '신의 번개';

  @override
  String get accessoryIceCube => '얼음 조각';

  @override
  String get accessoryCroissant => '크루아상';

  @override
  String get accessoryPancakes => '팬케이크';

  @override
  String get accessoryWaffle => '와플';

  @override
  String get accessoryBagel => '베이글';

  @override
  String get accessoryCakeSlice => '케이크 조각';

  @override
  String get accessoryPie => '파이';

  @override
  String get accessoryCandy => '사탕';

  @override
  String get accessoryGrapes => '포도';

  @override
  String get accessoryWatermelon => '수박';

  @override
  String get accessoryPineapple => '파인애플';

  @override
  String get accessoryMango => '망고';

  @override
  String get accessoryKiwi => '키위';

  @override
  String get accessoryBanana => '바나나';

  @override
  String get accessoryApple => '사과';

  @override
  String get accessoryTeddy => '곰 인형';

  @override
  String get accessoryCrayon => '크레용';

  @override
  String get accessoryBucket => '양동이';

  @override
  String get accessoryGuitar => '기타';

  @override
  String get accessoryTrumpet => '트럼펫';

  @override
  String get accessoryPiano => '피아노';

  @override
  String get accessorySaxophone => '색소폰';

  @override
  String get accessoryBanjo => '밴조';

  @override
  String get accessoryMicroscope => '현미경';

  @override
  String get accessoryRingedPlanet => '고리 행성';

  @override
  String get accessoryCrescentMoon => '초승달';

  @override
  String get accessoryBowArrow => '활과 화살';

  @override
  String get accessoryMirror => '거울';

  @override
  String get accessoryFerrisWheel => '대관람차';

  @override
  String get accessoryCarousel => '회전목마';

  @override
  String get accessorySwan => '백조';

  @override
  String get accessoryFlamingo => '홍학';

  @override
  String get accessoryOwl => '부엉이';

  @override
  String get accessoryWhale => '고래';

  @override
  String get accessoryCrown => '왕관';

  @override
  String get accessoryCircusTent => '서커스 텐트';

  @override
  String get accessoryPinata => '피냐타';

  @override
  String get accessoryCastle => '성';

  @override
  String get accessoryGenie => '지니';

  @override
  String get accessoryVolcano => '화산';

  @override
  String get accessoryCarrot => '당근';

  @override
  String get accessoryCorn => '옥수수';

  @override
  String get accessoryTomato => '토마토';

  @override
  String get accessoryAvocado => '아보카도';

  @override
  String get accessoryCoconut => '코코넛';

  @override
  String get accessoryBlueberries => '블루베리';

  @override
  String get accessoryPear => '배';

  @override
  String get accessoryRiceBall => '주먹밥';

  @override
  String get accessoryDumpling => '만두';

  @override
  String get accessorySushi => '초밥';

  @override
  String get accessoryRamen => '라멘';

  @override
  String get accessoryTaco => '타코';

  @override
  String get accessoryPizza => '피자';

  @override
  String get accessoryHotDog => '핫도그';

  @override
  String get accessoryFries => '감자튀김';

  @override
  String get accessoryEgg => '달걀';

  @override
  String get accessoryBread => '식빵';

  @override
  String get accessoryButter => '버터';

  @override
  String get accessoryPuzzle => '퍼즐 조각';

  @override
  String get accessoryDice => '주사위';

  @override
  String get accessoryChessPawn => '체스 폰';

  @override
  String get accessoryDart => '다트판';

  @override
  String get accessoryBowling => '볼링';

  @override
  String get accessoryYoYo => '요요';

  @override
  String get accessoryRollerSkate => '롤러스케이트';

  @override
  String get accessorySkateboard => '스케이트보드';

  @override
  String get accessorySatellite => '인공위성';

  @override
  String get accessoryAlembic => '증류기';

  @override
  String get accessoryDna => 'DNA';

  @override
  String get accessoryTrophy => '트로피';

  @override
  String get accessoryLeopard => '표범';

  @override
  String get accessoryElephant => '코끼리';

  @override
  String get accessoryPanda => '판다';

  @override
  String get accessoryGiraffe => '기린';

  @override
  String get accessoryTurtle => '거북이';

  @override
  String get accessoryKoala => '코알라';

  @override
  String get accessoryPenguin => '펭귄';

  @override
  String get accessorySauropod => '용각류';

  @override
  String get accessoryMermaid => '인어';

  @override
  String get accessoryEagle => '독수리';

  @override
  String get marketTitle => '액세서리 마켓';

  @override
  String get marketTabBrowse => '마켓';

  @override
  String get marketTabMine => '내 아이템';

  @override
  String get marketRecentSalesHeader => '최근 판매';

  @override
  String get marketMerchantTitle => '주간 상인';

  @override
  String get marketFilterAll => '전체';

  @override
  String get marketFilterMissing => '미보유';

  @override
  String get marketSortPriceAsc => '낮은 가격순';

  @override
  String get marketBadgeNew => 'NEW';

  @override
  String marketNeedMore(int n) {
    return '마켓 코인 $n개가 더 필요해요';
  }

  @override
  String get marketNoFilterResults => '필터에 맞는 아이템이 없어요.';

  @override
  String accessoryRevealNew(String name) {
    return '새 액세서리: $name!';
  }

  @override
  String accessoryRevealDuplicate(String name, int gems) {
    return '중복된 $name: +$gems 💎, 마켓에서 팔 수 있는 여분 1개';
  }

  @override
  String accessoryEquipHint(int n, int max) {
    return '전시 $n/$max — 가진 아이템을 탭하면 컵 주위에 전시돼요';
  }

  @override
  String accessoryEquipFull(int max) {
    return '전시 공간이 가득 찼어요 ($max) — 먼저 하나를 빼 주세요';
  }

  @override
  String get accessoryFlairHint => '아이템을 길게 누르면 리더보드 배지로 사용해요';

  @override
  String accessoryFlairSet(String name) {
    return '$name이(가) 리더보드 배지로 설정됐어요';
  }

  @override
  String get accessoryFlairCleared => '리더보드 배지를 해제했어요';

  @override
  String get accessoryFlairFailed => '배지를 설정하지 못했어요 — 아직 동기화되지 않았거나 오프라인이에요';

  @override
  String get marketStarterTitle => '마켓 스타터 팩';

  @override
  String get marketStarterBody =>
      '일반 액세서리 1개 + 판매용 여분 1개 + 마켓 코인 10개를 받아요. 1회 한정.';

  @override
  String get marketStarterClaim => '받기';

  @override
  String get marketStarterDone => '스타터 팩을 받았어요! 컬렉션을 확인해 보세요.';

  @override
  String get marketStarterErrCap => '오늘의 선물이 서버 전체에서 모두 소진됐어요 — 내일 다시 오세요.';

  @override
  String get marketStarterErrNet => '받지 못했어요 — 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get marketIntroTitle => '마켓에 오신 걸 환영해요!';

  @override
  String get marketIntroStep1 =>
      '1. 💎이나 코인을 마켓 코인으로 바꾸세요 (변환 버튼). 마켓에서만 쓸 수 있고 다시 바꿀 수 없어요.';

  @override
  String get marketIntroStep2 => '2. 다른 플레이어가 올린 액세서리를 사서 컬렉션을 완성하세요.';

  @override
  String get marketIntroStep3 => '3. 내 아이템 탭에서 여분을 팔 수 있어요. 수수료는 1%뿐이에요.';

  @override
  String get marketIntroOk => '확인';

  @override
  String get collectionTitle10 => '수집가';

  @override
  String get collectionTitle25 => '감정가';

  @override
  String get collectionTitle40 => '전문 수집가';

  @override
  String get collectionTitle50 => '수집의 전설';

  @override
  String get collectionTitle80 => '마스터 수집가';

  @override
  String get collectionTitle100 => '위대한 수집가';

  @override
  String get collectionTitle120 => '수집의 왕';

  @override
  String get collectionTitle140 => '수집의 현자';

  @override
  String get collectionTitle160 => '수집의 신';

  @override
  String collectionTitleLabel(String title) {
    return '칭호: $title';
  }

  @override
  String collectionMilestoneClaim(int coins) {
    return '+$coins 받기';
  }

  @override
  String collectionMilestoneLocked(int count, int coins) {
    return '$count개 · 마켓 코인 $coins개';
  }

  @override
  String collectionMilestoneDone(int coins) {
    return '마켓 코인 $coins개와 새 칭호를 받았어요!';
  }

  @override
  String get collectionMilestoneErrNet => '받지 못했어요 — 연결을 확인하고 다시 시도해 주세요.';

  @override
  String marketPriceLast(int n) {
    return '최근 판매가: $n';
  }

  @override
  String marketPriceLowest(int n) {
    return '최저 등록가: $n';
  }

  @override
  String marketPriceAvg(int n) {
    return '7일 평균: $n';
  }

  @override
  String get marketWishAdd => '위시리스트에 추가';

  @override
  String get marketWishRemove => '위시리스트에서 제거';

  @override
  String marketWishFull(int max) {
    return '위시리스트가 가득 찼어요 (최대 $max개)';
  }

  @override
  String marketFeeFreeNote(int proceeds) {
    return '주말에는 무료: 마켓 코인 $proceeds개를 전액 받아요';
  }

  @override
  String get marketWeekendBanner => '🎉 주말: 마켓 수수료 0% & 희귀 액세서리 드롭 확률 UP!';

  @override
  String collectionPeekTitle(String name) {
    return '$name님의 컬렉션';
  }

  @override
  String get collectionPeekError => '컬렉션을 불러오지 못했어요 — 나중에 다시 시도해 주세요.';

  @override
  String get collectionShareTooltip => '컬렉션 자랑하기';

  @override
  String collectionShareText(int owned, int total, String items) {
    return '보바 엠파이어에서 액세서리 $owned/$total개를 모았어요! $items';
  }

  @override
  String get collectionShareCopied => '복사했어요 — 채팅에 붙여넣어 자랑해 보세요!';

  @override
  String get collectionCardTitle => '컬렉션 카드';

  @override
  String get collectionShareImage => '이미지 공유';

  @override
  String get collectionShareCopy => '텍스트 복사';

  @override
  String get collectionShareFailed => '공유하지 못했어요 — 텍스트를 복사해 보세요.';

  @override
  String whatsNewTitle(String version) {
    return '$version 새로운 기능';
  }

  @override
  String get whatsNewCollection =>
      '🎀 컬렉션이 액세서리 160종으로 늘고, 수집 가이드와 새 아이템 획득 애니메이션이 추가됐어요';

  @override
  String get whatsNewMilestones =>
      '🏅 80/100/120/140/160 컬렉션 이정표 추가, 더 큰 마켓 코인 보상';

  @override
  String get whatsNewMatch3 => '🧋 떨어지는 펄이 80레벨로 늘고 더 쉬워졌어요 (레벨당 25번 이동)';

  @override
  String get whatsNewAds =>
      '📺 이동이 끝났나요? 광고를 보면 +5회, 횟수 제한 없음. 중간에 나가도 게임이 유지돼요';

  @override
  String get whatsNewFixes =>
      '🛠️ 수정: 스크롤 시 마켓 목록이 찌그러지던 문제, 광고가 게임 이탈로 집계되던 문제, 일부 크래시';

  @override
  String get whatsNewLater => '나중에';

  @override
  String get whatsNewOpen => '컬렉션 보기';

  @override
  String marketWallet(int n) {
    return '마켓 코인 $n개';
  }

  @override
  String get marketError => '마켓을 불러오지 못했어요. 나중에 다시 시도해 주세요.';

  @override
  String get marketEmptyBrowse => '아직 등록된 물건이 없어요.';

  @override
  String get marketBuyButton => '구매';

  @override
  String get marketBoughtToast => '구매 완료!';

  @override
  String marketConfirmBuy(int price) {
    return '마켓 코인 $price개로 구매할까요?';
  }

  @override
  String marketPriceTag(int price) {
    return '마켓 코인 $price개';
  }

  @override
  String get marketMyListingsHeader => '내 등록 목록';

  @override
  String get marketEmptyMine => '아직 등록한 물건이 없어요.';

  @override
  String get marketCancelButton => '등록 취소';

  @override
  String get marketCancelledToast => '등록을 취소했어요.';

  @override
  String get marketSellableHeader => '판매 가능한 액세서리';

  @override
  String get marketEmptySellable => '아직 판매할 액세서리가 없어요.';

  @override
  String get marketListedToast => '등록 완료!';

  @override
  String get marketListButton => '판매 등록';

  @override
  String get marketPriceLabel => '가격 (마켓 코인)';

  @override
  String marketListFeeNote(int proceeds, int fee) {
    return '수수료 1%(−$fee)를 제외하고 마켓 코인 $proceeds개를 받아요';
  }

  @override
  String get marketConvertButton => '변환';

  @override
  String get marketConvertTitle => '마켓 코인으로 변환';

  @override
  String get marketConvertAmountLabel => '필요한 마켓 코인';

  @override
  String marketConvertCostGems(String cost) {
    return '비용: $cost 💎';
  }

  @override
  String marketConvertCostMoney(String cost) {
    return '비용: $cost 💰';
  }

  @override
  String get marketConvertSuccessToast => '변환 완료!';

  @override
  String get marketConvertFailToast => '변환에 실패했어요 — 잔액이 부족하거나 네트워크 오류예요.';

  @override
  String get storySpeedrunEmpty => '아직 스토리를 완료한 사람이 없어요 — 첫 번째가 되어 보세요!';

  @override
  String get arenaLeaderboardMenuTitle => 'PK 리더보드';

  @override
  String get arenaLeaderboardTitle => 'PK 리더보드';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      '아직 아레나 경기를 하지 않았어요 — 한 번 이기면 여기에 표시돼요.';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '$wins승 - $losses패';
  }

  @override
  String get ascensionTitle => '승천';

  @override
  String get ascensionOpen => '승천 ⏳';

  @override
  String get ascensionIntro =>
      '모든 별과 별 상점 혜택을 ⏳ 승천 포인트로 바꿔 더 강력한 영구 혜택을 얻어요. 처음부터 다시 시작해요.';

  @override
  String ascensionProgress(int percent) {
    return '해금까지 진행도: $percent%';
  }

  @override
  String get ascensionPointsNow => '보유 포인트';

  @override
  String get ascensionPointsGain => '승천 시 획득';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ 별, 별 상점 혜택 전부, 코인, 업그레이드 레벨, 단계가 초기화돼요. 💎, 업적, 스토리는 유지돼요. 리더보드 별은 0이 돼요 (누적 수입 기준 순위는 그대로).';

  @override
  String ascensionConfirm(int points) {
    return '승천 (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => '아직 이용할 수 없어요';

  @override
  String ascensionSuccess(int points) {
    return '새로운 시대가 시작돼요! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => '승천 혜택 ⏳';

  @override
  String ascensionShopSpendable(int points) {
    return '사용 가능한 ⏳ $points';
  }

  @override
  String ascensionCost(int cost) {
    return '$cost ⏳';
  }

  @override
  String get ascensionMaxed => '최대';

  @override
  String get ascensionIncomeName => '동력원';

  @override
  String ascensionIncomeDesc(int percent) {
    return '레벨당 수입 +$percent%';
  }

  @override
  String get ascensionStarBonusName => '빛나는 별';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '레벨당 별 1개의 효과 +$percent%';
  }

  @override
  String get ascensionStarGainName => '풍성한 별';

  @override
  String ascensionStarGainDesc(int percent) {
    return '레벨당 별 획득률 +$percent%';
  }

  @override
  String get achAscend => '처음으로 승천하기';

  @override
  String get dailyQuestsTitle => '일일 퀘스트';

  @override
  String get dailyQuestsChip => '퀘스트';

  @override
  String get dailyQuestsBonusLabel => '퀘스트 3개 모두 완료';

  @override
  String dailyQuestsResetsIn(Object time) {
    return '$time 후 새 퀘스트';
  }

  @override
  String get dailyQuestClaimed => '수령 완료';

  @override
  String dqTap(int n) {
    return '컵을 $n번 탭하기';
  }

  @override
  String dqBuy(int n) {
    return '업그레이드 $n개 구매';
  }

  @override
  String dqEarn(Object amount) {
    return '코인 $amount 벌기';
  }

  @override
  String get dqCat => '황금 고양이 잡기';

  @override
  String get dqVip => 'VIP 손님 응대하기';

  @override
  String get dqSpin => '럭키 룰렛 돌리기';

  @override
  String get notifyOfflineFullTitle => '코인 창고가 가득 찼어요! 🧋';

  @override
  String get notifyOfflineFullBody => '가게에 코인이 더 쌓이지 않아요 — 와서 받고 새 근무를 시작하세요.';

  @override
  String get notifyDailyTitle => '새로운 하루, 새로운 퀘스트 📋';

  @override
  String get notifyDailyBody => '일일 출석, 무료 룰렛, 퀘스트 3개가 기다리고 있어요.';

  @override
  String get notifyD3Title => '가게가 당신을 기다려요 🧋';

  @override
  String get notifyD3Body => '3일이 지났어요 — 코인 창고는 진작 가득 찼어요. 와서 받아 가세요.';

  @override
  String get notifyD7Title => '벌써 일주일이에요! 🧋';

  @override
  String get notifyD7Body => '승천, 떨어지는 펄 등 새로운 콘텐츠가 기다리고 있어요.';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 이벤트: 수입 ×$mult! $timeLeft 남음';
  }

  @override
  String get navMatch3 => '펄';

  @override
  String get m3Title => '떨어지는 펄';

  @override
  String m3Level(int n) {
    return '$n단계';
  }

  @override
  String get m3Locked => '잠김';

  @override
  String m3MovesLeft(int n) {
    return '$n번 남음';
  }

  @override
  String get m3Score => '점수';

  @override
  String get m3Win => '단계 클리어!';

  @override
  String get m3Lose => '목표 미달성';

  @override
  String get m3Retry => '다시 도전';

  @override
  String get m3Next => '다음 단계';

  @override
  String get m3Back => '단계 목록';

  @override
  String get m3Reward => '보상';

  @override
  String get m3NoReward => '이 단계의 보상은 이미 받았어요';

  @override
  String get m3LeaveTitle => '이 게임을 나갈까요?';

  @override
  String get m3LeaveBody => '앱을 종료하기 전까지 진행 중인 게임이 유지됩니다.';

  @override
  String get m3LeaveStay => '계속하기';

  @override
  String get m3LeaveConfirm => '나가기';

  @override
  String get accessoryHowToTitle => '수집 가이드';

  @override
  String get accessoryHowToButton => '가이드';

  @override
  String get accessoryHtp1 =>
      '🎯 목표: 모든 아이템을 모으세요. 액세서리는 장식 전용(수입 증가 없음)이지만 컵 주위에 장식하고, 자랑하고, 컬렉션 순위를 올릴 수 있어요.';

  @override
  String get accessoryHtp2 =>
      '🎁 얻는 방법: 일일 퀘스트 3개 완료 · 떨어지는 진주 이정표 레벨(10/30/60) 클리어 · 기본 룰렛의 상자 칸 · 승천할 때마다 · 💎로 액세서리 팩 구매.';

  @override
  String get accessoryHtp3 =>
      '🎰 액세서리 룰렛: 1회마다 광고 1번 시청 또는 💎가 필요해요. 광고 회전은 하루 횟수 제한이 있어요.';

  @override
  String get accessoryHtp4 =>
      '✨ 희귀도: 일반 → 희귀 → 영웅 → 전설. 주말과 기념일에는 영웅/전설 확률이 올라가고, 희귀/영웅 팩은 최소 희귀도를 보장하며, 기념일에는 한정 아이템이 든 축제 팩이 열려요.';

  @override
  String accessoryHtp5(int gems) {
    return '♻️ 중복으로 나오면 $gems 💎와 시장에서 팔 수 있는 여분 1개를 받아요.';
  }

  @override
  String get accessoryHtp6 =>
      '🏬 시장: 여분을 팔아 시장 코인을 얻고, 부족한 아이템은 다른 플레이어에게서 사세요(수수료 1%). 시장 코인은 코인이나 💎로 충전하며 되돌릴 수 없어요.';

  @override
  String get accessoryHtp7 =>
      '🏅 컬렉션 이정표(10/25/40/50/80/100/120/140/160개)는 시장 코인을 줘요. 원하는 아이템은 위시리스트에 담고, 순위는 서로 다른 아이템 수로 계산해요.';

  @override
  String get accessoryHtp8 => '👆 보유한 아이템을 탭하면 메인 화면의 컵 주위에 장식돼요.';

  @override
  String m3AdMoves(int n) {
    return '광고 시청: $n번 추가';
  }

  @override
  String get m3KeepPlaying => '계속 플레이';

  @override
  String get m3Pause => '잠시 쉬기';

  @override
  String get m3GoalReached => '목표 달성!';

  @override
  String m3NeedScore(String n, int star) {
    return '$star★까지 $n점 더';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return '$star★까지 $icon $n개 더';
  }

  @override
  String get m3HowToTitle => '떨어지는 펄 플레이 방법';

  @override
  String get m3HtpSwap =>
      '🔄 인접한 두 타일을 바꿔서 (하나를 탭한 뒤 다른 하나를 탭하거나 스와이프) 같은 종류 3개 이상을 한 줄로 맞춰요. 줄이 만들어지지 않는 교환은 인정되지 않아요.';

  @override
  String get m3HtpGoal =>
      '🎯 단계마다 목표가 하나 있어요: 점수에 도달하거나 한 종류의 타일을 충분히 모으기. 목표는 위쪽 바에 표시돼요.';

  @override
  String get m3HtpMoves =>
      '👣 이동 횟수는 제한되어 있어요. 다 쓰면 단계가 끝나니, 더 많은 타일을 지우는 교환을 우선하세요.';

  @override
  String get m3HtpChain =>
      '⛓️ 지워진 타일 위의 타일이 떨어지고, 새 줄이 만들어지면 연쇄가 일어나요 — 뒤로 갈수록 점수가 훨씬 커요.';

  @override
  String get m3HtpSpecial =>
      '💥 4개를 맞추면 십자 폭탄(가로줄과 세로줄 전체 삭제)이 생겨요. 5개 이상을 맞추면 컬러 폭탄 🌈(해당 종류 타일 전부 삭제)이 생겨요. 일반 타일처럼 맞춰서 터뜨리세요.';

  @override
  String get m3HtpStars =>
      '⭐ 바의 별 세 개는 세 단계예요. 첫 번째에 도달하면 클리어이고, \"계속 플레이\"를 누르면 남은 이동 횟수로 더 많은 별에 도전할 수 있어요.';

  @override
  String get m3HtpReward =>
      '🎁 보상은 각 별 단계에 처음 도달할 때만 지급돼요. 연습으로 다시 플레이해도 추가 보상은 없어요.';

  @override
  String get m3LbTitle => '떨어지는 펄 순위';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty => '아직 순위에 아무도 없어요. 몇 단계를 클리어하면 1위는 당신이에요!';

  @override
  String get m3LbNoStars => '아직 별이 없어요 — 한 단계를 클리어하면 순위에 올라요.';

  @override
  String m3LbLevels(int n) {
    return '$n단계';
  }

  @override
  String get m3LbError => '순위를 불러오지 못했어요. 나중에 다시 시도해 주세요.';

  @override
  String eventBanner(String name) {
    return '🎉 $name 이벤트';
  }

  @override
  String eventTitle(String name) {
    return '$name 이벤트';
  }

  @override
  String eventEndsIn(String time) {
    return '$time 후 종료';
  }

  @override
  String eventPoints(int n) {
    return '이벤트 포인트: $n';
  }

  @override
  String get eventRedeemHint =>
      '퀘스트를 완료해 포인트를 모으고 한정 아이템을 무료로 교환하세요. 포인트로 전체 세트는 못 얻으니 마음에 드는 것을 고르세요!';

  @override
  String eventRedeemCost(int cost) {
    return '$cost점';
  }

  @override
  String get eventLbTitle => '이벤트 랭킹';

  @override
  String get eventLbEmpty => '아직 아무도 없어요. 몇 번만 탭하면 1등!';

  @override
  String get eventLbNoScore => '아직 점수가 없어요. 컵을 탭하고, 고양이를 잡고, VIP를 응대해 보세요.';

  @override
  String eventLbMyScore(int n) {
    return '내 점수: $n';
  }

  @override
  String eventLbScore(int n) {
    return '$n점';
  }

  @override
  String eventBuff(String mult) {
    return '이벤트 기간 동안 수익 ×$mult';
  }

  @override
  String get guildTitle => '길드';

  @override
  String get guildIntro => '길드를 만들거나 가입해 함께 주간 목표를 달성하고 보상을 받으세요.';

  @override
  String get guildCreate => '길드 만들기';

  @override
  String get guildJoin => '가입';

  @override
  String guildMembersCount(int n, int max) {
    return '$n/$max명';
  }

  @override
  String guildWeekTotal(int n) {
    return '이번 주: $n점';
  }

  @override
  String get guildNameLabel => '길드 이름 (3-20자)';

  @override
  String get guildTagLabel => '태그 (영문/숫자 2-4자)';

  @override
  String get guildLeave => '길드 탈퇴';

  @override
  String get guildLeaveConfirm => '이 길드를 탈퇴할까요? 이번 주 내 점수는 더 이상 반영되지 않아요.';

  @override
  String get guildKick => '내보내기';

  @override
  String guildKickConfirm(String name) {
    return '$name님을 길드에서 내보낼까요?';
  }

  @override
  String get guildReport => '길드 신고';

  @override
  String get guildReportSent => '신고가 접수되었어요. 감사합니다.';

  @override
  String get guildGoalTitle => '주간 목표';

  @override
  String get guildClaim => '받기';

  @override
  String guildNeedPoints(int n) {
    return '받으려면 ≥$n점 기여 필요';
  }

  @override
  String guildYourPoints(int n) {
    return '내 기여: $n점';
  }

  @override
  String get guildOwner => '길드장';

  @override
  String get guildEmpty => '공개 길드가 아직 없어요. 첫 길드를 만들어 보세요!';

  @override
  String get guildErrNameTaken => '이미 사용 중인 길드 이름이에요.';

  @override
  String get guildErrFull => '길드 인원이 가득 찼어요.';

  @override
  String get guildErrAlready => '이미 길드에 가입되어 있어요.';

  @override
  String get guildErrInvalid => '이름 또는 태그가 올바르지 않아요.';

  @override
  String get guildErrNotFound => '길드를 찾을 수 없어요 (폐쇄되었을 수 있어요).';

  @override
  String get guildErrContribution => '이번 주에 더 기여해야 해요.';

  @override
  String get guildErrNetwork => '연결할 수 없어요. 다시 시도해 주세요.';

  @override
  String get guildLbTitle => '길드 랭킹';

  @override
  String get guildLbEmpty => '이번 주 점수가 있는 길드가 아직 없어요.';

  @override
  String guildRewardGot(int gems) {
    return '+$gems 💎 획득';
  }

  @override
  String guildRewardGotAccessory(int gems, String name) {
    return '+$gems 💎 와 $name 획득';
  }

  @override
  String guildPoints(int n) {
    return '$n점';
  }

  @override
  String guildCreateCost(int n) {
    return '길드 생성 비용: $n 💎';
  }

  @override
  String guildErrGems(int n) {
    return '길드를 만들려면 $n 💎가 필요해요.';
  }

  @override
  String get guildApprovalSwitch => '가입 신청은 길드장이 승인';

  @override
  String get guildRequestJoin => '신청';

  @override
  String get guildRequestSent => '신청을 보냈어요. 길드장의 승인을 기다려 주세요.';

  @override
  String get guildRequestPending => '승인 대기';

  @override
  String guildRequestsTitle(int n) {
    return '가입 신청 ($n)';
  }

  @override
  String get guildAccept => '승인';

  @override
  String get guildReject => '거절';

  @override
  String get guildErrApproval => '이 길드는 길드장 승인이 필요해요. \"신청\"을 눌러 주세요.';

  @override
  String get guildErrRequestsFull => '이 길드에 대기 중인 신청이 너무 많아요.';

  @override
  String cloudSaveConflictGems(String local, String cloud) {
    return '💎 이 기기: $local · 클라우드: $cloud';
  }

  @override
  String get cloudRemindTitle => '진행 상황을 보호하세요';

  @override
  String get cloudRemindBody =>
      '이메일을 연결하지 않았어요. 기기를 바꾸거나 게임을 다시 설치하면 진행 상황(코인, 💎, 액세서리, 마켓 코인)이 모두 사라져요. 연결은 1분이면 되고 무료예요.';

  @override
  String get cloudRemindLink => '지금 연결';

  @override
  String get cloudRemindLater => '나중에';
}
