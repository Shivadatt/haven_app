// ============================================================================
// tests/stub_query.ts — the fluent, immutably-chained query builder the stub hands
// out from `from(table)` / `rpc(name, args)`. Split out of stub_db.ts for the
// 200-line rule; every method body is unchanged from the original file.
//
// The one thing to understand: EVERY builder method returns a NEW FakeQuery that
// shares one client. That is what `_shared/rate_limit.ts` does when it writes
// `q = q.eq(col, val)`, and what the real PostgREST client does too — so a stub
// that mutated in place would record predicates the handler never asked for.
// ============================================================================

import type { FakeClient } from "./stub_db.ts";
import { FILTER_METHODS, type RecordedCall, type StubReply } from "./stub_types.ts";

export class FakeQuery {
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

export type { RecordedCall, StubReply };
