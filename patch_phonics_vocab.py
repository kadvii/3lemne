import json
import re

phonics_path = r"c:\Users\spn\Desktop\3lemne\backend\Alemni.Infrastructure\Seed\Data\phonics.json"
vocab_path = r"c:\Users\spn\Desktop\3lemne\backend\Alemni.Infrastructure\Seed\Data\vocab.json"

with open(phonics_path, "r", encoding="utf-8") as f:
    items = json.load(f)

with open(vocab_path, "r", encoding="utf-8") as f:
    vocab_data = json.load(f)

vocab_words = {entry["english"].lower().strip(): entry for entry in vocab_data}

# Also gather Arabic translations from minimal pairs
pair_translations = {}
for it in items:
    for mp in it["minimalPairs"]:
        w1 = mp["word1"].lower().strip()
        w2 = mp["word2"].lower().strip()
        if w1 not in pair_translations and mp.get("meaningAr1"):
            pair_translations[w1] = mp["meaningAr1"]
        if w2 not in pair_translations and mp.get("meaningAr2"):
            pair_translations[w2] = mp["meaningAr2"]

all_phonics_words = set()
for it in items:
    for w in it["exampleWords"]:
        all_phonics_words.add(w.lower().strip())
    for mp in it["minimalPairs"]:
        all_phonics_words.add(mp["word1"].lower().strip())
        all_phonics_words.add(mp["word2"].lower().strip())

missing = [w for w in all_phonics_words if w not in vocab_words]
print(f"Missing count: {len(missing)}")

# Known translations dictionary for the missing words
known_ar = {
    'peach': 'خوخ', 'ice': 'ثلج', 'joke': 'نكتة', 'den': 'عرين', 'beg': 'يتوسل / يرجو',
    'photographic': 'فوتوغرافي', 'lake': 'بحيرة', 'pack': 'يحزم أو حزمة', 'vote': 'يصوت أو تصويت',
    'stripe': 'شريط أو خط ملون', 'classes': 'صفوف أو دروس', 'pat': 'يربت برفق', 'illusion': 'وهم',
    'shouted': 'صرخ', 'pleasure': 'سرور أو متعة', 'bourgeois': 'برجوازي', 'thumb': 'إبهام',
    'import': 'يستورد أو استيراد', 'hats': 'قبعات', 'duck': 'بطة', 'choke': 'يختنق',
    'spot': 'بقعة أو يلمح', 'pie': 'فطيرة', 'carp': 'سمك الشبوط', 'said': 'قال', 'gin': 'مشروب الجن',
    'sin': 'خطيئة', 'books': 'كتب', 'luke': 'لوقا', 'suit': 'بدلة', 'kissed': 'قبّل',
    'lark': 'طائر القبرة', 'chin': 'ذقن', 'sought': 'سعى أو طلب', 'pill': 'حبة دواء',
    'kin': 'أقارب وأهل', 'spit': 'يبصق', 'cup': 'كوب', 'nought': 'صفر', 'rare': 'نادر',
    'skirt': 'تنورة', 'pot': 'قدر أو إناء', 'cliffs': 'منحدرات صخرية', 'pain': 'ألم',
    'pine': 'شجر الصنوبر', 'rin': 'شطف', 'ended': 'انتهى', 'bake': 'يخبز', 'bark': 'نباح أو لحاء',
    'tare': 'وزن الوعاء', 'tar': 'قطران', 'buses': 'حافلات', 'thump': 'ضربة أو خبطة',
    'fission': 'انشطار', 'clothe': 'يكسو أو يلبس', 'stare': 'يحدق', 'wren': 'طائر النمنمة',
    'wring': 'يعصر باليد', 'wrinkle': 'تجاعيد', 'written': 'مكتوب', 'wrestle': 'يصارع',
    'wreath': 'إكليل زهور', 'wreck': 'حطام', 'wrist': 'معصم اليد', 'rung': 'درجة السلم',
    'patio': 'فناء خارجي', 'viscount': 'فيكونت (لقب نبيل)', 'debris': 'حطام أو ركام',
    'islander': 'ساكن الجزيرة', 'aisle': 'ممر', 'isle': 'جزيرة صغيرة', 'highland': 'مرتفعات',
    'balm': 'بلسم', 'could': 'استطاع', 'would': 'سوف / كان سيـ', 'should': 'ينبغي',
    'salmon': 'سمك السلمون', 'folk': 'قوم أو شعبي', 'chalk': 'طباشير', 'palm': 'نخلة أو كف اليد',
    'wok': 'مقلاة ووك', 'tock': 'تكة الساعة', 'pam': 'اسم بام', 'limb': 'طرف من أطراف الجسم',
    'subtle': 'دقيق أو خفي', 'crumb': 'فتات الخبز', 'numb': 'مخدر أو فاقد الحس', 'tomb': 'مقبرة أو ضريح',
    'comb': 'مشط', 'bomb': 'قنبلة', 'lamb': 'حمل صغير', 'lamp': 'مصباح', 'claim': 'يدّعي',
    'knuckle': 'مفصل الإصبع', 'knob': 'مقبض الباب', 'knack': 'موهبة أو حنكة', 'kneel': 'يركع',
    'knitting': 'حياكة أو حك', 'knot': 'عقدة', 'knock': 'يطرق', 'knife': 'سكين',
    'knee': 'ركبة', 'knight': 'فارس', 'splash': 'رشاش ماء', 'spread': 'ينشر أو يوزع',
    'split': 'يقسم أو ينشطر', 'strike': 'يضرب أو إضراب', 'strict': 'صارم أو حازم', 'straw': 'قش أو شفاطة',
    'straight': 'مستقيم', 'boon': 'نعمة أو فائدة', 'pace': 'وتيرة أو خطوة', 'peak': 'قمة',
    'spark': 'شرارة', 'spider': 'عنكبوت', 'skate': 'يتزلج', 'skull': 'جمجمة', 'skeleton': 'هيكل عظمي',
    'scale': 'مقياس أو قشور سمك', 'sketch': 'رسم تخطيطي', 'kip': 'قيلولة', 'rare': 'نادر',
    'rear': 'خلفي أو يربي', 'peer': 'قرين أو ند', 'cheer': 'هتاف تشجيع', 'steer': 'يقود أو يوجه',
    'fear': 'خوف', 'dear': 'عزيزي', 'beer': 'شراب الشعير', 'career': 'مسيرة مهنية', 'fare': 'أجرة',
    'hop': 'يقفز على قدم واحدة', 'rod': 'قضيب أو سنارة', 'cone': 'مخروط', 'vice': 'رذيلة',
    'bait': 'طعم الصيد', 'raid': 'غارة', 'die': 'يموت', 'lord': 'سيد أو لورد', 'clad': 'مكسو أو مرتدي',
    'banner': 'شعار أو لافتة', 'bout': 'نوبة أو جولة', 'soot': 'هباب الفحم', 'luke': 'لوقا',
    'said': 'قال', 'bun': 'كعكة صغيرة', 'barn': 'حظيرة', 'luck': 'حظ', 'carp': 'سمك الشبوط',
    'fork': 'شوكة', 'port': 'ميناء', 'cot': 'سرير صغير', 'sport': 'رياضة', 'shot': 'طلقة أو لقطة',
    'peas': 'بازلاء', 'zinc': 'معدن الزنك', 'zeal': 'حماسة وغيرة', 'seal': 'فقمة أو يختم',
    'toll': 'رسوم طريق', 'coal': 'فحم', 'late': 'متأخر', 'let': 'يدع أو يسمح', 'mine': 'ملكي أو منجم',
    'tail': 'ذيل', 'tile': 'بلاطة', 'bake': 'يخبز', 'veal': 'لحم عجل', 'wiper': 'ممسحة',
    'viper': 'أفعى سامة', 'vent': 'فتحة تهوية', 'verse': 'بيت شعر', 'vary': 'يتنوع', 'wary': 'حذر ومحترس',
    'ling': 'سمك اللينغ', 'led': 'قادَ', 'load': 'حمولة', 'raw': 'نيء أو خام', 'law': 'قانون',
    'badge': 'شارة أو وسام', 'batch': 'دفعة أو وجبة', 'chunk': 'قطعة كبيرة سميكة', 'junk': 'خردة',
    'jeep': 'سيارة جيب', 'cheap': 'رخيص', 'chin': 'ذقن', 'gin': 'مشروب الجن', 'choke': 'يختنق',
    'joke': 'نكتة', 'jam': 'مربى أو ازدحام', 'chain': 'سلسلة', 'choose': 'يختار', 'shoes': 'أحذية',
    'chop': 'يقطع أو فرم', 'shop': 'متجر', 'chip': 'شريحة', 'ship': 'سفينة', 'chair': 'كرسي',
    'share': 'يشارك أو حصة', 'cheat': 'يغش', 'sheet': 'ورقة أو ملاءة', 'catch': 'يمسك', 'cash': 'نقد كاش',
    'allusion': 'تلميح أدبي', 'mirage': 'سراب', 'casual': 'غير رسمي أو عابر', 'asia': 'قارة آسيا',
    'version': 'إصدار أو نسخة', 'decision': 'قرار', 'leisure': 'وقت الفراغ', 'treasure': 'كنز',
    'pleasure': 'سرور', 'measure': 'يقيس أو قياس', 'mesher': 'شابك أو مدمج', 'pledger': 'المتعهد',
    'bay': 'خليج', 'bang': 'صدمة أو فرقعة', 'ban': 'حظر', 'wing': 'جناح', 'win': 'يفوز',
    'morning': 'صباح', 'running': 'ركض', 'theme': 'موضوع أو نسق', 'team': 'فريق', 'north': 'شمال',
    'south': 'جنوب', 'earth': 'الأرض', 'tooth': 'سن', 'bath': 'حمام', 'bass': 'صوت جهير أو سمك القاروص',
    'thick': 'سميك', 'sick': 'مريض', 'thumb': 'إبهام', 'some': 'بعض', 'think': 'يفكر', 'sink': 'يغرق أو مغسلة',
    'feather': 'ريشة', 'weather': 'طقس', 'breathe': 'يتنفس', 'breed': 'سلالة أو يتكاثر',
    'dare': 'يجرؤ', 'then': 'حينئذ / ثم', 'den': 'عرين', 'they': 'هم', 'day': 'يوم',
    'clothe': 'يكسو', 'close': 'يغلق أو قريب', 'thy': 'لك (ضمير قديم)', 'vast': 'شاسع',
    'fast': 'سريع', 'vault': 'قبو أو خزانة', 'fault': 'خطأ أو عيب', 'vest': 'سترة', 'fest': 'مهرجان',
    'view': 'منظر أو يرى', 'few': 'قليل', 'vine': 'شجرة العنب', 'fine': 'بخير أو غرامة',
    'van': 'شاحنة صغيرة', 'fan': 'مروحة أو معجب', 'valley': 'وادي', 'veil': 'حجاب أو غطاء',
    'vital': 'حيوي وأساسي', 'pet': 'حيوان أليف', 'bet': 'رهان أو يراهن', 'peach': 'خوخ',
    'beach': 'شاطئ', 'park': 'حديقة عامة', 'bark': 'نباح', 'pie': 'فطيرة', 'bye': 'مع السلامة',
    'pat': 'يربت برفق', 'bat': 'مضرب أو خفاش', 'pin': 'دبوس', 'bin': 'سلة مهملات', 'pot': 'قدر',
    'pack': 'يحزم أو حزمة', 'pill': 'حبة دواء', 'post': 'منشور أو عمود',
    'walked': 'مشى', 'stopped': 'توقف', 'cooked': 'طبخ', 'helped': 'ساعد', 'missed': 'اشتاق أو فاته',
    'watched': 'شاهد', 'washed': 'غسل', 'laughed': 'ضحك', 'fixed': 'أصلح', 'talked': 'تحدث',
    'jumped': 'قفز', 'kissed': 'قبّل', 'played': 'لعب', 'cleaned': 'نظف', 'called': 'اتصل أو نادى',
    'lived': 'عاش', 'loved': 'أحب', 'opened': 'فتح', 'closed': 'أغلق', 'stayed': 'بقي',
    'moved': 'تحرك أو انتقل', 'showed': 'أظهر أو عرض', 'trained': 'تدرّب', 'listened': 'استمع',
    'wanted': 'أراد', 'needed': 'احتاج', 'waited': 'انتظر', 'decided': 'قرر', 'visited': 'زار',
    'started': 'بدأ', 'invited': 'دعا', 'painted': 'رسم أو طلى', 'shouted': 'صرخ', 'ended': 'انتهى',
    'created': 'أنشأ أو ابتكر', 'tested': 'اختبر', 'cats': 'قطط', 'books': 'كتب', 'cups': 'أكواب',
    'hats': 'قبعات', 'maps': 'خرائط', 'cliffs': 'منحدرات', 'myths': 'أساطير', 'walks': 'يمشي أو نزهات',
    'stops': 'محطات أو يتوقف', 'cooks': 'طهاة أو يطبخ', 'lights': 'أضواء', 'trips': 'رحلات',
    'dogs': 'كلاب', 'pens': 'أقلام', 'rooms': 'غرف', 'days': 'أيام', 'trees': 'أشجار',
    'cars': 'سيارات', 'dreams': 'أحلام', 'plays': 'مسرحيات أو يلعب', 'songs': 'أغاني',
    'friends': 'أصدقاء', 'stars': 'نجوم', 'doors': 'أبواب', 'buses': 'حافلات', 'boxes': 'صناديق',
    'watches': 'ساعات يد أو يشاهد', 'dishes': 'أطباق', 'places': 'أماكن', 'sizes': 'مقاسات أو أحجام',
    'changes': 'تغييرات', 'bridges': 'جسور', 'glasses': 'نظارات أو كؤوس', 'classes': 'صفوف',
    'pages': 'صفحات', 'judges': 'قضاة', 'facts': 'حقائق', 'tests': 'اختبارات', 'desks': 'مكاتب',
    'asks': 'يسأل أو طلبات', 'lists': 'قوائم', 'tasks': 'مهام', 'guests': 'ضيوف', 'costs': 'تكاليف',
    'acts': 'أفعال أو فصول', 'posts': 'منشورات', 'rests': 'استراحات', 'trusts': 'يثق أو أمانات',
    'record': 'سجل أو يسجل', 'present': 'حاضر أو هدية أو يقدّم', 'object': 'شيء أو يعترض',
    'project': 'مشروع أو يُسقط', 'desert': 'صحراء أو يهجر', 'conduct': 'سلوك أو يقود',
    'contract': 'عقد أو ينكمش', 'import': 'استيراد أو يستورد', 'export': 'تصدير أو يُصدّر',
    'produce': 'منتج أو يُنتج', 'rebel': 'متمرّد أو يتمرّد', 'suspect': 'مشتبه به أو يشتبه',
    'recorder': 'مسجل', 'presence': 'حضور أو وجود', 'objective': 'هدف أو موضوعي',
    'projection': 'إسقاط أو عرض', 'dessert': 'حلوى ما بعد الطعام', 'photograph': 'صورة فوتوغرافية',
    'photography': 'فن التصوير', 'photographic': 'فوتوغرافي', 'economy': 'اقتصاد',
    'economic': 'اقتصادي', 'educate': 'يُعلّم أو يربي', 'education': 'تعليم', 'family': 'عائلة',
    'familiar': 'مألوف', 'politics': 'علم السياسة', 'political': 'سياسي', 'musician': 'موسيقي',
    'chamois': 'جلد الشامواه', 'rendezvous': 'موعد لقاء', 'bass': 'صوت جهير',
    'guy': 'رجل أو فتى', 'kill': 'يقتل', 'top': 'قمة', 'tan': 'سمرة', 'feed': 'يطعم',
    'dream': 'حلم', 'treat': 'يعامل أو حلوى', 'ring': 'يرن أو خاتم', 'wrong': 'خاطئ',
    'night': 'ليل', 'no': 'كلا أو لا', 'bee': 'نحلة', 'life': 'حياة', 'mist': 'ضباب',
    'rap': 'موسيقى الراب', 'neck': 'رقبة', 'dot': 'نقطة', 'have': 'يملك', 'file': 'ملف',
    'tile': 'بلاطة', 'at': 'في', 'art': 'فن', 'old': 'قديم', 'and': 'و (حرف عطف)', 'eat': 'يأكل',
    'test': 'اختبار', 'fact': 'حقيقة', 'desk': 'مكتب', 'task': 'مهمة', 'list': 'قائمة',
    'walk': 'يمشي', 'stop': 'يتوقف', 'cook': 'يطبخ', 'help': 'يساعد', 'miss': 'يشتاق',
    'play': 'يلعب', 'clean': 'ينظف', 'call': 'يتصل', 'love': 'يحب', 'open': 'يفتح',
    'want': 'يريد', 'need': 'يحتاج', 'wait': 'ينتظر', 'paint': 'يرسم', 'visit': 'يزور',
    'cat': 'قطة', 'book': 'كتاب', 'hat': 'قبعة', 'map': 'خريطة', 'dog': 'كلب', 'pen': 'قلم',
    'room': 'غرفة', 'day': 'يوم', 'tree': 'شجرة', 'bus': 'حافلة', 'box': 'صندوق', 'watch': 'ساعة يد',
    'place': 'مكان', 'size': 'مقاس'
}

added_entries = []
for w in missing:
    ar = known_ar.get(w) or pair_translations.get(w) or f"معنى {w}"
    # find baseWord if ends with ed or s
    base = None
    if w.endswith("ed") and len(w) > 4:
        base = w[:-2]
    elif w.endswith("s") and len(w) > 3:
        base = w[:-1]
    
    added_entries.append({
        "english": w,
        "arabic": ar,
        "baseWord": base
    })
    vocab_words[w] = added_entries[-1]

vocab_data.extend(added_entries)
with open(vocab_path, "w", encoding="utf-8") as f:
    json.dump(vocab_data, f, ensure_ascii=False, indent=2)

print(f"Added {len(added_entries)} entries to vocab.json. Total vocab: {len(vocab_data)}")
