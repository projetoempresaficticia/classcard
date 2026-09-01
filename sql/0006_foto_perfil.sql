-- Foto de perfil no cartão: bucket público de Storage + coluna foto_url +
-- RPC que só deixa a própria pessoa atualizar a sua foto.
-- Aplicada ao Supabase do projeto (moxxbehwylcjaqjacmyh) em 2026-09-01.

insert into storage.buckets (id, name, public)
values ('avatares', 'avatares', true)
on conflict (id) do nothing;

-- Cada pessoa só grava/atualiza/apaga dentro da própria pasta
-- (avatares/{uid}/...), identificada pelo primeiro segmento do path.
create policy "dono envia a propria foto"
  on storage.objects for insert
  with check (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "dono atualiza a propria foto"
  on storage.objects for update
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "dono remove a propria foto"
  on storage.objects for delete
  using (bucket_id = 'avatares' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "leitura publica de avatares"
  on storage.objects for select
  using (bucket_id = 'avatares');

alter table public.pessoas add column if not exists foto_url text;

-- Porta única: só atualiza a própria foto, nunca a de outra pessoa.
create or replace function public.id_atualizar_foto(p_foto_url text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'erro', 'Sem sessão.');
  end if;
  update public.pessoas set foto_url = p_foto_url where id = v_uid;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Ficha não encontrada.');
  end if;
  return jsonb_build_object('ok', true, 'dados', jsonb_build_object('foto_url', p_foto_url));
end;
$$;
