import 'package:get/get.dart';
import '../data/approval_models.dart';
import '../data/approvals_repository.dart';

final class ExtensionRequestsController extends GetxController {
  ExtensionRequestsController({required ApprovalsRepository repository})
      : _repository = repository;

  final ApprovalsRepository _repository;

  final RxBool isLoading = true.obs;
  final RxList<ScreenTimeExtensionRequest> allRequests =
      <ScreenTimeExtensionRequest>[].obs;
  final RxInt currentTab = 0.obs; // 0: Pending, 1: History
  final RxnString message = RxnString();

  List<ScreenTimeExtensionRequest> get pendingRequests => allRequests
      .where((r) => r.status == ApprovalStatus.pending)
      .toList();

  List<ScreenTimeExtensionRequest> get historyRequests => allRequests
      .where((r) => r.status != ApprovalStatus.pending)
      .toList();

  List<ScreenTimeExtensionRequest> get displayedRequests =>
      currentTab.value == 0 ? pendingRequests : historyRequests;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final res = await _repository.loadExtensionRequests();
    if (isClosed) return;
    if (res.isOk) {
      allRequests.assignAll(res.valueOrNull ?? []);
    } else {
      message.value = res.failureOrNull?.message;
    }
    isLoading.value = false;
  }

  Future<void> approve(
    String requestId, {
    int? grantedMinutes,
    String? note,
  }) async {
    final res = await _repository.respondExtensionRequest(
      requestId,
      approve: true,
      grantedMinutes: grantedMinutes,
      note: note,
    );
    if (res.isOk) {
      message.value = 'Extension approved ($grantedMinutes mins)';
      await load();
    } else {
      message.value = res.failureOrNull?.message;
    }
  }

  Future<void> reject(String requestId, {String? note}) async {
    final res = await _repository.respondExtensionRequest(
      requestId,
      approve: false,
      note: note,
    );
    if (res.isOk) {
      message.value = 'Extension request rejected';
      await load();
    } else {
      message.value = res.failureOrNull?.message;
    }
  }

  Future<void> generateSample() async {
    final res = await _repository.generateSampleExtensionRequest();
    if (res.isOk) {
      message.value = 'Sample extension request generated';
      await load();
    }
  }
}
