import 'package:boba_empire/referral/referral_repository.dart';

class FakeReferralRepo implements ReferralRepository {
  ReferralStatus current = const ReferralStatus(code: 'ABC234');
  final calls = <String>[];
  final Map<String, ReferralFailure> failures = {};
  int? lastStage;

  void _hit(String name) {
    calls.add(name);
    final f = failures.remove(name);
    if (f != null) throw ReferralException(f);
  }

  @override
  Future<ReferralStatus> status() async {
    _hit('status');
    return current;
  }

  @override
  Future<int> redeem(String code) async {
    _hit('redeem');
    return referralInviteeReward;
  }

  @override
  Future<int> claim() async {
    _hit('claim');
    final n = current.claimable;
    current = ReferralStatus(code: current.code, invited: current.invited, reached: current.reached);
    return n * referralInviterReward;
  }

  @override
  Future<void> reportStage(int stage) async {
    _hit('reportStage');
    lastStage = stage;
  }
}
