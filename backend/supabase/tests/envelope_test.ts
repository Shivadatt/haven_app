// ============================================================================
// tests/envelope_test.ts — the response envelope every one of the seven re-authored
// functions shares (_shared/envelope.ts + _shared/cors.ts).
//
// STATUS: these tests exercise the STAGE-2 RE-AUTHORED lane only. A pass means the
// re-authored logic matches the contract recorded in docs/stage1/14 and the anchors cited
// below. It is NOT parity with the deployed bundles (those stay labelled
// NO PARITY VERIFICATION) and NOT an executed row of docs/stage1/15 — the HTTP-level
// TE-*/PE-* cases remain NOT EXECUTED until a staging deploy is approved.
// Case ids named in each test are the 15-* rows whose DECISION this reproduces offline.
// ============================================================================

import { assertEquals, assertMatch, assertRejects, assertStringIncludes } from "@std/assert";

import { ApiError, ensureNoError, errorResponse, fail, ok, readJson, requireAction, unknownAction } from "../functions/_shared/envelope.ts";
import { CORS_ALLOW_HEADERS, corsHeaders, handleCors } from "../functions/_shared/cors.ts";
import { post } from "./stub_db.ts";

Deno.test("ok() - success envelope carries no-store and the shared CORS headers (14:216)", async () => {
  const res = ok({ session: { id: "x" } });
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("Cache-Control"), "no-store"); // VERIFIED: every JSON response
  assertEquals(res.headers.get("Content-Type"), "application/json");
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), corsHeaders["Access-Control-Allow-Origin"]);
  const body = await res.json();
  assertEquals(body, { ok: true, session: { id: "x" } }); // key names are NOT VERIFIED (see header)
});

Deno.test("fail() - error consumers read error.code and error.message (15:20, 15:222)", async () => {
  const body = await (await fail(409, "session_not_open", "This session is not open.")).json();
  assertEquals(body, { ok: false, error: { code: "session_not_open", message: "This session is not open." } });
});

Deno.test("handleCors - OPTIONS is answered before any authentication, GET is 405 (14:264-267)", () => {
  const preflight = handleCors(new Request("http://localhost/f", { method: "OPTIONS" }));
  assertEquals(preflight?.status, 200);
  assertEquals(preflight?.headers.get("Access-Control-Allow-Origin"), "*"); // E9 baseline, preserved
  assertMatch(String(preflight?.headers.get("Access-Control-Allow-Headers")), /x-device-secret/);
  assertEquals(CORS_ALLOW_HEADERS.includes("x-cron-secret"), true);
  const wrong = handleCors(new Request("http://localhost/f", { method: "GET" }));
  assertEquals(wrong?.status, 405);
  assertEquals(handleCors(post({ action: "ping" })), null); // POST -> "continue"
});

Deno.test("readJson - object-only body (14:212-215)", async () => {
  assertEquals(await readJson(post({ action: "list_family" })), { action: "list_family" });
  assertEquals(await readJson(post({})), {});
});

Deno.test("readJson - array, scalar and unparseable bodies are all 400 (14:342 positive controls)", async () => {
  for (const raw of ["[1,2]", "\"just a string\"", "42", "not json at all"]) {
    const res = await assertRejects(() =>
      readJson(new Request("http://localhost/f", { method: "POST", body: raw })));
    assertEquals((res as ApiError).status, 400);
  }
});

Deno.test("readJson - the 512 KB cap is enforced on the actual text (14:213)", async () => {
  // The declared content-length gate cannot be driven from a test: the Request constructor
  // owns that header. The second gate — the one that matters, because a gateway can rewrite
  // the declared length — is exercised here with 512 KB + 1 of unparseable bytes, which must
  // be rejected as TOO LARGE, not as INVALID JSON.
  const huge = "a".repeat(512 * 1024 + 1);
  const err = await assertRejects(() =>
    readJson(new Request("http://localhost/f", { method: "POST", body: huge })));
  assertEquals((err as ApiError).status, 413);
  assertEquals((err as ApiError).code, "payload_too_large");
});

Deno.test("requireAction - action is a string of 1 to 64 characters (14:219)", () => {
  assertEquals(requireAction({ action: "redeem" }), "redeem");
  for (const body of [{}, { action: "" }, { action: 7 }, { action: "x".repeat(65) }]) {
    const err = (() => {
      try {
        requireAction(body as Record<string, unknown>);
        return null;
      } catch (e) {
        return e as ApiError;
      }
    })();
    assertEquals(err?.status, 400);
    assertEquals(err?.code, "invalid_action");
  }
});

Deno.test("unknownAction - one 400 code for all nine functions (15:137, 15:204 = PE-R07, PE-CR06)", () => {
  const err = (() => {
    try {
      unknownAction("drop_everything");
      return null;
    } catch (e) {
      return e as ApiError;
    }
  })();
  assertEquals(err?.status, 400);
  assertEquals(err?.code, "unknown_action");
});

Deno.test("errorResponse - curated codes pass through, everything else is a fixed 500 (14:271-274)", async () => {
  const curated = errorResponse(new ApiError(403, "forbidden", "Not your session."));
  assertEquals(curated.status, 403);
  assertEquals((await curated.json()).error.code, "forbidden");

  const leaky = errorResponse(new Error("relation \"private.tokens\" does not exist"));
  assertEquals(leaky.status, 500);
  const body = JSON.stringify(await leaky.json());
  assertEquals(body.includes("private"), false); // never forwards the internal message
  assertStringIncludes(body, "internal_error");
});

Deno.test("ensureNoError - logs the code, throws the caller's sentence, never the DB text (14:275-276)", () => {
  ensureNoError(null, "fine.");
  const err = (() => {
    try {
      ensureNoError({ code: "42501", message: "new row violates row-level security policy" }, "Could not write.");
      return null;
    } catch (e) {
      return e as ApiError;
    }
  })();
  assertEquals(err?.status, 500);
  assertEquals(err?.code, "db_error");
  assertEquals(err?.message, "Could not write.");
});
