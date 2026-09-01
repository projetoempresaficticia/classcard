// ClassCard — página pública de verificação (aberta pelo QR do cartão).
// Não exige login: id_resolver expõe só campos públicos.

const painelCarregando = document.getElementById('carregando');
const painelResultado = document.getElementById('resultado');
const painelNaoEncontrado = document.getElementById('nao-encontrado');

function mostrarPainel(painel) {
  painelCarregando.hidden = true;
  painelResultado.hidden = true;
  painelNaoEncontrado.hidden = true;
  painel.hidden = false;
}

const SELO_POR_ESTADO = {
  ativa: {
    classe: 'verificacao-selo-ok',
    icone: '✓',
    titulo: 'Identidade verificada',
    subtitulo: 'Reconhecida e ativa no Prepara Portugal',
  },
  suspensa: {
    classe: 'verificacao-selo-aviso',
    icone: '!',
    titulo: 'Identidade suspensa',
    subtitulo: 'Reconhecida pelo Prepara Portugal, mas atualmente suspensa',
  },
  falida: {
    classe: 'verificacao-selo-erro',
    icone: '✕',
    titulo: 'Empresa falida',
    subtitulo: 'Já não está ativa no Prepara Portugal',
  },
};

async function verificar() {
  const params = new URLSearchParams(window.location.search);
  const cedula = params.get('cedula');
  if (!cedula) {
    mostrarPainel(painelNaoEncontrado);
    return;
  }

  const r = await api('id_resolver', { p_cedula: cedula });
  if (!r.ok) {
    mostrarPainel(painelNaoEncontrado);
    return;
  }

  const d = r.dados;
  const selo = SELO_POR_ESTADO[d.estado] || SELO_POR_ESTADO.ativa;

  const seloEl = document.getElementById('v-selo');
  seloEl.className = 'verificacao-selo ' + selo.classe;
  document.getElementById('v-icone').textContent = selo.icone;
  document.getElementById('v-titulo').textContent = selo.titulo;
  document.getElementById('v-subtitulo').textContent = selo.subtitulo;

  document.getElementById('v-nome').textContent = d.nome;
  document.getElementById('v-cedula').textContent = d.cedula;

  const estadoEl = document.getElementById('v-estado');
  estadoEl.textContent = d.estado;
  estadoEl.className = 'estado-badge estado-' + d.estado;

  if (d.tipo === 'empresa') {
    document.getElementById('v-rotulo-papel').textContent = 'Setor';
    document.getElementById('v-papel').textContent = d.setor || '—';
    document.getElementById('v-linha-empresa').hidden = true;
  } else {
    document.getElementById('v-rotulo-papel').textContent = 'Papel';
    document.getElementById('v-papel').textContent = d.papel || '—';
    document.getElementById('v-linha-empresa').hidden = false;
    document.getElementById('v-empresa').textContent = d.empresa_nome || '—';
  }

  mostrarPainel(painelResultado);
}

verificar();
