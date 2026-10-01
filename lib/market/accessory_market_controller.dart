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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  });

  final List<MarketListing> listings;
  final List<MarketListing> myListings;
  final int walletBalance;
  final String? myUserId;
}

class AccessoryMarketError extends AccessoryMarketViewState {
  const AccessoryMarketError(this.message);
  final String message;
}

class AccessoryMarketController extends Notifier<AccessoryMarketViewState> {
  AccessoryMarketRepository? _repo;

  /// UI gán trước khi gọi bất kỳ hành động nào.
  List<String> Function()? getLocalOwnedAccessories;
  void Function(String accessoryId)? onAccessoryRemovedLocally;
  void Function(String accessoryId)? onAccessoryAddedLocally;

  @override
  AccessoryMarketViewState build() => const AccessoryMarketLoading();

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
    final serverOwned = await _repository.fetchServerOwnedIds();
    final missing = local.where((id) => !serverOwned.contains(id));
    for (final id in missing) {
      try {
        await _repository.registerDrop(id);
      } catch (e) {
        // Lỗi mạng giữa chừng — bỏ qua, lần mở Chợ sau sẽ thử lại (vẫn
        // idempotent, không có gì bị mất).
        developer.log('đối chiếu sở hữu lỗi cho $id: $e', name: 'Market');
      }
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AccessoryMarketLoading();
    try {
      await _reconcileOwnership();
      final listings = await _repository.fetchActiveListings();
      final myListings = await _repository.fetchMyActiveListings();
      final balance = await _repository.fetchWalletBalance();
      state = AccessoryMarketLoaded(
        listings: listings,
        myListings: myListings,
        walletBalance: balance,
        myUserId: Supabase.instance.client.auth.currentUser?.id,
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
        AccessoryMarketController.new);
