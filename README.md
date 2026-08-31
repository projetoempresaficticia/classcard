# pp-identidade

Carteirinha Prepara — identidade de pessoas e empresas (Prepara Portugal)

**Status:** RPCs de registo construídas e testadas, RLS de leitura aplicada,
frontend (cartão + admin) publicado.
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
- `index.html` + `app.js` — login e carteirinha visual da própria pessoa.
- `admin.html` + `admin.js` — painel do professor/admin: registar pessoa,
  registar empresa, vincular pessoa↔empresa, buscar por cédula.
- `web/estilos.css` — paleta oficial Prepara Portugal (azul), distinta da
  paleta do Banco em `pp-base`, conforme fixado no `SKILL.md` §7.

## Como registar a primeira pessoa (bootstrap do professor)

Não há auto-registo — só quem já tem `papel = 'professor'` pode chamar as
RPCs de registo. Isto cria um problema de arranque: **a própria primeira
conta de professor** tem de ser inserida manualmente uma vez, fora das RPCs
(pelo dono do projeto Supabase, com acesso direto à base). Depois disso,
esse professor usa o painel admin normalmente para registar todo o resto.

Para cada pessoa (incluindo o próprio professor), o login do Supabase Auth é
criado antes, no Dashboard do Supabase → Authentication → Add user — as RPCs
desta skill não criam logins, só ligam a ficha (`pessoas`) a um login já
existente pelo seu UID.

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
