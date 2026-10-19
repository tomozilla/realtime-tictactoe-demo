-- ライブ注文ボード用のテーブル。「いまの状態」はデータベースが持ち、Realtimeは「変わったよ」を知らせる役。
-- （前の記事の三目並べは、状態を持たない Broadcast だけだったので、途中参加の人の盤面が空になりました）
create table if not exists public.orders (
  id bigint primary key generated always as identity,
  customer text not null,
  item text not null,
  status text not null default '受付' check (status in ('受付', '調理中', '完了')),
  updated_by text,
  updated_at timestamptz not null default now()
);
alter table public.orders enable row level security;

-- ★ デモ用: ログインなし（anon）で、読む・追加する・更新するのを許可します。
--   本物のアプリでは、ログインした人（authenticated）だけにして、更新できる列や行も絞ってください。
create policy "demo: anyone can read orders" on public.orders for select to anon, authenticated using (true);
create policy "demo: anyone can add orders" on public.orders for insert to anon, authenticated with check (true);
create policy "demo: anyone can update orders" on public.orders for update to anon, authenticated using (true) with check (true);

-- 変更をRealtime（postgres_changes）で配信する対象にする
alter publication supabase_realtime add table public.orders;

insert into public.orders (customer, item, status) values
  ('テーブル3', 'ナポリタン', '受付'),
  ('テーブル1', 'ハンバーグ定食', '調理中'),
  ('テーブル5', 'クリームソーダ', '受付'),
  ('テイクアウト', 'から揚げ弁当', '完了');
