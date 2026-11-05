import 'package:get/get.dart';
import '../data/approval_models.dart';
import '../data/approvals_repository.dart';

final class AppApprovalsController extends GetxController {
  AppApprovalsController({required ApprovalsRepository repository})
      : _repository = repository;

  final ApprovalsRepository _repository;

  final RxBool isLoading = true.obs;
  final RxList<AppInstallRequest> allRequests = <AppInstallRequest>[].obs;
  final RxInt currentTab = 0.obs; // 0: Pending, 1: Approved, 2: Rejected
  final RxnString message = RxnString();

  List<AppInstallRequest> get pendingRequests => allRequests
      .where((r) => r.status == ApprovalStatus.pending)
      .toList();

  List<AppInstallRequest> get approvedRequests => allRequests
      .where((r) => r.status == ApprovalStatus.approved)
      .toList();

  List<AppInstallRequest> get rejectedRequests => allRequests
      .where((r) => r.status == ApprovalStatus.rejected)
      .toList();

  List<AppInstallRequest> get displayedRequests => switch (currentTab.value) {
        0 => pendingRequests,
        1 => approvedRequests,
        2 => rejectedRequests,
        _ => pendingRequests,
      };

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final res = await _repository.loadAppRequests();
    if (isClosed) return;
    if (res.isOk) {
      allRequests.assignAll(res.valueOrNull ?? []);
    } else {
      message.value = res.failureOrNull?.message;
    }
    isLoading.value = false;
  }

  Future<void> approve(String requestId, {String? note}) async {
    final res = await _repository.respondAppRequest(
      requestId,
      approve: true,
      note: note,
    );
    if (res.isOk) {
      message.value = 'Request approved';
      await load();
    } else {
      message.value = res.failureOrNull?.message;
    }
  }

  Future<void> reject(String requestId, {String? note}) async {
    final res = await _repository.respondAppRequest(
      requestId,
      approve: false,
      note: note,
    );
    if (res.isOk) {
      message.value = 'Request rejected';
      await load();
    } else {
      message.value = res.failureOrNull?.message;
    }
  }

  Future<void> generateSample() async {
    final res = await _repository.generateSampleAppRequest();
    if (res.isOk) {
      message.value = 'Sample request generated';
      await load();
    }
  }
}
