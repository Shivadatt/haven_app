// ============================================================================
// _shared/family.ts — family and membership assertions, split out of
// _shared/auth.ts at port time for the 200-line source rule. Behaviour unchanged.
//
// STATUS: RE-AUTHORED FROM SPECIFICATION — NO PARITY VERIFICATION.
//   Captured anchors: `_shared/auth.ts:151-196`, audit 14:129-135.
//   Every assertion reads the family first (exists, not soft-deleted), then the
//   membership row. `service_role` bypasses RLS, so these predicates ARE the control.
// ============================================================================

import { ApiError } from "./envelope.ts";
import type { DbClient } from "./db.ts";

// ---------------------------------------------------------------------------
// Family assertions — :151-196. Each first asserts the family exists and is not
// soft-deleted (14:129-131), then the membership row.
// ---------------------------------------------------------------------------

const FAMILIES_SELECT = "id, name, owner_id, settings, created_at, updated_at, deleted_at";
const MEMBERS_SELECT = "id, family_id, user_id, role, status, created_at, removed_at";

async function loadLiveFamily(db: DbClient, familyId: string): Promise<any> {
  const { data: family, error } = await db
    .from("families")
    .select(FAMILIES_SELECT)
    .eq("id", familyId)
    .maybeSingle();
  if (error) {
    console.error(`family_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  if (!family || family.deleted_at !== null) {
    throw new ApiError(403, "forbidden", "Family not available.");
  }
  return family;
}

async function loadActiveMembership(db: DbClient, familyId: string, userId: string): Promise<any> {
  const { data: member, error } = await db
    .from("family_members")
    .select(MEMBERS_SELECT)
    .eq("family_id", familyId)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();
  if (error) {
    console.error(`membership_lookup: ${error.code ?? "unknown"}`);
    throw new ApiError(500, "internal_error", "An unexpected error occurred.");
  }
  return member;
}

/** assertFamilyParent — active member AND role 'parent' in THAT family (14:132-133). */
export async function assertFamilyParent(db: DbClient, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "parent") {
    throw new ApiError(403, "forbidden", "Not a parent of this family.");
  }
  return family;
}

/** assertFamilyMember — any active member (parent or child). */
export async function assertFamilyMember(db: DbClient, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member) throw new ApiError(403, "forbidden", "Not a member of this family.");
  return { family, member };
}

/** assertFamilyChild / assertChildMembership — active member with role 'child'. */
export async function assertFamilyChild(db: DbClient, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  const member = await loadActiveMembership(db, familyId, userId);
  if (!member || member.role !== "child") {
    throw new ApiError(403, "forbidden", "Not a child of this family.");
  }
  return family;
}

export const assertChildMembership = assertFamilyChild;

/** assertFamilyOwner — families.owner_id; the code used as 403 owner_required. */
export async function assertFamilyOwner(db: DbClient, userId: string, familyId: string): Promise<any> {
  const family = await loadLiveFamily(db, familyId);
  if (family.owner_id !== userId) {
    throw new ApiError(403, "owner_required", "This action requires the family owner.");
  }
  return family;
}
