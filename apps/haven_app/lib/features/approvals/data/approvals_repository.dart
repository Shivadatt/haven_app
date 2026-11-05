import 'package:haven_core/haven_core.dart';
import 'approval_models.dart';

abstract interface class ApprovalsRepository {
  Future<Result<List<AppInstallRequest>>> loadAppRequests({String? familyId});

  Future<Result<void>> respondAppRequest(
    String requestId, {
    required bool approve,
    String? note,
  });

  Future<Result<void>> generateSampleAppRequest({String? familyId});

  Future<Result<List<ScreenTimeExtensionRequest>>> loadExtensionRequests({
    String? familyId,
  });

  Future<Result<void>> respondExtensionRequest(
    String requestId, {
    required bool approve,
    int? grantedMinutes,
    String? note,
  });

  Future<Result<void>> generateSampleExtensionRequest({String? familyId});
}
