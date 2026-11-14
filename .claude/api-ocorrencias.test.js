// Teste de fumaça da API de demonstração dos alertas.
// Uso: node .claude/api-ocorrencias.test.js  (sai com código 1 se falhar)
'use strict';

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const assert = require('assert/strict');
const { criarApiOcorrencias } = require('./api-ocorrencias');

const HORA = 3600 * 1000;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'acessa-alertas-'));
const arquivo = path.join(dir, 'ocorrencias.json');
let agora = Date.parse('2026-11-14T15:00:00Z');
const relogio = () => agora;

function subir() {
  const api = criarApiOcorrencias({ arquivo, relogio });
  const srv = http.createServer((req, res) => {
    if (!api(req, res)) { res.writeHead(404); res.end(); }
  });
  return new Promise((ok) => srv.listen(0, '127.0.0.1', () => ok(srv)));
}

async function chamar(srv, metodo, caminho, { sessao, corpo, headers = {} } = {}) {
  const { port } = srv.address();
  const h = { ...headers };
  if (sessao) h['X-Sessao'] = sessao;
  let dados;
  if (corpo !== undefined) {
    dados = typeof corpo === 'string' ? corpo : JSON.stringify(corpo);
    h['Content-Type'] = h['Content-Type'] || 'application/json';
  }
  const r = await fetch(`http://127.0.0.1:${port}${caminho}`, { method: metodo, headers: h, body: dados });
  const texto = await r.text();
  return { status: r.status, headers: r.headers, json: texto ? JSON.parse(texto) : null };
}

const A = 'sessaoAAAAAAAAAAAAAA';
const B = 'sessaoBBBBBBBBBBBBBB';
const C = 'sessaoCCCCCCCCCCCCCC';
const relato = { shoppingId: 'demo', tipo: 'pisoMolhado', piso: 'Térreo', x: 175, y: 120, pontoId: 'COR_C' };

async function main() {
  let srv = await subir();
  const testes = [];
  const t = (nome, fn) => testes.push([nome, fn]);
  let id;

  t('saúde responde', async () => {
    const r = await chamar(srv, 'GET', '/api/ocorrencias/saude');
    assert.equal(r.status, 200);
    assert.equal(r.json.ok, true);
  });

  t('A registra e B lista e vê (sem ids de sessão)', async () => {
    const r = await chamar(srv, 'POST', '/api/ocorrencias', { sessao: A, corpo: relato });
    assert.equal(r.status, 201);
    assert.equal(r.json.duplicada, false);
    id = r.json.ocorrencia.id;
    const l = await chamar(srv, 'GET', '/api/ocorrencias?shopping=demo', { sessao: B });
    assert.equal(l.status, 200);
    assert.equal(l.json.ocorrencias.length, 1);
    const o = l.json.ocorrencias[0];
    assert.equal(o.id, id);
    assert.equal(o.confirmacoes, 1);
    assert.equal(o.confirmadoPor, undefined);
    assert.equal(o.resolvidoPor, undefined);
    assert.ok(!JSON.stringify(l.json).includes(A));
    const outro = await chamar(srv, 'GET', '/api/ocorrencias?shopping=outro');
    assert.equal(outro.json.ocorrencias.length, 0);
  });

  t('B confirma (+1); confirmar de novo não conta, mas renova o prazo', async () => {
    agora += 30 * 60 * 1000;
    let r = await chamar(srv, 'POST', `/api/ocorrencias/${id}/confirmar`, { sessao: B });
    assert.equal(r.status, 200);
    assert.equal(r.json.ocorrencia.confirmacoes, 2);
    agora += 60 * 1000;
    r = await chamar(srv, 'POST', `/api/ocorrencias/${id}/confirmar`, { sessao: B });
    assert.equal(r.json.ocorrencia.confirmacoes, 2);
    assert.equal(r.json.ocorrencia.confirmadaEm, new Date(agora).toISOString());
  });

  t('relato igual a até 30 unidades vira confirmação (duplicada)', async () => {
    const r = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: C, corpo: { ...relato, x: relato.x + 20 },
    });
    assert.equal(r.status, 200);
    assert.equal(r.json.duplicada, true);
    assert.equal(r.json.ocorrencia.id, id);
    assert.equal(r.json.ocorrencia.confirmacoes, 3);
    const longe = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: C, corpo: { ...relato, x: relato.x + 80 },
    });
    assert.equal(longe.status, 201);
    const outroTipo = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: C, corpo: { ...relato, tipo: 'obstaculo' },
    });
    assert.equal(outroTipo.status, 201);
  });

  t('resolução: voto repetido não conta; precisa de 2 votos', async () => {
    let r = await chamar(srv, 'POST', `/api/ocorrencias/${id}/resolver`, { sessao: A });
    assert.equal(r.json.ocorrencia.resolucoes, 1);
    assert.equal(r.json.ocorrencia.resolvidaEm, undefined);
    r = await chamar(srv, 'POST', `/api/ocorrencias/${id}/resolver`, { sessao: A });
    assert.equal(r.json.ocorrencia.resolucoes, 1);
    r = await chamar(srv, 'POST', `/api/ocorrencias/${id}/resolver`, { sessao: B });
    assert.equal(r.json.ocorrencia.resolucoes, 2);
    assert.ok(r.json.ocorrencia.resolvidaEm);
  });

  t('com uma confirmação só, um voto resolve', async () => {
    const n = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: B, corpo: { ...relato, tipo: 'localCheio', x: 300, y: 115 },
    });
    const r = await chamar(srv, 'POST', `/api/ocorrencias/${n.json.ocorrencia.id}/resolver`, { sessao: B });
    assert.ok(r.json.ocorrencia.resolvidaEm);
  });

  t('validação devolve 400/404/413/415 com mensagem', async () => {
    const casos = [
      { ...relato, tipo: 'incendio' },
      { ...relato, piso: '' },
      { ...relato, x: 'dez' },
      { shoppingId: 'demo', tipo: 'pisoMolhado', piso: 'Térreo', y: 1 },
      { ...relato, descricao: 'a'.repeat(141) },
    ];
    for (const corpo of casos) {
      const r = await chamar(srv, 'POST', '/api/ocorrencias', { sessao: C, corpo });
      assert.equal(r.status, 400, JSON.stringify(corpo).slice(0, 60));
      assert.equal(typeof r.json.erro, 'string');
    }
    assert.equal((await chamar(srv, 'POST', '/api/ocorrencias', { corpo: relato })).status, 400);
    assert.equal((await chamar(srv, 'POST', '/api/ocorrencias', { sessao: C, corpo: '{x' })).status, 400);
    assert.equal((await chamar(srv, 'GET', '/api/ocorrencias')).status, 400);
    assert.equal((await chamar(srv, 'POST', '/api/ocorrencias/nao-existe/confirmar', { sessao: C })).status, 404);
    assert.equal((await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: C, corpo: { ...relato, descricao: 'a'.repeat(5000) },
    })).status, 413);
    assert.equal((await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: C, corpo: relato, headers: { 'Content-Type': 'text/plain' },
    })).status, 415);
  });

  t('limite de relatos por sessão por minuto (429)', async () => {
    const S = 'sessaoLimiteLimite01';
    const status = [];
    for (let i = 0; i < 6; i++) {
      const r = await chamar(srv, 'POST', '/api/ocorrencias', {
        sessao: S, corpo: { ...relato, tipo: 'outro', x: 10 + i * 100, y: 400 },
      });
      status.push(r.status);
    }
    assert.deepEqual(status, [201, 201, 201, 201, 201, 429]);
  });

  t('CORS só para localhost', async () => {
    const ok = await chamar(srv, 'OPTIONS', '/api/ocorrencias', { headers: { Origin: 'http://localhost:8093' } });
    assert.equal(ok.status, 204);
    assert.equal(ok.headers.get('access-control-allow-origin'), 'http://localhost:8093');
    const fora = await chamar(srv, 'GET', '/api/ocorrencias/saude', { headers: { Origin: 'https://exemplo.com' } });
    assert.equal(fora.headers.get('access-control-allow-origin'), null);
  });

  t('persiste em arquivo e sobrevive a reinício (votos continuam únicos)', async () => {
    const antes = (await chamar(srv, 'GET', '/api/ocorrencias?shopping=demo')).json.ocorrencias;
    await new Promise((ok) => srv.close(ok));
    srv = await subir();
    const depois = (await chamar(srv, 'GET', '/api/ocorrencias?shopping=demo')).json.ocorrencias;
    assert.deepEqual(depois, antes);
    const salvo = fs.readFileSync(arquivo, 'utf8');
    assert.ok(!salvo.includes(A), 'id de sessão não deve ir cru para o arquivo');
    const r = await chamar(srv, 'POST', `/api/ocorrencias/${id}/confirmar`, { sessao: B });
    assert.equal(r.json.ocorrencia.confirmacoes, 3); // B já tinha confirmado
  });

  t('expira pela validade do tipo e some da lista depois de 24 h', async () => {
    const n = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: A, corpo: { ...relato, tipo: 'elevadorParado', x: 215, y: 150 },
    });
    const elevId = n.json.ocorrencia.id;
    agora += 11 * HORA; // 12 h de validade: ainda ativo, então duplica
    let d = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: B, corpo: { ...relato, tipo: 'elevadorParado', x: 215, y: 150 },
    });
    assert.equal(d.json.duplicada, true);
    agora += 12 * HORA + 1; // expirou (renovado há 12 h)
    d = await chamar(srv, 'POST', '/api/ocorrencias', {
      sessao: C, corpo: { ...relato, tipo: 'elevadorParado', x: 215, y: 150 },
    });
    assert.equal(d.json.duplicada, false);
    let l = (await chamar(srv, 'GET', '/api/ocorrencias?shopping=demo')).json.ocorrencias;
    assert.ok(l.some((o) => o.id === elevId), 'expirado recente continua na lista');
    agora += 25 * HORA;
    l = (await chamar(srv, 'GET', '/api/ocorrencias?shopping=demo')).json.ocorrencias;
    assert.ok(!l.some((o) => o.id === elevId));
    assert.ok(!l.some((o) => o.id === id), 'resolvido há mais de 24 h sai');
  });

  let falhas = 0;
  for (const [nome, fn] of testes) {
    try { await fn(); console.log(`ok   ${nome}`); } catch (e) {
      falhas++;
      console.log(`FALHOU ${nome}\n  ${e.message}`);
    }
  }
  await new Promise((ok) => srv.close(ok));
  fs.rmSync(dir, { recursive: true, force: true });
  console.log(falhas ? `${falhas} falha(s)` : `${testes.length} testes ok`);
  process.exit(falhas ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
