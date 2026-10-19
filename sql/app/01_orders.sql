-- Table for the live order board. The database holds the "current state"; Realtime only says "something changed".
-- (The tic-tac-toe in the previous article used Broadcast only, which keeps no state, so a late joiner saw an empty board.)
-- Note: the status values are Japanese on purpose: 受付 = received, 調理中 = cooking, 完了 = done.
-- The app compares against these stored values and maps them to English labels for display.
create table if not exists public.orders (
  id bigint primary key generated always as identity,
  customer text not null,
  item text not null,
  status text not null default '受付' check (status in ('受付', '調理中', '完了')),
  updated_by text,
  updated_at timestamptz not null default now()
);
alter table public.orders enable row level security;

-- * DEMO ONLY: allow reading, adding and updating without login (anon).
--   In a real app, allow only logged-in users (authenticated) and restrict which columns and rows can be updated.
create policy "demo: anyone can read orders" on public.orders for select to anon, authenticated using (true);
create policy "demo: anyone can add orders" on public.orders for insert to anon, authenticated with check (true);
create policy "demo: anyone can update orders" on public.orders for update to anon, authenticated using (true) with check (true);

-- Add the table to the publication that Realtime (postgres_changes) streams from
alter publication supabase_realtime add table public.orders;

-- Sample data stays Japanese (table 3 / Napolitan spaghetti, table 1 / hamburger steak set,
-- table 5 / cream soda, takeout / fried chicken bento)
insert into public.orders (customer, item, status) values
  ('テーブル3', 'ナポリタン', '受付'),
  ('テーブル1', 'ハンバーグ定食', '調理中'),
  ('テーブル5', 'クリームソーダ', '受付'),
  ('テイクアウト', 'から揚げ弁当', '完了');
