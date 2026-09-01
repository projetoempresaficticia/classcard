-- id_registar_pessoa agora cria o próprio login no Supabase Auth (deixa de
-- exigir que o admin crie o utilizador manualmente no Dashboard e cole o
-- UID). Usa o mesmo workaround já validado no bootstrap do professor
-- (sql/0004_bootstrap_professor.sql): insert direto em
-- auth.users/auth.identities com senha via pgcrypto. Idempotente por
-- email_login (tanto no lado Auth quanto na ficha).
-- Aplicada ao Supabase do projeto (moxxbehwylcjaqjacmyh) em 2026-09-01.

drop function if exists public.id_registar_pessoa(uuid, text, text, text, text);

create or replace function public.id_registar_pessoa(
  p_nome text,
  p_email_login text,
  p_senha text,
  p_email_interno text,
  p_papel text default 'aluno'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existente record;
  v_novo_uid uuid;
  v_cedula text;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'erro', 'Sem sessão.');
  end if;
  if not exists (select 1 from public.pessoas where id = v_uid and papel = 'professor') then
    return jsonb_build_object('ok', false, 'erro', 'Só o professor/admin regista pessoas.');
  end if;
  if coalesce(p_nome,'') = '' or coalesce(p_email_login,'') = '' or coalesce(p_senha,'') = '' then
    return jsonb_build_object('ok', false, 'erro', 'Dados obrigatórios em falta.');
  end if;
  if length(p_senha) < 6 then
    return jsonb_build_object('ok', false, 'erro', 'Senha precisa de pelo menos 6 caracteres.');
  end if;

  select * into v_existente from public.pessoas where email_login = p_email_login;
  if found then
    return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', v_existente.cedula));
  end if;

  select id into v_novo_uid from auth.users where email = p_email_login;
  if v_novo_uid is null then
    v_novo_uid := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data,
      is_super_admin, confirmation_token, recovery_token,
      email_change_token_new, email_change, is_sso_user, is_anonymous
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_novo_uid, 'authenticated', 'authenticated', p_email_login,
      extensions.crypt(p_senha, extensions.gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
      false, '', '', '', '', false, false
    );
    insert into auth.identities (
      id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_novo_uid::text, v_novo_uid,
      jsonb_build_object('sub', v_novo_uid::text, 'email', p_email_login, 'email_verified', true),
      'email', now(), now(), now()
    );
  end if;

  v_cedula := public.fn_proxima_cedula('PP');
  insert into public.pessoas(id, cedula, nome, email_login, email_interno, papel)
  values (v_novo_uid, v_cedula, p_nome, p_email_login, p_email_interno, coalesce(p_papel, 'aluno'));

  return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', v_cedula, 'email_login', p_email_login));
exception when others then
  return jsonb_build_object('ok', false, 'erro', 'Falha ao registar pessoa.');
end;
$$;
