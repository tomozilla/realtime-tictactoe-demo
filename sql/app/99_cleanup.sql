-- Cleanup: drop the demo table (this also removes it from the Realtime publication)
drop table if exists public.orders cascade;
