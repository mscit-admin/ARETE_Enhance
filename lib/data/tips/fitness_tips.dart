import '../models/fitness_tip.dart';

/// The built-in tip catalogue.
///
/// Content is bundled rather than fetched so the daily tip works offline and
/// can be raised as a notification while the app is closed. Add to the end of
/// the list — [tipForDay] cycles through it by date, so reordering only shuffles
/// which day shows which tip.
class FitnessTips {
  const FitnessTips._();

  static const List<FitnessTip> all = [
    // ---- Training ----
    FitnessTip(
      id: 'warmup',
      category: TipCategory.training,
      text: {
        'en': 'Never skip the warm-up: 5–10 minutes of light cardio and mobility cuts your injury risk sharply.',
        'ar': 'لا تتجاوز الإحماء أبداً: من ٥ إلى ١٠ دقائق كارديو خفيف وإطالة حركية تقلّل خطر الإصابة كثيراً.',
        'fr': "Ne sautez jamais l'échauffement : 5 à 10 minutes de cardio léger réduisent nettement le risque de blessure.",
      },
    ),
    FitnessTip(
      id: 'form_first',
      category: TipCategory.training,
      text: {
        'en': 'Form before weight. A clean rep with less load beats a heavy rep that wrecks your back.',
        'ar': 'الأداء الصحيح قبل الوزن. تكرار سليم بوزن أقل خير من تكرار ثقيل يؤذي ظهرك.',
        'fr': "La technique avant la charge. Une répétition propre vaut mieux qu'une lourde mal exécutée.",
      },
    ),
    FitnessTip(
      id: 'progressive_overload',
      category: TipCategory.training,
      text: {
        'en': 'Add a little each week — a rep, a set, or 2.5 kg. Steady overload is what builds strength.',
        'ar': 'أضف قليلاً كل أسبوع — تكرار أو مجموعة أو ٢٫٥ كجم. التدرّج المستمر هو ما يبني القوة.',
        'fr': 'Ajoutez un peu chaque semaine : une répétition, une série ou 2,5 kg. La progression construit la force.',
      },
    ),
    FitnessTip(
      id: 'compound_first',
      category: TipCategory.training,
      text: {
        'en': 'Start your session with compound lifts (squat, press, row) while you are freshest.',
        'ar': 'ابدأ حصتك بالتمارين المركّبة (سكوات، ضغط، سحب) وأنت في أوج نشاطك.',
        'fr': 'Commencez par les mouvements polyarticulaires (squat, développé, tirage) quand vous êtes frais.',
      },
    ),
    FitnessTip(
      id: 'breathe',
      category: TipCategory.training,
      text: {
        'en': 'Exhale on the effort, inhale on the way back. Holding your breath spikes blood pressure.',
        'ar': 'ازفر أثناء الجهد واشهق أثناء العودة. حبس النفس يرفع ضغط الدم.',
        'fr': "Expirez à l'effort, inspirez au retour. Bloquer sa respiration fait grimper la tension.",
      },
    ),
    FitnessTip(
      id: 'tempo',
      category: TipCategory.training,
      text: {
        'en': 'Slow the lowering phase to about three seconds — controlled negatives grow muscle faster.',
        'ar': 'أبطئ مرحلة النزول إلى نحو ثلاث ثوانٍ — التحكّم في النزول يبني العضلة أسرع.',
        'fr': 'Ralentissez la phase de descente à trois secondes : les négatives contrôlées font progresser.',
      },
    ),
    FitnessTip(
      id: 'walk_daily',
      category: TipCategory.training,
      text: {
        'en': 'On rest days, walk. 8,000 easy steps keep the blood moving without taxing recovery.',
        'ar': 'في أيام الراحة، امشِ. ٨٠٠٠ خطوة هادئة تنشّط الدورة الدموية دون إرهاق الاستشفاء.',
        'fr': 'Les jours de repos, marchez. 8 000 pas tranquilles activent la circulation sans nuire à la récupération.',
      },
    ),
    FitnessTip(
      id: 'log_sets',
      category: TipCategory.training,
      text: {
        'en': 'Log every set. What gets measured gets improved — and your coach can see the trend.',
        'ar': 'سجّل كل مجموعة. ما يُقاس يتحسّن — ومدرّبك يرى تطوّرك.',
        'fr': 'Notez chaque série. Ce qui se mesure progresse, et votre coach suit la tendance.',
      },
    ),

    // ---- Recovery ----
    FitnessTip(
      id: 'sleep',
      category: TipCategory.recovery,
      text: {
        'en': 'Muscle is built while you sleep. Aim for 7–9 hours; under 6 blunts strength gains.',
        'ar': 'العضلة تُبنى أثناء النوم. استهدف ٧–٩ ساعات؛ أقل من ٦ يُضعف مكاسب القوة.',
        'fr': 'Le muscle se construit pendant le sommeil. Visez 7 à 9 heures ; moins de 6 freine les gains.',
      },
    ),
    FitnessTip(
      id: 'rest_day',
      category: TipCategory.recovery,
      text: {
        'en': 'Take at least one full rest day a week. Progress happens between sessions, not during them.',
        'ar': 'خذ يوم راحة كاملاً واحداً على الأقل أسبوعياً. التقدّم يحدث بين الحصص لا أثناءها.',
        'fr': 'Prenez au moins un jour de repos complet par semaine. Les progrès se font entre les séances.',
      },
    ),
    FitnessTip(
      id: 'soreness',
      category: TipCategory.recovery,
      text: {
        'en': 'Sore is fine, sharp pain is not. Stop the set if a joint hurts and tell your coach.',
        'ar': 'ألم العضلات طبيعي، أما الألم الحاد فلا. أوقف المجموعة إذا آلمك مفصل وأخبر مدرّبك.',
        'fr': "Des courbatures, oui ; une douleur vive, non. Arrêtez la série et prévenez votre coach.",
      },
    ),
    FitnessTip(
      id: 'stretch',
      category: TipCategory.recovery,
      text: {
        'en': 'Finish with 5 minutes of stretching on the muscles you trained — it speeds recovery.',
        'ar': 'اختم بخمس دقائق إطالة للعضلات التي دربتها — تسرّع الاستشفاء.',
        'fr': 'Terminez par 5 minutes d’étirements sur les muscles travaillés : la récupération est plus rapide.',
      },
    ),
    FitnessTip(
      id: 'deload',
      category: TipCategory.recovery,
      text: {
        'en': 'Every 6–8 weeks, drop the load by a third for a week. You come back stronger, not weaker.',
        'ar': 'كل ٦–٨ أسابيع، خفّض الأحمال الثلث لمدة أسبوع. ستعود أقوى لا أضعف.',
        'fr': 'Toutes les 6 à 8 semaines, réduisez les charges d’un tiers pendant une semaine : vous reviendrez plus fort.',
      },
    ),

    // ---- Nutrition ----
    FitnessTip(
      id: 'protein',
      category: TipCategory.nutrition,
      text: {
        'en': 'Spread protein across the day: roughly 1.6–2 g per kg of body weight, in every meal.',
        'ar': 'وزّع البروتين على اليوم: نحو ١٫٦–٢ جرام لكل كجم من وزنك، في كل وجبة.',
        'fr': 'Répartissez les protéines : environ 1,6 à 2 g par kg de poids, à chaque repas.',
      },
    ),
    FitnessTip(
      id: 'dont_skip_breakfast',
      category: TipCategory.nutrition,
      text: {
        'en': 'Eat within a couple of hours of waking — skipping breakfast usually means overeating at night.',
        'ar': 'تناول طعامك خلال ساعتين من الاستيقاظ — تفويت الفطور غالباً يعني إفراطاً في الأكل ليلاً.',
        'fr': 'Mangez dans les deux heures après le réveil : sauter le petit-déjeuner mène souvent aux excès du soir.',
      },
    ),
    FitnessTip(
      id: 'pre_workout',
      category: TipCategory.nutrition,
      text: {
        'en': 'Eat a light carb + protein meal 1–2 hours before training, not right before the first set.',
        'ar': 'تناول وجبة خفيفة من الكربوهيدرات والبروتين قبل التمرين بساعة إلى ساعتين، لا قبل أول مجموعة مباشرة.',
        'fr': 'Prenez glucides + protéines 1 à 2 heures avant l’entraînement, pas juste avant la première série.',
      },
    ),
    FitnessTip(
      id: 'post_workout',
      category: TipCategory.nutrition,
      text: {
        'en': 'Get a protein-rich meal in within a couple of hours of finishing — that is when repair starts.',
        'ar': 'تناول وجبة غنية بالبروتين خلال ساعتين من انتهاء التمرين — حينها يبدأ الإصلاح.',
        'fr': 'Prenez un repas riche en protéines dans les deux heures suivant la séance : la réparation commence là.',
      },
    ),
    FitnessTip(
      id: 'whole_foods',
      category: TipCategory.nutrition,
      text: {
        'en': 'Build meals around whole foods first; supplements fill gaps, they do not replace food.',
        'ar': 'ابنِ وجباتك على الأطعمة الكاملة أولاً؛ المكمّلات تسدّ النقص ولا تُغني عن الطعام.',
        'fr': 'Construisez vos repas sur des aliments bruts ; les compléments comblent, ils ne remplacent pas.',
      },
    ),
    FitnessTip(
      id: 'fibre',
      category: TipCategory.nutrition,
      text: {
        'en': 'Put vegetables on every plate. Fibre keeps you full and steadies your energy through the day.',
        'ar': 'اجعل الخضار في كل طبق. الألياف تُشعرك بالشبع وتثبّت طاقتك طوال اليوم.',
        'fr': 'Mettez des légumes dans chaque assiette : les fibres rassasient et stabilisent l’énergie.',
      },
    ),
    FitnessTip(
      id: 'slow_eating',
      category: TipCategory.nutrition,
      text: {
        'en': 'Eat slowly — fullness signals take about 20 minutes to arrive.',
        'ar': 'تناول طعامك ببطء — إشارات الشبع تحتاج نحو ٢٠ دقيقة لتصل.',
        'fr': 'Mangez lentement : les signaux de satiété mettent environ 20 minutes à arriver.',
      },
    ),

    // ---- Hydration ----
    FitnessTip(
      id: 'water_daily',
      category: TipCategory.hydration,
      text: {
        'en': 'Thirst lags behind need. Drink on a schedule, not only when your mouth is dry.',
        'ar': 'الإحساس بالعطش متأخر عن حاجة الجسم. اشرب على جدول لا عند جفاف الفم فقط.',
        'fr': 'La soif arrive en retard. Buvez régulièrement, pas seulement quand la bouche est sèche.',
      },
    ),
    FitnessTip(
      id: 'water_training',
      category: TipCategory.hydration,
      text: {
        'en': 'Sip water through the session: even 2% dehydration drops your strength noticeably.',
        'ar': 'ارشف الماء أثناء التمرين: جفاف بنسبة ٢٪ فقط يخفض قوّتك بوضوح.',
        'fr': 'Buvez pendant la séance : 2 % de déshydratation suffisent à faire chuter la force.',
      },
    ),
    FitnessTip(
      id: 'water_wake',
      category: TipCategory.hydration,
      text: {
        'en': 'Start the day with a glass of water — you wake up mildly dehydrated after 7 hours without any.',
        'ar': 'ابدأ يومك بكوب ماء — تستيقظ وأنت في جفاف خفيف بعد سبع ساعات دون شرب.',
        'fr': 'Commencez la journée par un verre d’eau : après 7 heures sans boire, vous êtes déshydraté.',
      },
    ),
    FitnessTip(
      id: 'water_sugar',
      category: TipCategory.hydration,
      text: {
        'en': 'Swap one sugary drink a day for water — it is the easiest calorie cut you will ever make.',
        'ar': 'استبدل مشروباً سكرياً واحداً يومياً بالماء — أسهل تخفيض للسعرات على الإطلاق.',
        'fr': 'Remplacez une boisson sucrée par jour par de l’eau : la réduction calorique la plus simple.',
      },
    ),

    // ---- Mindset ----
    FitnessTip(
      id: 'consistency',
      category: TipCategory.mindset,
      text: {
        'en': 'Consistency beats intensity. Three steady sessions a week outperform one heroic one.',
        'ar': 'الاستمرارية تتفوّق على الشدّة. ثلاث حصص منتظمة أسبوعياً أفضل من حصة بطولية واحدة.',
        'fr': 'La régularité l’emporte sur l’intensité : trois séances stables valent mieux qu’une héroïque.',
      },
    ),
    FitnessTip(
      id: 'show_up',
      category: TipCategory.mindset,
      text: {
        'en': 'On low days, do the shortest version of the plan. Showing up keeps the habit alive.',
        'ar': 'في الأيام الصعبة، نفّذ أقصر نسخة من الخطة. مجرد الحضور يبقي العادة حية.',
        'fr': 'Les jours sans, faites la version la plus courte du plan : l’habitude survit.',
      },
    ),
    FitnessTip(
      id: 'compare_self',
      category: TipCategory.mindset,
      text: {
        'en': 'Compare yourself to last month, not to the person next to you.',
        'ar': 'قارن نفسك بشهرك الماضي لا بمن بجوارك.',
        'fr': 'Comparez-vous au vous d’il y a un mois, pas à votre voisin.',
      },
    ),
    FitnessTip(
      id: 'ask_coach',
      category: TipCategory.mindset,
      text: {
        'en': 'Unsure about a movement? Message your coach — one correction now saves months of bad habits.',
        'ar': 'غير متأكد من حركة؟ راسل مدرّبك — تصحيح واحد الآن يوفّر أشهراً من العادات الخاطئة.',
        'fr': 'Un doute sur un mouvement ? Écrivez à votre coach : une correction évite des mois de mauvaises habitudes.',
      },
    ),
  ];

  /// Tips left after the muted [categories] are removed.
  static List<FitnessTip> forCategories(Set<TipCategory> categories) {
    if (categories.isEmpty) return all;
    final kept = all.where((t) => categories.contains(t.category)).toList();
    return kept.isEmpty ? all : kept;
  }

  /// The tip for a given day — the same day always yields the same tip, and the
  /// catalogue cycles without repeating until it has been exhausted.
  static FitnessTip tipForDay(DateTime day, {Set<TipCategory>? categories}) {
    final pool = categories == null ? all : forCategories(categories);
    final dayNumber = DateTime.utc(day.year, day.month, day.day)
            .millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final index = dayNumber % pool.length;
    return pool[index < 0 ? index + pool.length : index];
  }
}
