/* =========================================================
   قطع القراءة المتدرجة + أسئلة الفهم
   كل قطعة: عنوان، نصوص الجمل، ترجمة كل جملة، أسئلة
   ========================================================= */
window.DATA = window.DATA || {};

DATA.reading = [
  /* ================= A1 ================= */
  {
    id: "a1-morning",
    level: "A1",
    title: "My Morning",
    titleAr: "صباحي",
    minutes: 2,
    sentences: [
      "My name is Sara. I am twelve years old.",
      "Every morning, I wake up at seven o'clock.",
      "I wash my face and eat breakfast with my family.",
      "I drink milk and eat bread and cheese.",
      "Then I go to school with my friend Lina.",
      "School starts at eight o'clock.",
      "I like my morning because it is quiet and happy."
    ],
    translation: [
      "اسمي سارة. عمري اثنا عشر عامًا.",
      "كل صباح، أستيقظ في الساعة السابعة.",
      "أغسل وجهي وأتناول الفطور مع عائلتي.",
      "أشرب الحليب وآكل الخبز والجبن.",
      "ثم أذهب إلى المدرسة مع صديقتي لينا.",
      "تبدأ المدرسة في الساعة الثامنة.",
      "أحب صباحي لأنه هادئ وسعيد."
    ],
    questions: [
      {
        q: "في أي ساعة تستيقظ سارة؟",
        options: ["السابعة", "الثامنة", "السادسة"],
        answer: 0
      },
      {
        q: "مع من تذهب سارة إلى المدرسة؟",
        options: ["مع أمها", "مع صديقتها لينا", "وحدها"],
        answer: 1
      }
    ]
  },
  {
    id: "a1-market",
    level: "A1",
    title: "At the Market",
    titleAr: "في السوق",
    minutes: 2,
    sentences: [
      "On Friday, I go to the market with my mother.",
      "The market is near our house.",
      "We buy apples, bananas, and oranges.",
      "My mother buys fresh bread and eggs.",
      "The prices are good, and the people are friendly.",
      "I carry one bag, and my mother carries two bags.",
      "We go home and cook a big lunch."
    ],
    translation: [
      "يوم الجمعة، أذهب إلى السوق مع أمي.",
      "السوق قريب من بيتنا.",
      "نشتري التفاح والموز والبرتقال.",
      "تشتري أمي خبزًا طازجًا وبيضًا.",
      "الأسعار جيدة والناس ودودون.",
      "أحمل حقيبة واحدة، وأمي تحمل حقيبتين.",
      "نعود إلى البيت ونطبخ غداءً كبيرًا."
    ],
    questions: [
      {
        q: "ماذا تشتري الأم؟",
        options: ["خبزًا وبيضًا", "سمكًا وأرزًا", "قهوة وشايًا"],
        answer: 0
      },
      {
        q: "كم حقيبة يحمل الولد؟",
        options: ["حقيبتين", "ثلاث حقائب", "حقيبة واحدة"],
        answer: 2
      }
    ]
  },
  {
    id: "a1-room",
    level: "A1",
    title: "My Small Room",
    titleAr: "غرفتي الصغيرة",
    minutes: 2,
    sentences: [
      "I have a small room in my house.",
      "There is a bed, a desk, and a window in it.",
      "My books are on the desk.",
      "My bag is under the bed.",
      "I sit at my desk and read every evening.",
      "I open the window because I like fresh air.",
      "My room is simple, but I love it."
    ],
    translation: [
      "لديّ غرفة صغيرة في بيتي.",
      "فيها سرير ومكتب ونافذة.",
      "كتبي على المكتب.",
      "حقيبتي تحت السرير.",
      "أجلس على مكتبي وأقرأ كل مساء.",
      "أفتح النافذة لأنني أحب الهواء الطازج.",
      "غرفتي بسيطة، لكنني أحبها."
    ],
    questions: [
      {
        q: "أين كتابات الولد؟",
        options: ["تحت السرير", "على المكتب", "على النافذة"],
        answer: 1
      }
    ]
  },

  /* ================= A2 ================= */
  {
    id: "a2-trip",
    level: "A2",
    title: "A Trip to the City",
    titleAr: "رحلة إلى المدينة",
    minutes: 3,
    sentences: [
      "Last month, my brother and I traveled to the city by bus.",
      "The trip took two hours, but the road was beautiful.",
      "We visited a large museum and saw old pictures.",
      "After that, we ate lunch in a small restaurant near the river.",
      "The food was delicious and not expensive.",
      "In the evening, we walked around the market and bought gifts for our family.",
      "We returned home late, tired but very happy."
    ],
    translation: [
      "الشهر الماضي، سافرتُ أنا وأخي إلى المدينة بالباص.",
      "استغرقت الرحلة ساعتين، لكن الطريق كان جميلًا.",
      "زرنا متحفًا كبيرًا ورأينا صورًا قديمة.",
      "بعد ذلك، تناولنا الغداء في مطعم صغير قرب النهر.",
      "كان الطعام لذيذًا وغير مكلف.",
      "في المساء، تمشينا في السوق واشترينا هدايا لعائلتنا.",
      "عدنا إلى البيت متأخرين، متعبين لكن سعداء جدًا."
    ],
    questions: [
      {
        q: "كيف سافر الكاتب وأخوه؟",
        options: ["بالقطار", "بالسيارة", "بالباص"],
        answer: 2
      },
      {
        q: "أين تناولوا الغداء؟",
        options: ["في مطعم قرب النهر", "في المتحف", "في البيت"],
        answer: 0
      }
    ]
  },
  {
    id: "a2-neighbor",
    level: "A2",
    title: "The New Neighbor",
    titleAr: "الجار الجديد",
    minutes: 3,
    sentences: [
      "A new family moved into the house next to ours last week.",
      "They have a son called Adam, and he is the same age as me.",
      "On Saturday, I invited him to play football in the park.",
      "At first, he was quiet because he did not know anyone.",
      "After an hour, we were laughing and talking about school.",
      "Now Adam is my best friend, and we walk to school together every day.",
      "I am glad that his family chose our street."
    ],
    translation: [
      "انتقلت عائلة جديدة إلى البيت المجاور لنا الأسبوع الماضي.",
      "لديهم ابن اسمه آدم، وهو في عمري نفسه.",
      "يوم السبت، دعوته للعب كرة القدم في الحديقة.",
      "في البداية كان هادئًا لأنه لم يعرف أحدًا.",
      "بعد ساعة، كنا نضحك ونتحدث عن المدرسة.",
      "الآن آدم أفضل أصدقائي، ونمشي إلى المدرسة معًا كل يوم.",
      "أنا سعيد لأن عائلته اختارت شارعنا."
    ],
    questions: [
      {
        q: "لماذا كان آدم هادئًا في البداية؟",
        options: ["لأنه كان متعبًا", "لأنه لم يعرف أحدًا", "لأنه لا يحب كرة القدم"],
        answer: 1
      },
      {
        q: "ما العلاقة بين الكاتب وآدم الآن؟",
        options: ["جاران فقط", "أفضل صديقين", "أخوان"],
        answer: 1
      }
    ]
  },
  {
    id: "a2-job",
    level: "A2",
    title: "My First Job",
    titleAr: "أول وظيفة لي",
    minutes: 3,
    sentences: [
      "Two years ago, I found my first job in a small coffee shop.",
      "I worked four hours every afternoon after school.",
      "At the beginning, I was slow and made many mistakes.",
      "My manager was patient, and she taught me how to make good coffee.",
      "I learned to speak to customers politely and to work with a team.",
      "The money was not a lot, but I saved some of it for a new phone.",
      "That job taught me more than any lesson at school."
    ],
    translation: [
      "قبل عامين، وجدت أول وظيفة لي في مقهى صغير.",
      "كنت أعمل أربع ساعات كل يوم بعد المدرسة.",
      "في البداية كنت بطيئًا وارتكبت أخطاء كثيرة.",
      "كانت مديرتي صبورة، وعلّمتني كيف أحضّر قهوة جيدة.",
      "تعلمت أن أتحدث مع الزبائن بأدب وأن أعمل ضمن فريق.",
      "لم يكن المال كثيرًا، لكنني وفّرت جزءًا منه لهاتف جديد.",
      "علّمتني تلك الوظيفة أكثر من أي درس في المدرسة."
    ],
    questions: [
      {
        q: "أين كانت أول وظيفة للكاتب؟",
        options: ["في مطعم", "في مقهى صغير", "في متجر ملابس"],
        answer: 1
      },
      {
        q: "ماذا فعل الكاتب بالمال؟",
        options: ["وفّر جزءًا منه لهاتف", "اشترى سيارة", "أعطاه لعائلته"],
        answer: 0
      }
    ]
  },

  /* ================= B1 ================= */
  {
    id: "b1-language",
    level: "B1",
    title: "Learning a Language",
    titleAr: "تعلّم لغة",
    minutes: 4,
    sentences: [
      "When I started learning English, I thought that grammar was the most important thing.",
      "I spent hours memorizing rules, but I could not speak a single sentence without fear.",
      "Everything changed when I began to read simple stories and listen to short podcasts every day.",
      "Although I did not understand every word, I slowly became comfortable with the sounds of the language.",
      "Now I write down five new words each morning and try to use them before the day ends.",
      "Mistakes are still part of my routine, but they no longer stop me from speaking.",
      "The secret, I believe, is not talent but daily practice."
    ],
    translation: [
      "عندما بدأت تعلّم الإنجليزية، ظننت أن القواعد هي الشيء الأهم.",
      "أمضيت ساعات في حفظ القواعد، لكنني لم أستطع قول جملة واحدة دون خوف.",
      "تغيّر كل شيء عندما بدأت أقرأ قصصًا بسيطة وأستمع إلى بودكاست قصير كل يوم.",
      "على الرغم من أنني لم أفهم كل كلمة، أصبحت تدريجيًا مرتاحًا مع أصوات اللغة.",
      "الآن أكتب خمس كلمات جديدة كل صباح وأحاول استخدامها قبل نهاية اليوم.",
      "الأخطاء ما زالت جزءًا من روتيني، لكنها لم تعد تمنعني من الكلام.",
      "السر، كما أعتقد، ليس الموهبة بل التدريب اليومي."
    ],
    questions: [
      {
        q: "ما الذي اعتقده الكاتب في البداية؟",
        options: [
          "أن القواعد هي الأهم",
          "أن الاستماع هو الأهم",
          "أن السفر هو الأهم"
        ],
        answer: 0
      },
      {
        q: "ماذا يفعل الكاتب الآن كل صباح؟",
        options: [
          "يحفظ عشر قواعد",
          "يكتب خمس كلمات جديدة",
          "يقرأ رواية كاملة"
        ],
        answer: 1
      }
    ]
  },
  {
    id: "b1-doctor",
    level: "B1",
    title: "The Village Doctor",
    titleAr: "طبيبة القرية",
    minutes: 4,
    sentences: [
      "Dr. Hana has worked in our village for almost twenty years.",
      "She opens her small clinic at eight every morning, even on Fridays.",
      "People trust her because she listens carefully before she gives any advice.",
      "During the winter, when the roads are wet, she visits old patients on foot.",
      "She charges very little, and she never refuses anyone who cannot pay.",
      "Last year, the town wanted to build a larger hospital and asked her to manage it.",
      "She refused politely, explaining that her place was with the people of the village."
    ],
    translation: [
      "تعمل الدكتورة هناء في قريتنا منذ ما يقارب عشرين عامًا.",
      "تفتح عيادتها الصغيرة في الثامنة كل صباح، حتى أيام الجمعة.",
      "يثق بها الناس لأنها تستمع باهتمام قبل أن تقدّم أي نصيحة.",
      "خلال الشتاء، حين تكون الطرق مبللة، تزور المرضى المسنين سيرًا على الأقدام.",
      "تتقاضى مبلغًا قليلًا جدًا، ولا ترفض أبدًا من لا يستطيع الدفع.",
      "في العام الماضي، أرادت البلدة بناء مستشفى أكبر وطلبت منها إدارته.",
      "رفضت بأدب، موضحةً أن مكانها مع أهل القرية."
    ],
    questions: [
      {
        q: "لماذا يثق الناس بالدكتورة هناء؟",
        options: [
          "لأنها تستمع باهتمام قبل النصيحة",
          "لأن عيادتها كبيرة",
          "لأنها تفتح في المساء"
        ],
        answer: 0
      },
      {
        q: "لماذا رفضت إدارة المستشفى الجديد؟",
        options: [
          "لأن الراتب كان قليلًا",
          "لأن مكانها مع أهل القرية",
          "لأنها كانت مريضة"
        ],
        answer: 1
      }
    ]
  },

  /* ================= B2 ================= */
  {
    id: "b2-convenience",
    level: "B2",
    title: "The Cost of Convenience",
    titleAr: "ثمن الراحة",
    minutes: 5,
    sentences: [
      "It has become normal to order almost anything with a single tap on a screen.",
      "Convenience, however, is rarely free, even when the price seems small.",
      "Every delivery we request requires a vehicle, a driver, and a package that is thrown away afterwards.",
      "Had we paused to consider these hidden costs, we might have chosen to walk to the shop instead.",
      "The same pattern appears in the way we communicate: messages arrive instantly, yet conversations grow shorter.",
      "This is not an argument against technology, but a reminder that every benefit carries a cost.",
      "Perhaps the wisest approach is to ask what we gain, what we lose, and whether the trade is worth making."
    ],
    translation: [
      "أصبح من الطبيعي أن نطلب أي شيء تقريبًا بنقرة واحدة على الشاشة.",
      "غير أن الراحة نادرًا ما تكون مجانية، حتى عندما يبدو الثمن صغيرًا.",
      "كل عملية توصيل نطلبها تتطلب مركبة وسائقًا وطردًا يُرمى بعدها.",
      "لو توقفنا للتفكير في هذه التكاليف الخفية، لربما اخترنا المشي إلى المتجر بدلًا من ذلك.",
      "النمط نفسه يظهر في طريقة تواصلنا: الرسائل تصل فورًا، لكن المحادثات تصبح أقصر.",
      "هذه ليست حجة ضد التقنية، بل تذكير بأن كل فائدة تحمل تكلفة.",
      "ربما يكون النهج الأحكم هو السؤال: ماذا نكسب، وماذا نخسر، وهل تستحق المقايضة؟"
    ],
    questions: [
      {
        q: "ما الفكرة الرئيسية للكاتب؟",
        options: [
          "أن التقنية يجب أن تُمنع",
          "أن لكل فائدة تكلفة خفية",
          "أن التوصيل أرخص من المشي"
        ],
        answer: 1
      },
      {
        q: "ماذا يعني الكاتب بعبارة «every benefit carries a cost»؟",
        options: [
          "كل مكسب له ثمن",
          "التقنية غالية الثمن",
          "الرسائل القصيرة أفضل"
        ],
        answer: 0
      }
    ]
  },
  {
    id: "b2-cars",
    level: "B2",
    title: "A City Without Cars",
    titleAr: "مدينة بلا سيارات",
    minutes: 5,
    sentences: [
      "For decades, city planners assumed that wider roads would reduce traffic.",
      "The evidence now suggests the opposite: more space for cars tends to attract more cars.",
      "Several European cities have therefore decided to remove vehicles from their historic centers.",
      "The results have surprised even their supporters, with cleaner air and busier shops.",
      "Critics argue that such changes punish people who live far from public transport.",
      "A fair policy, they say, must offer reliable alternatives before it restricts anything.",
      "What is clear is that the debate is no longer about whether to change, but about how quickly."
    ],
    translation: [
      "لعقود، افترض مخططو المدن أن توسيع الطرق سيقلل الازدحام.",
      "تشير الأدلة الآن إلى العكس: المزيد من المساحة للسيارات يجذب مزيدًا من السيارات.",
      "لذلك قررت عدة مدن أوروبية إزالة المركبات من مراكزها التاريخية.",
      "فاجأت النتائج حتى مؤيديها، بهواء أنظف ومتاجر أكثر ازدحامًا بالزبائن.",
      "يرى النقاد أن مثل هذه التغييرات تعاقب من يعيشون بعيدًا عن النقل العام.",
      "يقولون إن السياسة العادلة يجب أن تقدّم بدائل موثوقة قبل أن تقيّد أي شيء.",
      "الواضح أن النقاش لم يعد حول ما إذا كان يجب التغيير، بل حول سرعته."
    ],
    questions: [
      {
        q: "ماذا كشفت الأدلة عن توسيع الطرق؟",
        options: [
          "أنه يقلل الازدحام",
          "أنه يجذب مزيدًا من السيارات",
          "أنه يحسّن النقل العام"
        ],
        answer: 1
      },
      {
        q: "ما شرط النقاد للسياسة العادلة؟",
        options: [
          "تقديم بدائل موثوقة قبل التقييد",
          "منع السيارات كليًا",
          "بناء طرق أوسع"
        ],
        answer: 0
      }
    ]
  }
];

/* ---------- عناوين قطع القراءة المولّدة ---------- */
DATA.genTitles = {
  A1: [
    ["A Normal Day", "يوم عادي"],
    ["My Week", "أسبوعي"],
    ["At Home", "في البيت"],
    ["A Simple Morning", "صباح بسيط"],
    ["My Small World", "عالمي الصغير"]
  ],
  A2: [
    ["A Weekend to Remember", "عطلة لا تُنسى"],
    ["A Day in the Past", "يوم من الماضي"],
    ["My Last Holiday", "عطلتي الأخيرة"],
    ["Something New", "شيء جديد"],
    ["A Short Adventure", "مغامرة قصيرة"]
  ],
  B1: [
    ["A Lesson I Learned", "درس تعلمته"],
    ["Something That Changed", "شيء تغيّر"],
    ["My Honest Opinion", "رأيي الصادق"],
    ["A Small Step Forward", "خطوة صغيرة إلى الأمام"],
    ["What Really Matters", "ما يهم حقًا"]
  ],
  B2: [
    ["A Question Worth Asking", "سؤال يستحق الطرح"],
    ["Beyond the Obvious", "أبعد من الظاهر"],
    ["The Hidden Trade-off", "المقايضة الخفية"],
    ["Weighing the Evidence", "موازنة الأدلة"],
    ["A Matter of Choice", "مسألة اختيار"]
  ]
};
