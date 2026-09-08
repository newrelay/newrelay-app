# FRD: Teams & Agents

**Status:** Shipped
**Module:** OSS core (roles, teams), Enterprise (Custom Roles, Agent Capacity Policies)
**Last updated:** 2026-09-07

---

## 1. What it is

**One-liner:** The people layer — `User` is a person (can belong to multiple accounts), `AccountUser` is their per-account membership (role, availability, capacity), and `Team` is a named group of agents conversations can be assigned to as a unit.

**Who uses it:** Account admins (invite/manage agents, create teams), agents (set their own availability, get assigned via team membership).

---

## 2. How it works

1. `User` is account-agnostic — one login can belong to many accounts via the `account_users` join table. Auth fields (Devise-based: `encrypted_password`, `otp_secret`/`otp_required_for_login` for 2FA, `pubsub_token` for ActionCable auth) live on `User`; account-scoped state lives on `AccountUser`.
2. `AccountUser.role` enum (`agent:0 / administrator:1`) is the core permission split — most policy checks (`app/policies/*_policy.rb`) key off this per-account role, not a global one.
3. Enterprise adds finer-grained permissions via `custom_role_id` (see [Custom Roles], not yet its own FRD) layered on top of the base agent/admin split.
4. `AccountUser.availability` enum (`online/offline/busy`) plus `auto_offline` (auto-flip to offline after inactivity) drives who's eligible for auto-assignment — read by `AssignmentService` (see [04-inboxes.md](04-inboxes.md)).
5. `AgentsController#bulk_create` allows inviting multiple agents at once, gated by `validate_limit_for_bulk_create`/`available_agent_count` — enforces the account's seat/plan limit before creating.
6. Deleting an agent (`delete_user_record`) removes their `AccountUser` membership; if that was their only account, the underlying `User` record itself may also be cleaned up (exact cascade logic in controller, not the model).
7. `Team` is simpler: a named, optionally auto-assignable (`allow_auto_assign`) group; `TeamMember` is the join table (unique `team_id, user_id`). Conversations get a `team_id` (see [01-conversations.md](01-conversations.md)) either manually or via automation/macro `assign_team` action.
8. Enterprise `AgentCapacityPolicy` + `InboxCapacityLimit` (linked via `account_users.agent_capacity_policy_id`) cap how many open conversations an agent can be auto-assigned at once, per-inbox.

---

## 3. Data model

**Table:** `users` (Devise-backed)
```
users
  - name, display_name, email: string
  - encrypted_password, provider, uid: Devise auth
  - otp_secret, otp_required_for_login, otp_backup_codes, consumed_timestep: 2FA
  - pubsub_token: unique, ActionCable auth
  - availability: integer (global default, overridden per-account by account_users.availability)
  - ui_settings, custom_attributes: jsonb
  - type: string (STI column — used by SuperAdmin subclass)
  - message_signature: text
```

**Table:** `account_users` (per-account membership)
```
account_users
  - account_id, user_id: bigint (unique pair)
  - role: integer, default 0        # enum agent:0 administrator:1
  - availability: integer, default 0   # enum online:0 offline:1 busy:2
  - auto_offline: boolean, default true
  - inviter_id: bigint (User)
  - custom_role_id: bigint (Enterprise)
  - agent_capacity_policy_id: bigint (Enterprise)
  - active_at: datetime
```

**Table:** `teams`
```
teams
  - account_id: bigint, not null
  - name: string (unique per account_id)
  - description: text
  - allow_auto_assign: boolean, default true
```

**Table:** `team_members`
```
team_members
  - team_id, user_id: bigint (unique pair)
```

---

## 4. Backend / API

**Routes:**
| Method | Path | Controller#action |
|---|---|---|
| GET | `/agents` | `agents#index` |
| POST | `/agents` | `agents#create` |
| PATCH/DELETE | `/agents/:id` | `agents#update/destroy` |
| POST | `/agents/bulk_create` | `agents#bulk_create` |
| GET | `/assignable_agents` | `assignable_agents#index` (agents eligible for assignment in current context) |
| GET/POST | `/teams` | `teams#index/create` |
| GET/PATCH/DELETE | `/teams/:id` | `teams#show/update/destroy` |
| GET/POST | `/teams/:id/team_members` | `team_members#index/create` |
| PATCH/DELETE | `/teams/:id/team_members` | `team_members#update/destroy` |

**Policies:** `app/policies/team_policy.rb`, `team_member_policy.rb` (and implicit `AccountUser`-role-based checks across most other policies).

---

## 5. Frontend

**Vue:** agent management under `dashboard/routes/dashboard/settings/agents/`, team management under `dashboard/routes/dashboard/settings/teams/`; agent availability toggle in the top nav (online/offline/busy).

**States handled:** seat-limit-reached error on invite, bulk-invite form (multi-row), team member add/remove, self-availability toggle (real-time via ActionCable).

---

## 6. Test coverage (as it exists today)

| Spec file | What it covers |
|---|---|
| `spec/models/team_spec.rb`, `team_member_spec.rb`, `spec/enterprise/models/team_spec.rb`, `team_member_spec.rb` | model validations, Enterprise extensions |
| `spec/controllers/api/v1/accounts/agents_controller_spec.rb`, `spec/enterprise/controllers/.../agents_controller_spec.rb` (x2) | agent CRUD, bulk create, Enterprise role/capacity behavior |
| `spec/controllers/api/v1/accounts/teams_controller_spec.rb`, `team_members_controller_spec.rb` | team CRUD, membership |
| `spec/controllers/api/v1/accounts/assignable_agents_controller_spec.rb` | assignment-eligible agent listing |
| `spec/builders/v2/reports/team_summary_builder_spec.rb` | team-level reporting rollup |

**Coverage gaps observed:** no dedicated `spec/models/account_user_spec.rb` found — role/availability enum behavior and the `user_id` uniqueness-per-account validation don't appear to have a direct model spec; likely covered indirectly through controller specs, but not confirmed.

---

## 7. Dev tools / dependencies actually used

- Backend: Rails, **Devise** (+ devise_token_auth-style token API auth) for `User`, TOTP-based 2FA (`otp_secret`), ActionCable (`pubsub_token`, real-time availability/typing)
- No external identity provider by default (Enterprise SAML is a separate model, `AccountSamlSettings`, not covered here)

---

## 8. Edge cases / failure modes (as handled in code)

| Scenario | Current behavior |
|---|---|
| Bulk-inviting more agents than plan allows | Blocked by `validate_limit_for_bulk_create` before any records are created |
| Deleting an agent who's the sole member of a team with open assigned conversations | Not confirmed whether conversations auto-unassign — check `delete_user_record`/associated callbacks before relying on this |
| User with `otp_required_for_login` loses their authenticator | `otp_backup_codes` provide the recovery path |
| Same user invited to same account twice | Blocked by unique index `(account_id, user_id)` |

---

## 9. Price / plan gating

**Gating type:** Mixed — agent/team management is ungated; seat count is a resource quota (`seats` stored as `account.limits['agents']`). Custom roles are in [19-sla-custom-roles.md](19-sla-custom-roles.md).
**`feature_key`(s):** resource `seats`; boolean `agent_management`, `team_management`, `agent_bots` (all plans)

| Plan | Included? | Limit / quota | Notes |
|---|---|---|---|
| Hobby | yes | 1 seat | |
| Standard | yes | 5 seats | |
| Business | yes | 20 seats | |
| Enterprise | yes | negotiated | `EnterpriseContract.negotiated_limit_overrides['seats']` maps to `account.limits['agents']` |

**Credits / usage:** none
**Enforced by:** `ReconcilePlanFeaturesService` maps `seats` → `account.limits['agents']`
**Source:** `lib/seeders/plan_feature_limit_seeder.rb`

---

## 10. Open gaps / notes

- No direct `account_user_spec.rb` found — flagged for confirmation, likely low-risk given controller-level coverage.
- Unassignment cascade behavior when an agent is removed from a team/account is not confirmed against conversations already assigned to them — worth a quick check if "orphaned assignee" is a real concern.
