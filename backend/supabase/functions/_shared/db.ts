// ============================================================================
// _shared/db.ts — the `DbClient` seam type, extracted from _shared/auth.ts at
// port time (2026-11-04) so every shared helper can import it without creating
// an import cycle back through auth.ts. auth.ts re-exports it, so handler
// imports from "../_shared/auth.ts" still resolve. No behaviour lives here:
// this file declares one type and nothing else.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION
//   The deployed `_shared/auth.ts` (338 lines, sha256 34b46f5a...,
//   capture-20261030.json:166) is unread; only its exported vocabulary and the
//   audit's line-number anchors survive. The shape below is inferred from those
//   anchors plus the call sites in the seven captured handlers.
//
// TARGET PROJECT: Supabase parent-control-staging / dzonzgngwxclhfnvxtvu (staging only).
// TABLES TOUCHED: none — this module performs no queries.
// SECRETS BY NAME: none.
// ============================================================================

/**
 * DbClient — the deliberately loose shape of the service-role client.
 *
 * CORRECTED AT PORT TIME. `ReturnType<typeof createClient>` is strictly generic: with no
 * generated `Database` type every table name resolves to `never`, and `deno check` reported
 * dozens of errors of the form "Argument of type { status: string } is not assignable to
 * parameter of type 'never'" against code that is correct. No generated types file exists to
 * import — staging holds 0 tables (`docs/stage2/S2-EXEC-09`) and `supabase gen types` is a CLI
 * command this project is not authorised to run.
 *
 * The boundary is therefore typed by hand and kept narrow where it matters: `auth.getUser`
 * retains a real shape, because an error there is an authentication bypass, while `from` and
 * `rpc` stay permissive, because an error there is caught by the readers in
 * `_shared/validation.ts`, by the database's own CHECK constraints, and on the client side by
 * `TableName.assertKnown` / `RpcName.assertKnown` in
 * `packages/haven_api/lib/src/backend_endpoints.dart`.
 *
 * The `any` occurrences below are the reason `no-explicit-any` is excluded for this tree in
 * `deno.json`. They are confined to this interface and to the row values returned by the
 * loaders that read it; every function PARAMETER that can be typed is typed `DbClient`.
 */
export interface DbClient {
  from(table: string): any;
  /**
   * `rpc` returns the SDK's filter builder, which is thenable but is not a `Promise`, so the
   * declared type is `any` here rather than a `Promise`. Awaiting it at the call site still
   * yields `{ data, error }` — that is the shape every handler in this tree destructures.
   */
  rpc(name: string, args?: Record<string, unknown>): any;
  auth: {
    getUser(token: string): Promise<{ data: { user: any } | null; error: any }>;
  };
}
