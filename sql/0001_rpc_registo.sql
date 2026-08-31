-- pp-identidade: RPCs de registo/vínculo/estado (porta única).
-- Aplicada ao Supabase do projeto (moxxbehwylcjaqjacmyh) em 2026-08-31.
-- id_resolver e fn_proxima_cedula já existiam de sessões anteriores.

-- id_registar_pessoa: liga a ficha a um utilizador de Auth já criado pelo
-- admin (Supabase não permite criar auth.users de forma suportada a partir
-- de SQL puro — o admin cria o login no Dashboard/Admin API e passa o uid
-- aqui). Idempotente: se o uid já tem ficha, devolve a cédula existente.
create or replace function public.id_registar_pessoa(
  p_auth_uid uuid,
  p_nome text,
  p_email_login text,
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
  v_cedula text;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'erro', 'Sem sessão.');
  end if;
  if not exists (select 1 from public.pessoas where id = v_uid and papel = 'professor') then
    return jsonb_build_object('ok', false, 'erro', 'Só o professor/admin regista pessoas.');
  end if;
  if p_auth_uid is null or coalesce(p_nome,'') = '' or coalesce(p_email_login,'') = '' then
    return jsonb_build_object('ok', false, 'erro', 'Dados obrigatórios em falta.');
  end if;

  select * into v_existente from public.pessoas where id = p_auth_uid;
  if found then
    return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', v_existente.cedula));
  end if;

  v_cedula := public.fn_proxima_cedula('PP');
  insert into public.pessoas(id, cedula, nome, email_login, email_interno, papel)
  values (p_auth_uid, v_cedula, p_nome, p_email_login, p_email_interno, coalesce(p_papel, 'aluno'));

  return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', v_cedula));
exception when others then
  return jsonb_build_object('ok', false, 'erro', 'Falha ao registar pessoa.');
end;
$$;

-- id_registar_empresa: idempotente por email_empresa quando fornecido.
create or replace function public.id_registar_empresa(
  p_nome text,
  p_email_empresa text,
  p_regiao text,
  p_setor text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_existente record;
  v_cedula text;
  v_nif text;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'erro', 'Sem sessão.');
  end if;
  if not exists (select 1 from public.pessoas where id = v_uid and papel = 'professor') then
    return jsonb_build_object('ok', false, 'erro', 'Só o professor/admin regista empresas.');
  end if;
  if coalesce(p_nome,'') = '' then
    return jsonb_build_object('ok', false, 'erro', 'Nome é obrigatório.');
  end if;

  if p_email_empresa is not null then
    select * into v_existente from public.empresas where email_empresa = p_email_empresa;
    if found then
      return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', v_existente.cedula, 'nif_ficticio', v_existente.nif_ficticio));
    end if;
  end if;

  v_cedula := public.fn_proxima_cedula('EP');
  v_nif := regexp_replace(v_cedula, '\D', '', 'g');
  insert into public.empresas(cedula, nome, nif_ficticio, email_empresa, regiao, setor)
  values (v_cedula, p_nome, v_nif, p_email_empresa, p_regiao, p_setor);

  return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', v_cedula, 'nif_ficticio', v_nif));
exception when others then
  return jsonb_build_object('ok', false, 'erro', 'Falha ao registar empresa.');
end;
$$;

-- id_vincular: liga/transfere uma pessoa para uma empresa.
create or replace function public.id_vincular(
  p_pessoa_cedula text,
  p_empresa_cedula text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_empresa_id uuid;
  v_pessoa record;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'erro', 'Sem sessão.');
  end if;
  if not exists (select 1 from public.pessoas where id = v_uid and papel = 'professor') then
    return jsonb_build_object('ok', false, 'erro', 'Só o professor/admin vincula pessoas a empresas.');
  end if;

  select * into v_pessoa from public.pessoas where cedula = p_pessoa_cedula;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Pessoa não encontrada.');
  end if;
  if v_pessoa.estado <> 'ativa' then
    return jsonb_build_object('ok', false, 'erro', 'Pessoa não está ativa.');
  end if;

  select id into v_empresa_id from public.empresas where cedula = p_empresa_cedula and estado = 'ativa';
  if v_empresa_id is null then
    return jsonb_build_object('ok', false, 'erro', 'Empresa não encontrada ou inativa.');
  end if;

  update public.pessoas set empresa_id = v_empresa_id where cedula = p_pessoa_cedula;

  return jsonb_build_object('ok', true, 'dados', jsonb_build_object('pessoa', p_pessoa_cedula, 'empresa', p_empresa_cedula));
exception when others then
  return jsonb_build_object('ok', false, 'erro', 'Falha ao vincular.');
end;
$$;

-- id_estado: máquina de estados explícita (R4 da pp-base).
create or replace function public.id_estado(
  p_cedula text,
  p_novo_estado text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_atual text;
  v_e_pessoa boolean := p_cedula like 'PP-%';
  v_transicoes_pessoa jsonb := '{"ativa":["suspensa"],"suspensa":["ativa"]}'::jsonb;
  v_transicoes_empresa jsonb := '{"ativa":["suspensa","falida"],"suspensa":["ativa","falida"],"falida":[]}'::jsonb;
  v_permitidas jsonb;
begin
  if v_uid is null then
    return jsonb_build_object('ok', false, 'erro', 'Sem sessão.');
  end if;
  if not exists (select 1 from public.pessoas where id = v_uid and papel = 'professor') then
    return jsonb_build_object('ok', false, 'erro', 'Só o professor/admin muda estados.');
  end if;

  if v_e_pessoa then
    select estado into v_atual from public.pessoas where cedula = p_cedula;
  else
    select estado into v_atual from public.empresas where cedula = p_cedula;
  end if;
  if v_atual is null then
    return jsonb_build_object('ok', false, 'erro', 'Cédula não encontrada.');
  end if;

  v_permitidas := case when v_e_pessoa then v_transicoes_pessoa -> v_atual else v_transicoes_empresa -> v_atual end;
  if v_permitidas is null or not (v_permitidas ? p_novo_estado) then
    return jsonb_build_object('ok', false, 'erro', format('Transição %s → %s não permitida.', v_atual, p_novo_estado));
  end if;

  if v_e_pessoa then
    update public.pessoas set estado = p_novo_estado where cedula = p_cedula;
  else
    update public.empresas set estado = p_novo_estado where cedula = p_cedula;
  end if;

  return jsonb_build_object('ok', true, 'dados', jsonb_build_object('cedula', p_cedula, 'estado', p_novo_estado));
exception when others then
  return jsonb_build_object('ok', false, 'erro', 'Falha ao mudar estado.');
end;
$$;
