/// Điều phối UI Chợ Phụ kiện: tải danh sách đang bán + của mình + số dư Xu
/// Chợ, và thực hiện đăng bán/mua/huỷ. Không có bước đặt tên (khác các bảng
/// xếp hạng) — chợ không hiện tên người bán, chỉ hiện món + giá.
///
/// GameState (ownedAccessories) được UI mutate qua 2 callback
/// [onAccessoryRemovedLocally]/[onAccessoryAddedLocally] sau khi RPC Supabase
/// xác nhận thành công — cùng khuôn cloud_save_controller.dart (không đụng
/// thẳng GameController từ đây, giữ 2 module tách biệt).
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/locale_provider.dart';
import 'accessory_market_repository.dart';

sealed class AccessoryMarketViewState {
  const AccessoryMarketViewState();
}

class AccessoryMarketLoading extends AccessoryMarketViewState {
  const AccessoryMarketLoading();
}

class AccessoryMarketLoaded extends AccessoryMarketViewState {
  const AccessoryMarketLoaded({
    required this.listings,
    required this.myListings,
    required this.walletBalance,
    required this.myUserId,
    this.recentSales = const [],
  });

  final List<MarketListing> listings;
  final List<MarketListing> myListings;
  final int walletBalance;
  final String? myUserId;
  final List<RecentSale> recentSales;
}

class AccessoryMarketError extends AccessoryMarketViewState {
  const AccessoryMarketError(this.message);
  final String message;
}

class AccessoryMarketController extends Notifier<AccessoryMarketViewState> {
  AccessoryMarketRepository? _repo;

  /// UI gán trước khi gọi bất kỳ hành động nào.
  List<String> Function()? getLocalOwnedAccessories;
  Map<String, int> Function()? getLocalSpares;
  void Function(String accessoryId)? onAccessoryRemovedLocally;
  void Function(String accessoryId)? onAccessoryAddedLocally;

  RealtimeChannel? _channel;
  Timer? _debounce;

  @override
  AccessoryMarketViewState build() {
    ref.onDispose(stopRealtime);
    return const AccessoryMarketLoading();
  }

  /// Lắng nghe thay đổi `accessory_listings` (đăng/bán/huỷ — của bất kỳ ai) và
  /// làm mới âm thầm, để người bán thấy món "đã bán" ngay mà không phải thoát
  /// ra vào lại. Cần bảng nằm trong publication supabase_realtime (xem SQL).
  /// Lỗi nuốt im lặng — không có realtime thì Chợ vẫn dùng được (kéo để làm mới).
  void startRealtime() {
    if (_channel != null) return;
    try {
      _channel = Supabase.instance.client
          .channel('accessory-market')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'accessory_listings',
            callback: (_) => _scheduleRefresh(),
          )
          .subscribe();
    } catch (e) {
      developer.log('bật realtime Chợ lỗi: $e', name: 'Market');
    }
  }

  void stopRealtime() {
    _debounce?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel == null) return;
    try {
      Supabase.instance.client.removeChannel(channel);
    } catch (e) {
      developer.log('tắt realtime Chợ lỗi: $e', name: 'Market');
    }
  }

  // Một lần mua có thể bắn vài sự kiện liên tiếp — gộp lại thành 1 lần tải.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      refresh(silent: true);
    });
  }

  AccessoryMarketRepository get _repository =>
      _repo ??= AccessoryMarketRepository(Supabase.instance.client);

  /// So local (`GameState.ownedAccessories`) với server
  /// (`accessory_server_ownership`) — món nào local có mà server CHƯA xác
  /// nhận thì đăng ký bù. Bù cho 2 trường hợp: (a) người chơi mở Chợ lần
  /// đầu, có sẵn phụ kiện từ trước khi Chợ ra đời; (b) lần `registerDrop`
  /// lúc rớt món bị lỗi mạng, chưa kịp đăng ký. An toàn gọi lại mỗi lần mở
  /// Chợ — registerDrop là idempotent.
  Future<void> _reconcileOwnership() async {
    final local = getLocalOwnedAccessories?.call() ?? const <String>[];
    if (local.isEmpty) return;
    final server = await _repository.fetchServerCopies();
    final spares = getLocalSpares?.call() ?? const <String, int>{};
    for (final id in local) {
      final copies = 1 + (spares[id] ?? 0);
      if ((server[id] ?? 0) >= copies) continue;
      try {
        await _repository.registerDrop(id, copies: copies);
      } catch (e) {
        // Lỗi mạng giữa chừng — bỏ qua, lần mở Chợ sau sẽ thử lại (vẫn
        // idempotent, không có gì bị mất).
        developer.log('đối chiếu sở hữu lỗi cho $id: $e', name: 'Market');
      }
    }
  }

  /// Đăng ký token FCM để server đẩy "món của bạn đã bán được" lúc app không
  /// mở. [ask] = true (vừa đăng bán — đúng lúc người chơi hiểu vì sao cần)
  /// mới xin quyền; ngược lại chỉ đăng ký lại khi đã được cấp từ trước. Lỗi
  /// nuốt im lặng: thông báo chỉ là phần thêm, không được làm hỏng Chợ.
  Future<void> _registerPush({required bool ask}) async {
    try {
      final fcm = FirebaseMessaging.instance;
      final settings =
          ask ? await fcm.requestPermission() : await fcm.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      // iOS: token APNs về SAU lúc bấm "Cho phép" vài giây — gọi getToken sớm
      // thì ném apns-token-not-set (bị nuốt → không bao giờ đăng ký được).
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 5 && await fcm.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      final token = await fcm.getToken();
      if (token == null) return;
      final locale = ref.read(localeProvider)?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      await _repository.registerPushToken(
        token,
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        locale,
      );
    } catch (e) {
      developer.log('đăng ký push lỗi: $e', name: 'Market');
    }
  }

  /// Đẩy danh sách muốn có lên server (để nhận thông báo khi có người đăng bán).
  /// [askPush]: vừa THÊM món → đúng lúc người chơi hiểu vì sao cần xin quyền
  /// thông báo. Lỗi nuốt im lặng — wishlist vẫn còn cục bộ, lần sau đồng bộ lại.
  Future<void> syncWishlist(List<String> ids, {bool askPush = false}) async {
    try {
      await _repository.setWishlist(ids);
      if (askPush) unawaited(_registerPush(ask: true));
    } catch (e) {
      developer.log('đồng bộ danh sách muốn có lỗi: $e', name: 'Market');
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      state = const AccessoryMarketLoading();
      unawaited(_registerPush(ask: false));
    }
    try {
      await _reconcileOwnership();
      final listings = await _repository.fetchActiveListings();
      final myListings = await _repository.fetchMyActiveListings();
      final balance = await _repository.fetchWalletBalance();
      // Phần phụ: lỗi (vd SQL mới chưa deploy) không được làm hỏng cả Chợ.
      final recentSales = await _repository.fetchRecentSales().catchError(
        (_) => const <RecentSale>[],
      );
      state = AccessoryMarketLoaded(
        listings: listings,
        myListings: myListings,
        walletBalance: balance,
        myUserId: Supabase.instance.client.auth.currentUser?.id,
        recentSales: recentSales,
      );
    } catch (e) {
      _fail(e);
    }
  }

  /// Đăng bán [accessoryId] với giá [price] Xu Chợ. Trả về thông báo lỗi
  /// (tiếng Việt, controller không có BuildContext để dịch) hoặc null nếu
  /// thành công.
  Future<String?> listItem(String accessoryId, int price) async {
    try {
      await _repository.listAccessory(accessoryId, price);
      unawaited(_registerPush(ask: true));
      onAccessoryRemovedLocally?.call(accessoryId);
      await refresh(silent: true);
      return null;
    } on PostgrestException catch (e) {
      if (e.message.contains('not_owned')) {
        return 'Server chưa ghi nhận bạn sở hữu món này — thử mở lại Chợ để '
            'đối chiếu rồi đăng bán lại.';
      }
      return 'Đăng bán thất bại, thử lại sau nhé.';
    } catch (e) {
      return 'Đăng bán thất bại, thử lại sau nhé.';
    }
  }

  Future<String?> buyItem(MarketListing listing) async {
    try {
      await _repository.buyListing(listing.id);
      onAccessoryAddedLocally?.call(listing.accessoryId);
      await refresh(silent: true);
      return null;
    } on PostgrestException catch (e) {
      if (e.message.contains('insufficient_balance')) {
        return 'Không đủ Xu Chợ.';
      }
      if (e.message.contains('listing_not_active')) {
        return 'Món này vừa được bán hoặc huỷ — danh sách đã tự cập nhật.';
      }
      if (e.message.contains('cannot_buy_own_listing')) {
        return 'Không thể tự mua món mình đăng.';
      }
      return 'Mua thất bại, thử lại sau nhé.';
    } catch (e) {
      return 'Mua thất bại, thử lại sau nhé.';
    } finally {
      // Dù lỗi (VD listing_not_active) danh sách cũng có thể đã đổi —
      // refresh âm thầm để UI không hiện listing đã bán/huỷ.
      unawaited(refresh(silent: true));
    }
  }

  Future<String?> cancelItem(MarketListing listing) async {
    try {
      await _repository.cancelListing(listing.id);
      onAccessoryAddedLocally?.call(listing.accessoryId);
      await refresh(silent: true);
      return null;
    } catch (e) {
      return 'Huỷ đăng thất bại, thử lại sau nhé.';
    }
  }

  void _fail(Object error) {
    developer.log('$error', name: 'Market');
    state = const AccessoryMarketError('Không tải được Chợ, thử lại sau nhé.');
  }
}

final accessoryMarketControllerProvider =
    NotifierProvider<AccessoryMarketController, AccessoryMarketViewState>(
      AccessoryMarketController.new,
    );

/// Thương gia tuần (null = chưa có / không tải được) — dùng ở bảng xếp hạng
/// Sưu tập và tab "Của tôi" của Chợ.
final marketMerchantIdProvider = FutureProvider<String?>((ref) async {
  try {
    return await AccessoryMarketRepository(
      Supabase.instance.client,
    ).fetchWeeklyTopSeller();
  } catch (_) {
    return null;
  }
});
