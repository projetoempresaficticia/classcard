// pp-identidade — login e carteirinha visual da própria pessoa.

const areaLogin = document.getElementById('area-login');
const areaCartao = document.getElementById('area-cartao');
const formLogin = document.getElementById('form-login');
const msgLogin = document.getElementById('msg-login');

function mostrarErro(el, texto) {
  el.textContent = texto;
  el.className = 'msg erro';
}

async function carregarCartao() {
  const { data: sessao } = await sb.auth.getSession();
  if (!sessao.session) return;

  const uid = sessao.session.user.id;
  const { data: pessoa, error } = await sb
    .from('pessoas')
    .select('cedula, nome, papel, estado, empresa_id')
    .eq('id', uid)
    .single();

  if (error || !pessoa) {
    mostrarErro(msgLogin, 'Sem ficha no ClassCard para este login. Fale com o professor/admin.');
    return;
  }

  let empresaNome = '—';
  if (pessoa.empresa_id) {
    const { data: empresa } = await sb
      .from('empresas')
      .select('nome')
      .eq('id', pessoa.empresa_id)
      .single();
    if (empresa) empresaNome = empresa.nome;
  }

  document.getElementById('c-cedula').textContent = pessoa.cedula;
  document.getElementById('c-nome').textContent = pessoa.nome;
  document.getElementById('c-empresa').textContent = empresaNome;
  document.getElementById('c-papel').textContent = pessoa.papel;

  const iniciais = pessoa.nome
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0].toUpperCase())
    .join('');
  document.getElementById('c-avatar').textContent = iniciais || '?';

  const badge = document.getElementById('c-estado');
  badge.textContent = pessoa.estado;
  badge.className = 'estado-badge estado-' + pessoa.estado;

  const urlVerificacao =
    'https://projetoempresaficticia.github.io/classcard/verificar.html?cedula=' +
    encodeURIComponent(pessoa.cedula);
  document.getElementById('c-qr').innerHTML = '';
  new QRCode(document.getElementById('c-qr'), {
    text: urlVerificacao,
    width: 92,
    height: 92,
    colorDark: '#1A1C31',
    colorLight: '#FFFFFF',
  });

  areaLogin.hidden = true;
  areaCartao.hidden = false;
}

formLogin.addEventListener('submit', async (ev) => {
  ev.preventDefault();
  msgLogin.textContent = '';
  const email = document.getElementById('email').value;
  const senha = document.getElementById('senha').value;
  const { error } = await sb.auth.signInWithPassword({ email, password: senha });
  if (error) {
    mostrarErro(msgLogin, 'Login inválido.');
    return;
  }
  await carregarCartao();
});

document.getElementById('btn-sair').addEventListener('click', async () => {
  await sb.auth.signOut();
  areaCartao.hidden = true;
  areaLogin.hidden = false;
});

carregarCartao();
