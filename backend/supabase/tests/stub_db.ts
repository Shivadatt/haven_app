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

const FILTER_METHODS = [
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

class FakeQuery {
  constructor(
    private readonly client: FakeClient,
    private readonly table: string,
    private readonly op: string,
    private readonly payload?: unknown,
    private readonly predicates: string[] = [],
    private readonly opts: Record<string, unknown> = {},
  ) {}

  select(columns?: string, opts?: unknown): FakeQuery {
    // `select` is the default op; `{ count: "exact", head: true }` arrives here.
    return new FakeQuery(this.client, this.table, this.op, this.payload, this.predicates, {
      ...this.opts,
      select: `${String(columns)}:${JSON.stringify(opts ?? null)}`,
    });
  }

  insert(row: unknown): FakeQuery {
    return new FakeQuery(this.client, this.table, "insert", row, this.predicates);
  }

  update(row: unknown): FakeQuery {
    return new FakeQuery(this.client, this.table, "update", row, this.predicates);
  }

  upsert(row: unknown, opts?: unknown): FakeQuery {
    return new FakeQuery(this.client, this.table, "upsert", row, this.predicates, {
      upsert: opts,
    });
  }

  delete(): FakeQuery {
    return new FakeQuery(this.client, this.table, "delete", undefined, this.predicates);
  }

  eq(col: string, val: unknown): FakeQuery {
    return this.filter("eq", col, val);
  }
  neq(col: string, val: unknown): FakeQuery {
    return this.filter("neq", col, val);
  }
  gt(col: string, val: unknown): FakeQuery {
    return this.filter("gt", col, val);
  }
  gte(col: string, val: unknown): FakeQuery {
    return this.filter("gte", col, val);
  }
  lt(col: string, val: unknown): FakeQuery {
    return this.filter("lt", col, val);
  }
  lte(col: string, val: unknown): FakeQuery {
    return this.filter("lte", col, val);
  }
  is(col: string, val: unknown): FakeQuery {
    return this.filter("is", col, val);
  }
  in(col: string, val: unknown): FakeQuery {
    return this.filter("in", col, val);
  }
  contains(col: string, val: unknown): FakeQuery {
    return this.filter("contains", col, val);
  }
  order(col: string, opts?: unknown): FakeQuery {
    return this.filter("order", col, JSON.stringify(opts ?? null));
  }
  limit(n: number): FakeQuery {
    return this.filter("limit", "n", n);
  }

  private filter(method: string, col: string, val: unknown): FakeQuery {
    if (!(FILTER_METHODS as readonly string[]).includes(method)) {
      throw new Error(`stub: unrecorded filter ${method}`);
    }
    return new FakeQuery(this.client, this.table, this.op, this.payload, [
      ...this.predicates,
      `${col}:${method}:${String(val)}`,
    ]);
  }

  /** Terminal builders resolve the recorded reply; the predicates are captured first. */
  maybeSingle(): Promise<StubReply> {
    return Promise.resolve(this.resolve());
  }

  single(): Promise<StubReply> {
    return Promise.resolve(this.resolve());
  }

  then<T>(onFulfilled: (reply: StubReply) => T): Promise<T> {
    return Promise.resolve(this.resolve()).then(onFulfilled);
  }

  private resolve(): StubReply {
    return this.client.record(this.table, this.op, this.predicates, this.payload, this.opts);
  }

}

/** requireUser-shaped actor, so assertion tests do not need a real JWT. */
export function actor(role: string, userId = "11111111-1111-4111-8111-111111111111"): {
  userId: string;
  role: string;
} {
  return { userId, role };
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
