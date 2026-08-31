// pp-identidade — painel admin: registo de pessoas/empresas, vínculo, busca.

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
  }
}

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
});

document.getElementById('form-vincular').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const r = await api('id_vincular', {
    p_pessoa_cedula: document.getElementById('v-pessoa').value,
    p_empresa_cedula: document.getElementById('v-empresa').value,
  });
  mostrar(document.getElementById('msg-vincular'), r);
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
