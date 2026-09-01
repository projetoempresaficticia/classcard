# pp-identidade

ClassCard (Carteirinha Prepara) — identidade de pessoas e empresas (Prepara Portugal)

**Status:** RPCs de registo construídas e testadas, RLS de leitura aplicada,
frontend (cartão + admin) publicado, professor bootstrap concluído e
testado de ponta a ponta com login real.
**Depende de:** [pp-base](https://github.com/projetoempresaficticia/pp-base)

Documentação completa (PRDs e decisões) em
[prepara-portugal-docs](https://github.com/projetoempresaficticia/prepara-portugal-docs).

Site: https://projetoempresaficticia.github.io/pp-identidade/

## O que este repositório fornece

- `sql/0001_rpc_registo.sql` — RPCs `id_registar_pessoa`, `id_registar_empresa`,
  `id_vincular`, `id_estado` (porta única, `{ok}` sempre, só professor/admin).
  `id_resolver` e `fn_proxima_cedula` já existiam de sessões anteriores e não
  foram alteradas.
- `sql/0002_rls_leitura.sql` — cada pessoa lê a própria ficha; quem está
  vinculado a uma empresa lê os dados dela; o professor lê tudo.
- `sql/0003_fix_rls_recursao.sql` — corrige "infinite recursion detected in
  policy for relation pessoas" (42P17): a policy "professor lê todas as
  pessoas" fazia uma subquery na própria tabela `pessoas`, o que quebra
  **qualquer** select na tabela (inclusive o self-read), porque o Postgres
  avalia todas as policies permissivas, não só a que bateria primeiro.
  Corrigido com uma função `security definer` (`fn_e_professor()`), que
  bypassa RLS na checagem interna — mesmo padrão do `fn_auditar()`. Regra
  para as próximas skills: **nunca** fazer subquery de checagem de papel na
  mesma tabela que a policy protege; usar sempre uma função assim.
- `sql/0004_bootstrap_professor.sql` — molde (sem credenciais reais) do
  script usado para criar o primeiro professor diretamente em
  `auth.users`/`auth.identities`, workaround não-oficial já que o Supabase
  não expõe a API de admin por SQL puro.
- `index.html` + `app.js` — login e carteirinha visual da própria pessoa.
- `admin.html` + `admin.js` — painel do professor/admin: registar pessoa,
  registar empresa, vincular pessoa↔empresa, buscar por cédula.
- `web/estilos.css` — paleta oficial Prepara Portugal (azul), distinta da
  paleta do Banco em `pp-base`, conforme fixado no `SKILL.md` §7.

## Bootstrap do professor (concluído)

Não há auto-registo — só quem já tem `papel = 'professor'` pode chamar as
RPCs de registo, o que cria um problema clássico de arranque. Resolvido em
2026-09-01: o primeiro login (`projetoempresaficticia@gmail.com`) foi criado
diretamente em `auth.users`/`auth.identities` (ver
`sql/0004_bootstrap_professor.sql` para o molde) e ligado à ficha
`PP-2026-00002`, papel `professor`. Testado de ponta a ponta com login real
no admin publicado e na carteirinha.

Para as próximas pessoas, o professor usa o painel admin normalmente — mas o
login do Supabase Auth de cada uma ainda precisa ser criado antes no
Dashboard → Authentication → Add user (as RPCs não criam logins, só ligam a
ficha a um login já existente pelo seu UID).

## Testes

Todas as RPCs foram testadas via SQL real contra o Supabase do projeto
(registo, idempotência ao repetir, vínculo, transição de estado válida e
inválida, e conferência da auditoria) e os dados de teste foram limpos no
fim — sem dados fictícios de teste a mais na base.

## Advisory de segurança (esperado)

O Supabase security advisor assinala `id_registar_pessoa`,
`id_registar_empresa`, `id_vincular` e `id_estado` como `SECURITY DEFINER`
chamáveis por `anon`/`authenticated` — isto é intencional (porta única): a
própria função verifica `papel = 'professor'` internamente e recusa quem não
tem permissão, em vez de bloquear pelo `GRANT`. Mesmo padrão já usado por
`banco_transferir`, `orgao_submeter`, etc.

## Convenções

- Todas as regras técnicas completas estão na skill `pp-identidade` dentro
  de `.claude/skills/` (não versionada neste repositório — configuração
  local do Claude Code).
- Commits seguem a convenção Angular (`feat`, `fix`, `docs`, `chore`, ...).
