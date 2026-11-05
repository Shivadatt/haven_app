# Data builder for HAVEN Parental Control frontend functionality audit
# Modules A through M, 172 discrete product features

import csv
import os
import sys

OUTPUT_DIR = r"D:\control\docs\audit\frontend_functionality"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Data structure: List of dicts with all 15 fields
features = []

def add_feature(
    fid, module, name, expected, screens, actions, ui_states,
    controller, model, service, native, deps, status, evidence, missing, priority="P1", classification="Core"
):
    features.append({
        "id": fid,
        "module": module,
        "name": name,
        "expected": expected,
        "screens": screens,
        "actions": actions,
        "ui_states": ui_states,
        "controller": controller,
        "model": model,
        "service": service,
        "native": native,
        "deps": deps,
        "status": status,
        "evidence": evidence,
        "missing": missing,
        "priority": priority,
        "classification": classification,
    })

print("Builder initialized.")
