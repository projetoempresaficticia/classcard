// ClassCard — painel admin: registo de pessoas/empresas, vínculo, busca,
// diretório (somente alunos / somente empresas).

const areaLogin = document.getElementById('area-login');
const areaAdmin = document.getElementById('area-admin');
const formLogin = document.getElementById('form-login');
const msgLogin = document.getElementById('msg-login');

function mostrar(el, resultado) {
  if (resultado.ok) {
    el.textContent = 'OK: ' + JSON.stringify(resultado.dados);
    el.className = 'msg sucesso';
  } else {
    el.textContent = 'Erro: ' + resultado.erro;
    el.className = 'msg erro';
  }
}

async function verificarSessao() {
  const { data } = await sb.auth.getSession();
  if (data.session) {
    areaLogin.hidden = true;
    areaAdmin.hidden = false;
    carregarAlunos();
  }
}

// ---- Diretório: somente alunos / somente empresas ----

const abaAlunos = document.getElementById('aba-alunos');
const abaEmpresas = document.getElementById('aba-empresas');
const tabelaAlunos = document.getElementById('tabela-alunos');
const listaEmpresas = document.getElementById('lista-empresas');

async function carregarAlunos() {
  abaAlunos.classList.add('aba-ativa');
  abaEmpresas.classList.remove('aba-ativa');
  tabelaAlunos.hidden = false;
  listaEmpresas.hidden = true;

  const { data, error } = await sb
    .from('pessoas')
    .select('cedula, nome, estado, empresas(nome)')
    .eq('papel', 'aluno')
    .order('nome');

  const corpo = tabelaAlunos.querySelector('tbody');
  corpo.innerHTML = '';
  if (error) {
    corpo.innerHTML = `<tr><td colspan="4">Erro ao carregar: ${error.message}</td></tr>`;
    return;
  }
  if (!data.length) {
    corpo.innerHTML = '<tr><td colspan="4">Nenhum aluno registado ainda.</td></tr>';
    return;
  }
  for (const p of data) {
    const linha = document.createElement('tr');
    linha.innerHTML = `
      <td>${p.cedula}</td>
      <td>${p.nome}</td>
      <td>${p.empresas ? p.empresas.nome : '—'}</td>
      <td><span class="estado-badge estado-${p.estado}">${p.estado}</span></td>
    `;
    corpo.appendChild(linha);
  }
}

async function carregarEmpresas() {
  abaEmpresas.classList.add('aba-ativa');
  abaAlunos.classList.remove('aba-ativa');
  listaEmpresas.hidden = false;
  tabelaAlunos.hidden = true;

  const { data, error } = await sb
    .from('empresas')
    .select('cedula, nome, setor, regiao, estado, pessoas!pessoas_empresa_id_fkey(cedula, nome, papel, estado)')
    .order('nome');

  listaEmpresas.innerHTML = '';
  if (error) {
    listaEmpresas.innerHTML = `<p class="msg erro">Erro ao carregar: ${error.message}</p>`;
    return;
  }
  if (!data.length) {
    listaEmpresas.innerHTML = '<p class="msg">Nenhuma empresa registada ainda.</p>';
    return;
  }
  for (const e of data) {
    const bloco = document.createElement('div');
    bloco.className = 'bloco-empresa';
    const membros = (e.pessoas || [])
      .map((p) => `<li>${p.nome} <span class="cedula-inline">${p.cedula}</span> — ${p.papel}, ${p.estado}</li>`)
      .join('');
    bloco.innerHTML = `
      <div class="bloco-empresa-topo">
        <strong>${e.nome}</strong> <span class="cedula-inline">${e.cedula}</span>
        <span class="estado-badge estado-${e.estado}">${e.estado}</span>
      </div>
      <div class="bloco-empresa-meta">${e.setor || '—'} · ${e.regiao || '—'}</div>
      <ul class="bloco-empresa-membros">
        ${membros || '<li class="vazio">Nenhuma pessoa vinculada ainda.</li>'}
      </ul>
    `;
    listaEmpresas.appendChild(bloco);
  }
}

abaAlunos.addEventListener('click', carregarAlunos);
abaEmpresas.addEventListener('click', carregarEmpresas);

formLogin.addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const email = document.getElementById('email').value;
  const senha = document.getElementById('senha').value;
  const { error } = await sb.auth.signInWithPassword({ email, password: senha });
  if (error) {
    msgLogin.textContent = 'Login inválido.';
    msgLogin.className = 'msg erro';
    return;
  }
  await verificarSessao();
});

document.getElementById('form-pessoa').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const r = await api('id_registar_pessoa', {
    p_auth_uid: document.getElementById('p-uid').value,
    p_nome: document.getElementById('p-nome').value,
    p_email_login: document.getElementById('p-email-login').value,
    p_email_interno: document.getElementById('p-email-interno').value || null,
    p_papel: document.getElementById('p-papel').value,
  });
  mostrar(document.getElementById('msg-pessoa'), r);
  if (r.ok) carregarAlunos();
});

document.getElementById('form-empresa').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const r = await api('id_registar_empresa', {
    p_nome: document.getElementById('e-nome').value,
    p_email_empresa: document.getElementById('e-email').value || null,
    p_regiao: document.getElementById('e-regiao').value || null,
    p_setor: document.getElementById('e-setor').value || null,
  });
  mostrar(document.getElementById('msg-empresa'), r);
  if (r.ok && !listaEmpresas.hidden) carregarEmpresas();
});

document.getElementById('form-vincular').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const r = await api('id_vincular', {
    p_pessoa_cedula: document.getElementById('v-pessoa').value,
    p_empresa_cedula: document.getElementById('v-empresa').value,
  });
  mostrar(document.getElementById('msg-vincular'), r);
  if (r.ok) (listaEmpresas.hidden ? carregarAlunos() : carregarEmpresas());
});

document.getElementById('form-buscar').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const r = await api('id_resolver', { p_cedula: document.getElementById('b-cedula').value });
  const msg = document.getElementById('msg-buscar');
  const tabela = document.getElementById('tabela-busca');
  if (!r.ok) {
    mostrar(msg, r);
    tabela.hidden = true;
    return;
  }
  msg.textContent = '';
  tabela.hidden = false;
  const corpo = tabela.querySelector('tbody');
  corpo.innerHTML = '';
  for (const [chave, valor] of Object.entries(r.dados)) {
    const linha = document.createElement('tr');
    linha.innerHTML = `<th>${chave}</th><td>${valor ?? '—'}</td>`;
    corpo.appendChild(linha);
  }
});

verificarSessao();
