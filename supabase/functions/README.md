# Supabase Edge Functions

## delete-account

Permanently deletes the signed-in user's account + data. Required for App Store
Guideline 5.1.1(v). Invoked from the iOS app via
`supabase.functions.invoke("delete-account")`.

### Deploy

```bash
# One-time
supabase link --project-ref gqdaczlcxinemjelirip

# Deploy
supabase functions deploy delete-account
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are provided
automatically by the Supabase runtime, so no secrets need to be set manually.

### Recommended: cascade deletes

So account deletion is bulletproof even if a table is missed in the function,
add `ON DELETE CASCADE` foreign keys to `auth.users` on every user-owned table,
e.g.:

```sql
alter table public.goals
  add constraint goals_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete cascade;
```
