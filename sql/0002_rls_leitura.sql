-- pp-identidade §6: leitura própria + leitura total do professor/admin.
-- Aplicada ao Supabase do projeto (moxxbehwylcjaqjacmyh) em 2026-08-31.

create policy "pessoa le a propria ficha"
  on public.pessoas for select
  using (id = auth.uid());

create policy "professor le todas as pessoas"
  on public.pessoas for select
  using (
    exists (select 1 from public.pessoas p where p.id = auth.uid() and p.papel = 'professor')
  );

create policy "vinculado le a propria empresa"
  on public.empresas for select
  using (
    exists (select 1 from public.pessoas p where p.empresa_id = empresas.id and p.id = auth.uid())
  );

create policy "professor le todas as empresas"
  on public.empresas for select
  using (
    exists (select 1 from public.pessoas p where p.id = auth.uid() and p.papel = 'professor')
  );
