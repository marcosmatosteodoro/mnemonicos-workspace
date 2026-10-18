# MEDICAO-065: sharp, tamanho e tempo do PDF final

**Slug**: producao-material · **TASK**: TASK-065-005 · **PLAN**: PLAN-065 (DEC-065-004, DEC-065-010) · **Medido em**: 2026-10-18

## Ambiente

- Node: v26.8.2 (engines do projeto: >=22; a função Vercel roda outro Node, e isso muda ms e RSS apenas em ordem de grandeza)
- sharp 0.35.5 (exato) · libvips 8.18.7 · pdf-lib ^1.17.1 · fonte Noto Sans Regular+Bold via `embedFinalFonts` (`final-pdf-font.ts`, commit 4c134b4 da branch)
- CPU: 13th Gen Intel(R) Core(TM) i7-1355U (12 threads) · RAM 31 GB · SO: Linux 7.0.0-38-generic · `sharp.concurrency()` padrão desta máquina = 1
- Não é a função Vercel (1024 MB, 15 s): `ms` e `rss` valem como ordem de grandeza. TRISK-065-002 (binário nativo na Vercel) NÃO foi medido aqui.
- Semente do gerador pseudoaleatório (mulberry32): `20261018`; WEBP de origem com `quality: 80`; JPEG de origem da tira com `quality: 95`.
- O compositor real (`buildFinalStripPdf`) ainda não desenha a imagem em destaque (TASK-065-006 só entregou o modo texto): o PDF foi montado pela sonda com `embedFinalFonts` + `drawImage` de pdf-lib (caixa 480x400 pt), isto é, mede imagem, fonte e `save()`, não o layout final.

## Sonda

Arquivo único, roda de qualquer pasta fora do repositório: `BACKEND=<.../mnemonicos-backend> <BACKEND>/node_modules/.bin/tsx <caminho>/probe.cjs`. Resolve `sharp`, `pdf-lib` e o módulo de fonte a partir de `mnemonicos-backend` (`createRequire`). Tempo de execução ~2 min.

```js
// Sonda MEDICAO-065. Uso: BACKEND=<dir mnemonicos-backend> <BACKEND>/node_modules/.bin/tsx probe.cjs
const { createRequire } = require('node:module');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const BACKEND = process.env.BACKEND;
const req = createRequire(path.join(BACKEND, 'package.json'));
const sharp = req('sharp');
const { PDFDocument, PageSizes } = req('pdf-lib');
const { embedFinalFonts } = req(path.join(BACKEND, 'src/modules/publication/final-pdf-font.ts'));

const SEED = 20261018;
const WEBP_QUALITY = 80;
const JPEG_SRC_QUALITY = 95;
const JPEG_SRC_GRAIN = 30;
const RECOMMENDED_LONG_SIDE_PX = 2000;
const REDUCE = { fit: 'inside', withoutEnlargement: true, kernel: 'lanczos3' };
const REDUCED_JPEG = { quality: 85, mozjpeg: false, chromaSubsampling: '4:2:0' };
const ADOPTED = { cache: { memory: 50, files: 0, items: 100 }, concurrency: 1 };
const mode = process.argv[2] || 'main';
const PARAMS = process.env.SHARP_PARAMS || 'adotado';
if (PARAMS === 'adotado') { sharp.cache(ADOPTED.cache); sharp.concurrency(ADOPTED.concurrency); }

function prng(seed) { let a = seed >>> 0; return () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const clamp = (v) => (v < 0 ? 0 : v > 255 ? 255 : v | 0);

async function synth(kind, w, h, seed = SEED, grain = 16) {
  const rnd = prng(seed + w * 31 + h);
  const buf = Buffer.alloc(w * h * 3);
  if (kind === 'gradiente') {
    for (let y = 0, i = 0; y < h; y++) for (let x = 0; x < w; x++, i += 3) { buf[i] = (x * 255 / w) | 0; buf[i + 1] = (y * 255 / h) | 0; buf[i + 2] = ((x + y) * 255 / (w + h)) | 0; }
  } else if (kind === 'ruido') {
    for (let i = 0; i < buf.length; i++) buf[i] = (rnd() * 256) | 0;
  } else if (kind === 'mista') {
    for (let y = 0, i = 0; y < h; y++) for (let x = 0; x < w; x++, i += 3) {
      const block = ((x / 64) | 0) % 4 === 0 && ((y / 64) | 0) % 3 === 0;
      if (block) { buf[i] = rnd() * 256; buf[i + 1] = rnd() * 256; buf[i + 2] = rnd() * 256; }
      else { buf[i] = (x * 255 / w) | 0; buf[i + 1] = (y * 255 / h) | 0; buf[i + 2] = 128; }
    }
  } else if (kind === 'foto') {
    // textura natural: ruído de valor multi-oitava (suavizado por bicúbico) + grão fino
    const acc = new Float32Array(w * h * 3);
    for (const [cells, amp] of [[6, 90], [24, 50], [96, 28], [384, 14]]) {
      const cw = Math.max(2, Math.round(cells)), ch = Math.max(2, Math.round(cells * h / w));
      const small = Buffer.alloc(cw * ch * 3); for (let i = 0; i < small.length; i++) small[i] = (rnd() * 256) | 0;
      const up = await sharp(small, { raw: { width: cw, height: ch, channels: 3 } }).resize(w, h, { kernel: 'cubic' }).raw().toBuffer();
      for (let i = 0; i < acc.length; i++) acc[i] += (up[i] - 128) * amp / 128;
    }
    for (let i = 0; i < buf.length; i++) buf[i] = clamp(128 + acc[i] + (rnd() - 0.5) * grain);
  }
  return buf;
}
const raw = (buf, w, h) => sharp(buf, { raw: { width: w, height: h, channels: 3 } });
const median = (a) => { const s = [...a].sort((x, y) => x - y); return s[s.length >> 1]; };
const mb = (n) => (n / 1048576).toFixed(1);
const out = [];
const row = (id, val, note = '') => { const l = `| ${id} | ${val} | ${note} |`; out.push(l); console.log(l); };

async function webpOf(kind, w, h, seed) { return raw(await synth(kind, w, h, seed), w, h).webp({ quality: WEBP_QUALITY }).toBuffer(); }
const toPng = (webp) => sharp(webp, { limitInputPixels: 20_000_000, animated: false }).png().toBuffer();

async function pdfFromPngs(pngs, fontsText = true) {
  const doc = await PDFDocument.create();
  const fonts = await embedFinalFonts(doc);
  for (let i = 0; i < pngs.length; i++) {
    const page = doc.addPage(PageSizes.A4);
    page.drawText(`Quadro ${i + 1} — Ação, é, ç, ã`, { x: 57, y: 770, size: 16, font: fonts.bold });
    const img = await doc.embedPng(pngs[i]);
    const s = Math.min(480 / img.width, 400 / img.height);
    page.drawImage(img, { x: 57, y: 340, width: img.width * s, height: img.height * s });
    page.drawText('Texto de apoio do Quadro com acentuação para exercitar a fonte embutida.', { x: 57, y: 300, size: 12, font: fonts.regular });
  }
  return Buffer.from(await doc.save());
}

async function childRss() {
  const [seqpar] = [process.argv[3]];
  const webp = require('node:fs').readFileSync(process.argv[4]);
  await toPng(webp); // aquece
  const base = process.memoryUsage.rss() / 1024;
  let peakSampled = 0; const iv = setInterval(() => { peakSampled = Math.max(peakSampled, process.memoryUsage.rss()); }, 2);
  const t0 = performance.now();
  if (seqpar === 'seq') { for (let i = 0; i < 12; i++) { const p = await toPng(webp); void p.length; } }
  else { const r = await Promise.all(Array.from({ length: 12 }, () => toPng(webp))); void r.length; }
  const ms = performance.now() - t0; clearInterval(iv);
  console.log(JSON.stringify({ base, peak: peakSampled / 1024, sampled: peakSampled / 1024, ms, conc: sharp.concurrency(), cache: sharp.cache() }));
}

async function main() {
  const os = require('node:os');
  console.log(`# node ${process.version} · sharp ${JSON.parse(require('node:fs').readFileSync(path.join(BACKEND, 'node_modules/sharp/package.json'), 'utf8')).version} · libvips ${sharp.versions.vips} · params=${PARAMS} · cpus=${os.cpus().length}`);
  // razao-png-webp + ms-conversao
  const kinds = ['gradiente', 'ruido', 'mista', 'foto'];
  const resos = [[1000, 667], [2000, 1333], [3000, 2000], [5000, 4000]];
  const ratios = []; const msByReso = {};
  for (const [w, h] of resos) {
    for (const k of kinds) {
      const webp = await webpOf(k, w, h);
      const png = await toPng(webp);
      const r = png.length / webp.length; ratios.push([k, w, h, r]);
      row(`detalhe-razao-png-webp-${k}-${w}x${h}`, r.toFixed(2), `webp ${webp.length} B; png ${png.length} B`);
      if (k === 'foto' || k === 'mista') {
        const times = [];
        for (let i = 0; i < 10; i++) { const t = performance.now(); await toPng(webp); times.push(performance.now() - t); }
        const m = median(times);
        (msByReso[`${w}x${h}`] ||= {})[k] = m;
        row(`detalhe-ms-conversao-${k}-${w}x${h}`, m.toFixed(0), 'mediana de 10');
      }
    }
  }
  const mx = ratios.reduce((a, b) => (b[3] > a[3] ? b : a));
  const fotoR = ratios.filter((r) => r[0] === 'foto').map((r) => r[3].toFixed(1)).join('/');
  const gradR = ratios.filter((r) => r[0] === 'gradiente').map((r) => r[3].toFixed(1)).join('/');
  const ruR = ratios.filter((r) => r[0] === 'ruido').map((r) => r[3].toFixed(1)).join('/');
  row('razao-png-webp', `máx ${mx[3].toFixed(1)}x (${mx[0]} ${mx[1]}x${mx[2]})`, `foto ${fotoR}; ruído ${ruR}; gradiente ${gradR} (por resolução 1000/2000/3000/5000)`);
  row('ms-conversao', Object.entries(msByReso).map(([r, o]) => `${r}: foto ${o.foto.toFixed(0)} ms`).join('; '), `mediana de 10 conversões; mista: ${Object.entries(msByReso).map(([r, o]) => `${r} ${o.mista.toFixed(0)}`).join('/')} ms`);

  // pico-rss: processos filhos
  const env = (p) => ({ ...process.env, SHARP_PARAMS: p });
  const res = {};
  const wf = path.join(require('node:os').tmpdir(), `m065-${process.pid}.webp`); require('node:fs').writeFileSync(wf, await webpOf('foto', 2000, 1333, SEED + 7));
  for (const p of ['padrao', 'adotado']) for (const m of ['seq', 'par']) {
    const r = spawnSync(process.execPath, [...process.execArgv, __filename, 'rss', m, wf], { env: env(p), encoding: 'utf8' });
    const line = r.stdout.trim().split('\n').pop();
    try { res[`${p}-${m}`] = JSON.parse(line); } catch { console.log('rss child falhou', r.stderr); }
  }
  require('node:fs').unlinkSync(wf);
  const f = (k) => `${(res[k].peak / 1024).toFixed(0)} MB (base ${(res[k].base / 1024).toFixed(0)} MB; ${res[k].ms.toFixed(0)} ms; conc ${res[k].conc})`;
  for (const k of Object.keys(res)) row(`detalhe-pico-rss-${k}`, f(k), `cache ${JSON.stringify(res[k].cache)}`);
  row('pico-rss', `sequencial ${(res['adotado-seq'].peak / 1024).toFixed(0)} MB contra paralelo ${(res['adotado-par'].peak / 1024).toFixed(0)} MB (params adotados)`, `padrão: seq ${(res['padrao-seq'].peak / 1024).toFixed(0)} MB, par ${(res['padrao-par'].peak / 1024).toFixed(0)} MB; 12 Quadros 2000x1333 foto, RSS máx do processo`);

  // pdf-12-paginas
  {
    const webp = await webpOf('foto', 2000, 1333, SEED + 7);
    const t = performance.now();
    const pngs = []; for (let i = 0; i < 12; i++) pngs.push(await toPng(webp));
    const tConv = performance.now() - t;
    const t1 = performance.now(); const pdf = await pdfFromPngs(pngs); const tPdf = performance.now() - t1;
    row('pdf-12-paginas', `${pdf.length} B em ${tPdf.toFixed(0)} ms`, `12 PNG de foto 2000x1333 (${pngs[0].length} B cada) + Noto Sans subset; conversão dos 12: ${tConv.toFixed(0)} ms`);
    const webpM = await webpOf('mista', 2000, 1333, SEED + 8);
    const pm = []; for (let i = 0; i < 12; i++) pm.push(await toPng(webpM));
    const t2 = performance.now(); const pdfM = await pdfFromPngs(pm); const tM = performance.now() - t2;
    row('detalhe-pdf-12-paginas-mista', `${pdfM.length} B em ${tM.toFixed(0)} ms`, `PNG de mista ${pm[0].length} B cada`);
    const t3 = performance.now(); const pdfT = await pdfFromPngs([]); void pdfT; 
    const base = await (async () => { const d = await PDFDocument.create(); const fo = await embedFinalFonts(d); const p = d.addPage(PageSizes.A4); p.drawText('Ação é ç ã', { x: 50, y: 50, font: fo.regular }); p.drawText('Ação', { x: 50, y: 80, font: fo.bold }); return (await d.save()).length; })();
    row('detalhe-pdf-fonte-embutida', `${base} B`, `1 página, só as duas fontes (subset), custo da fonte; ${(performance.now() - t3).toFixed(0)} ms`);
  }


  // WEBP -> PNG contra WEBP -> JPEG, foto suave (grão ±1) e foto com grão (±8), 2000x1333
  for (const [nome, grain] of [['suave', 2], ['grao', 16]]) {
    const wp = await raw(await synth('foto', 2000, 1333, SEED + 11, grain), 2000, 1333).webp({ quality: WEBP_QUALITY }).toBuffer();
    const png = await toPng(wp); const jpg = await sharp(wp).jpeg(REDUCED_JPEG).toBuffer();
    row(`detalhe-webp-saida-foto-${nome}-2000x1333`, `png ${png.length} B; jpeg q${REDUCED_JPEG.quality} ${jpg.length} B`, `webp ${wp.length} B`);
  }
  // m-maximo
  {
    const webp = await webpOf('foto', 3000, 2000, SEED + 9);
    let best = 0; const tab = [];
    for (const M of [1, 2, 3, 4, 6, 8, 10, 12, 16]) {
      const t = performance.now();
      const pngs = []; for (let i = 0; i < M; i++) pngs.push(await toPng(webp));
      const pdf = await pdfFromPngs(pngs);
      const ms = performance.now() - t; tab.push(`${M}:${ms.toFixed(0)}ms/${mb(pdf.length)}MB`);
      row(`detalhe-m-maximo-M${M}`, ms.toFixed(0), `PDF ${pdf.length} B`);
      if (ms <= 6000) best = M; else break;
    }
    row('m-maximo', `${best} Quadros 3000x2000 em ≤ 6000 ms (teto 12 s com margem 2x)`, `conversão+embed+save, foto WEBP q${WEBP_QUALITY}; ${tab.join(' ')}`);
  }

  // pdf-final-reduzido
  {
    const M = 8; const w = 4000, h = 3000;
    const jpegs = []; for (let i = 0; i < M; i++) jpegs.push(await raw(await synth('foto', w, h, SEED + 100 + i, JPEG_SRC_GRAIN), w, h).jpeg({ quality: JPEG_SRC_QUALITY }).toBuffer());
    const total = jpegs.reduce((a, b) => a + b.length, 0);
    row('detalhe-pdf-final-fonte', `${M} JPEG ${w}x${h}`, `q${JPEG_SRC_QUALITY}, grão ±${JPEG_SRC_GRAIN / 2}; ${jpegs.map((j) => mb(j.length)).join('/')} MB; soma ${total} B`);
    const t = performance.now();
    const doc = await PDFDocument.create(); const fonts = await embedFinalFonts(doc); let imgBytes = 0;
    for (let i = 0; i < M; i++) {
      const red = await sharp(jpegs[i], { limitInputPixels: 20_000_000 }).rotate().resize({ width: RECOMMENDED_LONG_SIDE_PX, height: RECOMMENDED_LONG_SIDE_PX, ...REDUCE }).jpeg(REDUCED_JPEG).toBuffer();
      imgBytes += red.length;
      const page = doc.addPage(PageSizes.A4);
      page.drawText(`Quadro ${i + 1} — Ação`, { x: 57, y: 770, size: 16, font: fonts.bold });
      const img = await doc.embedJpg(red); const s = Math.min(480 / img.width, 400 / img.height);
      page.drawImage(img, { x: 57, y: 340, width: img.width * s, height: img.height * s });
    }
    const pdf = Buffer.from(await doc.save()); const ms = performance.now() - t;
    row('pdf-final-reduzido', `${pdf.length} B em ${ms.toFixed(0)} ms`, `M=${M}; fotos JPEG ${w}x${h} (~${mb(total / M)} MB cada) reduzidas a ${RECOMMENDED_LONG_SIDE_PX} px; imagens reduzidas somam ${imgBytes} B; teto 4000000: ${pdf.length <= 4000000 ? 'cabe' : 'NÃO cabe'}`);
    // sem redução, para comparação
    const d2 = await PDFDocument.create(); for (const j of jpegs) { const p = d2.addPage(PageSizes.A4); const im = await d2.embedJpg(j); p.drawImage(im, { x: 57, y: 340, width: 480, height: 360 }); }
    row('detalhe-pdf-final-sem-reducao', `${(await d2.save()).length} B`, 'mesmos 8 JPEG embutidos sem redução (referência do teto)');
    // PNG 4000x3000 foto reduzido (pior caso de PNG)
    const t5 = performance.now(); let pb = 0; const d3 = await PDFDocument.create();
    const src = await raw(await synth('foto', w, h, SEED + 200), w, h).png().toBuffer();
    for (let i = 0; i < M; i++) { const red = await sharp(src).resize({ width: 2000, height: 2000, ...REDUCE }).png({ compressionLevel: 9 }).toBuffer(); pb += red.length; const p = d3.addPage(PageSizes.A4); const im = await d3.embedPng(red); p.drawImage(im, { x: 57, y: 340, width: 480, height: 320 }); }
    row('detalhe-pdf-final-png-reduzido', `${(await d3.save()).length} B em ${(performance.now() - t5).toFixed(0)} ms`, `8 PNG foto ${w}x${h} (${src.length} B cada) reduzidos a 2000 px, compressionLevel 9, ${pb} B de imagem`);
  }
  row('recompressao', `saída JPEG q${REDUCED_JPEG.quality} (mozjpeg ${REDUCED_JPEG.mozjpeg}, ${REDUCED_JPEG.chromaSubsampling}); PNG sem perda (compressionLevel 9)`, `resize ${RECOMMENDED_LONG_SIDE_PX}px fit '${REDUCE.fit}', withoutEnlargement true, kernel ${REDUCE.kernel}; .rotate() aplica EXIF`);
  row('sharp-cache', JSON.stringify(ADOPTED.cache), 'sharp.cache({ memory MB, files, items })');
  row('sharp-concurrency', String(ADOPTED.concurrency), `sharp.concurrency(); padrão da máquina = ${(() => { const s = spawnSync(process.execPath, ['-e', `console.log(require(${JSON.stringify(path.join(BACKEND, 'node_modules/sharp'))}).concurrency())`], { encoding: 'utf8' }); return s.stdout.trim(); })()}`);
}
(mode === 'rss' ? childRss() : main()).catch((e) => { console.error(e); process.exit(1); });
```

## Medidas

Resultado literal da execução da sonda (linhas-resumo com o identificador como primeira célula; `| detalhe-… |` são detalhes). Fonte de verdade das decisões abaixo.

| medida | valor | observação |
| --- | --- | --- |
| detalhe-razao-png-webp-gradiente-1000x667 | 30.71 | webp 5404 B; png 165963 B |
| detalhe-razao-png-webp-ruido-1000x667 | 4.28 | webp 454934 B; png 1945642 B |
| detalhe-razao-png-webp-mista-1000x667 | 7.54 | webp 48282 B; png 364023 B |
| detalhe-ms-conversao-mista-1000x667 | 23 | mediana de 10 |
| detalhe-razao-png-webp-foto-1000x667 | 21.12 | webp 88584 B; png 1871233 B |
| detalhe-ms-conversao-foto-1000x667 | 42 | mediana de 10 |
| detalhe-razao-png-webp-gradiente-2000x1333 | 17.54 | webp 14788 B; png 259432 B |
| detalhe-razao-png-webp-ruido-2000x1333 | 4.30 | webp 1806114 B; png 7771155 B |
| detalhe-razao-png-webp-mista-2000x1333 | 6.36 | webp 165308 B; png 1052169 B |
| detalhe-ms-conversao-mista-2000x1333 | 52 | mediana de 10 |
| detalhe-razao-png-webp-foto-2000x1333 | 28.64 | webp 253892 B; png 7271603 B |
| detalhe-ms-conversao-foto-2000x1333 | 148 | mediana de 10 |
| detalhe-razao-png-webp-gradiente-3000x2000 | 16.90 | webp 27960 B; png 472512 B |
| detalhe-razao-png-webp-ruido-3000x2000 | 4.24 | webp 4119204 B; png 17485597 B |
| detalhe-razao-png-webp-mista-3000x2000 | 6.00 | webp 380262 B; png 2279709 B |
| detalhe-ms-conversao-mista-3000x2000 | 106 | mediana de 10 |
| detalhe-razao-png-webp-foto-3000x2000 | 32.74 | webp 475406 B; png 15562616 B |
| detalhe-ms-conversao-foto-3000x2000 | 314 | mediana de 10 |
| detalhe-razao-png-webp-gradiente-5000x4000 | 18.55 | webp 70456 B; png 1307261 B |
| detalhe-razao-png-webp-ruido-5000x4000 | 4.25 | webp 13721296 B; png 58281132 B |
| detalhe-razao-png-webp-mista-5000x4000 | 5.89 | webp 1184288 B; png 6976058 B |
| detalhe-ms-conversao-mista-5000x4000 | 712 | mediana de 10 |
| detalhe-razao-png-webp-foto-5000x4000 | 38.86 | webp 1138536 B; png 44239031 B |
| detalhe-ms-conversao-foto-5000x4000 | 1742 | mediana de 10 |
| razao-png-webp | máx 38.9x (foto 5000x4000) | foto 21.1/28.6/32.7/38.9; ruído 4.3/4.3/4.2/4.2; gradiente 30.7/17.5/16.9/18.6 (por resolução 1000/2000/3000/5000) |
| ms-conversao | 1000x667: foto 42 ms; 2000x1333: foto 148 ms; 3000x2000: foto 314 ms; 5000x4000: foto 1742 ms | mediana de 10 conversões; mista: 1000x667 23/2000x1333 52/3000x2000 106/5000x4000 712 ms |
| detalhe-pico-rss-padrao-seq | 288 MB (base 123 MB; 3877 ms; conc 1) | cache {"memory":{"current":27,"high":67,"max":50},"files":{"current":0,"max":20},"items":{"current":10,"max":100}} |
| detalhe-pico-rss-padrao-par | 497 MB (base 122 MB; 1152 ms; conc 1) | cache {"memory":{"current":0,"high":159,"max":50},"files":{"current":0,"max":20},"items":{"current":0,"max":100}} |
| detalhe-pico-rss-adotado-seq | 283 MB (base 123 MB; 2739 ms; conc 1) | cache {"memory":{"current":27,"high":67,"max":50},"files":{"current":0,"max":0},"items":{"current":10,"max":100}} |
| detalhe-pico-rss-adotado-par | 497 MB (base 122 MB; 898 ms; conc 1) | cache {"memory":{"current":0,"high":159,"max":50},"files":{"current":0,"max":0},"items":{"current":0,"max":100}} |
| pico-rss | sequencial 283 MB contra paralelo 497 MB (params adotados) | padrão: seq 288 MB, par 497 MB; 12 Quadros 2000x1333 foto, RSS máx do processo |
| pdf-12-paginas | 84741814 B em 7811 ms | 12 PNG de foto 2000x1333 (7203485 B cada) + Noto Sans subset; conversão dos 12: 2282 ms |
| detalhe-pdf-12-paginas-mista | 12378055 B em 2635 ms | PNG de mista 1052713 B cada |
| detalhe-pdf-fonte-embutida | 3527 B | 1 página, só as duas fontes (subset), custo da fonte; 18 ms |
| detalhe-webp-saida-foto-suave-2000x1333 | png 6980714 B; jpeg q85 301628 B | webp 182226 B |
| detalhe-webp-saida-foto-grao-2000x1333 | png 7164819 B; jpeg q85 367781 B | webp 255742 B |
| detalhe-m-maximo-M1 | 1745 | PDF 14871490 B |
| detalhe-m-maximo-M2 | 2754 | PDF 29738332 B |
| detalhe-m-maximo-M3 | 5492 | PDF 44605197 B |
| detalhe-m-maximo-M4 | 8044 | PDF 59472020 B |
| m-maximo | OBSOLETA (medida com saída PNG; superada pela emenda da DEC-065-004: WEBP opaco sai em JPEG, ver `tempo-caminho-jpeg-m8`) — 3 Quadros 3000x2000 em ≤ 6000 ms (teto 12 s com margem 2x) | conversão+embed+save, foto WEBP q80; 1:1745ms/14.2MB 2:2754ms/28.4MB 3:5492ms/42.5MB 4:8044ms/56.7MB |
| detalhe-pdf-final-fonte | 8 JPEG 4000x3000 | q95, grão ±15; 5.5/5.5/5.4/5.5/5.5/5.4/5.5/5.5 MB; soma 45729905 B |
| pdf-final-reduzido | 3738354 B em 962 ms | M=8; fotos JPEG 4000x3000 (~5.5 MB cada) reduzidas a 2000 px; imagens reduzidas somam 3731131 B; teto 4000000: cabe |
| detalhe-pdf-final-sem-reducao | 45733298 B | mesmos 8 JPEG embutidos sem redução (referência do teto) |
| detalhe-pdf-final-png-reduzido | 68945398 B em 9508 ms | 8 PNG foto 4000x3000 (34603578 B cada) reduzidos a 2000 px, compressionLevel 9, 68955976 B de imagem |
| recompressao | saída JPEG q85 (mozjpeg false, 4:2:0); PNG sem perda (compressionLevel 9) | resize 2000px fit 'inside', withoutEnlargement true, kernel lanczos3; .rotate() aplica EXIF |
| sharp-cache | {"memory":50,"files":0,"items":100} | sharp.cache({ memory MB, files, items }) |
| sharp-concurrency | 1 | sharp.concurrency(); padrão da máquina = 1 |

Leitura:

- `razao-png-webp`: o PNG convertido de um WEBP fotográfico/de textura natural é 21x a 39x maior que o WEBP (ruído puro, o pior caso de entropia, é "só" 4,3x porque o WEBP também fica grande). Um Quadro 2000x1333 fotográfico vira ~7,0 a 7,2 MB de PNG (`detalhe-webp-saida-foto-*`), contra ~0,30 a 0,37 MB se a saída fosse JPEG q85.
- `m-maximo`: o PDF com PNG de foto 3000x2000 cresce ~14 MB por Quadro e o tempo não é linear (M=3 ≈ 5,5 s, M=4 ≈ 8 s); dentro de 6 s cabem 3 Quadros. O gargalo é conversão + `save()` de dezenas de MB, não a fonte (`detalhe-pdf-fonte-embutida` = 3,5 KB).
- `pico-rss`: sequencial (liberando cada buffer) fica em ~283 MB de RSS (base ~123 MB); em paralelo sobe a ~497 MB (+374 MB contra +160 MB). Em 1024 MB da Vercel isso aponta para sequencial.
- `pdf-final-reduzido`: tira de referência de 8 Quadros, cada um com JPEG 4000x3000 de ~5,5 MB (soma ~45,7 MB; sem redução o PDF teria 45,7 MB) → PDF de 3.738.354 B em ~1 s depois da redução a 2000 px (JPEG q85); cabe no teto com folga de ~6,5%. A folga é pequena: a tira de referência é sintética e o conteúdo real muda o resultado.
- PNG 4000x3000 fotográfico reduzido a 2000 px continua ~8,6 MB por Quadro (`detalhe-pdf-final-png-reduzido`: 68,9 MB em 8 Quadros): a redução não salva Quadros em PNG de foto.

## Decisão

Decisão: Reabrir DEC-065-004 / DEC-065-010? sim — ver razao-png-webp

- DEC-065-010 (redução ao lado maior `RECOMMENDED_LONG_SIDE_PX` + teto de 4.000.000 B): **confirmada** para a tira de referência em JPEG (`pdf-final-reduzido` = 3.738.354 B ≤ 4.000.000). Não é o gatilho "Reabrir se" do DEC-065-010.
- DEC-065-004 (WEBP → PNG com `sharp`): **a reabrir**. A conversão para PNG de um WEBP fotográfico dá 21x–39x de inchaço (`razao-png-webp`), ~7 MB por Quadro em 2000x1333; um único Quadro já estoura o teto de 4.000.000 B, e o PDF de 12 páginas passa de 80 MB (`pdf-12-paginas`). A saída JPEG (q85) para WEBP sem canal alfa daria ~0,3 MB por Quadro (`detalhe-webp-saida-foto-*`). A escolha do formato de saída (PNG só quando houver alfa; JPEG caso contrário) é decisão do PO/Tech Lead, não desta medição.
Teto-default PUBLICATION_FINAL_PDF_MAX_BYTES: confirmado em 4000000
Parâmetros do sharp: cache { memory: 50, files: 0, items: 100 } e concurrency 1 (sequencial, um Quadro por vez, liberando cada buffer); medidos em `sharp-cache` e `sharp-concurrency`. Redução: `recompressao`.

## Licenças e scripts de instalação

Valores lidos do `package.json` instalado em `node_modules`.

Licença sharp: Apache-2.0 (sharp 0.35.5; `@img/sharp-linux-x64` 0.35.5 também Apache-2.0; `@img/colour` 1.1.0 MIT)
Licença libvips: LGPL-3.0-or-later (`@img/sharp-libvips-linux-x64` 1.3.4, binário pré-compilado em pacote opcional por plataforma; vinculação dinâmica)
Scripts de instalação: nenhum (sharp, `@img/sharp-*` e `@img/colour` não declaram preinstall/install/postinstall; `scripts.build` do sharp não roda na instalação). Binário nativo vem do pacote opcional `@img/sharp-linux-x64`.

`npm audit --omit=dev --audit-level=high` sai 1 antes e depois, com o mesmo conjunto (fast-uri:high, ip-address, multer, mysql2:high, prisma, proxy-addr:critical, qs): nenhum achado novo vem do sharp.

## Estado da árvore

Commit da dependência no backend: `a4792d8` (pai `4c134b4`). `git -C mnemonicos-backend diff --name-only 4c134b4..HEAD`: `package-lock.json`, `package.json`. A sonda rodou do scratchpad da sessão; nada em `tests/**` nem untracked.

```
$ git -C mnemonicos-backend status --porcelain
(vazio)
```

## Medidas do caminho adotado (TASK-065-008)

**Medido em**: 2026-10-18 · mesmo ambiente acima (Node v26.8.2, sharp 0.35.5, 12 threads), com o host sob carga de outras sessões (load average 6 a 16): valem como ordem de grandeza. Caminho medido: `buildFinalStripPdf` real (`final-image.ts`: decode com `limitInputPixels = IMAGE_PIXEL_BUDGET_PX`, redução a `RECOMMENDED_LONG_SIDE_PX`, saída JPEG q85 4:2:0 sem alfa e PNG `compressionLevel 9` com alfa, `sharp.cache({memory:50,files:0,items:100})`, `concurrency 1`, conversões em sequência), em processo filho por cenário; pico = `process.resourceUsage().maxRSS` do filho depois do aquecimento (fontes e `sharp`), base ≈ 150-180 MB. O mesmo `Buffer` de origem serve a todos os Quadros (equivale a uma Associação repetida; a carga real traz até 4 binários distintos por lote). Teto de tamanho `PUBLICATION_FINAL_PDF_MAX_BYTES` = 4 000 000 (produção) ou 1 000 000 000 (elevado, sem o atalho de tamanho).

| medida | valor | observação |
| --- | --- | --- |
| rss-caminho-jpeg | WEBP 5000x4000: 334 / 354 / 334 MB; JPEG 5000x4000: 267 / 283 / 264 MB (3 rodadas cada) | M = 8 × 20 Mpx, teto de produção; limite 1024 MB: máx 354 MB (35%) |
| tempo-caminho-jpeg-m8 | WEBP 5000x4000: 886 / 855 / 1019 ms; JPEG 5000x4000: 1378 / 1690 / 1434 ms | M = 8 Quadros (compõe e serializa o PDF); limite `PUBLICATION_PDF_TIMEOUT_MS` 12 000 ms: máx 1690 ms; PDF de 1 459 553 B (WEBP) e 1 563 259 B (JPEG) |
| detalhe-origem-caminho-jpeg | webp 808 832 B · jpeg 1 975 916 B | foto sintética 5000x4000 (ondas + grão ±6), WEBP q80, JPEG q85 |
| rss-png-alfa-n10 | teto de produção (4 MB): 335 MB e 422 no Quadro 4 em 6 366 ms (alfa em gradiente); 336 MB e 3 564 ms (alfa uniforme, cabe). Teto elevado: 442 MB e 22 197 ms (alfa com ondas), 378 MB e 13 925 ms (gradiente) | N = 10 PNG com alfa 4472x4472; limites 700 MB e 12 s: RSS cumprido em todos; tempo estourado só com o teto de tamanho elevado (22,2 s e 13,9 s) |
| rss-png-alfa-n30 | teto de produção (4 MB): 338 MB e 422 no Quadro 4 em 4 069 ms (gradiente); 363 MB e 12 007 ms (alfa uniforme, cabe). Teto elevado: 728 MB e 82 521 ms (alfa com ondas), 401 MB e 24 465 ms (gradiente) | N = 30 PNG com alfa 4472x4472; limites 700 MB e 12 s: **728 MB e 82,5 s só com o teto elevado**; no teto de produção o RSS fica ≤ 363 MB, e o N = 30 que cabe no teto leva 12,0 s, na borda do teto de duração (503 por prazo) |
| detalhe-png-alfa-origens | alfa com ondas 12 653 293 B (reduz a ~4,5 MB por Quadro) · gradiente 2 354 255 B (~1,04 MB) · uniforme 86 673 B (~15,6 KB) | as três origens têm 4472x4472 RGBA; só a uniforme cabe em 30 Quadros sob 4 MB |
| detalhe-png-alfa-liso-teto-producao | 253 MB e 422 no Quadro 1 em ~1,4 s (N = 10 e N = 30) | alfa com ondas: o 1º Quadro reduzido (~4,5 MB) já passa de 4 MB |
| detalhe-ponto-de-cessao | 8 PNG RGBA 4000x3000 (~2 MB cada), teto elevado, `PUBLICATION_PDF_TIMEOUT_MS` 12 000: sucesso em 5228-5643 ms; maior intervalo entre disparos do batimento do event loop 621-893 ms (3 rodadas) | contra 12,3 s de bloqueio medido no gate 10 da wave 3 (sem redução, `setImmediate`) |

Leitura:

- O caminho JPEG (WEBP/JPEG de 20 Mpx → 2000 px → JPEG q85) custa 0,1 a 0,2 s por Quadro e ~350 MB de pico para M = 8: a memória não cresce com a soma dos rasters porque o `sharp` decodifica um Quadro por vez e o pdf-lib solta o raster no `embed()` ansioso.
- A soma de rasters de PNG com alfa deixou de ser o vetor: o pico de RSS em N = 30 só passa de 700 MB (728 MB) com o teto de tamanho elevado, quando o PDF acumula 135 MB de streams de PNG reduzido na memória; sob o teto de produção a soma embutida é limitada a 4 MB e o RSS fica em 335-363 MB. O tempo de N = 10 e N = 30 só fica ≤ 12 s porque o teto de tamanho (422) ou o de duração (503) encerram antes: PNG com alfa que cabe nos 4 MB nos 30 Quadros (alfa uniforme) leva 12,0 s e vive na borda do teto de duração.

Roteiro (sonda de processo filho; as origens foram geradas com `sharp` e gravadas em arquivo antes, para não entrar no RSS medido):

```ts
// BACKEND=<.../mnemonicos-backend>; NODE_PATH=$BACKEND/node_modules DATABASE_URL=... JWT_SECRET=... $BACKEND/node_modules/.bin/tsx run.ts <origem> <N> [<teto>]
import { readFileSync } from 'node:fs';
import { buildFinalStripPdf } from '<BACKEND>/src/modules/publication/final-pdf-composer';
const [file, N, cap] = [process.argv[2]!, Number(process.argv[3]), process.argv[4] ? Number(process.argv[4]) : undefined];
const bin = readFileSync(file);
const META = { disciplineName: 'Direito', topicName: 'Tópico', version: { number: 1, legislativeClosureDate: new Date('2026-09-01') } };
await buildFinalStripPdf([{ position: 1, text: 'a', binary: null }], META); // aquece fontes e sharp
const frames = Array.from({ length: N }, (_, i) => ({ position: i + 1, text: `Quadro ${i + 1}`, binary: bin }));
const t0 = performance.now();
const r = await buildFinalStripPdf(frames, META, undefined, cap).catch((e) => ({ err: e.constructor.name, position: e.position }));
console.log(JSON.stringify({ ms: Math.round(performance.now() - t0), peakMB: Math.round(process.resourceUsage().maxRSS / 1024), r: 'err' in r ? r : r.buffer.length }));
```
