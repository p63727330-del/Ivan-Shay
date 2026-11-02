-- Initial schema for Nosso Novo Lar / Ivan & Shay
create extension if not exists pgcrypto;
create schema if not exists private;
create table public.admin_users (user_id uuid primary key references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create table public.guests (id uuid primary key default gen_random_uuid(), full_name text not null, invitation_code text not null unique, max_companions integer not null default 0 check (max_companions between 0 and 10), rsvp_status text not null default 'pending' check (rsvp_status in ('pending','confirmed','declined')), companions_count integer not null default 0 check (companions_count >= 0 and companions_count <= max_companions), guest_message text, responded_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.gift_items (id integer primary key, name text not null, category text not null, price_cents integer not null check (price_cents > 0), is_active boolean not null default true, created_at timestamptz not null default now());
create table public.contributions (id uuid primary key default gen_random_uuid(), gift_id integer not null references public.gift_items(id) on delete restrict, donor_name text, amount_cents integer not null check (amount_cents > 0), message text, pix_reference text, status text not null default 'pending' check (status in ('pending','approved','rejected')), reviewed_at timestamptz, created_at timestamptz not null default now());
create index guests_rsvp_status_idx on public.guests(rsvp_status);
create index contributions_status_created_idx on public.contributions(status, created_at desc);
create index contributions_gift_id_idx on public.contributions(gift_id);
alter table public.admin_users enable row level security;
alter table public.guests enable row level security;
alter table public.gift_items enable row level security;
alter table public.contributions enable row level security;
create or replace function private.is_admin() returns boolean language sql stable security definer set search_path = '' as $$ select exists (select 1 from public.admin_users where user_id=(select auth.uid())); $$;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
revoke all on function private.is_admin() from public, anon;
grant execute on function private.is_admin() to authenticated;
create policy "Admins manage admin users" on public.admin_users for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "Admins manage guests" on public.guests for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "Public can read active gifts" on public.gift_items for select to anon, authenticated using (is_active=true);
create policy "Admins insert gifts" on public.gift_items for insert to authenticated with check ((select private.is_admin()));
create policy "Admins update gifts" on public.gift_items for update to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
create policy "Admins delete gifts" on public.gift_items for delete to authenticated using ((select private.is_admin()));
create policy "Admins manage contributions" on public.contributions for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()));
grant select on public.gift_items to anon, authenticated;
grant select, insert, update, delete on public.admin_users, public.guests, public.contributions, public.gift_items to authenticated;
insert into public.gift_items (id,name,category,price_cents,is_active) values
(1, 'Jogo de panelas', 'Cozinha', 35000, true),
(2, 'Jogo de frigideiras', 'Cozinha', 8000, true),
(3, 'Jogo de talheres', 'Cozinha', 10000, true),
(4, 'Faqueiro', 'Cozinha', 12000, true),
(5, 'Jogo de copos (6 peças)', 'Cozinha', 4500, true),
(6, 'Jogo de xícaras (6 peças)', 'Cozinha', 8000, true),
(7, 'Pratos rasos (jogo com 6)', 'Cozinha', 12000, true),
(8, 'Pratos fundos (jogo com 6)', 'Cozinha', 12000, true),
(9, 'Pratos de sobremesa (jogo com 6)', 'Cozinha', 10000, true),
(10, 'Tigelas (conjunto)', 'Cozinha', 5000, true),
(11, 'Potes herméticos (kit)', 'Cozinha', 10000, true),
(12, 'Tábua de corte', 'Cozinha', 4000, true),
(13, 'Facas de cozinha', 'Cozinha', 8000, true),
(14, 'Assadeiras antiaderentes (jogo)', 'Cozinha', 12000, true),
(15, 'Assadeiras de vidro (jogo)', 'Cozinha', 10000, true),
(16, 'Travessas (conjunto)', 'Cozinha', 7000, true),
(17, 'Escorredor de louças', 'Cozinha', 6000, true),
(18, 'Escorredor de massa', 'Cozinha', 3000, true),
(19, 'Escorredor de arroz', 'Cozinha', 2500, true),
(20, 'Conchas (conjunto)', 'Cozinha', 3500, true),
(21, 'Espátulas (conjunto)', 'Cozinha', 3000, true),
(22, 'Descanso de panela', 'Cozinha', 2500, true),
(23, 'Panos de prato (kit com 5)', 'Cozinha', 5000, true),
(24, 'Jarra para água', 'Cozinha', 3500, true),
(25, 'Garrafa térmica', 'Cozinha', 7000, true),
(26, 'Lixeira de cozinha', 'Cozinha', 6000, true),
(27, 'Porta-papel-toalha', 'Cozinha', 3000, true),
(28, 'Porta-temperos', 'Cozinha', 6000, true),
(29, 'Porta-mantimentos', 'Cozinha', 10000, true),
(30, 'Geladeira', 'Eletrodomésticos', 260000, true),
(31, 'Fogão 4 bocas', 'Eletrodomésticos', 85000, true),
(32, 'Máquina de lavar roupa', 'Eletrodomésticos', 190000, true),
(33, 'Micro-ondas', 'Eletrodomésticos', 50000, true),
(34, 'Liquidificador', 'Eletrodomésticos', 18000, true),
(35, 'Air fryer', 'Eletrodomésticos', 40000, true),
(36, 'Cafeteira elétrica', 'Eletrodomésticos', 18000, true),
(37, 'Ferro de passar', 'Eletrodomésticos', 12000, true),
(38, 'Aspirador de pó', 'Eletrodomésticos', 35000, true),
(39, 'Ventilador', 'Eletrodomésticos', 18000, true),
(40, 'Cama (base casal padrão)', 'Quarto', 65000, true),
(41, 'Colchão casal padrão', 'Quarto', 100000, true),
(42, 'Guarda-roupa casal', 'Quarto', 175000, true),
(43, 'Jogo de lençol casal', 'Quarto', 25000, true),
(44, 'Lençol com elástico', 'Quarto', 9000, true),
(45, 'Travesseiros (par)', 'Quarto', 12000, true),
(46, 'Fronhas (par)', 'Quarto', 6000, true),
(47, 'Cobertor casal', 'Quarto', 16000, true),
(48, 'Edredom casal', 'Quarto', 35000, true),
(49, 'Cortina para quarto', 'Quarto', 18000, true),
(50, 'Cabides (kit com 10)', 'Quarto', 3000, true),
(51, 'Protetor de colchão', 'Quarto', 15000, true),
(52, 'Protetores de travesseiro (par)', 'Quarto', 6000, true),
(53, 'Espelho de corpo inteiro', 'Quarto', 15000, true),
(54, 'Toalhas de banho (jogo com 4)', 'Banheiro', 24000, true),
(55, 'Toalhas de rosto (jogo com 4)', 'Banheiro', 10000, true),
(56, 'Tapetes de banheiro (jogo)', 'Banheiro', 8000, true),
(57, 'Escova para vaso sanitário', 'Banheiro', 3000, true),
(58, 'Porta-papel higiênico', 'Banheiro', 3500, true),
(59, 'Porta-escova de dente', 'Banheiro', 2500, true),
(60, 'Porta-sabonete líquido', 'Banheiro', 2500, true),
(61, 'Porta-shampoo e condicionador', 'Banheiro', 4500, true),
(62, 'Porta-toalha', 'Banheiro', 4500, true),
(63, 'Cesto de roupa suja', 'Banheiro', 6000, true),
(64, 'Sofá de 2 lugares', 'Sala de estar e jantar', 183500, true),
(65, 'Cortina para sala', 'Sala de estar e jantar', 18000, true),
(66, 'Varão para cortina', 'Sala de estar e jantar', 6000, true),
(67, 'Rack para TV', 'Sala de estar e jantar', 48600, true),
(68, 'Mesa de centro', 'Sala de estar e jantar', 25000, true),
(69, 'Mesa de jantar com 4 cadeiras', 'Sala de estar e jantar', 130100, true),
(70, 'Varal', 'Lavanderia e limpeza', 10000, true),
(71, 'Cesto para roupas', 'Lavanderia e limpeza', 5000, true),
(72, 'Vassoura', 'Lavanderia e limpeza', 2500, true),
(73, 'Rodo', 'Lavanderia e limpeza', 2500, true),
(74, 'Balde', 'Lavanderia e limpeza', 2500, true),
(75, 'Pá de lixo', 'Lavanderia e limpeza', 1500, true),
(76, 'Panos de chão (kit)', 'Lavanderia e limpeza', 4000, true),
(77, 'Panos de limpeza multiuso (kit)', 'Lavanderia e limpeza', 3000, true),
(78, 'Prendedores de roupa (kit)', 'Lavanderia e limpeza', 2000, true),
(79, 'Escovas de limpeza (kit)', 'Lavanderia e limpeza', 2500, true),
(80, 'Luvas de limpeza', 'Lavanderia e limpeza', 1500, true),
(81, 'Lixeira', 'Lavanderia e limpeza', 5000, true),
(82, 'Bacia', 'Lavanderia e limpeza', 2000, true),
(83, 'Suporte para vassoura', 'Lavanderia e limpeza', 3500, true),
(84, 'Kit de ferramentas domésticas', 'Ferramentas e utilidades', 12000, true),
(85, 'Escada doméstica', 'Ferramentas e utilidades', 20000, true),
(86, 'Extensão elétrica', 'Ferramentas e utilidades', 5000, true),
(87, 'Adaptadores de tomada (kit)', 'Ferramentas e utilidades', 2500, true),
(88, 'Lâmpadas extras (kit com 6)', 'Ferramentas e utilidades', 9000, true),
(89, 'Lanterna', 'Ferramentas e utilidades', 4000, true),
(90, 'Sacos de lixo (pacote)', 'Ferramentas e utilidades', 2500, true),
(91, 'Tesoura', 'Ferramentas e utilidades', 2000, true),
(92, 'Fita isolante', 'Ferramentas e utilidades', 1000, true),
(93, 'Kit de costura', 'Ferramentas e utilidades', 3500, true),
(94, 'Curativos adesivos', 'Primeiros socorros', 1500, true),
(95, 'Gaze (pacote)', 'Primeiros socorros', 1500, true),
(96, 'Esparadrapo', 'Primeiros socorros', 1500, true),
(97, 'Termômetro', 'Primeiros socorros', 4000, true),
(98, 'Maleta de primeiros socorros', 'Primeiros socorros', 6000, true),
(99, 'Repelente', 'Primeiros socorros', 2500, true)
on conflict (id) do update set name=excluded.name, category=excluded.category, price_cents=excluded.price_cents, is_active=excluded.is_active;
