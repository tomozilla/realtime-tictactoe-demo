-- 注文をはじめの状態に戻す（デモをやり直したいとき）
truncate public.orders restart identity;
insert into public.orders (customer, item, status) values
  ('テーブル3', 'ナポリタン', '受付'),
  ('テーブル1', 'ハンバーグ定食', '調理中'),
  ('テーブル5', 'クリームソーダ', '受付'),
  ('テイクアウト', 'から揚げ弁当', '完了');
select id, item, status from public.orders order by id;
