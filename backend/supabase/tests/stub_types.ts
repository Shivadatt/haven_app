// ============================================================================
// tests/stub_types.ts — the shapes the stub records, shared by stub_db.ts and
// stub_query.ts. Split from stub_db.ts only to satisfy the 200-line rule; the
// behaviour, the recorded strings and the comment above each field are unchanged.
//
// WHY THE STUB EXISTS AT ALL (the full rationale is in stub_db.ts's header)
//   The re-authored handlers split (a) the auth/authz/validation decisions from
//   (b) the SQL round-trips. Only (a) can be tested offline, and (a) is where every
//   finding in docs/stage1/14-edge-function-security-audit.md lives. This stub answers
//   the queries those decisions make and RECORDS them, so a test can assert both the
//   verdict and the predicates the verdict was reached with — which is the only way an
//   offline test can say anything about a `service_role` client that bypasses RLS.
// ============================================================================

export interface StubReply {
  data?: unknown;
  count?: number;
  error?: { code?: string; message?: string } | null;
}

export interface RecordedCall {
  table: string;
  op: string;
  payload?: unknown;
  /** Flat "col:op:value" strings, in the order the handler wrote them. */
  predicates: string[];
  opts?: unknown;
}

/**
 * The builder methods `_shared/` actually chains, grown from those call sites rather than
 * invented: `from(table)` -> select/insert/update/delete/upsert -> each of these ->
 * single/maybeSingle, and the builder is awaitable at any point.
 */
export const FILTER_METHODS = [
  "eq",
  "neq",
  "gt",
  "gte",
  "lt",
  "lte",
  "is",
  "in",
  "contains",
  "order",
  "limit",
] as const;
