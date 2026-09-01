-- Fix: "professor le todas as pessoas" fazia subquery na própria tabela
-- pessoas, causando "infinite recursion detected in policy for relation
-- pessoas" (42P17) em qualquer select — inclusive o self-read da própria
-- pessoa, porque o Postgres avalia TODAS as policies permissivas da
-- tabela, não só a que bateria primeiro.
-- Corrige com uma função security definer (bypassa RLS na checagem
-- interna, como fn_auditar()), quebrando o ciclo.
-- Aplicada ao Supabase do projeto (moxxbehwylcjaqjacmyh) em 2026-09-01,
-- descoberta ao testar o login real do professor de ponta a ponta.

create or replace function public.fn_e_professor()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.pessoas where id = auth.uid() and papel = 'professor'
  );
$$;
revoke execute on function public.fn_e_professor() from anon, authenticated;
grant execute on function public.fn_e_professor() to authenticated;

drop policy if exists "professor le todas as pessoas" on public.pessoas;
create policy "professor le todas as pessoas"
  on public.pessoas for select
  using (public.fn_e_professor());

drop policy if exists "professor le todas as empresas" on public.empresas;
create policy "professor le todas as empresas"
  on public.empresas for select
  using (public.fn_e_professor());
