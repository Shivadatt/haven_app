import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:haven_core/haven_core.dart';

import '../../family/data/family_models.dart';
import '../../family/data/family_repository.dart';
import '../data/pairing_simulation_service.dart';
import '../data/simulation_models.dart';

/// Controller orchestrating the local pairing simulation workflow.
final class PairingSimulationController extends GetxController {
  PairingSimulationController({
    required this.service,
    required this.family,
    void Function()? close,
  }) : _close = close ?? Get.back;

  final PairingSimulationService service;
  final FamilyRepository family;
  final void Function() _close;

  final Rxn<SimulatedPairingSession> session = Rxn<SimulatedPairingSession>();
  final RxInt remainingSeconds = 0.obs;
  Timer? _timer;

  final TextEditingController codeController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  final RxList<FamilyPerson> children = <FamilyPerson>[].obs;
  final Rxn<FamilyPerson> selectedChild = Rxn<FamilyPerson>();
  final Rxn<SimulatedDevice> createdDevice = Rxn<SimulatedDevice>();

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _timer?.cancel();
    codeController.dispose();
    displayNameController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    final Result<FamilyBundle?> bundleRes = await family.load();
    final FamilyBundle? bundle = bundleRes.valueOrNull;
    if (bundle != null && bundle.children.isNotEmpty) {
      children.assignAll(bundle.children);
      selectedChild.value = children.first;
    }
    isLoading.value = false;
  }

  void generateCode() {
    _timer?.cancel();
    errorMessage.value = null;
    codeController.clear();

    final SimulatedPairingSession newSession = service.generateSession();
    session.value = newSession;
    remainingSeconds.value = newSession.remainingTime.inSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (newSession.isExpired || newSession.isRedeemed || newSession.isCancelled) {
        timer.cancel();
        remainingSeconds.value = 0;
      } else {
        remainingSeconds.value = newSession.remainingTime.inSeconds;
      }
    });
  }

  void selectChild(FamilyPerson child) {
    selectedChild.value = child;
    errorMessage.value = null;
  }

  Future<void> submitCode() async {
    final currentSession = session.value;
    if (currentSession == null) {
      errorMessage.value = 'Please generate a pairing code first.';
      return;
    }

    final validation = service.validateInput(
      rawInput: codeController.text,
      session: currentSession,
    );

    if (validation.isErr) {
      errorMessage.value = validation.failureOrNull?.message;
      return;
    }

    final child = selectedChild.value;
    if (child == null) {
      errorMessage.value = 'Select a child for this device.';
      return;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    final paired = await service.completePairing(
      session: currentSession,
      childUserId: child.userId,
      childName: child.name,
      customDisplayName: displayNameController.text,
    );

    isSubmitting.value = false;

    if (paired.isOk) {
      _timer?.cancel();
      createdDevice.value = paired.valueOrNull;
    } else {
      errorMessage.value = paired.failureOrNull?.message;
    }
  }

  void cancelSimulation() {
    _timer?.cancel();
    session.value?.cancel();
    session.value = null;
    remainingSeconds.value = 0;
    codeController.clear();
    errorMessage.value = null;
  }

  void reset() {
    cancelSimulation();
    createdDevice.value = null;
  }

  void done() => _close();

  String get remainingTimeString {
    final s = remainingSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
