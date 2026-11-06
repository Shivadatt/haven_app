import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../../core/permissions/child_permission.dart';
import '../../../core/permissions/permission_status_source.dart';

/// One rendered card's worth of data: the permission and whatever the source
/// answered — a blocked read stays a blocked read all the way to the widget,
/// so the UI can never print granted/denied without a real read (brief §4 E).
final class PermissionCardState {
  const PermissionCardState({required this.permission, required this.status});

  final ChildPermission permission;
  final Result<PermissionStatus> status;
}

/// Loads all four permission states once, with retry — the repository
/// controller pattern from the parent app. Stage 1's source answers `blocked`
/// for every entry; that is data, not an error to hide.
final class PermissionsController extends GetxController {
  PermissionsController({required this.source});

  final PermissionStatusSource source;

  final RxBool isLoading = true.obs;
  final RxList<PermissionCardState> cards = <PermissionCardState>[].obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final answers = await Future.wait(
        ChildPermission.values.map(source.statusOf),
      );
      if (isClosed) return;
      cards.assignAll(
        List.generate(
          answers.length,
          (i) => PermissionCardState(
            permission: ChildPermission.values[i],
            status: answers[i],
          ),
        ),
      );
      isLoading.value = false;
    } on Object catch (error) {
      // The interface forbids throws; if a future source breaks that rule,
      // report it instead of showing a frozen spinner.
      if (isClosed) return;
      errorMessage.value =
          'The permission list could not be loaded: $error';
      isLoading.value = false;
    }
  }
}
