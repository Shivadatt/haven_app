set -e
cd /d/control/backend/supabase/functions/pairing

MODIMPORTS='import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import {
  assertChildMembership,
  assertFamilyParent,
  requireRole,
  type DbClient,
} from "../_shared/auth.ts";
import { assertPairingRedeemAllowed, recordPairingAttempt } from "../_shared/rate_limit.ts";
import {
  assertInviteQuotaAllowed,
  assertPairingCodeCreationAllowed,
} from "../_shared/quotas.ts";
import {
  CONTACT_ID_RE,
  identifierHash,
  isContactIdForm,
  newContactId,
  newPairingCode,
  normalizeIdentifier,
  PAIRING_CODE_RE,
  readBoolean,
  readUuid,
  sha256Hex,
} from "../_shared/validation.ts";
import {
  CODE_TTL_MINUTES,
  INVITE_TTL_MINUTES,
  MAX_ATTEMPTS_PER_CODE,
  PENDING_LIST_LIMIT,
  REQUEST_COLUMNS,
  TOKEN_COLUMNS,
  invalidIdentifier,
  ttl,
} from "./shared.ts";'

fn() { case "$1" in
  get_contact_id) echo handleContactId;; create) echo handleCreate;;
  redeem) echo handleRedeem;; invite) echo handleInvite;;
  pending_child) echo handlePendingChild;; respond) echo handleRespond;;
  cancel) echo handleCancel;; list_family) echo handleListFamily;;
  unlink) echo handleUnlink;; esac; }

# module: name, "action:start:end" list, description
genmod() {
  local mod="$1"; shift
  local desc="$1"; shift
  { printf '// pairing / %s — %s\n//\n' "$mod" "$desc"
    printf '// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Each action below was sliced\n'
    printf '// VERBATIM out of the captured switch in `index.ts` at port time for the project'"'"'s 200-line source\n'
    printf '// rule; behaviour, labels and evidence anchors are unchanged. The full captured-facts header stays\n'
    printf '// in `index.ts` — read it before editing. `db`, `uid` (the verified user id), `profile` and the\n'
    printf '// parsed `body` are handed in by the dispatcher: no identity value is ever read from the body.\n'
    printf '// ============================================================================\n\n'
    printf '%s\n' "$MODIMPORTS"
    for spec in "$@"; do
      local action="${spec%%:*}"; local rest="${spec#*:}"; local s="${rest%%:*}"; local e="${rest##*:}"
      local body; body=$(sed -n "$((s+1)),$((e-1))p" index.ts)
      local params="db: DbClient, uid: string, profile: { role: string }, body: Record<string, unknown>"
      echo "$body" | grep -q '\bprofile\b' || params="db: DbClient, uid: string, body: Record<string, unknown>"
      echo "$body" | grep -q '\bbody\b' || params="db: DbClient, uid: string, profile: { role: string }"
      echo "$body" | grep -qE '\bbody\b|\bprofile\b' && params="db: DbClient, uid: string, profile: { role: string }, body: Record<string, unknown>"
      printf '\nexport async function %s(\n' "$(fn "$action")"
      echo "$params" | tr ',' '\n' | sed -e '/^ /d' -e 's/^/  /' -e '1i\  ' | head -0
      printf '%s\n' "$(echo "$params" | sed 's/, /\n/g' | sed 's/^/  /' | paste -sd',\n' -)"
      printf '): Promise<Response> {\n%s\n}\n' "$body"
    done
  } > "$mod.ts"
  wc -l "$mod.ts"
}

# --- shared.ts (constants + helpers only) ---
{ printf '// pairing / shared — the constants, column whitelists and two helpers all nine actions use.\n//\n'
  printf '// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION. Moved verbatim out of\n'
  printf '// `index.ts` at port time for the project'"'"'s 200-line source rule; values and anchors unchanged.\n'
  printf '// The full captured-facts header stays in `index.ts` — read it before editing this file.\n'
  printf '// ============================================================================\n\n'
  printf 'import { ApiError } from "../_shared/envelope.ts";\n\n'
  sed -n '159,181p' index.ts | sed -e 's/^const /export const /' -e 's/^function /export function /'
} > shared.ts
wc -l shared.ts

genmod issuance "ISSUANCE actions: get_contact_id, create (a code) and invite." \
  "get_contact_id:194:216" "create:219:246" "invite:373:445"
genmod redeem "the REDEEM action — the code/contact-id exchange (capture:37-38)." "redeem:249:370"
genmod requests "REQUEST-STATE actions: pending_child, respond and list_family." \
  "pending_child:448:461" "respond:464:498" "list_family:541:569"
genmod unlink "CANCEL and UNLINK — the two destructive pairing mutations." "cancel:501:538" "unlink:572:611"
