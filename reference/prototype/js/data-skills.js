/* =========================================================
   محتوى المهارات: الكتابة (إملاء) / الاستماع / التكلم
   + مولّد قطع القراءة
   ========================================================= */
window.DATA = window.DATA || {};

/* ---------------- الكتابة: كلمات الإملاء ---------------- */
DATA.writing = {
  A1: [
    ["water", "ماء"],
    ["bread", "خبز"],
    ["school", "مدرسة"],
    ["friend", "صديق"],
    ["family", "عائلة"],
    ["morning", "صباح"],
    ["house", "منزل"],
    ["happy", "سعيد"],
    ["book", "كتاب"],
    ["teacher", "مدرس"],
    ["apple", "تفاحة"],
    ["milk", "حليب"],
    ["window", "نافذة"],
    ["garden", "حديقة"],
    ["market", "سوق"],
    ["chair", "كرسي"],
    ["sister", "أخت"],
    ["yellow", "أصفر"],
    ["small", "صغير"],
    ["drink", "يشرب"],
    ["table", "طاولة"],
    ["clean", "نظيف"],
    ["night", "ليل"],
    ["cold", "بارد"],
    ["gift", "هدية"]
  ],
  A2: [
    ["breakfast", "فطور"],
    ["holiday", "عطلة"],
    ["neighbor", "جار"],
    ["weather", "طقس"],
    ["expensive", "غالي"],
    ["beautiful", "جميل"],
    ["listen", "يستمع"],
    ["travel", "يسافر"],
    ["money", "مال"],
    ["doctor", "طبيب"],
    ["question", "سؤال"],
    ["together", "معًا"],
    ["dinner", "عشاء"],
    ["airport", "مطار"],
    ["message", "رسالة"],
    ["practice", "يتدرب"],
    ["decide", "يقرر"],
    ["famous", "مشهور"],
    ["village", "قرية"],
    ["kitchen", "مطبخ"],
    ["delicious", "لذيذ"],
    ["invite", "يدعو"],
    ["quiet", "هادئ"],
    ["remember", "يتذكر"]
  ],
  B1: [
    ["improve", "يحسّن"],
    ["experience", "خبرة"],
    ["opinion", "رأي"],
    ["although", "على الرغم من أن"],
    ["environment", "بيئة"],
    ["opportunity", "فرصة"],
    ["achieve", "يحقق"],
    ["describe", "يصف"],
    ["culture", "ثقافة"],
    ["suggest", "يقترح"],
    ["advantage", "ميزة"],
    ["prepare", "يحضّر"],
    ["knowledge", "معرفة"],
    ["confident", "واثق"],
    ["community", "مجتمع"],
    ["technology", "تقنية"],
    ["reduce", "يقلل"],
    ["ordinary", "عادي"],
    ["discussion", "مناقشة"],
    ["apologize", "يعتذر"],
    ["decision", "قرار"],
    ["succeed", "ينجح"],
    ["patient", "صبور"],
    ["describe", "يصف"]
  ],
  B2: [
    ["consequence", "نتيجة / عاقبة"],
    ["assumption", "افتراض"],
    ["evidence", "دليل"],
    ["therefore", "لذلك"],
    ["reluctant", "متردد"],
    ["significant", "مهم"],
    ["perspective", "منظور"],
    ["justify", "يبرر"],
    ["inevitable", "لا مفر منه"],
    ["contradict", "يناقض"],
    ["emphasize", "يؤكد"],
    ["compromise", "تسوية"],
    ["sustain", "يستدام / يحافظ"],
    ["controversial", "مثير للجدل"],
    ["undermine", "يقوّض"],
    ["coherent", "متماسك"],
    ["comprehensive", "شامل"],
    ["anticipate", "يتوقع"],
    ["considerable", "كبير"],
    ["pursue", "يسعى إلى"],
    ["justify", "يبرر"],
    ["consequence", "عاقبة"]
  ]
};

/* ---------------- الاستماع ---------------- */
DATA.listening = {
  A1: [
    {
      en: "I drink coffee every morning.",
      ar: "أشرب القهوة كل صباح.",
      q: "ماذا يشرب المتحدث كل صباح؟",
      options: ["قهوة", "حليب", "شاي"],
      answer: 0
    },
    {
      en: "My sister goes to school at eight o'clock.",
      ar: "أختي تذهب إلى المدرسة في الثامنة.",
      q: "متى تذهب الأخت إلى المدرسة؟",
      options: ["السابعة", "الثامنة", "التاسعة"],
      answer: 1
    },
    {
      en: "We buy bread and cheese from the market.",
      ar: "نشتري الخبز والجبن من السوق.",
      q: "ماذا يشترون من السوق؟",
      options: ["خبزًا وجبنًا", "تفاحًا وموزًا", "سمكًا وأرزًا"],
      answer: 0
    },
    {
      en: "The weather is cold today.",
      ar: "الطقس بارد اليوم.",
      q: "كيف الطقس اليوم؟",
      options: ["حار", "بارد", "ممطر"],
      answer: 1
    },
    {
      en: "I have two brothers and one sister.",
      ar: "لديّ أخوان وأخت واحدة.",
      q: "كم أخًا لدى المتحدث؟",
      options: ["واحد", "اثنان", "ثلاثة"],
      answer: 1
    },
    {
      en: "She likes to read before she sleeps.",
      ar: "تحب القراءة قبل أن تنام.",
      q: "ماذا تحب أن تفعل قبل النوم؟",
      options: ["المشي", "القراءة", "الطبخ"],
      answer: 1
    },
    {
      en: "The bus leaves at half past seven.",
      ar: "الباص يغادر في السابعة والنصف.",
      q: "متى يغادر الباص؟",
      options: ["السابعة", "السابعة والنصف", "الثامنة والنصف"],
      answer: 1
    }
  ],
  A2: [
    {
      en: "Last weekend, I visited my grandmother in the village.",
      ar: "في عطلة نهاية الأسبوع الماضية، زرت جدتي في القرية.",
      q: "أين زار المتحدث جدته؟",
      options: ["في المدينة", "في القرية", "في المستشفى"],
      answer: 1
    },
    {
      en: "The train leaves at half past six.",
      ar: "القطار يغادر في السادسة والنصف.",
      q: "متى يغادر القطار؟",
      options: ["السادسة", "السادسة والنصف", "السابعة"],
      answer: 1
    },
    {
      en: "I forgot my phone at the office.",
      ar: "نسيت هاتفي في المكتب.",
      q: "ماذا نسي المتحدث وأين؟",
      options: ["محفظته في البيت", "هاتفه في المكتب", "مفتاحه في السيارة"],
      answer: 1
    },
    {
      en: "We stayed at home because it was raining.",
      ar: "بقينا في البيت لأن المطر كان ينزل.",
      q: "لماذا بقوا في البيت؟",
      options: ["لأنهم كانوا متعبين", "لأن المطر كان ينزل", "لأنهم مرضى"],
      answer: 1
    },
    {
      en: "He has worked in the hospital for five years.",
      ar: "يعمل في المستشفى منذ خمس سنوات.",
      q: "كم سنة يعمل في المستشفى؟",
      options: ["ثلاث", "خمس", "سبع"],
      answer: 1
    },
    {
      en: "The restaurant was full, so we ate at a small cafe.",
      ar: "كان المطعم ممتلئًا، فأكلنا في مقهى صغير.",
      q: "أين أكلوا؟",
      options: ["في المطعم", "في البيت", "في مقهى صغير"],
      answer: 2
    },
    {
      en: "Please bring your book and a pen to the class.",
      ar: "أحضر كتابك وقلمًا إلى الصف من فضلك.",
      q: "ماذا يجب أن يحضر الطالب؟",
      options: ["كتابًا وقلمًا", "حاسوبًا", "دفترًا فقط"],
      answer: 0
    }
  ],
  B1: [
    {
      en: "Although the exam was difficult, she passed it easily.",
      ar: "على الرغم من أن الامتحان كان صعبًا، نجحت فيه بسهولة.",
      q: "كيف كانت نتيجة الامتحان؟",
      options: ["رسبت فيه", "نجحت بسهولة", "لم تتقدم للامتحان"],
      answer: 1
    },
    {
      en: "I have been learning English for three years.",
      ar: "أتعلم الإنجليزية منذ ثلاث سنوات.",
      q: "منذ متى يتعلم المتحدث الإنجليزية؟",
      options: ["منذ سنة", "منذ ثلاث سنوات", "منذ خمس سنوات"],
      answer: 1
    },
    {
      en: "The meeting has been moved to Thursday afternoon.",
      ar: "تم تأجيل الاجتماع إلى ظهر يوم الخميس.",
      q: "إلى متى نُقل الاجتماع؟",
      options: ["إلى صباح الأربعاء", "إلى ظهر الخميس", "إلى مساء الجمعة"],
      answer: 1
    },
    {
      en: "If I had more time, I would read every day.",
      ar: "لو كان لديّ وقت أكثر، لقرأت كل يوم.",
      q: "ماذا سيفعل لو كان لديه وقت أكثر؟",
      options: ["سيسافر", "سيقرأ كل يوم", "سيعمل أكثر"],
      answer: 1
    },
    {
      en: "She apologized for arriving late to the interview.",
      ar: "اعتذرت عن وصولها متأخرة إلى المقابلة.",
      q: "لماذا اعتذرت؟",
      options: ["لأنها وصلت متأخرة", "لأنها نسيت الموعد", "لأنها رفضت الوظيفة"],
      answer: 0
    },
    {
      en: "The museum is worth visiting, especially in the morning.",
      ar: "المتحف يستحق الزيارة، خاصة في الصباح.",
      q: "متى يُفضل زيارة المتحف؟",
      options: ["في المساء", "في الصباح", "في الليل"],
      answer: 1
    },
    {
      en: "I would rather stay at home tonight than go out.",
      ar: "أفضل البقاء في البيت الليلة على الخروج.",
      q: "ماذا يفضل المتحدث؟",
      options: ["الخروج", "البقاء في البيت", "الذهاب إلى العمل"],
      answer: 1
    }
  ],
  B2: [
    {
      en: "The report suggests that the policy has failed to reduce traffic.",
      ar: "يشير التقرير إلى أن السياسة فشلت في تقليل الازدحام.",
      q: "ماذا يقول التقرير عن السياسة؟",
      options: ["أنها نجحت", "أنها فشلت في تقليل الازدحام", "أنها لم تُطبّق بعد"],
      answer: 1
    },
    {
      en: "Had we known about the delay, we would have taken an earlier train.",
      ar: "لو عرفنا بالتأخير، لأخذنا قطارًا أبكر.",
      q: "ماذا كانوا سيفعلون لو عرفوا بالتأخير؟",
      options: ["كانوا سينتظرون", "كانوا سيأخذون قطارًا أبكر", "كانوا سيلغون الرحلة"],
      answer: 1
    },
    {
      en: "The company claims the new system is more reliable than the old one.",
      ar: "تزعم الشركة أن النظام الجديد أكثر موثوقية من القديم.",
      q: "ماذا تزعم الشركة؟",
      options: ["أن النظام الجديد أرخص", "أن النظام الجديد أكثر موثوقية", "أن النظام القديم أفضل"],
      answer: 1
    },
    {
      en: "Despite considerable criticism, the project was approved.",
      ar: "على الرغم من الانتقادات الكبيرة، تمت الموافقة على المشروع.",
      q: "ما نتيجة المشروع؟",
      options: ["تمت الموافقة عليه", "تم إلغاؤه", "تم تأجيله"],
      answer: 0
    },
    {
      en: "Researchers argue that the evidence is far from conclusive.",
      ar: "يرى الباحثون أن الأدلة بعيدة عن أن تكون قاطعة.",
      q: "ما رأي الباحثين في الأدلة؟",
      options: ["أنها قاطعة", "أنها غير كافية", "أنها مزيفة"],
      answer: 1
    },
    {
      en: "It is unlikely that the agreement will be signed this week.",
      ar: "من غير المحتمل توقيع الاتفاق هذا الأسبوع.",
      q: "ما احتمال توقيع الاتفاق هذا الأسبوع؟",
      options: ["مؤكد", "غير محتمل", "تم توقيعه بالفعل"],
      answer: 1
    },
    {
      en: "The benefits of the change outweigh the risks, in my view.",
      ar: "في رأيي، فوائد التغيير تفوق مخاطره.",
      q: "ما رأي المتحدث في التغيير؟",
      options: ["فوائده تفوق مخاطره", "مخاطره أكبر", "لا رأي له"],
      answer: 0
    }
  ]
};

/* ---------------- التكلم ---------------- */
DATA.speaking = {
  A1: [
    {
      en: "Hello, my name is Sara.",
      ar: "مرحبًا، اسمي سارة.",
      tip: "انطق th في «the» بوضع طرف اللسان بين الأسنان."
    },
    {
      en: "I would like a cup of tea, please.",
      ar: "أريد كوب شاي من فضلك.",
      tip: "«would like» أنعم من «want» وأكثر أدبًا."
    },
    {
      en: "How much is this?",
      ar: "كم سعر هذا؟",
      tip: "ارفع نبرة الصوت في نهاية السؤال."
    },
    {
      en: "Where is the bus station?",
      ar: "أين محطة الباص؟",
      tip: "لا تنطق حرف e في «station»، بل /ˈsteɪ.ʃən/."
    },
    {
      en: "Thank you very much.",
      ar: "شكرًا جزيلًا.",
      tip: "انطق th في «Thank» بصوت مهموس."
    },
    {
      en: "I don't understand.",
      ar: "أنا لا أفهم.",
      tip: "«don't» تنطق /doʊnt/ بحرف t خفيف."
    },
    {
      en: "Can I have the menu, please?",
      ar: "هل يمكنني الحصول على قائمة الطعام من فضلك؟",
      tip: "«Can I» تنطق متصلة: /kəˈnaɪ/."
    },
    {
      en: "See you tomorrow.",
      ar: "أراك غدًا.",
      tip: "«tomorrow» التشديد على المقطع الثاني: /təˈmɒr.oʊ/."
    }
  ],
  A2: [
    {
      en: "Could you speak more slowly, please?",
      ar: "هل يمكنك أن تتحدث بشكل أبطأ من فضلك؟",
      tip: "«Could you» تنطق /kʊdʒuː/ متصلة."
    },
    {
      en: "I went to the market yesterday.",
      ar: "ذهبت إلى السوق أمس.",
      tip: "«went» فعل ماضٍ شاذ، لا تضف له ed."
    },
    {
      en: "What time does the train leave?",
      ar: "في أي ساعة يغادر القطار؟",
      tip: "في السؤال نستخدم does ثم الفعل بصيغة أساسية."
    },
    {
      en: "I'm looking for a small restaurant.",
      ar: "أبحث عن مطعم صغير.",
      tip: "«looking for» تنطق متصلة /ˈlʊk.ɪŋ.fɔːr/."
    },
    {
      en: "Can I pay by card?",
      ar: "هل يمكنني الدفع بالبطاقة؟",
      tip: "حرف a في «pay» طويل: /peɪ/."
    },
    {
      en: "I have been waiting for ten minutes.",
      ar: "أنتظر منذ عشر دقائق.",
      tip: "«been» تنطق /biːn/ وليست /ben/."
    },
    {
      en: "This is my first time here.",
      ar: "هذه أول مرة لي هنا.",
      tip: "«first» تنطق /fɜːrst/ بدون إشباع."
    },
    {
      en: "Would you like to join us?",
      ar: "هل تود الانضمام إلينا؟",
      tip: "«join» تنطق /dʒɔɪn/ بصوت j مثل «ج»."
    }
  ],
  B1: [
    {
      en: "In my opinion, learning a language takes daily practice.",
      ar: "في رأيي، تعلّم اللغة يتطلب تدريبًا يوميًا.",
      tip: "«opinion» التشديد على المقطع الثاني: /əˈpɪn.jən/."
    },
    {
      en: "I would rather stay at home tonight.",
      ar: "أفضل البقاء في البيت الليلة.",
      tip: "«would rather» يتبعها فعل بصيغته الأساسية."
    },
    {
      en: "Could you explain that again, please?",
      ar: "هل يمكنك شرح ذلك مرة أخرى من فضلك؟",
      tip: "«explain» التشديد على المقطع الثاني."
    },
    {
      en: "If I had more time, I would travel more.",
      ar: "لو كان لديّ وقت أكثر، لسافرت أكثر.",
      tip: "هذه حالة شرطية غير واقعية: had + would."
    },
    {
      en: "I'm not sure I agree with that.",
      ar: "لست متأكدًا أنني أوافق على ذلك.",
      tip: "«agree with» للتأييد، و«agree to» للموافقة على اقتراح."
    },
    {
      en: "The meeting has been postponed until Monday.",
      ar: "تم تأجيل الاجتماع حتى الاثنين.",
      tip: "«postponed» التشديد على المقطع الثاني."
    },
    {
      en: "I've been trying to improve my pronunciation.",
      ar: "أحاول تحسين نطقي.",
      tip: "«pronunciation» بلا حرف o بعد n: /prəˌnʌn.siˈeɪ.ʃən/."
    },
    {
      en: "That is a good point, but I see it differently.",
      ar: "هذه نقطة جيدة، لكنني أراها بشكل مختلف.",
      tip: "استخدم «but» بنبرة هادئة في النقاش."
    }
  ],
  B2: [
    {
      en: "I'd argue that the benefits outweigh the risks.",
      ar: "أرى أن الفوائد تفوق المخاطر.",
      tip: "«outweigh» التشديد على المقطع الأول."
    },
    {
      en: "Had I known earlier, I would have acted differently.",
      ar: "لو عرفت مبكرًا، لتصرفت بشكل مختلف.",
      tip: "«Had I known» بديل رسمي لـ «If I had known»."
    },
    {
      en: "There is little evidence to support that claim.",
      ar: "هناك أدلة قليلة تدعم ذلك الادعاء.",
      tip: "«evidence» غير معدودة: لا تقل evidences."
    },
    {
      en: "To what extent do you agree with this statement?",
      ar: "إلى أي مدى توافق على هذا التصريح؟",
      tip: "«extent» تنطق /ɪkˈstent/."
    },
    {
      en: "The project was completed despite considerable difficulties.",
      ar: "أُنجز المشروع على الرغم من صعوبات كبيرة.",
      tip: "«despite» يتبعها اسم أو -ing، وليس جملة كاملة."
    },
    {
      en: "It is worth considering the long-term consequences.",
      ar: "يجدر التفكير في العواقب طويلة الأمد.",
      tip: "«worth» يتبعها -ing: worth considering."
    },
    {
      en: "The evidence does not necessarily support that conclusion.",
      ar: "الأدلة لا تدعم بالضرورة ذلك الاستنتاج.",
      tip: "«necessarily» التشديد على المقطع الثالث."
    },
    {
      en: "We need to weigh the costs against the benefits.",
      ar: "علينا موازنة التكاليف مقابل الفوائد.",
      tip: "«weigh» تنطق /weɪ/ بحرف g صامت."
    }
  ]
};

/* ---------------- مولّد قطع القراءة ---------------- */
DATA.gen = {
  A1: {
    blocks: [
      {
        en: "My name is {name}. I am {age} years old.",
        ar: "اسمي {name}. عمري {age} عامًا.",
        slots: {
          name: [
            { en: "Sara", ar: "سارة" },
            { en: "Omar", ar: "عمر" },
            { en: "Lina", ar: "لينا" },
            { en: "Ali", ar: "علي" },
            { en: "Noor", ar: "نور" },
            { en: "Maya", ar: "مايا" },
            { en: "Yousef", ar: "يوسف" }
          ],
          age: [
            { en: "twelve", ar: "اثنا عشر" },
            { en: "fifteen", ar: "خمسة عشر" },
            { en: "twenty", ar: "عشرون" },
            { en: "fourteen", ar: "أربعة عشر" },
            { en: "seventeen", ar: "سبعة عشر" }
          ]
        }
      },
      {
        en: "Every morning, I {vp} {place}.",
        ar: "كل صباح، {vp} {place}.",
        slots: {
          vp: [
            { en: "drink coffee", ar: "أشرب القهوة" },
            { en: "eat breakfast", ar: "أتناول الفطور" },
            { en: "read a book", ar: "أقرأ كتابًا" },
            { en: "study English", ar: "أدرس الإنجليزية" },
            { en: "clean my room", ar: "أنظف غرفتي" },
            { en: "watch the news", ar: "أشاهد الأخبار" },
            { en: "cook lunch", ar: "أطبخ الغداء" }
          ],
          place: [
            { en: "at home", ar: "في البيت" },
            { en: "in the kitchen", ar: "في المطبخ" },
            { en: "near the window", ar: "قرب النافذة" },
            { en: "in my room", ar: "في غرفتي" }
          ]
        }
      },
      {
        en: "I usually feel {adj} after that.",
        ar: "عادةً أشعر بأنني {adj} بعد ذلك.",
        slots: {
          adj: [
            { en: "happy", ar: "سعيد" },
            { en: "tired", ar: "متعب" },
            { en: "hungry", ar: "جائع" },
            { en: "ready", ar: "مستعد" },
            { en: "calm", ar: "هادئ" }
          ]
        }
      },
      {
        en: "Then I go to {place2} with {person}.",
        ar: "ثم أذهب إلى {place2} مع {person}.",
        slots: {
          place2: [
            { en: "school", ar: "المدرسة" },
            { en: "work", ar: "العمل" },
            { en: "the market", ar: "السوق" },
            { en: "the park", ar: "الحديقة" },
            { en: "the gym", ar: "النادي" }
          ],
          person: [
            { en: "my friend", ar: "صديقي" },
            { en: "my sister", ar: "أختي" },
            { en: "my father", ar: "أبي" },
            { en: "my brother", ar: "أخي" },
            { en: "my mother", ar: "أمي" }
          ]
        }
      },
      {
        en: "In the evening, I {evening}.",
        ar: "في المساء، {evening}.",
        slots: {
          evening: [
            { en: "rest at home", ar: "أستريح في البيت" },
            { en: "call my family", ar: "أتصل بعائلتي" },
            { en: "plan the next day", ar: "أخطط لليوم التالي" },
            { en: "read a short story", ar: "أقرأ قصة قصيرة" }
          ]
        }
      },
      {
        en: "I like this day because it is {adj2}.",
        ar: "أحب هذا اليوم لأنه {adj2}.",
        slots: {
          adj2: [
            { en: "simple and quiet", ar: "بسيط وهادئ" },
            { en: "useful", ar: "مفيد" },
            { en: "full of small things", ar: "مليء بالأشياء الصغيرة" }
          ]
        }
      }
    ]
  },

  A2: {
    blocks: [
      {
        en: "Last {day}, I {vp} with {person}.",
        ar: "يوم {day} الماضي، {vp} مع {person}.",
        slots: {
          day: [
            { en: "Friday", ar: "الجمعة" },
            { en: "Saturday", ar: "السبت" },
            { en: "Sunday", ar: "الأحد" }
          ],
          vp: [
            { en: "visited a museum", ar: "زرت متحفًا" },
            { en: "walked in the old market", ar: "تمشيت في السوق القديم" },
            { en: "had lunch in a small restaurant", ar: "تناولت الغداء في مطعم صغير" },
            { en: "met an old friend", ar: "التقيت صديقًا قديمًا" },
            { en: "traveled to another city", ar: "سافرت إلى مدينة أخرى" }
          ],
          person: [
            { en: "my brother", ar: "أخي" },
            { en: "my cousin", ar: "ابن عمي" },
            { en: "my best friend", ar: "أفضل صديقي" },
            { en: "my sister", ar: "أختي" }
          ]
        }
      },
      {
        en: "We {vp2} for about two hours.",
        ar: "{vp2} لنحو ساعتين.",
        slots: {
          vp2: [
            { en: "walked around the river", ar: "تمشينا حول النهر" },
            { en: "talked about our school days", ar: "تحدثنا عن أيام المدرسة" },
            { en: "looked at old pictures", ar: "نظرنا إلى صور قديمة" },
            { en: "sat in a quiet cafe", ar: "جلسنا في مقهى هادئ" }
          ]
        }
      },
      {
        en: "The weather was {weather}, but we did not mind.",
        ar: "كان الطقس {weather}، لكننا لم نمانع.",
        slots: {
          weather: [
            { en: "cold", ar: "باردًا" },
            { en: "hot", ar: "حارًا" },
            { en: "windy", ar: "عاصفًا" },
            { en: "perfect", ar: "مثاليًا" }
          ]
        }
      },
      {
        en: "After that, we {vp3}.",
        ar: "بعد ذلك، {vp3}.",
        slots: {
          vp3: [
            { en: "ate a delicious dinner", ar: "تناولنا عشاءً لذيذًا" },
            { en: "bought a small gift for my mother", ar: "اشترينا هدية صغيرة لأمي" },
            { en: "took a bus back home", ar: "أخذنا باصًا للعودة إلى البيت" },
            { en: "watched the sunset", ar: "شاهدنا غروب الشمس" }
          ]
        }
      },
      {
        en: "I arrived home at {time} and felt {feeling}.",
        ar: "وصلت إلى البيت في {time} وشعرت بأنني {feeling}.",
        slots: {
          time: [
            { en: "eight o'clock", ar: "الثامنة" },
            { en: "nine o'clock", ar: "التاسعة" },
            { en: "half past ten", ar: "العاشرة والنصف" },
            { en: "midnight", ar: "منتصف الليل" }
          ],
          feeling: [
            { en: "exhausted but happy", ar: "مرهق لكن سعيد" },
            { en: "calm", ar: "هادئ" },
            { en: "ready for a new week", ar: "مستعد لأسبوع جديد" }
          ]
        }
      },
      {
        en: "It was a simple day, but I will remember it for a long time.",
        ar: "كان يومًا بسيطًا، لكنني سأتذكره طويلًا.",
        slots: {}
      }
    ]
  },

  B1: {
    blocks: [
      {
        en: "For the last few years, I have {vp}.",
        ar: "خلال السنوات القليلة الماضية، {vp}.",
        slots: {
          vp: [
            { en: "tried to learn something new", ar: "حاولت تعلّم شيء جديد" },
            { en: "worked on my English every day", ar: "عملت على إنجليزيتي كل يوم" },
            { en: "wanted to change one small habit", ar: "أردت تغيير عادة صغيرة" },
            { en: "been thinking about my future", ar: "كنت أفكر في مستقبلي" }
          ]
        }
      },
      {
        en: "At first, I {past} and made several mistakes.",
        ar: "في البداية، {past} وارتكبت عدة أخطاء.",
        slots: {
          past: [
            { en: "felt nervous", ar: "شعرت بالتوتر" },
            { en: "moved too quickly", ar: "تحركت بسرعة زائدة" },
            { en: "did not know where to start", ar: "لم أعرف من أين أبدأ" }
          ]
        }
      },
      {
        en: "However, I {vp2} because {reason}.",
        ar: "غير أنني {vp2} لأن {reason}.",
        slots: {
          vp2: [
            { en: "kept going", ar: "واصلت" },
            { en: "asked for help", ar: "طلبت المساعدة" },
            { en: "changed my method", ar: "غيّرت طريقتي" },
            { en: "started with small steps", ar: "بدأت بخطوات صغيرة" }
          ],
          reason: [
            { en: "I wanted real progress", ar: "أردت تقدمًا حقيقيًا" },
            { en: "I had a clear goal", ar: "كان لديّ هدف واضح" },
            { en: "I did not want to give up", ar: "لم أرد الاستسلام" }
          ]
        }
      },
      {
        en: "What helped me most was {thing}.",
        ar: "أكثر ما ساعدني هو {thing}.",
        slots: {
          thing: [
            { en: "daily practice", ar: "التدريب اليومي" },
            { en: "a patient friend", ar: "صديق صبور" },
            { en: "listening every morning", ar: "الاستماع كل صباح" },
            { en: "writing down new words", ar: "كتابة الكلمات الجديدة" }
          ]
        }
      },
      {
        en: "Now I {vp3}, and I feel {adj}.",
        ar: "الآن {vp3}، وأشعر بأنني {adj}.",
        slots: {
          vp3: [
            { en: "speak with more confidence", ar: "أتحدث بثقة أكبر" },
            { en: "understand films without subtitles", ar: "أفهم الأفلام دون ترجمة" },
            { en: "enjoy the process", ar: "أستمتع بالعملية" },
            { en: "read a little every night", ar: "أقرأ قليلًا كل ليلة" }
          ],
          adj: [
            { en: "more confident", ar: "أكثر ثقة" },
            { en: "proud of the progress", ar: "فخور بالتقدم" },
            { en: "less afraid of mistakes", ar: "أقل خوفًا من الأخطاء" }
          ]
        }
      },
      {
        en: "Progress is slow, but it is real.",
        ar: "التقدم بطيء، لكنه حقيقي.",
        slots: {}
      }
    ]
  },

  B2: {
    blocks: [
      {
        en: "It is often said that {claim}.",
        ar: "يُقال غالبًا إن {claim}.",
        slots: {
          claim: [
            { en: "technology has made our lives easier", ar: "التقنية جعلت حياتنا أسهل" },
            { en: "hard work always leads to success", ar: "العمل الجاد يؤدي دائمًا إلى النجاح" },
            { en: "cities should be designed for cars", ar: "المدن يجب أن تُصمم للسيارات" },
            { en: "learning a language requires talent", ar: "تعلّم اللغة يتطلب موهبة" }
          ]
        }
      },
      {
        en: "While this may be true in some cases, {counter}.",
        ar: "ورغم أن هذا قد يكون صحيحًا في بعض الحالات، فإن {counter}.",
        slots: {
          counter: [
            { en: "it ignores the hidden costs", ar: "هذا يتجاهل التكاليف الخفية" },
            { en: "the reality is more complicated", ar: "الواقع أكثر تعقيدًا" },
            { en: "the evidence tells a different story", ar: "الأدلة تحكي قصة مختلفة" },
            { en: "it is not true for everyone", ar: "هذا لا ينطبق على الجميع" }
          ]
        }
      },
      {
        en: "In my experience, {example}.",
        ar: "في تجربتي، {example}.",
        slots: {
          example: [
            { en: "small habits matter more than big plans", ar: "العادات الصغيرة أهم من الخطط الكبيرة" },
            { en: "people change when they see a real benefit", ar: "الناس يتغيرون عندما يرون فائدة حقيقية" },
            { en: "the cheapest option is rarely the best", ar: "الخيار الأرخص نادرًا ما يكون الأفضل" },
            { en: "time is the resource we ignore most", ar: "الوقت هو المورد الذي نهمله أكثر" }
          ]
        }
      },
      {
        en: "The main reason is that {reason}.",
        ar: "السبب الرئيسي هو أن {reason}.",
        slots: {
          reason: [
            { en: "short-term comfort hides long-term costs", ar: "الراحة قصيرة الأمد تخفي تكاليف طويلة الأمد" },
            { en: "we rarely measure what we lose", ar: "نادرًا ما نقيس ما نخسره" },
            { en: "change requires patience", ar: "التغيير يتطلب صبرًا" },
            { en: "good decisions need clear evidence", ar: "القرارات الجيدة تحتاج أدلة واضحة" }
          ]
        }
      },
      {
        en: "Therefore, I would argue that {conclusion}.",
        ar: "لذلك، أرى أن {conclusion}.",
        slots: {
          conclusion: [
            { en: "we should ask better questions", ar: "علينا طرح أسئلة أفضل" },
            { en: "a balanced approach is wiser than a strict one", ar: "النهج المتوازن أحكم من المتشدد" },
            { en: "the debate should focus on fairness", ar: "يجب أن يركز النقاش على الإنصاف" },
            { en: "small changes are better than none", ar: "التغييرات الصغيرة أفضل من لا شيء" }
          ]
        }
      },
      {
        en: "The question is not whether to change, but how.",
        ar: "السؤال ليس هل نتغير، بل كيف نتغير.",
        slots: {}
      }
    ]
  }
};

DATA.levels = [
  {
    id: "A1",
    name: "مبتدئ",
    en: "Beginner",
    desc: "جمل قصيرة وكلمات يومية أساسية"
  },
  {
    id: "A2",
    name: "أساسي",
    en: "Elementary",
    desc: "مواقف الحياة اليومية والماضي البسيط"
  },
  {
    id: "B1",
    name: "متوسط",
    en: "Intermediate",
    desc: "آراء وتجارب وجمل أطول"
  },
  {
    id: "B2",
    name: "متقدم",
    en: "Upper Intermediate",
    desc: "نقاش وأفكار مجردة ومفردات أدق"
  }
];
