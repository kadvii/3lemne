/* أداة تحقق: تغطية القاموس لكل كلمة في القطع والتمارين + سلامة البيانات */
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const ctx = { console };
vm.createContext(ctx);
ctx.window = ctx; // في المتصفح window هو الكائن العام نفسه

for (const f of ["js/data-vocab.js", "js/data-reading.js", "js/data-skills.js"]) {
  const code = fs.readFileSync(path.join(root, f), "utf8");
  vm.runInContext(code, ctx, { filename: f });
}

const D = ctx.window.DATA;

/* ---------- قاموس + نفس منطق البحث في التطبيق ---------- */
const DICT = new Map();
const dupes = new Set();
for (const v of D.vocab) {
  const k = v.en.toLowerCase();
  if (DICT.has(k)) dupes.add(k);
  DICT.set(k, { ar: v.ar, base: v.base });
}

function candidates(w) {
  const c = [];
  const add = (x) => { if (x && x.length > 1 && !c.includes(x)) c.push(x); };
  if (/ies$/.test(w)) add(w.slice(0, -3) + "y");
  if (/ves$/.test(w)) add(w.slice(0, -3) + "f");
  if (/es$/.test(w)) { add(w.slice(0, -2)); add(w.slice(0, -1)); }
  if (/s$/.test(w) && !/ss$/.test(w)) add(w.slice(0, -1));
  if (/ied$/.test(w)) add(w.slice(0, -3) + "y");
  if (/ed$/.test(w)) {
    const s = w.slice(0, -2);
    add(s); add(s + "e");
    if (s.length > 2 && s.at(-1) === s.at(-2)) add(s.slice(0, -1));
  }
  if (/ing$/.test(w)) {
    const g = w.slice(0, -3);
    add(g); add(g + "e");
    if (g.length > 2 && g.at(-1) === g.at(-2)) add(g.slice(0, -1));
  }
  if (/ier$/.test(w)) add(w.slice(0, -3) + "y");
  if (/est$/.test(w)) {
    const e = w.slice(0, -3);
    add(e); add(e + "e");
    if (e.length > 2 && e.at(-1) === e.at(-2)) add(e.slice(0, -1));
  }
  if (/er$/.test(w)) {
    const r = w.slice(0, -2);
    add(r); add(r + "e");
    if (r.length > 2 && r.at(-1) === r.at(-2)) add(r.slice(0, -1));
  }
  return c;
}

function has(word) {
  const w = word.toLowerCase().replace(/[’']/g, "'");
  if (DICT.has(w)) return true;
  if (DICT.has(w.replace(/'s$/, ""))) return true;
  return candidates(w).some((c) => DICT.has(c));
}

const API = /[A-Za-z][A-Za-z'’]*/g;
const missing = new Map();

function scan(text, where) {
  for (const m of String(text).matchAll(API)) {
    const raw = m[0].replace(/[’']+$/, "");
    if (!raw) continue;
    if (!has(raw)) {
      const key = raw.toLowerCase();
      if (!missing.has(key)) missing.set(key, new Set());
      missing.get(key).add(where);
    }
  }
}

/* ---------- القطع ---------- */
for (const p of D.reading) {
  p.sentences.forEach((s) => scan(s, `reading:${p.id}`));
  if (p.sentences.length !== p.translation.length) {
    console.error(`✗ ${p.id}: عدد الجمل لا يطابق عدد الترجمات`);
    process.exitCode = 1;
  }
  for (const q of p.questions) {
    if (q.answer < 0 || q.answer >= q.options.length) {
      console.error(`✗ ${p.id}: جواب سؤال خارج النطاق`);
      process.exitCode = 1;
    }
  }
}

/* ---------- المولّد ---------- */
function fill(tpl, vals, lang) {
  return tpl.replace(/\{(\w+)\}/g, (m, k) => (vals[k] ? vals[k][lang] : m));
}
for (const level of Object.keys(D.gen)) {
  const cfg = D.gen[level];
  for (let round = 0; round < 40; round++) {
    const picks = {};
    cfg.blocks.forEach((block) => {
      const vals = {};
      for (const key of Object.keys(block.slots)) {
        if (!picks[key]) picks[key] = block.slots[key][Math.floor(Math.random() * block.slots[key].length)];
        vals[key] = picks[key];
      }
      scan(fill(block.en, vals, "en"), `generated:${level}`);
    });
  }
}

/* ---------- الاستماع والتكلم والكتابة ---------- */
for (const level of Object.keys(D.listening)) {
  D.listening[level].forEach((item, i) => {
    scan(item.en, `listening:${level}:${i}`);
    if (item.answer < 0 || item.answer >= item.options.length) {
      console.error(`✗ listening ${level} #${i}: جواب خارج النطاق`);
      process.exitCode = 1;
    }
  });
}
for (const level of Object.keys(D.speaking)) {
  D.speaking[level].forEach((item, i) => scan(item.en, `speaking:${level}:${i}`));
}
for (const level of Object.keys(D.writing)) {
  for (const [en, ar] of D.writing[level]) {
    if (!ar || !en) {
      console.error(`✗ writing ${level}: عنصر ناقص`);
      process.exitCode = 1;
    }
    scan(en, `writing:${level}`);
  }
}

/* ---------- التقرير ---------- */
console.log(`القاموس: ${DICT.size} مدخلًا (بدون تكرار)`);
console.log(`القطع: ${D.reading.length} | كلمات الإملاء: ${Object.values(D.writing).flat().length}`);
console.log(`الاستماع: ${Object.values(D.listening).flat().length} | التكلم: ${Object.values(D.speaking).flat().length}`);

if (dupes.size) console.log(`ℹ️ مدخلات مكررة في القاموس: ${[...dupes].join(", ")}`);

if (missing.size) {
  console.log(`\n⚠️ كلمات بلا ترجمة (${missing.size}):`);
  for (const [w, where] of [...missing].sort()) {
    console.log(`  ${w.padEnd(18)} ← ${[...where].join(", ")}`);
  }
  process.exitCode = 1;
} else {
  console.log("\n✅ كل الكلمات في القطع والتمارين لها ترجمة عربية.");
}
