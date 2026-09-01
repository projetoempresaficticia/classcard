-- Molde para o bootstrap do primeiro professor/admin — necessário porque as
-- RPCs de registo só aceitam chamadas de quem já é professor (problema
-- clássico de arranque). Substitua o email/senha e rode manualmente uma
-- única vez; depois disso use o painel admin normalmente.
--
-- NÃO commitar este ficheiro com credenciais reais preenchidas — é um
-- molde. O Supabase não suporta criar auth.users por SQL puro de forma
-- oficial; isto é um workaround para um projeto educacional, não o
-- caminho recomendado em produção real.

do $$
declare
  v_uid uuid := gen_random_uuid();
  v_cedula text;
  v_email text := 'trocar@exemplo.com';
  v_senha text := 'trocar-senha';
  v_nome text := 'Professor Prepara';
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, confirmation_token, recovery_token,
    email_change_token_new, email_change, is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000',
    v_uid, 'authenticated', 'authenticated', v_email,
    extensions.crypt(v_senha, extensions.gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    false, '', '', '', '', false, false
  );

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_uid::text, v_uid,
    jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', true),
    'email', now(), now(), now()
  );

  v_cedula := public.fn_proxima_cedula('PP');
  insert into public.pessoas(id, cedula, nome, email_login, email_interno, papel, estado)
  values (v_uid, v_cedula, v_nome, v_email, null, 'professor', 'ativa');
end $$;
