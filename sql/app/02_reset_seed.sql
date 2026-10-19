-- Put the orders back to the starting state (use this to redo the demo)
-- Sample data stays Japanese (table 3 / Napolitan spaghetti, table 1 / hamburger steak set,
-- table 5 / cream soda, takeout / fried chicken bento). Status: 受付 = received, 調理中 = cooking, 完了 = done.
truncate public.orders restart identity;
insert into public.orders (customer, item, status) values
  ('テーブル3', 'ナポリタン', '受付'),
  ('テーブル1', 'ハンバーグ定食', '調理中'),
  ('テーブル5', 'クリームソーダ', '受付'),
  ('テイクアウト', 'から揚げ弁当', '完了');
select id, item, status from public.orders order by id;
