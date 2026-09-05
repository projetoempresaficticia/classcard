# classcard

ClassCard (Carteirinha Prepara) — identidade de pessoas e empresas (Prepara Portugal)

**Status:** RPCs de registo construídas e testadas, RLS de leitura aplicada,
frontend (cartão + admin) publicado, professor bootstrap concluído e
testado de ponta a ponta com login real.
**Depende de:** [pp-base](https://github.com/projetoempresaficticia/pp-base)

Documentação completa (PRDs e decisões) em
[prepara-portugal-docs](https://github.com/projetoempresaficticia/prepara-portugal-docs).

Site: https://projetoempresaficticia.github.io/classcard/

## Identidade visual

**Adotada em 2026-09-05**, a partir do ícone e do fundo que o Germano
forneceu. A marca é a rede à volta de uma pessoa, que é literalmente o
que a Carteirinha faz: liga cada pessoa às empresas e aos órgãos.

- Azul da marca `#005ED7` · Azul forte `#0047BC` · Azul-marinho `#032268`
  · Tinta `#101828` · Secundário `#475467`
- A arte está em `web/marca/`; `python ferramentas/gerar_marca.py`
  regenera tudo a partir dos originais.

### Aqui a regra é ao contrário das outras apps

No Prepacoin o lima tem 1,10:1 sobre branco, e no Subsight o laranja tem
2,53:1: em ambos a cor da marca é clara demais para escrever, e serve só
de preenchimento com tinta por cima.

**O azul é escuro, e dá 5,86:1 nos dois sentidos** — branco por cima
dele, e ele por cima de branco. Uma cor só faz os dois trabalhos, e não
é preciso um segundo tom para texto. É a app mais fácil das três neste
ponto.

A exceção é o azul claro `#60BFFE`: 2,02:1 sobre branco, mas 7,25:1
sobre o azul-marinho. Só se usa sobre escuro. (O `#80BADB` que aqui
estava tinha o mesmo problema, 2,11:1, e era usado em links de
cabeçalho.)

### Dois bugs que a arte destapou

**Os rótulos dos campos eram brancos sobre branco.** O `body.tema-cartao`
define `color: #fff` para o texto assentar no fundo azul, e isso
cascateava para dentro do formulário branco: 1:1, invisíveis. O bug já cá
estava com o fundo azul-marinho anterior; só se viu agora porque fui
olhar de perto.

**O formulário de login ficava visível ao lado da carteirinha depois de
entrar.** Uma regra minha com `display: grid` no `#area-login` venceu o
comportamento nativo do atributo `hidden`. Esta folha não tinha a rede de
segurança `[hidden] { display: none !important }` — e é a terceira vez
que este mesmo bug aparece no ecossistema (antes no subsight, com
`header nav { display:flex }`). Agora tem.

### Peso e altura

O fundo passou de **1177 KB em PNG para 39 KB em WebP**, com JPEG de
70 KB como reserva e uma faixa central de 6 KB para telemóvel. A marca do
cabeçalho aparece a 38px, por isso é servida a 128px em WebP (8 KB) e não
aos 512 do ficheiro de partilha, que eram 227 KB para desenhar 38.

Os espaçamentos da entrada acompanham a **altura da janela**, com `svh`
(que já desconta as barras do browser) e `clamp()` a travar os extremos,
para não ser preciso rolar num portátil comum. Há um piso de 560px:
abaixo disso apertar mais cortava o formulário.

`python ferramentas/versoes.py` carimba os `?v=` e o `versao.json`; o
`web/atualizar.js` recarrega quem tiver uma versão velha em cache, porque
o GitHub Pages manda `Cache-Control: max-age=600` no HTML.

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
- `sql/0005_registro_cria_auth.sql` — `id_registar_pessoa` passou a criar o
  próprio login no Supabase Auth (nome + email + senha), em vez de exigir
  que o admin crie o utilizador no Dashboard e cole o UID. Mesmo workaround
  do bootstrap do professor, agora reutilizável por qualquer registo.
  Assinatura mudou: `p_auth_uid` saiu, entrou `p_senha`.
- `sql/0006_foto_perfil.sql` — bucket público `avatares` no Storage (cada
  pessoa só grava na própria pasta `{uid}/...`), coluna `pessoas.foto_url`,
  e a RPC `id_atualizar_foto` (só atualiza a própria foto).
- `verificar.html` + `verificar.js` — página pública de verificação
  (sem login) aberta pelo QR do cartão: mostra um selo "reconhecida pelo
  Prepara Portugal" (verde/ativa, âmbar/suspensa, vermelho/falida ou não
  encontrada) com os dados públicos de `id_resolver`.
- `index.html` + `app.js` — login, carteirinha visual da própria pessoa
  (com upload de foto de perfil, clicando no avatar) e QR que abre
  `verificar.html`.
- `admin.html` + `admin.js` — painel do professor/admin organizado em abas
  (Registar pessoa, Registar empresa, Vincular, Buscar, Diretório) em vez
  de uma página longa de rolar — cada seção só aparece quando a aba é
  clicada.
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

Para as próximas pessoas, o professor usa o painel admin normalmente — desde
`sql/0005_registro_cria_auth.sql` o próprio formulário (nome, email, senha)
cria o login e a ficha numa única ação, sem precisar do Dashboard nem de
UID.

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
