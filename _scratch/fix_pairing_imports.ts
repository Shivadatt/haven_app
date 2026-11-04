// Scratch: replace the import block of the four pairing modules with the names each file uses.
const blocks = {
  "issuance.ts": `import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { assertFamilyParent, requireRole, type DbClient } from "../_shared/auth.ts";
import { recordPairingAttempt } from "../_shared/rate_limit.ts";
import {
  assertInviteQuotaAllowed,
  assertPairingCodeCreationAllowed,
} from "../_shared/quotas.ts";
import {
  CONTACT_ID_RE,
  identifierHash,
  newContactId,
  newPairingCode,
  normalizeIdentifier,
  readUuid,
  sha256Hex,
} from "../_shared/validation.ts";
import {
  CODE_TTL_MINUTES,
  INVITE_TTL_MINUTES,
  MAX_ATTEMPTS_PER_CODE,
  invalidIdentifier,
  ttl,
} from "./shared.ts";
`,
  "redeem.ts": `import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { assertFamilyParent, requireRole, type DbClient } from "../_shared/auth.ts";
import {
  assertPairingRedeemAllowed,
  recordPairingAttempt,
} from "../_shared/rate_limit.ts";
import {
  identifierHash,
  isContactIdForm,
  normalizeIdentifier,
  PAIRING_CODE_RE,
  readUuid,
  sha256Hex,
} from "../_shared/validation.ts";
import { CODE_TTL_MINUTES, TOKEN_COLUMNS, invalidIdentifier, ttl } from "./shared.ts";
`,
  "requests.ts": `import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import { assertFamilyParent, requireRole, type DbClient } from "../_shared/auth.ts";
import { readBoolean, readUuid } from "../_shared/validation.ts";
import { PENDING_LIST_LIMIT, REQUEST_COLUMNS } from "./shared.ts";
`,
  "unlink.ts": `import { ApiError, ensureNoError, ok } from "../_shared/envelope.ts";
import {
  assertChildMembership,
  assertFamilyParent,
  requireRole,
  type DbClient,
} from "../_shared/auth.ts";
import { readUuid } from "../_shared/validation.ts";
import { REQUEST_COLUMNS } from "./shared.ts";
`,
};
const dir = "D:/control/backend/supabase/functions/pairing/";
for (const [f, block] of Object.entries(blocks)) {
  const src = await Deno.readTextFile(dir + f);
  const i = src.indexOf("import {");
  const j = src.indexOf("export async function");
  await Deno.writeTextFile(dir + f, src.slice(0, i) + block + "\n" + src.slice(j));
  console.log(f, "ok");
}
