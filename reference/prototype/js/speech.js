/* =========================================================
   طبقة الصوت: نطق الكلمات (TTS) والتعرّف على الكلام (STT)
   ========================================================= */
(function () {
  "use strict";

  var synth = window.speechSynthesis || null;
  var voices = [];
  var chosenVoice = null;
  var currentUtterance = null;
  var recog = null;

  function loadVoices() {
    if (!synth) return [];
    try {
      var all = synth.getVoices() || [];
      var en = all.filter(function (v) { return /^en(-|_|$)/i.test(v.lang || ""); });
      voices = en.length ? en : all;
    } catch (e) {
      voices = [];
    }
    return voices;
  }

  if (synth) {
    loadVoices();
    synth.addEventListener("voiceschanged", loadVoices);
    // بعض المتصفحات لا تشحن الأصوات قبل أول تفاعل
    setTimeout(loadVoices, 600);
  }

  function pickVoice(name) {
    var v = loadVoices();
    if (!v.length) return null;
    var wanted = name || chosenVoice;
    if (wanted) {
      var exact = v.find(function (x) { return x.name === wanted; });
      if (exact) return exact;
    }
    return (
      v.find(function (x) { return /en-US/i.test(x.lang) && /aria|jenny|zira|samantha|female|google us english/i.test(x.name); }) ||
      v.find(function (x) { return /en-US/i.test(x.lang); }) ||
      v.find(function (x) { return /^en/i.test(x.lang); }) ||
      v[0]
    );
  }

  var Speech = {
    supported: !!synth,

    getVoices: loadVoices,

    setVoice: function (name) { chosenVoice = name || null; },

    currentVoice: function () {
      var v = pickVoice();
      return v ? v.name : "";
    },

    /** نطق نص إنجليزي */
    speak: function (text, opts) {
      opts = opts || {};
      if (!synth) { if (opts.onend) opts.onend(); return; }
      try { synth.cancel(); } catch (e) {}

      var u = new SpeechSynthesisUtterance(String(text));
      u.lang = opts.lang || "en-US";
      u.rate = Math.min(1.5, Math.max(0.5, opts.rate || 1));
      u.pitch = opts.pitch || 1;
      var v = pickVoice(opts.voice);
      if (v) u.voice = v;
      u.onend = function () {
        currentUtterance = null;
        if (opts.onend) opts.onend();
      };
      u.onerror = function () {
        currentUtterance = null;
        if (opts.onerror) opts.onerror();
      };
      currentUtterance = u;
      try {
        synth.speak(u);
      } catch (e) {
        if (opts.onerror) opts.onerror();
      }
    },

    stop: function () {
      if (!synth) return;
      try { synth.cancel(); } catch (e) {}
      currentUtterance = null;
    },

    isSpeaking: function () {
      return !!(synth && (synth.speaking || synth.pending));
    },

    recognitionSupported: !!(window.SpeechRecognition || window.webkitSpeechRecognition),

    /**
     * الاستماع للميكروفون
     * handlers: {onInterim, onResult, onError, onEnd}
     */
    listen: function (handlers) {
      handlers = handlers || {};
      var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SR) {
        if (handlers.onError) handlers.onError("unsupported");
        return null;
      }
      Speech.stopRecognition();
      var rec = new SR();
      rec.lang = handlers.lang || "en-US";
      rec.interimResults = true;
      rec.continuous = false;
      rec.maxAlternatives = 1;

      var got = false;

      rec.onresult = function (ev) {
        var interim = "";
        var finalText = "";
        for (var i = ev.resultIndex; i < ev.results.length; i++) {
          var r = ev.results[i];
          if (r.isFinal) finalText += r[0].transcript;
          else interim += r[0].transcript;
        }
        if (interim && handlers.onInterim) handlers.onInterim(interim);
        if (finalText && !got) {
          got = true;
          if (handlers.onResult) handlers.onResult(finalText.trim());
        }
      };
      rec.onerror = function (e) {
        recog = null;
        if (handlers.onError) handlers.onError(e.error || "error");
      };
      rec.onend = function () {
        recog = null;
        if (handlers.onEnd) handlers.onEnd();
      };

      recog = rec;
      try {
        rec.start();
      } catch (e) {
        recog = null;
        if (handlers.onError) handlers.onError("start-failed");
        return null;
      }
      return rec;
    },

    stopRecognition: function () {
      if (recog) {
        try { recog.abort(); } catch (e) {}
        recog = null;
      }
    },

    isRecognizing: function () { return !!recog; }
  };

  window.Speech = Speech;
})();
