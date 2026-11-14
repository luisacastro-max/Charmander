// API de DEMONSTRAÇÃO do mapa colaborativo de alertas do Acessa+.
//
// Não é produção: sem autenticação, sem moderação, um processo só, dados
// num arquivo JSON local. Serve para mostrar o compartilhamento real entre
// sessões (dois navegadores/aparelhos apontando para o mesmo servidor).
//
// As regras repetem as do app (app/lib/domain/rules/ocorrencias.dart e
// app/lib/domain/models/ocorrencia.dart). Se mudar lá, mude aqui.
//
// Uso: const { criarApiOcorrencias } = require('./api-ocorrencias');
//      const api = criarApiOcorrencias({ arquivo });
//      http.createServer((req, res) => { if (api(req, res)) return; ... });
//
// Endpoints (prefixo /api/ocorrencias):
//   GET  /saude                 -> { ok: true }
//   GET  ?shopping=ID           -> { ocorrencias: [...], agora }
//   POST /                      -> 201 { ocorrencia, duplicada: false }
//                                  200 { ocorrencia, duplicada: true }
//   POST /:id/confirmar         -> { ocorrencia }
//   POST /:id/resolver          -> { ocorrencia }
// Erros: { erro: "mensagem curta" } com 400, 404, 405, 413, 415, 429, 500.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PREFIXO = '/api/ocorrencias';
const HORA = 3600 * 1000;

// Mesmas validades de TipoOcorrencia.validade (em horas).
const VALIDADE_H = {
  pisoMolhado: 2,
  passagemInterditada: 8,
  obstaculo: 2,
  elevadorParado: 12,
  escadaRolanteParada: 12,
  rampaBloqueada: 6,
  localCheio: 1,
  outro: 3,
};
const RAIO_DUPLICADO = 30; // raioDuplicado
const RESOLUCOES_NECESSARIAS = 2; // resolucoesNecessarias
const MAX_DESCRICAO = 140; // NovaOcorrencia.maxDescricao
const MAX_CORPO = 4 * 1024;
const RETENCAO_MS = 24 * HORA; // resolvidos/expirados somem da lista depois
const LIMITE_SESSAO_MIN = 5; // relatos por sessão por minuto
const LIMITE_IP_MIN = 20; // relatos por endereço por minuto

const ID_SIMPLES = /^[A-Za-z0-9_-]{1,40}$/;
const SESSAO = /^[A-Za-z0-9_-]{8,64}$/;
const ORIGEM_LOCAL = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d{1,5})?$/;

// ---- Regras (espelho do Dart) ----

const expiraEm = (o) => Date.parse(o.confirmadaEm) + VALIDADE_H[o.tipo] * HORA;

function situacao(o, agora) {
  if (o.resolvidaEm) return 'resolvida';
  if (agora >= expiraEm(o)) return 'expirada';
  return 'ativa';
}

const dist = (ax, ay, bx, by) => Math.hypot(ax - bx, ay - by);

function duplicadaDe(lista, n, agora) {
  let melhor = null;
  let menor = Infinity;
  for (const o of lista) {
    if (o.shoppingId !== n.shoppingId || o.tipo !== n.tipo || o.piso !== n.piso ||
        situacao(o, agora) !== 'ativa') continue;
    const d = dist(o.x, o.y, n.x, n.y);
    if (d <= RAIO_DUPLICADO && d < menor) { menor = d; melhor = o; }
  }
  return melhor;
}

// "Ainda está aqui": renova o prazo e zera votos de resolução; só conta
// mais uma pessoa se esta sessão ainda não tinha confirmado.
function confirmar(o, sessao, agora) {
  const nova = !o.confirmadoPor.includes(sessao);
  if (nova) {
    o.confirmadoPor.push(sessao);
    o.confirmacoes += 1;
  }
  o.confirmadaEm = new Date(agora).toISOString();
  o.resolucoes = 0;
  o.resolvidoPor = [];
  delete o.resolvidaEm;
  return o;
}

// "Já foi resolvido": voto repetido da mesma sessão não conta. Resolve com
// min(2, confirmações) votos.
function votarResolvida(o, sessao, agora) {
  if (o.resolvidoPor.includes(sessao)) return o;
  o.resolvidoPor.push(sessao);
  o.resolucoes += 1;
  if (o.resolucoes >= Math.min(RESOLUCOES_NECESSARIAS, o.confirmacoes)) {
    o.resolvidaEm = new Date(agora).toISOString();
  }
  return o;
}

// Resolvidos/expirados há mais de 24 h saem da lista (e do arquivo).
function vencida(o, agora) {
  if (o.resolvidaEm) return agora - Date.parse(o.resolvidaEm) > RETENCAO_MS;
  return agora - expiraEm(o) > RETENCAO_MS;
}

// O app recebe só contagens, nunca os conjuntos de sessões.
function publica(o) {
  const { confirmadoPor, resolvidoPor, ...resto } = o; // eslint-disable-line no-unused-vars
  return resto;
}

// O servidor guarda só um resumo (hash) do id anônimo da sessão.
const resumo = (sessao) =>
  crypto.createHash('sha256').update(sessao).digest('hex').slice(0, 32);

// ---- Validação ----

function validarNova(c) {
  if (!c || typeof c !== 'object' || Array.isArray(c)) return 'Corpo inválido.';
  if (typeof c.shoppingId !== 'string' || !ID_SIMPLES.test(c.shoppingId)) {
    return 'Shopping inválido.';
  }
  if (!Object.prototype.hasOwnProperty.call(VALIDADE_H, c.tipo)) {
    return 'Tipo de alerta inválido.';
  }
  if (typeof c.piso !== 'string' || !c.piso.trim() || c.piso.length > 40) {
    return 'Piso inválido.';
  }
  for (const k of ['x', 'y']) {
    if (typeof c[k] !== 'number' || !Number.isFinite(c[k]) || Math.abs(c[k]) > 100000) {
      return 'Posição inválida.';
    }
  }
  if (c.pontoId != null && (typeof c.pontoId !== 'string' || !ID_SIMPLES.test(c.pontoId))) {
    return 'Ponto de referência inválido.';
  }
  if (c.descricao != null) {
    if (typeof c.descricao !== 'string') return 'Descrição inválida.';
    if (c.descricao.trim().length > MAX_DESCRICAO) {
      return `A descrição pode ter até ${MAX_DESCRICAO} caracteres.`;
    }
  }
  return null;
}

// ---- Persistência ----

function carregar(arquivo) {
  try {
    const j = JSON.parse(fs.readFileSync(arquivo, 'utf8'));
    return Array.isArray(j.ocorrencias) ? j.ocorrencias : [];
  } catch (e) {
    if (e.code !== 'ENOENT') console.warn('[alertas] arquivo de dados ilegível; começando vazio.');
    return [];
  }
}

function salvar(arquivo, lista) {
  fs.mkdirSync(path.dirname(arquivo), { recursive: true });
  const tmp = `${arquivo}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify({ versao: 1, ocorrencias: lista }, null, 1));
  fs.renameSync(tmp, arquivo); // troca atômica
}

// ---- HTTP ----

function criarApiOcorrencias(opcoes = {}) {
  const arquivo = opcoes.arquivo || path.join(__dirname, 'dados', 'ocorrencias.json');
  const relogio = opcoes.relogio || Date.now;
  const porId = new Map(carregar(arquivo).map((o) => [o.id, o]));
  const janelas = new Map(); // chave -> [instantes] (só em memória)

  function limpar(agora) {
    let mudou = false;
    for (const [id, o] of porId) {
      if (vencida(o, agora)) { porId.delete(id); mudou = true; }
    }
    return mudou;
  }

  const persistir = () => salvar(arquivo, [...porId.values()]);

  function excedeu(chave, limite, agora) {
    const l = (janelas.get(chave) || []).filter((t) => agora - t < 60 * 1000);
    if (l.length >= limite) { janelas.set(chave, l); return true; }
    l.push(agora);
    janelas.set(chave, l);
    if (janelas.size > 5000) { // evita crescer sem limite
      for (const [k, v] of janelas) if (!v.some((t) => agora - t < 60 * 1000)) janelas.delete(k);
    }
    return false;
  }

  function responder(req, res, status, corpo) {
    const h = { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' };
    const origem = req.headers.origin;
    if (origem && ORIGEM_LOCAL.test(origem)) {
      h['Access-Control-Allow-Origin'] = origem;
      h['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
      h['Access-Control-Allow-Headers'] = 'Content-Type, X-Sessao';
      h['Access-Control-Max-Age'] = '600';
      h.Vary = 'Origin';
    }
    res.writeHead(status, h);
    res.end(corpo === undefined ? '' : JSON.stringify(corpo));
  }

  const erro = (req, res, status, msg) => responder(req, res, status, { erro: msg });

  function lerCorpo(req, res, cb) {
    const tipo = String(req.headers['content-type'] || '');
    if (!tipo.startsWith('application/json')) {
      return erro(req, res, 415, 'Envie os dados em JSON.');
    }
    let tamanho = 0;
    const partes = [];
    let abortado = false;
    req.on('data', (p) => {
      if (abortado) return;
      tamanho += p.length;
      if (tamanho > MAX_CORPO) {
        abortado = true;
        erro(req, res, 413, 'Dados grandes demais.');
        req.resume();
        return;
      }
      partes.push(p);
    });
    req.on('end', () => {
      if (abortado) return;
      let j;
      try { j = JSON.parse(Buffer.concat(partes).toString('utf8')); } catch (_) {
        return erro(req, res, 400, 'JSON inválido.');
      }
      cb(j);
    });
    req.on('error', () => { abortado = true; });
  }

  // Erros inesperados viram 500, sem dados do pedido no log (podem conter
  // texto livre).
  function seguro(req, res, fn) {
    try { fn(); } catch (_) {
      console.error('[alertas] erro interno ao atender pedido.');
      if (!res.headersSent) erro(req, res, 500, 'Erro interno do serviço de alertas.');
    }
  }

  function registrar(req, res, sessao) {
    const agora = relogio();
    const ip = req.socket.remoteAddress || '?';
    lerCorpo(req, res, (c) => seguro(req, res, () => {
      const invalido = validarNova(c);
      if (invalido) return erro(req, res, 400, invalido);
      if (excedeu(`s:${sessao}`, LIMITE_SESSAO_MIN, agora) ||
          excedeu(`i:${ip}`, LIMITE_IP_MIN, agora)) {
        return erro(req, res, 429, 'Muitos relatos em pouco tempo. Aguarde um minuto.');
      }
      limpar(agora);
      const n = {
        shoppingId: c.shoppingId,
        tipo: c.tipo,
        piso: c.piso.trim(),
        x: c.x,
        y: c.y,
      };
      const dup = duplicadaDe(porId.values(), n, agora);
      if (dup) {
        confirmar(dup, sessao, agora);
        persistir();
        return responder(req, res, 200, { ocorrencia: publica(dup), duplicada: true });
      }
      const quando = new Date(agora).toISOString();
      const o = {
        id: crypto.randomUUID(),
        ...n,
        ...(c.pontoId ? { pontoId: c.pontoId } : {}),
        ...(c.descricao && c.descricao.trim() ? { descricao: c.descricao.trim() } : {}),
        criadaEm: quando,
        confirmadaEm: quando,
        confirmacoes: 1,
        resolucoes: 0,
        confirmadoPor: [sessao],
        resolvidoPor: [],
      };
      porId.set(o.id, o);
      persistir();
      responder(req, res, 201, { ocorrencia: publica(o), duplicada: false });
    }));
  }

  function acao(req, res, sessao, id, qual) {
    const agora = relogio();
    if (limpar(agora)) persistir();
    const o = porId.get(id);
    if (!o) return erro(req, res, 404, 'Este alerta não existe mais.');
    if (qual === 'confirmar') confirmar(o, sessao, agora);
    else votarResolvida(o, sessao, agora);
    persistir();
    responder(req, res, 200, { ocorrencia: publica(o) });
    req.resume(); // descarta corpo, se houver
  }

  return function handler(req, res) {
    let url;
    try { url = new URL(req.url, 'http://local'); } catch (_) { return false; }
    const p = url.pathname.replace(/\/+$/, '');
    if (p !== PREFIXO && !p.startsWith(PREFIXO + '/')) return false;
    seguro(req, res, () => {
      if (req.method === 'OPTIONS') { responder(req, res, 204); return true; }
      const resto = p.slice(PREFIXO.length).split('/').filter(Boolean);

      if (req.method === 'GET') {
        if (resto.length === 1 && resto[0] === 'saude') {
          responder(req, res, 200, { ok: true, servico: 'alertas-demonstracao' });
        } else if (resto.length === 0) {
          const shopping = url.searchParams.get('shopping');
          if (!shopping || !ID_SIMPLES.test(shopping)) {
            erro(req, res, 400, 'Informe o shopping.');
          } else {
            const agora = relogio();
            if (limpar(agora)) persistir();
            const lista = [...porId.values()]
              .filter((o) => o.shoppingId === shopping)
              .sort((a, b) => a.criadaEm.localeCompare(b.criadaEm) || a.id.localeCompare(b.id))
              .map(publica);
            responder(req, res, 200, { ocorrencias: lista, agora: new Date(agora).toISOString() });
          }
        } else {
          erro(req, res, 404, 'Endereço não encontrado.');
        }
        return true;
      }

      if (req.method !== 'POST') { erro(req, res, 405, 'Método não permitido.'); return true; }
      const sessaoBruta = String(req.headers['x-sessao'] || '');
      if (!SESSAO.test(sessaoBruta)) { erro(req, res, 400, 'Sessão ausente ou inválida.'); return true; }
      const sessao = resumo(sessaoBruta);

      if (resto.length === 0) registrar(req, res, sessao);
      else if (resto.length === 2 && ID_SIMPLES.test(resto[0]) &&
               (resto[1] === 'confirmar' || resto[1] === 'resolver')) {
        acao(req, res, sessao, resto[0], resto[1]);
      } else erro(req, res, 404, 'Endereço não encontrado.');
    });
    return true;
  };
}

module.exports = {
  criarApiOcorrencias,
  // Exportados para o teste de fumaça.
  regras: { VALIDADE_H, RAIO_DUPLICADO, RETENCAO_MS, situacao, duplicadaDe, validarNova },
};
