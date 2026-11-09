/* =========================================================
   خُطوة — منطق التطبيق
   ========================================================= */
(function () {
  "use strict";

  var D = window.DATA;
  var LEVELS = ["A1", "A2", "B1", "B2"];

  var appEl = document.getElementById("app");
  var navEl = document.getElementById("nav");
  var statsEl = document.getElementById("stats");
  var sheetEl = document.getElementById("sheet");
  var backdropEl = document.getElementById("backdrop");
  var toastEl = document.getElementById("toast");

  /* ================= أدوات مساعدة ================= */
  function $(sel, root) { return (root || document).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function todayStr() {
    var d = new Date();
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
  }
  function yesterdayStr() {
    var d = new Date();
    d.setDate(d.getDate() - 1);
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
  }

  function shuffle(arr) {
    var a = arr.slice();
    for (var i = a.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  }
  function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
  function pct(done, total) { return total ? Math.round((done / total) * 100) : 0; }

  /* نطق مؤجل لا يُنفَّذ إذا تغيّرت الشاشة أو انتقلنا لكلمة أخرى */
  var speakToken = 0;
  function laterSpeak(fn, delay) {
    var my = ++speakToken;
    setTimeout(function () { if (my === speakToken) fn(); }, delay);
  }

  /** يعزل المقاطع الإنجليزية داخل النص العربي حتى لا يختل ترتيب الاتجاه */
  function ar(text) {
    return esc(text).replace(/[\x21-\x7E]+/g, function (m) { return "<bdi>" + m + "</bdi>"; });
  }
  function levelInfo(id) {
    return D.levels.filter(function (l) { return l.id === id; })[0] || D.levels[0];
  }

  /* ================= الحالة ================= */
  var LS_KEY = "khotwa_v1";

  function defaultState() {
    var p = {};
    LEVELS.forEach(function (l) {
      p[l] = { reading: [], writing: [], listening: [], speaking: [] };
    });
    return {
      level: "A1",
      xp: 0,
      streak: 0,
      lastActive: "",
      saved: [],
      voice: "",
      rate: 0.95,
      progress: p
    };
  }

  function loadState() {
    var base = defaultState();
    try {
      var raw = localStorage.getItem(LS_KEY);
      if (!raw) return base;
      var saved = JSON.parse(raw);
      if (!saved || typeof saved !== "object") return base;
      base.level = LEVELS.indexOf(saved.level) >= 0 ? saved.level : "A1";
      base.xp = Number(saved.xp) || 0;
      base.streak = Number(saved.streak) || 0;
      base.lastActive = saved.lastActive || "";
      base.voice = saved.voice || "";
      base.rate = Number(saved.rate) || 0.95;
      base.saved = Array.isArray(saved.saved) ? saved.saved.filter(function (w) { return typeof w === "string"; }) : [];
      LEVELS.forEach(function (l) {
        var src = saved.progress && saved.progress[l];
        if (src) {
          ["reading", "writing", "listening", "speaking"].forEach(function (k) {
            if (Array.isArray(src[k])) base.progress[l][k] = src[k];
          });
        }
      });
      return base;
    } catch (e) {
      return base;
    }
  }

  var state = loadState();
  var gens = new Map();

  function saveState() {
    try { localStorage.setItem(LS_KEY, JSON.stringify(state)); } catch (e) {}
  }

  function touchStreak() {
    var t = todayStr();
    if (state.lastActive === t) return;
    state.streak = state.lastActive === yesterdayStr() ? (state.streak || 0) + 1 : 1;
    state.lastActive = t;
  }

  function award(points, msg) {
    state.xp += points;
    touchStreak();
    saveState();
    updateStats();
    if (msg) toast(msg);
  }

  function markDone(level, skill, id) {
    var arr = state.progress[level][skill];
    if (arr.indexOf(id) === -1) {
      arr.push(id);
      saveState();
      return true;
    }
    return false;
  }

  /* ================= القاموس ================= */
  var DICT = {};
  D.vocab.forEach(function (v) {
    var k = v.en.toLowerCase();
    if (!DICT[k]) DICT[k] = { ar: v.ar, base: v.base || null };
  });

  function morphCandidates(w) {
    var c = [];
    function add(x) { if (x && x.length > 1 && c.indexOf(x) === -1) c.push(x); }
    if (/ies$/.test(w)) add(w.slice(0, -3) + "y");
    if (/ves$/.test(w)) add(w.slice(0, -3) + "f");
    if (/es$/.test(w)) { add(w.slice(0, -2)); add(w.slice(0, -1)); }
    if (/s$/.test(w) && !/ss$/.test(w)) add(w.slice(0, -1));
    if (/ied$/.test(w)) add(w.slice(0, -3) + "y");
    if (/ed$/.test(w)) {
      var s = w.slice(0, -2);
      add(s); add(s + "e");
      if (s.length > 2 && s[s.length - 1] === s[s.length - 2]) add(s.slice(0, -1));
    }
    if (/ing$/.test(w)) {
      var g = w.slice(0, -3);
      add(g); add(g + "e");
      if (g.length > 2 && g[g.length - 1] === g[g.length - 2]) add(g.slice(0, -1));
    }
    if (/ier$/.test(w)) add(w.slice(0, -3) + "y");
    if (/est$/.test(w)) {
      var e = w.slice(0, -3);
      add(e); add(e + "e");
      if (e.length > 2 && e[e.length - 1] === e[e.length - 2]) add(e.slice(0, -1));
    }
    if (/er$/.test(w)) {
      var r = w.slice(0, -2);
      add(r); add(r + "e");
      if (r.length > 2 && r[r.length - 1] === r[r.length - 2]) add(r.slice(0, -1));
    }
    if (/ily$/.test(w)) add(w.slice(0, -3) + "y");
    return c;
  }

  function lookup(raw) {
    var original = String(raw || "");
    var w = original.toLowerCase().replace(/[’]/g, "'").replace(/^[^a-z']+|[^a-z']+$/g, "");
    if (!w) return { word: original, ar: "—", base: null };

    if (DICT[w]) return { word: original, ar: DICT[w].ar, base: DICT[w].base, found: true };

    // صيغ الملكية والاختصارات
    var noPoss = w.replace(/'s$/, "");
    if (DICT[noPoss]) return { word: original, ar: DICT[noPoss].ar, base: null, found: true };

    var cands = morphCandidates(w);
    for (var i = 0; i < cands.length; i++) {
      if (DICT[cands[i]]) {
        return { word: original, ar: DICT[cands[i]].ar, base: cands[i], found: true };
      }
    }
    return { word: original, ar: "لا يوجد معنى محفوظ لهذه الكلمة بعد", base: null, found: false };
  }

  /* ================= أيقونات ================= */
  var I = {
    home: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M9.5 21v-6h5v6"/></svg>',
    book: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 6.3C10.4 5 8.4 4.4 6.2 4.4H3v13.2h3.2c2.2 0 4.2.6 5.8 1.9 1.6-1.3 3.6-1.9 5.8-1.9H21V4.4h-3.2c-2.2 0-4.2.6-5.8 1.9Z"/><path d="M12 6.3v13.2"/></svg>',
    pen: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>',
    headphones: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/></svg>',
    mic: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 10v2a7 7 0 0 0 14 0v-2"/><path d="M12 19v3"/></svg>',
    star: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3 2.7 5.8 6.3.8-4.6 4.4 1.2 6.3L12 17.3 6.4 20.3l1.2-6.3L3 9.6l6.3-.8Z"/></svg>',
    flame: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3c1.5 3 5 5.2 5 9a5 5 0 0 1-10 0c0-2 1-3.5 2-4.5 0 2 1 3 1.8 3.3C11.3 8.6 11 5.6 12 3Z"/></svg>',
    bookmark: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h12v18l-6-4.5L6 21Z"/></svg>',
    gear: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.87l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.7 1.7 0 0 0-1.87-.34 1.7 1.7 0 0 0-1 1.55V21a2 2 0 1 1-4 0v-.09a1.7 1.7 0 0 0-1.11-1.55 1.7 1.7 0 0 0-1.87.34l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.7 1.7 0 0 0 4.6 15a1.7 1.7 0 0 0-1.55-1H3a2 2 0 1 1 0-4h.09A1.7 1.7 0 0 0 4.6 8.9a1.7 1.7 0 0 0-.34-1.87l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.7 1.7 0 0 0 9 4.6h.09A1.7 1.7 0 0 0 10.1 3V3a2 2 0 1 1 4 0v.09a1.7 1.7 0 0 0 1 1.55 1.7 1.7 0 0 0 1.87-.34l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.7 1.7 0 0 0 19.4 9v.09a1.7 1.7 0 0 0 1.55 1H21a2 2 0 1 1 0 4h-.09a1.7 1.7 0 0 0-1.51 1Z"/></svg>',
    volume: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/></svg>',
    play: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l11-6.5z"/></svg>',
    sparkles: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="m12 3 1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9Z"/><path d="m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8Z"/></svg>',
    check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="m4.5 12.5 5 5 10-11"/></svg>',
    x: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="m6 6 12 12M18 6 6 18"/></svg>',
    arrow: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m13 6 6 6-6 6"/></svg>',
    globe: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a15 15 0 0 1 0 18a15 15 0 0 1 0-18"/></svg>',
    keyboard: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M6 14h.01M18 14h.01M9 14h6"/></svg>',
    refresh: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 1 1-3-6.7"/><path d="M21 4v5h-5"/></svg>',
    trash: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 14h10l1-14"/></svg>'
  };
  function icon(name) { return I[name] || ""; }

  /* ================= الترويسة والتنقّل ================= */
  var NAV_ITEMS = [
    { id: "home", label: "الرئيسية", path: "/", symbol: "home" },
    { id: "reading", label: "القراءة", path: "/reading", symbol: "book" },
    { id: "writing", label: "الكتابة", path: "/writing", symbol: "pen" },
    { id: "listening", label: "الاستماع", path: "/listening", symbol: "headphones" },
    { id: "speaking", label: "التكلم", path: "/speaking", symbol: "mic" },
    { id: "words", label: "مفرداتي", path: "/words", symbol: "bookmark" }
  ];

  function currentSection() {
    var h = location.hash.replace(/^#/, "").replace(/^\//, "");
    var seg = h.split("/")[0];
    return seg || "home";
  }

  function renderNav() {
    var active = currentSection();
    navEl.innerHTML = NAV_ITEMS.map(function (n) {
      var on = n.id === active ? " active" : "";
      return '<button class="nav-pill' + on + '" data-go="' + n.path + '">' + icon(n.symbol) + n.label + "</button>";
    }).join("");
  }

  function updateStats() {
    var voiceWarn = !Speech.supported ? "" : "";
    statsEl.innerHTML =
      '<div class="stat">' + icon("star") + "<b>" + state.xp + '</b><span class="lbl">نقطة</span></div>' +
      '<div class="stat streak">' + icon("flame") + "<b>" + (state.streak || 0) + '</b><span class="lbl">يوم</span></div>' +
      '<div class="stat">' + icon("bookmark") + "<b>" + state.saved.length + '</b><span class="lbl">كلمة</span></div>' +
      voiceWarn;
  }

  /* ================= تنبيهات ================= */
  var toastTimer = null;
  function toast(msg) {
    toastEl.innerHTML = '<div class="toast-msg">' + msg + "</div>";
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.innerHTML = ""; }, 2600);
  }

  /* ================= اللوحة السفلية ================= */
  function openSheet(html) {
    sheetEl.innerHTML = '<div class="grab"></div>' + html;
    backdropEl.classList.add("open");
    sheetEl.classList.add("open");
  }
  function closeSheet() {
    backdropEl.classList.remove("open");
    sheetEl.classList.remove("open");
  }
  backdropEl.addEventListener("click", closeSheet);

  function openWordSheet(raw) {
    var info = lookup(raw);
    var key = String(raw).toLowerCase();
    var saved = state.saved.indexOf(key) >= 0;
    openSheet(
      '<div class="word-big">' + esc(raw) + "</div>" +
      '<div class="word-ar">' + esc(info.ar) + "</div>" +
      (info.base ? '<div class="word-note">root: ' + esc(info.base) + "</div>" : (info.found ? "" : '<div class="word-note">try another word</div>')) +
      '<div class="sheet-actions">' +
      '<button class="btn small" data-sheet-speak="' + esc(raw) + '">' + icon("volume") + " استمع</button>" +
      '<button class="btn ghost small" data-sheet-save="' + esc(raw) + '">' + (saved ? "إزالة من مفرداتي" : "＋ أضف إلى مفرداتي") + "</button>" +
      '<button class="btn ghost small" data-sheet-close="1">إغلاق</button>' +
      "</div>"
    );
    var speakBtn = $("[data-sheet-speak]", sheetEl);
    if (speakBtn) speakBtn.onclick = function () { Speech.speak(raw, { rate: 0.9, voice: state.voice }); };

    var saveBtn = $("[data-sheet-save]", sheetEl);
    if (saveBtn) saveBtn.onclick = function () {
      var idx = state.saved.indexOf(key);
      if (idx >= 0) { state.saved.splice(idx, 1); toast("أُزيلت من مفرداتي"); }
      else { state.saved.push(key); toast("أُضيفت إلى مفرداتي ✅"); }
      saveState();
      updateStats();
      openWordSheet(raw);
      var readerOpen = document.querySelector(".word.saved");
      if (readerOpen) { /* تحديث التظليل في القطعة */ }
      $$(".word").forEach(function (el) {
        if (el.dataset.word && state.saved.indexOf(String(el.dataset.word).toLowerCase()) >= 0) el.classList.add("saved");
        else el.classList.remove("saved");
      });
    };

    var closeBtn = $("[data-sheet-close]", sheetEl);
    if (closeBtn) closeBtn.onclick = closeSheet;
  }

  /* ================= الإعدادات ================= */
  function openSettings() {
    var voices = Speech.getVoices();
    var opts = voices.map(function (v) {
      var sel = state.voice === v.name ? " selected" : "";
      return '<option value="' + esc(v.name) + '"' + sel + ">" + esc(v.name) + " (" + esc(v.lang) + ")</option>";
    }).join("");

    openSheet(
      "<h3 style=\"margin:0 0 4px\">الإعدادات</h3>" +
      '<p class="tiny muted" style="margin:0 0 16px">اختر الصوت وسرعة النطق المناسبة لك.</p>' +
      '<label class="tiny muted" for="voiceSel">صوت النطق</label>' +
      '<select id="voiceSel" style="width:100%;margin:6px 0 16px;padding:11px;border-radius:12px;background:#151d33;color:#eef2ff;border:1px solid var(--line)">' +
      (opts || '<option value="">لا توجد أصوات إنجليزية متاحة</option>') + "</select>" +
      '<label class="tiny muted" for="rateRange">السرعة: <b id="rateVal">' + state.rate.toFixed(2) + "</b></label>" +
      '<input id="rateRange" type="range" min="0.6" max="1.2" step="0.05" value="' + state.rate + '" style="width:100%;margin:8px 0 18px;accent-color:#59e0c8">' +
      '<div style="display:flex;gap:8px;flex-wrap:wrap">' +
      '<button class="btn ghost small" data-settings-test="1">🔊 تجربة الصوت</button>' +
      '<button class="btn ghost small" data-settings-reset="1">حذف التقدم</button>' +
      '<button class="btn ghost small" data-sheet-close="1">إغلاق</button>' +
      "</div>" +
      '<p class="tiny" style="color:var(--dim);margin-top:16px;line-height:1.9">' +
      "التعرّف على الصوت: " + (Speech.recognitionSupported ? "مدعوم في هذا المتصفح ✅" : "غير مدعوم ❌ — استخدم Chrome أو Edge") +
      "</p>"
    );

    var sel = $("#voiceSel", sheetEl);
    if (sel) sel.onchange = function () {
      state.voice = sel.value;
      saveState();
      Speech.setVoice(state.voice);
      Speech.speak("Hello, this is my voice.", { rate: state.rate, voice: state.voice });
    };

    var range = $("#rateRange", sheetEl);
    if (range) range.oninput = function () {
      state.rate = Number(range.value);
      var lbl = $("#rateVal", sheetEl);
      if (lbl) lbl.textContent = state.rate.toFixed(2);
      saveState();
    };

    var test = $("[data-settings-test]", sheetEl);
    if (test) test.onclick = function () {
      Speech.speak("Learning English a little every day makes a big difference.", { rate: state.rate, voice: state.voice });
    };

    var reset = $("[data-settings-reset]", sheetEl);
    if (reset) reset.onclick = function () {
      if (window.confirm("سيتم حذف كل تقدمك ونقاطك. هل أنت متأكد؟")) {
        try { localStorage.removeItem(LS_KEY); } catch (e) {}
        location.reload();
      }
    };

    var closeBtn = $("[data-sheet-close]", sheetEl);
    if (closeBtn) closeBtn.onclick = closeSheet;
  }

  /* ================= التوجيه ================= */
  function go(path) {
    if (location.hash === "#" + path) route();
    else location.hash = "#" + path;
  }

  function route() {
    Speech.stop();
    Speech.stopRecognition();
    stopMedia();
    speakToken++;
    closeSheet();
    var raw = location.hash.replace(/^#/, "") || "/";
    var seg = raw.split("?")[0].split("/").filter(Boolean);
    var key = seg[0] || "home";

    try {
      if (key === "reading") {
        if (!seg[1]) viewReading();
        else if (seg[1] === "new") {
          var g = generatePassage(state.level);
          gens.set(g.id, g);
          location.replace("#/reading/" + g.id);
          viewReader(g.id);
        } else viewReader(seg[1]);
      } else if (key === "writing") viewWriting();
      else if (key === "listening") viewListening();
      else if (key === "speaking") viewSpeaking();
      else if (key === "words") viewWords();
      else viewHome();
    } catch (err) {
      appEl.innerHTML = '<div class="card"><h3>حدث خطأ غير متوقع</h3><p class="muted tiny">' + esc(err && err.message) + '</p><button class="btn" data-go="/">الرئيسية</button></div>';
      console.error(err);
    }

    renderNav();
    window.scrollTo(0, 0);
  }

  function render(html) {
    appEl.innerHTML = html;
  }

  /* ================= الرئيسية ================= */
  function viewHome() {
    var lvl = state.level;
    var info = levelInfo(lvl);
    var wlist = D.writing[lvl];
    var day = Math.floor(Date.now() / 86400000);
    var wotd = wlist[day % wlist.length];

    var skills = [
      {
        key: "reading", path: "/reading", color: "#f5b451", icon: "book",
        title: "القراءة", en: "Reading",
        desc: "قطع قصيرة بمستواك. اضغط أي كلمة إنجليزية ليظهر معناها بالعربي فورًا."
      },
      {
        key: "writing", path: "/writing", color: "#a78bfa", icon: "pen",
        title: "الكتابة", en: "Writing",
        desc: "اسمع الكلمة واكتبها في مربعات بعدد حروفها، مع تلميحات عند الحاجة."
      },
      {
        key: "listening", path: "/listening", color: "#4fd1c5", icon: "headphones",
        title: "الاستماع", en: "Listening",
        desc: "جمل منطوقة بسرعة تناسبك، ثم اختر المعنى الصحيح واختبر فهمك."
      },
      {
        key: "speaking", path: "/speaking", color: "#fb7185", icon: "mic",
        title: "التكلم", en: "Speaking",
        desc: "قل الجملة بصوتك، وسنقيس دقة نطقك كلمة بكلمة ونصححها معك."
      }
    ];

    var cards = skills.map(function (s) {
      var total, done;
      if (s.key === "reading") {
        total = D.reading.filter(function (p) { return p.level === lvl; }).length;
        done = state.progress[lvl].reading.length;
      } else if (s.key === "writing") {
        total = D.writing[lvl].length;
        done = state.progress[lvl].writing.length;
      } else if (s.key === "listening") {
        total = D.listening[lvl].length;
        done = state.progress[lvl].listening.length;
      } else {
        total = D.speaking[lvl].length;
        done = state.progress[lvl].speaking.length;
      }
      done = Math.min(done, total);
      return (
        '<div class="skill-card" role="button" tabindex="0" style="--c:' + s.color + '" data-go="' + s.path + '">' +
        '<div class="skill-icon">' + icon(s.icon) + "</div>" +
        '<div class="skill-title">' + s.title + "</div>" +
        '<div class="skill-en">' + s.en + "</div>" +
        '<p class="skill-desc">' + s.desc + "</p>" +
        '<div class="skill-foot"><div class="skill-bar"><span style="width:' + pct(done, total) + '%"></span></div>' +
        '<span class="skill-count">' + done + "/" + total + "</span></div>" +
        "</div>"
      );
    }).join("");

    var chips = D.levels.map(function (l) {
      return '<button class="level-chip' + (l.id === lvl ? " active" : "") + '" data-level="' + l.id + '"><b>' + l.id + "</b>" + l.name + "</button>";
    }).join("");

    render(
      '<section class="screen">' +
      '<div class="hero">' +
      '<div class="hero-visual" aria-hidden="true">' +
      '<div class="hv-card" style="--c:#f5b451"><em>📖</em><span>Reading</span><i></i></div>' +
      '<div class="hv-card" style="--c:#a78bfa"><em>✍️</em><span>Writing</span><i></i></div>' +
      '<div class="hv-card" style="--c:#4fd1c5"><em>🎧</em><span>Listening</span><i></i></div>' +
      '<div class="hv-card" style="--c:#fb7185"><em>🎙️</em><span>Speaking</span><i></i></div>' +
      "</div>" +
      '<div class="hero-copy">' +
      '<div class="hero-kicker">' + icon("sparkles") + " مسارك الشخصي · <bdi>A1 → B2</bdi></div>" +
      '<h1>تعلّم الإنجليزية <span class="grad">بالعربية</span>،<br>بأربع مهارات كل يوم.</h1>' +
      "<p>اقرأ قطعة بمستواك واضغط أي كلمة لترى معناها، اكتب ما تسمعه، تدرّب على الاستماع، ثم تحدّث بصوتك. كل شيء بخطوات صغيرة تناسب وقتك.</p>" +
      '<div class="hero-actions">' +
      '<button class="btn" data-go="/reading">' + icon("book") + " ابدأ القراءة</button>" +
      '<button class="btn ghost" data-go="/speaking">' + icon("mic") + " جرّب التكلم</button>" +
      "</div>" +
      '<div class="hero-stat">' +
      "<div><b>" + state.xp + "</b><span>نقطة خبرة</span></div>" +
      "<div><b>" + state.saved.length + "</b><span>كلمة محفوظة</span></div>" +
      "<div><b>" + (state.streak || 0) + "</b><span>يوم متتابع</span></div>" +
      "</div></div></div>" +

      '<div class="level-switch"><span class="label">مستواك الحالي:</span>' + chips + "</div>" +
      '<div class="skills">' + cards + "</div>" +

      '<div class="home-lower">' +
      '<div class="card word-of-day">' +
      '<div class="panel-title"><h3>كلمة اليوم</h3><span class="tiny muted">' + info.name + " · " + info.en + "</span></div>" +
      '<div class="w-en">' + esc(wotd[0]) + "</div>" +
      '<div class="w-ar">' + esc(wotd[1]) + "</div>" +
      '<div style="display:flex;gap:8px;margin-top:14px;flex-wrap:wrap">' +
      '<button class="btn small" data-speak="' + esc(wotd[0]) + '">' + icon("volume") + " استمع</button>" +
      '<button class="btn ghost small" data-save="' + esc(wotd[0]) + '">' + icon("bookmark") + " احفظها</button>" +
      "</div></div>" +

      '<div class="card"><div class="panel-title"><h3>كيف تستفيد أكثر؟</h3></div>' +
      '<div class="tip-list">' +
      '<div class="tip"><span class="num">1</span><span>اضغط على أي كلمة في القطعة لترى معناها، ثم أضفها إلى «مفرداتي».</span></div>' +
      '<div class="tip"><span class="num">2</span><span>في الكتابة، أعد سماع الكلمة بصوت بطيء قبل أن تبدأ بالكتابة.</span></div>' +
      '<div class="tip"><span class="num">3</span><span>عشر دقائق يوميًا أفضل من ساعتين مرة واحدة في الأسبوع.</span></div>' +
      "</div></div>" +
      "</div>" +

      '<p class="footer-note">صُمّم ليكون بسيطًا: قراءة، كتابة، استماع، وتكلم — بالعربية والإنجليزية.<br>يعمل دون إنترنت، والتقدم يُحفظ على جهازك.</p>' +
      "</section>"
    );
  }

  /* ================= القراءة ================= */
  var LEVEL_COLORS = { A1: "#46d39a", A2: "#4fd1c5", B1: "#f5b451", B2: "#fb7185" };

  function chipsHtml() {
    return D.levels.map(function (l) {
      return '<button class="level-chip' + (l.id === state.level ? " active" : "") + '" data-level="' + l.id + '"><b>' + l.id + "</b>" + l.name + "</button>";
    }).join("");
  }

  function viewReading() {
    var lvl = state.level;
    var passages = D.reading.filter(function (p) { return p.level === lvl; });
    var done = state.progress[lvl].reading;

    var cards = passages.map(function (p) {
      var words = p.sentences.join(" ").split(/\s+/).length;
      var isDone = done.indexOf(p.id) >= 0;
      return (
        '<div class="passage-card" role="button" tabindex="0" data-open="' + p.id + '">' +
        (isDone ? '<span class="done-badge">✓</span>' : "") +
        '<span class="kind">' + p.level + " · " + p.minutes + " دقائق</span>" +
        '<div class="card-title"><h4>' + esc(p.title) + "</h4></div>" +
        '<div class="ar">' + esc(p.titleAr) + "</div>" +
        '<div class="passage-meta"><span>' + words + " كلمة</span><span class='dotm'></span><span>" +
        p.questions.length + " سؤال فهم</span><span class='dotm'></span><span>ترجمة كلمة بكلمة</span></div>" +
        "</div>"
      );
    }).join("");

    render(
      '<section class="screen">' +
      '<div class="screen-head">' +
      '<button class="back-btn" data-go="/" aria-label="رجوع">' + icon("arrow") + "</button>" +
      "<div><h2 class=\"screen-title\">القراءة</h2><p class=\"screen-sub\">اختر قطعة، واضغط أي كلمة لتعرف معناها بالعربي</p></div>" +
      '<div class="spacer"></div>' +
      '<button class="btn small" data-generate="1">' + icon("sparkles") + " قطعة جديدة</button>" +
      "</div>" +
      '<div class="level-switch">' + chipsHtml() + "</div>" +
      '<div class="grid-2">' +
      '<div class="passage-card gen wide" role="button" tabindex="0" data-generate="1" style="border-style:dashed;border-color:rgba(245,180,81,.35)">' +
      '<span class="kind">توليد فوري</span>' +
      '<div class="card-title"><h4>Generate a new passage</h4></div>' +
      '<div class="ar">قطعة جديدة تُبنى الآن من كلمات مستواك، مع ترجمة كل جملة.</div>' +
      '<div class="passage-meta"><span>لا نهائية</span><span class="dotm"></span><span>مناسبة للتدريب السريع</span></div>' +
      "</div>" +
      cards +
      "</div>" +
      '<p class="footer-note">نصيحة: اقرأ الجملة كاملة أولًا، ثم اضغط الكلمات الجديدة.</p>' +
      "</section>"
    );
  }

  function wordHtml(word, savedWords) {
    var key = String(word).toLowerCase();
    return '<span class="word' + (savedWords.indexOf(key) >= 0 ? " saved" : "") + '" data-word="' + esc(word) + '">' + esc(word) + "</span>";
  }

  function sentenceHtml(sentence, savedWords) {
    return sentence.split(/(\s+)/).map(function (tok) {
      if (!tok) return "";
      if (/^\s+$/.test(tok)) return tok;
      var m = tok.match(/^([^A-Za-z]*)([A-Za-z][A-Za-z'’]*)([^A-Za-z]*)$/);
      if (!m) return esc(tok);
      var pre = m[1], word = m[2], post = m[3];
      var trailing = "";
      if (/'+$/.test(word) && word.replace(/'+$/, "").length > 1) {
        trailing = word.match(/'+$/)[0];
        word = word.replace(/'+$/, "");
      }
      return esc(pre) + wordHtml(word, savedWords) + esc(trailing + post);
    }).join("");
  }

  function generatePassage(level) {
    var cfg = D.gen[level];
    var picks = {};
    var sentences = [];
    var translation = [];

    cfg.blocks.forEach(function (block) {
      var vals = {};
      Object.keys(block.slots).forEach(function (key) {
        if (!picks[key]) picks[key] = pick(block.slots[key]);
        vals[key] = picks[key];
      });
      sentences.push(block.en.replace(/\{(\w+)\}/g, function (m, k) { return vals[k] ? vals[k].en : m; }));
      translation.push(block.ar.replace(/\{(\w+)\}/g, function (m, k) { return vals[k] ? vals[k].ar : m; }));
    });

    var t = pick(D.genTitles[level]);
    return {
      id: "gen-" + Date.now().toString(36) + "-" + Math.floor(Math.random() * 999),
      level: level,
      title: t[0],
      titleAr: t[1],
      sentences: sentences,
      translation: translation,
      questions: [],
      generated: true
    };
  }

  function viewReader(id) {
    var p = null;
    if (gens.has(id)) p = gens.get(id);
    else {
      p = D.reading.filter(function (x) { return x.id === id; })[0] || null;
    }
    if (!p) {
      toast("لم أجد هذه القطعة، اختر واحدة من القائمة");
      go("/reading");
      return;
    }

    var savedWords = state.saved;
    var passageHtml = p.sentences.map(function (s) {
      return '<span class="sentence">' + sentenceHtml(s, savedWords) + "</span>";
    }).join(" ");

    var translationHtml = p.translation.map(function (t) {
      return '<div class="tr-line">' + esc(t) + "</div>";
    }).join("");

    var isDone = state.progress[p.level].reading.indexOf(p.id) >= 0;
    var words = p.sentences.join(" ").split(/\s+/).length;

    var quiz = "";
    if (p.questions && p.questions.length) {
      quiz =
        '<div class="quiz"><h4>' + icon("check") + " أسئلة الفهم</h4>" +
        p.questions.map(function (q, qi) {
          return '<div class="quiz-q" data-qidx="' + qi + '"><p><span class="qn">' + (qi + 1) + ".</span>" + esc(q.q) + "</p>" +
            '<div class="options">' + q.options.map(function (o, oi) {
              return '<button class="option" data-q="' + qi + '" data-o="' + oi + '"><span class="letter">' + "ABC"[oi] + "</span><span>" + esc(o) + "</span></button>";
            }).join("") + "</div></div>";
        }).join("") +
        "</div>";
    }

    render(
      '<section class="screen">' +
      '<div class="screen-head">' +
      '<button class="back-btn" data-go="/reading" aria-label="رجوع">' + icon("arrow") + "</button>" +
      "<div><h2 class=\"screen-title\">" + esc(p.generated ? "قطعة مولّدة" : "قطعة قراءة") + "</h2>" +
      '<p class="screen-sub">' + p.level + " · " + words + " كلمة · " + p.sentences.length + " جمل</p></div>" +
      '<div class="spacer"></div>' +
      '<span class="level-chip active" style="cursor:default"><b>' + p.level + "</b>" + levelInfo(p.level).name + "</span>" +
      "</div>" +

      '<div class="reader">' +
      '<div class="reader-top"><div><h1 class="reader-title">' + esc(p.title) + '</h1><div class="reader-title-ar">' + esc(p.titleAr) + "</div></div></div>" +

      '<div class="reader-tools">' +
      '<button class="tool" id="playPassage">' + icon("volume") + " استمع للقطعة</button>" +
      '<button class="tool" id="trBtn">' + icon("globe") + " الترجمة</button>" +
      '<button class="tool" id="sizeBtn">A+ حجم الخط</button>' +
      '<button class="tool" data-generate="1">' + icon("sparkles") + " قطعة جديدة</button>" +
      "</div>" +

      '<p class="passage" id="passageText">' + passageHtml + "</p>" +
      '<div class="hintline">' + icon("bookmark") + " اضغط أي كلمة لترى معناها بالعربي وتسمع نطقها</div>" +
      '<div class="translation-box" id="transBox" hidden>' + translationHtml + "</div>" +

      quiz +

      '<div class="hint-row" style="justify-content:flex-start;margin-top:20px">' +
      '<button class="btn" data-complete="' + p.id + '">' + (isDone ? "✓ أنهيت هذه القطعة" : "أنهيت القراءة") + "</button>" +
      '<button class="btn ghost" data-go="/reading">كل القطع</button>' +
      "</div></div>" +
      "</section>"
    );

    var playBtn = $("#playPassage");
    if (playBtn) playBtn.onclick = function () {
      if (Speech.isSpeaking()) { Speech.stop(); playBtn.classList.remove("on"); return; }
      playBtn.classList.add("on");
      Speech.speak(p.sentences.join(" "), {
        rate: Math.max(0.7, state.rate - 0.05),
        voice: state.voice,
        onend: function () { playBtn.classList.remove("on"); }
      });
    };

    var trBtn = $("#trBtn");
    if (trBtn) trBtn.onclick = function () {
      var box = $("#transBox");
      var show = box.hasAttribute("hidden");
      if (show) box.removeAttribute("hidden");
      else box.setAttribute("hidden", "");
      trBtn.classList.toggle("on", show);
    };

    var sizeBtn = $("#sizeBtn");
    if (sizeBtn) sizeBtn.onclick = function () {
      var pass = $("#passageText");
      pass.classList.toggle("large");
      sizeBtn.classList.toggle("on", pass.classList.contains("large"));
    };

    var completeBtn = $("[data-complete]");
    if (completeBtn) completeBtn.onclick = function () {
      if (p.generated) {
        award(8, "أحسنت! +8 نقاط");
        completeBtn.textContent = "✓ تم";
        return;
      }
      if (markDone(p.level, "reading", p.id)) {
        award(10, "أكملت القطعة! +10 نقاط");
        completeBtn.textContent = "✓ أنهيت هذه القطعة";
      } else {
        toast("أنهيت هذه القطعة مسبقًا ✓");
      }
    };

    $$(".option", appEl).forEach(function (btn) {
      btn.onclick = function () {
        var qi = Number(btn.dataset.q);
        var oi = Number(btn.dataset.o);
        var q = p.questions[qi];
        var group = $('.quiz-q[data-qidx="' + qi + '"]', appEl);
        if (!q || !group || group.dataset.answered) return;
        group.dataset.answered = "1";
        $$(".option", group).forEach(function (o) {
          o.disabled = true;
          if (Number(o.dataset.o) === q.answer) o.classList.add("correct");
        });
        if (oi === q.answer) { btn.classList.add("correct"); award(3, "إجابة صحيحة +3"); }
        else btn.classList.add("wrong");
      };
    });
  }

  /* ================= الكتابة ================= */
  var writingSession = null;

  function ensureWriting() {
    if (writingSession && writingSession.level === state.level) return writingSession;
    var pool = D.writing[state.level].map(function (w) { return { en: w[0], ar: w[1] }; });
    pool = shuffle(pool).slice(0, 10);
    writingSession = { level: state.level, items: pool, i: 0, attempts: 0, solved: false, correct: 0 };
    return writingSession;
  }

  function writingDone() {
    var s = writingSession;
    render(
      '<section class="screen"><div class="practice" style="justify-content:center">' +
      '<div class="done-screen"><div class="emoji">✍️</div>' +
      "<h3>أكملت جلسة الكتابة</h3>" +
      "<p>كتبت " + s.correct + " من " + s.items.length + " كلمة بشكل صحيح.<br>كل كلمة صحيحة = 5 نقاط خبرة.</p>" +
      '<div class="done-actions">' +
      '<button class="btn" data-action="writing-restart">' + icon("refresh") + " جلسة جديدة</button>" +
      '<button class="btn ghost" data-go="/">الرئيسية</button>' +
      "</div></div></div></section>"
    );
  }

  function viewWriting() {
    var s = ensureWriting();
    if (s.i >= s.items.length) { writingDone(); return; }

    var item = s.items[s.i];
    var word = item.en;
    var boxes = "";
    for (var k = 0; k < word.length; k++) {
      boxes += '<input class="box" type="text" inputmode="text" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" maxlength="1" aria-label="حرف ' + (k + 1) + '">';
    }

    var kbKeys = "";
    "abcdefghijklmnopqrstuvwxyz".split("").forEach(function (ch) {
      kbKeys += '<button class="kb-key" data-key="' + ch + '">' + ch + "</button>";
    });

    render(
      '<section class="screen">' +
      '<div class="screen-head">' +
      '<button class="back-btn" data-go="/" aria-label="رجوع">' + icon("arrow") + "</button>" +
      '<div><h2 class="screen-title">الكتابة · إملاء</h2><p class="screen-sub">اسمع الكلمة واكتبها في المربعات</p></div>' +
      '<div class="spacer"></div>' +
      '<button class="btn ghost small" data-action="writing-restart">' + icon("refresh") + " جلسة جديدة</button>" +
      "</div>" +

      '<div class="practice">' +
      '<div class="practice-top">' +
      '<span class="counter"><b>' + (s.i + 1) + "</b> / " + s.items.length + "</span>" +
      '<div class="mini-bar"><span style="width:' + Math.round((s.i / s.items.length) * 100) + '%"></span></div>' +
      '<div class="spacer"></div>' +
      '<span class="counter">✅ ' + s.correct + "</span>" +
      "</div>" +

      '<div class="practice-body">' +
      '<div class="prompt-label">listen &amp; type</div>' +
      '<button class="orb" id="playWord" aria-label="استمع للكلمة">' + icon("volume") + "</button>" +
      '<div class="wave" id="wave"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>' +
      '<div class="prompt-ar">المعنى: <b style="color:#eef2ff">' + esc(item.ar) + "</b></div>" +
      '<div class="boxes" id="boxes">' + boxes + "</div>" +
      '<div class="kb" id="kb">' + kbKeys + '<button class="kb-key wide" data-key="back">حذف</button></div>' +
      '<div class="hint-row">' +
      '<button class="tool" data-wact="replay">' + icon("volume") + " إعادة</button>" +
      '<button class="tool" data-wact="slow">🐢 ببطء</button>' +
      '<button class="tool" data-wact="hint">💡 أول حرف</button>' +
      '<button class="tool" data-wact="kb">' + icon("keyboard") + " لوحة</button>" +
      "</div>" +
      '<div class="feedback" id="feedback"></div>' +
      '<div class="hint-row" id="actions">' +
      '<button class="btn" id="checkBtn">تحقق</button>' +
      "</div>" +
      "</div></div>" +
      "</section>"
    );

    var boxEls = $$(".box", appEl);
    var feedback = $("#feedback");
    var actions = $("#actions");
    var playBtn = $("#playWord");
    var wave = $("#wave");

    function play(rate) {
      wave.classList.add("anim");
      playBtn.classList.add("playing");
      Speech.speak(word, {
        rate: rate,
        voice: state.voice,
        onend: function () { wave.classList.remove("anim"); playBtn.classList.remove("playing"); }
      });
      setTimeout(function () { wave.classList.remove("anim"); playBtn.classList.remove("playing"); }, 4000);
    }

    playBtn.onclick = function () { play(state.rate); };

    function focusAt(idx) {
      if (idx >= 0 && idx < boxEls.length) {
        boxEls[idx].focus();
        boxEls[idx].select();
      }
    }

    boxEls.forEach(function (box, idx) {
      box.addEventListener("input", function () {
        var v = box.value.replace(/[^a-zA-Z']/g, "");
        box.value = v.slice(-1);
        box.classList.remove("wrong", "correct");
        if (box.value && idx < boxEls.length - 1) focusAt(idx + 1);
        if (boxEls.every(function (b) { return b.value; })) setTimeout(check, 100);
      });
      box.addEventListener("keydown", function (e) {
        if (e.key === "Backspace" && !box.value && idx > 0) {
          e.preventDefault();
          boxEls[idx - 1].value = "";
          focusAt(idx - 1);
        } else if (e.key === "Enter") {
          e.preventDefault();
          check();
        } else if (e.key === "ArrowLeft" && idx > 0) {
          e.preventDefault(); focusAt(idx - 1);
        } else if (e.key === "ArrowRight" && idx < boxEls.length - 1) {
          e.preventDefault(); focusAt(idx + 1);
        }
      });
      box.addEventListener("paste", function (e) {
        var text = (e.clipboardData || window.clipboardData).getData("text") || "";
        text = text.replace(/[^a-zA-Z']/g, "");
        if (text) {
          e.preventDefault();
          text.split("").forEach(function (ch, j) {
            if (boxEls[idx + j]) boxEls[idx + j].value = ch;
          });
          focusAt(Math.min(idx + text.length, boxEls.length - 1));
          if (boxEls.every(function (b) { return b.value; })) setTimeout(check, 100);
        }
      });
    });

    function showSolution() {
      boxEls.forEach(function (b, k) {
        b.value = word[k] || "";
        b.classList.add("hinted");
        b.classList.remove("wrong");
      });
      feedback.className = "feedback bad";
      feedback.innerHTML = "الإجابة: <span class='translit'>" + esc(word) + "</span>";
      showNext();
    }

    function showNext() {
      actions.innerHTML = '<button class="btn" id="nextWord">التالي ' + icon("arrow") + "</button>";
      $("#nextWord").onclick = advance;
    }

    function advance() {
      writingSession.i++;
      writingSession.attempts = 0;
      writingSession.solved = false;
      viewWriting();
    }

    function check() {
      if (s.solved) return;
      var typed = boxEls.map(function (b) { return b.value.toLowerCase(); }).join("");
      var target = word.toLowerCase();

      if (typed.length < target.length) {
        feedback.className = "feedback bad";
        feedback.textContent = "أكمل كل الحروف أولًا.";
        return;
      }

      if (typed === target) {
        s.solved = true;
        s.correct++;
        boxEls.forEach(function (b) { b.classList.remove("wrong"); b.classList.add("correct"); });
        feedback.className = "feedback ok";
        feedback.innerHTML = "صحيح! <span class='translit'>" + esc(word) + "</span>";
        markDone(s.level, "writing", word);
        award(5, "+5 نقاط");
        boxEls.forEach(function (b) { b.disabled = true; });
        showNext();
        var idx = s.i;
        setTimeout(function () {
          if (writingSession && writingSession.i === idx && writingSession.solved) advance();
        }, 1600);
      } else {
        s.attempts++;
        boxEls.forEach(function (b, k) {
          if (b.value.toLowerCase() !== target[k]) {
            b.classList.add("wrong");
            b.classList.add("shake");
            setTimeout(function () { b.classList.remove("shake"); }, 400);
          }
        });
        feedback.className = "feedback bad";
        if (s.attempts >= 2) {
          setTimeout(showSolution, 500);
          feedback.textContent = "قريبة… هذا هو الحل:";
        } else {
          feedback.textContent = "ليست صحيحة، جرّب مرة أخرى.";
        }
      }
    }

    $("#checkBtn").onclick = check;

    $$("[data-wact]", appEl).forEach(function (btn) {
      btn.onclick = function () {
        var act = btn.dataset.wact;
        if (act === "replay") play(state.rate);
        else if (act === "slow") play(Math.max(0.55, state.rate - 0.25));
        else if (act === "hint") {
          var first = boxEls.findIndex(function (b) { return !b.value; });
          if (first === -1) first = 0;
          boxEls[first].value = word[first];
          boxEls[first].classList.add("hinted");
          focusAt(first + 1);
        } else if (act === "kb") {
          $("#kb").classList.toggle("show");
          btn.classList.toggle("on");
        }
      };
    });

    $$("[data-key]", appEl).forEach(function (btn) {
      btn.onclick = function () {
        var key = btn.dataset.key;
        var idx = boxEls.findIndex(function (b) { return !b.value; });
        if (key === "back") {
          if (idx === -1) idx = boxEls.length - 1;
          else idx = Math.max(0, idx - 1);
          boxEls[idx].value = "";
          boxEls[idx].classList.remove("wrong", "hinted");
          focusAt(idx);
        } else if (idx !== -1) {
          boxEls[idx].value = key;
          focusAt(idx + 1);
          if (boxEls.every(function (b) { return b.value; })) setTimeout(check, 100);
        }
      };
    });

    if (window.matchMedia && window.matchMedia("(pointer: fine)").matches) {
      focusAt(0);
    }
    laterSpeak(function () { play(state.rate); }, 380);
  }

  /* ================= الاستماع ================= */
  var listeningSession = null;

  function ensureListening() {
    if (listeningSession && listeningSession.level === state.level) return listeningSession;
    var order = shuffle(D.listening[state.level].map(function (_, i) { return i; })).slice(0, 6);
    listeningSession = { level: state.level, order: order, i: 0, answered: false, correct: 0, picked: null };
    return listeningSession;
  }

  function listeningDone() {
    var s = listeningSession;
    render(
      '<section class="screen"><div class="practice" style="justify-content:center">' +
      '<div class="done-screen"><div class="emoji">🎧</div>' +
      "<h3>انتهت جلسة الاستماع</h3>" +
      "<p>أجبت بشكل صحيح على " + s.correct + " من " + s.order.length + " جمل.<br>أعد الجلسة لتسمع جملًا أخرى.</p>" +
      '<div class="done-actions">' +
      '<button class="btn" data-action="listening-restart">' + icon("refresh") + " جلسة جديدة</button>" +
      '<button class="btn ghost" data-go="/">الرئيسية</button>' +
      "</div></div></div></section>"
    );
  }

  function viewListening() {
    var s = ensureListening();
    if (s.i >= s.order.length) { listeningDone(); return; }

    var item = D.listening[s.level][s.order[s.i]];

    render(
      '<section class="screen">' +
      '<div class="screen-head">' +
      '<button class="back-btn" data-go="/" aria-label="رجوع">' + icon("arrow") + "</button>" +
      '<div><h2 class="screen-title">الاستماع</h2><p class="screen-sub">استمع للجملة ثم اختر المعنى الصحيح</p></div>' +
      '<div class="spacer"></div>' +
      '<button class="btn ghost small" data-action="listening-restart">' + icon("refresh") + " جلسة جديدة</button>" +
      "</div>" +

      '<div class="practice">' +
      '<div class="practice-top">' +
      '<span class="counter"><b>' + (s.i + 1) + "</b> / " + s.order.length + "</span>" +
      '<div class="mini-bar"><span style="width:' + Math.round((s.i / s.order.length) * 100) + '%"></span></div>' +
      '<div class="spacer"></div>' +
      '<span class="counter">✅ ' + s.correct + "</span>" +
      "</div>" +

      '<div class="practice-body" style="gap:22px">' +
      '<button class="orb" id="playAudio" aria-label="شغّل الصوت">' + icon("volume") + "</button>" +
      '<div class="wave" id="wave"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>' +
      '<div class="prompt-ar" style="max-width:600px">' + esc(item.q) + "</div>" +
      '<div class="options" style="width:min(560px,100%)" id="options">' +
      item.options.map(function (o, oi) {
        return '<button class="option" data-opt="' + oi + '"><span class="letter">' + "ABC"[oi] + "</span><span>" + esc(o) + "</span></button>";
      }).join("") +
      "</div>" +
      '<div class="hint-row">' +
      '<button class="tool" id="slowAudio">🐢 أبطأ</button>' +
      '<button class="tool" id="revealBtn">' + icon("globe") + " النص</button>" +
      "</div>" +
      '<div class="translation-box" id="reveal" hidden style="width:min(640px,100%);text-align:start">' +
      '<div class="tr-line en" style="direction:ltr;text-align:left;font-family:var(--font-read);font-size:17px">' + esc(item.en) + "</div>" +
      '<div class="tr-line">' + esc(item.ar) + "</div>" +
      "</div>" +
      '<div class="feedback" id="lfeedback"></div>' +
      '<div class="hint-row" id="lactions"></div>' +
      "</div></div>" +
      "</section>"
    );

    var wave = $("#wave");
    function play(rate) {
      wave.classList.add("anim");
      Speech.speak(item.en, {
        rate: rate,
        voice: state.voice,
        onend: function () { wave.classList.remove("anim"); }
      });
      setTimeout(function () { wave.classList.remove("anim"); }, 6000);
    }
    $("#playAudio").onclick = function () { play(state.rate); };
    $("#slowAudio").onclick = function () { play(Math.max(0.55, state.rate - 0.3)); };

    $("#revealBtn").onclick = function () {
      var r = $("#reveal");
      if (r.hasAttribute("hidden")) r.removeAttribute("hidden");
      else r.setAttribute("hidden", "");
    };

    function next() {
      listeningSession.i++;
      listeningSession.answered = false;
      listeningSession.picked = null;
      viewListening();
    }

    $$("#options .option", appEl).forEach(function (btn) {
      btn.onclick = function () {
        if (s.answered) return;
        s.answered = true;
        var oi = Number(btn.dataset.opt);
        var correct = oi === item.answer;
        $$("#options .option", appEl).forEach(function (o) {
          o.disabled = true;
          if (Number(o.dataset.opt) === item.answer) o.classList.add("correct");
        });
        if (!correct) btn.classList.add("wrong");

        var fb = $("#lfeedback");
        if (correct) {
          s.correct++;
          fb.className = "feedback ok";
          fb.textContent = "إجابة صحيحة! 🎉";
          markDone(s.level, "listening", String(s.order[s.i]));
          award(5, "+5 نقاط");
        } else {
          fb.className = "feedback bad";
          fb.textContent = "ليست الإجابة الصحيحة. الإجابة الصحيحة مظللة.";
        }
        $("#reveal").removeAttribute("hidden");
        $("#lactions").innerHTML = '<button class="btn" id="nextL">التالي ' + icon("arrow") + "</button>";
        $("#nextL").onclick = next;
      };
    });

    laterSpeak(function () { play(state.rate); }, 420);
  }

  /* ================= التكلم ================= */
  var speakingSession = null;
  var media = { recorder: null, stream: null, chunks: [], url: null };

  function stopMedia() {
    try {
      if (media.recorder && media.recorder.state === "recording") media.recorder.stop();
    } catch (e) {}
    try {
      if (media.stream) media.stream.getTracks().forEach(function (t) { t.stop(); });
    } catch (e) {}
  }

  function ensureSpeaking() {
    if (speakingSession && speakingSession.level === state.level) return speakingSession;
    var order = shuffle(D.speaking[state.level].map(function (_, i) { return i; })).slice(0, 6);
    speakingSession = { level: state.level, order: order, i: 0, score: null, passed: false };
    return speakingSession;
  }

  function speakDone() {
    var s = speakingSession;
    render(
      '<section class="screen"><div class="practice" style="justify-content:center">' +
      '<div class="done-screen"><div class="emoji">🎙️</div>' +
      "<h3>أحسنت! أنهيت جلسة التكلم</h3>" +
      "<p>تدرّبت على " + s.order.length + " جملة. أعد الجلسة لتحصل على جمل جديدة.<br>التكرار بصوت عالٍ هو أسرع طريق للطلاقة.</p>" +
      '<div class="done-actions">' +
      '<button class="btn" data-action="speaking-restart">' + icon("refresh") + " جلسة جديدة</button>" +
      '<button class="btn ghost" data-go="/">الرئيسية</button>' +
      "</div></div></div></section>"
    );
  }

  function viewSpeaking() {
    var s = ensureSpeaking();
    if (s.i >= s.order.length) { speakDone(); return; }

    var item = D.speaking[s.level][s.order[s.i]];
    var supported = Speech.recognitionSupported;

    render(
      '<section class="screen">' +
      '<div class="screen-head">' +
      '<button class="back-btn" data-go="/" aria-label="رجوع">' + icon("arrow") + "</button>" +
      '<div><h2 class="screen-title">التكلم</h2><p class="screen-sub">استمع للجملة، ثم قلها بصوتك</p></div>' +
      '<div class="spacer"></div>' +
      '<button class="btn ghost small" data-action="speaking-restart">' + icon("refresh") + " جلسة جديدة</button>" +
      "</div>" +

      '<div class="practice">' +
      '<div class="practice-top">' +
      '<span class="counter"><b>' + (s.i + 1) + "</b> / " + s.order.length + "</span>" +
      '<div class="mini-bar"><span style="width:' + Math.round((s.i / s.order.length) * 100) + '%"></span></div>' +
      '<div class="spacer"></div>' +
      '<span class="counter">🎯 ' + s.order.length + " جمل</span>" +
      "</div>" +

      '<div class="practice-body" style="gap:16px">' +
      '<div class="prompt-label">say this out loud</div>' +
      '<div class="prompt-en" id="target">' + esc(item.en) + "</div>" +
      '<div class="prompt-ar">' + esc(item.ar) + "</div>" +
      '<div class="voice-warn" style="max-width:600px;text-align:start">💡 ' + ar(item.tip) + "</div>" +

      '<div style="display:flex;gap:10px;align-items:center;margin-top:6px">' +
      '<button class="btn ghost small" id="playModel">' + icon("volume") + " استمع</button>" +
      '<button class="btn ghost small" id="playSlow">🐢 ببطء</button>' +
      "</div>" +

      '<button class="orb mic-orb" id="micBtn" style="margin-top:8px" aria-label="ابدأ التحدث">' + icon("mic") + "</button>" +
      '<div class="transcript" id="transcript">' + (supported ? "اضغط الميكروفون ثم اقرأ الجملة" : "التعرّف على الصوت غير مدعوم هنا — استخدم Chrome أو Edge") + "</div>" +

      '<div id="scoreWrap" style="display:none;flex-direction:column;align-items:center;gap:12px;width:100%">' +
      '<div class="score-ring" id="scoreRing"><b id="scoreNum">0%</b><small>مطابقة</small></div>' +
      '<div class="chips" id="chips"></div>' +
      '<div class="feedback" id="sFeedback"></div>' +
      "</div>" +

      '<div class="hint-row" id="sActions"></div>' +

      '<div class="card" id="fallback" style="display:none;max-width:520px;width:100%;margin-top:6px">' +
      '<p class="tiny muted" style="margin:0 0 10px">بديل: سجّل صوتك واسمع نفسك، ثم قارنه بالنطق الأصلي.</p>' +
      '<div style="display:flex;gap:8px;flex-wrap:wrap">' +
      '<button class="btn ghost small" id="recBtn">🎙️ سجّل صوتك</button>' +
      '<button class="btn ghost small" id="selfBtn">✅ قلتها بشكل صحيح</button>' +
      "</div>" +
      '<div id="recPlay" style="margin-top:10px"></div>' +
      "</div>" +
      "</div></div>" +
      "</section>"
    );

    function play(rate) {
      Speech.speak(item.en, { rate: rate, voice: state.voice });
    }
    $("#playModel").onclick = function () { play(Math.max(0.7, state.rate - 0.05)); };
    $("#playSlow").onclick = function () { play(Math.max(0.55, state.rate - 0.3)); };

    function showNext() {
      $("#sActions").innerHTML = '<button class="btn" id="nextS">التالي ' + icon("arrow") + "</button>";
      $("#nextS").onclick = function () {
        speakingSession.i++;
        speakingSession.score = null;
        speakingSession.passed = false;
        viewSpeaking();
      };
    }

    function success() {
      if (s.passed) return;
      s.passed = true;
      markDone(s.level, "speaking", String(s.order[s.i]));
      award(8, "نطق جيد! +8 نقاط");
      showNext();
    }

    function applyScore(text) {
      var res = scoreSpeech(item.en, text);
      s.score = res.score;
      var ring = $("#scoreRing");
      var color = res.score >= 80 ? "#46d39a" : res.score >= 55 ? "#f5b451" : "#ff6b81";
      ring.style.setProperty("--deg", (res.score * 3.6) + "deg");
      ring.style.setProperty("--ringc", color);
      $("#scoreNum").textContent = res.score + "%";
      $("#chips").innerHTML = res.chips.map(function (c) {
        return '<span class="chip-word ' + (c.ok ? "good" : "miss") + '">' + esc(c.word) + "</span>";
      }).join("");
      $("#scoreWrap").style.display = "flex";

      var fb = $("#sFeedback");
      if (res.score >= 80) {
        fb.className = "feedback ok";
        fb.textContent = "ممتاز! نطقك واضح جدًا 🎉";
        success();
      } else if (res.score >= 55) {
        fb.className = "feedback ok";
        fb.textContent = "جيد! انتبه للكلمات المشطوبة وحاول مرة أخرى.";
        $("#sActions").innerHTML = '<button class="btn ghost small" id="retryS">إعادة المحاولة</button><button class="btn small" id="nextS2">تخطَّ</button>';
        $("#retryS").onclick = startMic;
        $("#nextS2").onclick = function () {
          speakingSession.i++; speakingSession.score = null; viewSpeaking();
        };
      } else {
        fb.className = "feedback bad";
        fb.textContent = "لم أفهم الجملة جيدًا. استمع للنموذج ثم أعد المحاولة بصوت أوضح.";
        $("#sActions").innerHTML = '<button class="btn ghost small" id="retryS">إعادة المحاولة</button><button class="btn small" id="nextS2">تخطَّ</button>';
        $("#retryS").onclick = startMic;
        $("#nextS2").onclick = function () {
          speakingSession.i++; speakingSession.score = null; viewSpeaking();
        };
      }
    }

    function startMic() {
      if (!supported) {
        $("#fallback").style.display = "block";
        return;
      }
      if (Speech.isRecognizing()) { Speech.stopRecognition(); return; }
      var mic = $("#micBtn");
      var tr = $("#transcript");
      mic.classList.add("listening");
      tr.textContent = "أستمع إليك…";

      Speech.listen({
        onInterim: function (t) { tr.textContent = t; },
        onResult: function (t) {
          tr.textContent = t;
          applyScore(t);
        },
        onError: function (err) {
          mic.classList.remove("listening");
          var msg = "تعذّر استخدام الميكروفون.";
          if (err === "not-allowed" || err === "service-not-allowed") msg = "لم يُسمح بالوصول إلى الميكروفون. اسمح به من إعدادات المتصفح.";
          else if (err === "no-speech") msg = "لم أسمع صوتًا. اقترب من الميكروفون وحاول مجددًا.";
          else if (err === "network") msg = "التعرّف على الصوت يحتاج اتصالًا بالإنترنت في هذه النسخة.";
          tr.textContent = msg;
          $("#fallback").style.display = "block";
          toast(msg);
        },
        onEnd: function () {
          mic.classList.remove("listening");
          if (!s.score && tr.textContent === "أستمع إليك…") tr.textContent = "لم أسمع شيئًا — جرّب مرة أخرى";
        }
      });
    }

    $("#micBtn").onclick = startMic;

    $("#recBtn").onclick = function () {
      var btn = $("#recBtn");
      if (media.recorder && media.recorder.state === "recording") {
        media.recorder.stop();
        btn.textContent = "🎙️ سجّل صوتك";
        return;
      }
      if (!navigator.mediaDevices || !window.MediaRecorder) {
        toast("التسجيل غير مدعوم في هذا المتصفح");
        return;
      }
      navigator.mediaDevices.getUserMedia({ audio: true }).then(function (stream) {
        media.stream = stream;
        media.chunks = [];
        media.recorder = new MediaRecorder(stream);
        media.recorder.ondataavailable = function (e) { if (e.data.size) media.chunks.push(e.data); };
        media.recorder.onstop = function () {
          var blob = new Blob(media.chunks, { type: "audio/webm" });
          if (media.url) URL.revokeObjectURL(media.url);
          media.url = URL.createObjectURL(blob);
          var rp = $("#recPlay");
          if (rp) rp.innerHTML = '<audio controls src="' + media.url + '" style="width:100%"></audio>';
          stream.getTracks().forEach(function (t) { t.stop(); });
        };
        media.recorder.start();
        btn.textContent = "⏹️ أوقف التسجيل";
      }).catch(function () {
        toast("لم يُسمح بالوصول إلى الميكروفون");
      });
    };

    $("#selfBtn").onclick = function () {
      var ring = $("#scoreRing");
      ring.style.setProperty("--deg", "360deg");
      ring.style.setProperty("--ringc", "#46d39a");
      $("#scoreNum").textContent = "✓";
      $("#scoreWrap").style.display = "flex";
      var fb = $("#sFeedback");
      fb.className = "feedback ok";
      fb.textContent = "أحسنت! استمر بالتدريب بصوت عالٍ.";
      success();
    };

    if (!supported) $("#fallback").style.display = "block";

    laterSpeak(function () { play(Math.max(0.7, state.rate - 0.05)); }, 420);
  }

  function lev(a, b) {
    if (a === b) return 0;
    var al = a.length, bl = b.length;
    if (!al) return bl;
    if (!bl) return al;
    var prev = new Array(bl + 1);
    for (var j = 0; j <= bl; j++) prev[j] = j;
    for (var i = 1; i <= al; i++) {
      var cur = [i];
      for (var k = 1; k <= bl; k++) {
        var cost = a[i - 1] === b[k - 1] ? 0 : 1;
        cur[k] = Math.min(prev[k] + 1, cur[k - 1] + 1, prev[k - 1] + cost);
      }
      prev = cur;
    }
    return prev[bl];
  }

  function normalizeSpeech(s) {
    return String(s || "")
      .toLowerCase()
      .replace(/[’']/g, "")
      .replace(/[^a-z0-9\s]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function scoreSpeech(target, said) {
    var T = normalizeSpeech(target).split(" ").filter(Boolean);
    var S = normalizeSpeech(said).split(" ").filter(Boolean);
    var used = new Array(S.length).fill(false);
    var chips = [];
    var matched = 0;

    T.forEach(function (tw) {
      var found = -1;
      for (var j = 0; j < S.length; j++) {
        if (used[j]) continue;
        if (S[j] === tw || (tw.length > 3 && S[j].length > 3 && lev(S[j], tw) <= 1)) { found = j; break; }
      }
      if (found >= 0) { used[found] = true; matched++; chips.push({ word: tw, ok: true }); }
      else chips.push({ word: tw, ok: false });
    });

    var score = T.length ? Math.round((matched / T.length) * 100) : 0;
    return { score: score, chips: chips };
  }

  /* ================= مفرداتي ================= */
  function viewWords() {
    var words = state.saved.slice().reverse();

    var body;
    if (!words.length) {
      body =
        '<div class="empty"><div class="big">📖</div>' +
        "<p>لم تحفظ أي كلمة بعد.<br>افتح قطعة قراءة واضغط على أي كلمة، ثم «أضف إلى مفرداتي».</p>" +
        '<button class="btn" data-go="/reading">' + icon("book") + " اذهب إلى القراءة</button></div>";
    } else {
      body = '<div class="wb-grid">' + words.map(function (w) {
        var info = lookup(w);
        return '<div class="wb-card"><div class="en">' + esc(w) + '</div><div class="ar">' + esc(info.ar) + "</div>" +
          '<div class="acts"><button class="mini-act" data-speak="' + esc(w) + '">🔊 استمع</button>' +
          '<button class="mini-act" data-unsave="' + esc(w) + '">إزالة</button></div></div>';
      }).join("") + "</div>";
    }

    render(
      '<section class="screen">' +
      '<div class="screen-head">' +
      '<button class="back-btn" data-go="/" aria-label="رجوع">' + icon("arrow") + "</button>" +
      "<div><h2 class=\"screen-title\">مفرداتي</h2><p class=\"screen-sub\">" + state.saved.length + " كلمة محفوظة على هذا الجهاز</p></div>" +
      '<div class="spacer"></div>' +
      (words.length ? '<button class="btn ghost small" data-speak-all="1">' + icon("volume") + " استمع للكل</button>" : "") +
      "</div>" +
      '<div class="card">' + body + "</div>" +
      "</section>"
    );

    $$("[data-unsave]", appEl).forEach(function (btn) {
      btn.onclick = function () {
        var w = btn.dataset.unsave;
        state.saved = state.saved.filter(function (x) { return x !== w; });
        saveState();
        updateStats();
        viewWords();
        toast("أُزيلت الكلمة");
      };
    });

    var allBtn = $("[data-speak-all]", appEl);
    if (allBtn) allBtn.onclick = function () {
      Speech.speak(words.join(", "), { rate: 0.8, voice: state.voice });
    };
  }

  /* ================= أحداث عامة ================= */
  function setLevel(lvl) {
    if (LEVELS.indexOf(lvl) === -1 || lvl === state.level) return;
    state.level = lvl;
    writingSession = null;
    listeningSession = null;
    speakingSession = null;
    saveState();
    updateStats();
    toast("المستوى: " + levelInfo(lvl).name + " (" + lvl + ")");
    route();
  }

  document.addEventListener("click", function (e) {
    var goEl = e.target.closest("[data-go]");
    if (goEl) {
      e.preventDefault();
      go(goEl.dataset.go);
      return;
    }

    var levelEl = e.target.closest("[data-level]");
    if (levelEl) {
      setLevel(levelEl.dataset.level);
      return;
    }

    var openEl = e.target.closest("[data-open]");
    if (openEl) {
      go("/reading/" + openEl.dataset.open);
      return;
    }

    var genEl = e.target.closest("[data-generate]");
    if (genEl) {
      var g = generatePassage(state.level);
      gens.set(g.id, g);
      go("/reading/" + g.id);
      return;
    }

    var wordEl = e.target.closest(".word");
    if (wordEl) {
      openWordSheet(wordEl.dataset.word);
      return;
    }

    var speakEl = e.target.closest("[data-speak]");
    if (speakEl) {
      Speech.speak(speakEl.dataset.speak, { rate: 0.9, voice: state.voice });
      return;
    }

    var saveEl = e.target.closest("[data-save]");
    if (saveEl) {
      var w = saveEl.dataset.save.toLowerCase();
      if (state.saved.indexOf(w) === -1) {
        state.saved.push(w);
        saveState();
        updateStats();
        toast("أُضيفت إلى مفرداتي ✅");
        $$(".word").forEach(function (el) {
          if (String(el.dataset.word).toLowerCase() === w) el.classList.add("saved");
        });
      } else {
        toast("الكلمة موجودة في مفرداتك بالفعل");
      }
      return;
    }

    var actionEl = e.target.closest("[data-action]");
    if (actionEl) {
      var act = actionEl.dataset.action;
      if (act === "writing-restart") { writingSession = null; viewWriting(); }
      else if (act === "listening-restart") { listeningSession = null; viewListening(); }
      else if (act === "speaking-restart") { speakingSession = null; viewSpeaking(); }
      return;
    }
  });

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeSheet();
    if ((e.key === "Enter" || e.key === " ") && document.activeElement) {
      var el = document.activeElement;
      if (el.matches("[data-go]") || el.matches("[data-open]") || el.matches("[data-generate]")) {
        e.preventDefault();
        el.click();
      }
    }
  });

  document.getElementById("settingsBtn").addEventListener("click", openSettings);

  window.addEventListener("hashchange", function () {
    route();
  });

  /* ================= بدء التشغيل ================= */
  Speech.setVoice(state.voice);
  updateStats();
  renderNav();
  route();
})();

