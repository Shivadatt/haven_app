// ============================================================================
// tests/stub_db.ts — a hand-written stand-in for the service-role client.
//
// WHY THIS EXISTS
//   The re-authored handlers split two things that the deployed bundles kept together:
//   (a) the auth / authorisation / validation decisions, and (b) the SQL round-trips.
//   Only (a) can be tested offline, and (a) is where every finding in
//   docs/stage1/14-edge-function-security-audit.md lives. This stub answers the queries
//   those decisions make and records them, so a test can assert BOTH the verdict and the
//   predicates the verdict was reached with.
//
// WHAT THESE TESTS ARE NOT
//   They do not touch Supabase, do not execute SQL, and do not verify the deployed
//   functions. A pass here means "the re-authored logic behaves as documented", never
//   "parity with production" (the seven re-authored functions stay labelled
//   NO PARITY VERIFICATION), and never "the case in docs/stage1/15 was run" — the
//   HTTP-level TE-* / PE-* rows remain NOT EXECUTED until a staging deploy is approved.
//   Each test below names the 15-* case id whose DECISION it reproduces offline.
//
// SHAPE COVERAGE (grown from the call sites in `_shared/`, not invented):
//   from(table) -> select/insert/update/delete/upsert -> eq|neq|gt|gte|lt|lte|in|is|
//                  contains|order|limit|single|maybeSingle, awaitable at any point;
//   rpc(name, args) -> awaitable.
//   Every builder method returns a NEW builder sharing one recording, so chained calls
//   like `q = q.eq(col, val)` in _shared/rate_limit.ts behave as the SDK does.
//
// LAYOUT: the builder itself is in ./stub_query.ts and the recorded shapes in
//   ./stub_types.ts. Split at port time for the 200-line source rule; no behaviour, no
//   recorded string and no comment changed. Nothing here opens a socket.
// ============================================================================

import { FakeQuery } from "./stub_query.ts";
import type { RecordedCall, StubReply } from "./stub_types.ts";

export { FakeQuery };
export type { RecordedCall, StubReply };

export class FakeClient {
  readonly calls: RecordedCall[] = [];
  private readonly replies: Record<string, StubReply[]>;

  constructor(replies: Record<string, StubReply | StubReply[]>) {
    this.replies = {};
    for (const [key, value] of Object.entries(replies)) {
      this.replies[key] = Array.isArray(value) ? value : [value];
    }
  }

  /** Every reply handed out, in order — used by tests that assert an UPDATE never ran. */
  ops(): string[] {
    return this.calls.map((c) => `${c.table}.${c.op}`);
  }

  last(): RecordedCall | undefined {
    return this.calls[this.calls.length - 1];
  }

  /**
   * The token verifier. `_shared/identity.ts:86` treats `db.auth.getUser` as the whole of
   * authentication, so this is the seam every TE-07/08/09 case has to drive. Replies come
   * from the "auth.getUser" key, where `data` is the USER object (or null) and `error` is
   * what the Auth server returned.
   */
  readonly auth = {
    getUser: (token: string): Promise<{ data: { user: unknown } | null; error: unknown }> => {
      const reply = this.pick("auth.getUser");
      this.calls.push({ table: "auth.getUser", op: "getUser", payload: token, predicates: [] });
      return Promise.resolve({
        data: reply.data === null || reply.data === undefined ? null : { user: reply.data },
        error: reply.error ?? null,
      });
    },
  };

  private pick(key: string): StubReply {
    const queue = this.replies[key];
    if (!queue || queue.length === 0) return { data: null, error: null };
    return queue.length === 1 ? queue[0] : (queue.shift() as StubReply);
  }

  private take(table: string, op: string): StubReply {
    return this.pick(`${table}.${op}`);
  }

  from(table: string): FakeQuery {
    return new FakeQuery(this, table, "select");
  }

  /** `_shared/auth.ts` DbClient declares rpc; the handlers use it for apply_policy_version. */
  rpc(name: string, args?: Record<string, unknown>): FakeQuery {
    return new FakeQuery(this, `rpc:${name}`, "rpc", args);
  }

  record(table: string, op: string, predicates: string[], payload?: unknown, opts?: unknown): StubReply {
    this.calls.push({ table, op, payload, predicates: [...predicates], opts });
    return this.take(table, op);
  }
}

/** A POST with a JSON body, as the handlers receive it. */
export function post(body: Record<string, unknown>, headers: Record<string, string> = {}): Request {
  return new Request("http://localhost/function", {
    method: "POST",
    headers: { "content-type": "application/json", ...headers },
    body: JSON.stringify(body),
  });
}

/** Read a Response body as JSON without leaking it into the test output on success. */
export async function jsonOf(res: Response): Promise<Record<string, unknown>> {
  return (await res.json()) as Record<string, unknown>;
}
