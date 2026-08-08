/* ARETE admin console — localization + currency.
 *
 * Three languages ship in the client (en/ar/fr). Extra languages are added
 * from Settings by downloading the CSV template, translating the last column
 * and uploading it; those are stored on the server (admin_locales) and merged
 * on top of English as a fallback.
 */
(function (global) {
  'use strict';

  // ---- Base dictionaries (the master key list is EN's key order) ----
  const EN = {
    'common.language': 'Language',
    'common.noData': 'No data yet',
    'common.loading': 'Loading…',

    'login.title': 'Admin console',
    'login.subtitle': 'Sign in to manage members, trainers and billing.',
    'login.email': 'Email',
    'login.password': 'Password',
    'login.signIn': 'Sign in',
    'login.signingIn': 'Signing in…',
    'login.failed': 'Login failed',

    'nav.overview': 'Overview',
    'nav.members': 'Members',
    'nav.trainers': 'Trainers',
    'nav.plans': 'Plans',
    'nav.system': 'System',
    'nav.settings': 'Settings',
    'nav.logout': 'Log out',

    'head.admin': 'Admin',

    'kpi.totalMembers': 'Total members',
    'kpi.active': 'Active',
    'kpi.activeDesc': 'with active plan',
    'kpi.expiring': 'Expiring ≤7d',
    'kpi.expiringDesc': 'needs follow-up',
    'kpi.mrr': 'MRR',
    'kpi.mrrDesc': '{trainers} trainers · {sessions} sessions today',
    'card.growth': 'Member growth',
    'card.growthSub': 'new sign-ups · last 12 weeks',
    'card.byTier': 'By tier',

    'members.searchPh': 'Search members by name or email…',
    'members.allStatuses': 'All statuses',
    'members.none': 'No members found',
    'status.active': 'Active',
    'status.frozen': 'Frozen',
    'status.expired': 'Expired',

    'table.member': 'Member',
    'table.tier': 'Tier',
    'table.trainer': 'Trainer',
    'table.status': 'Status',
    'table.renews': 'Renews',
    'table.specialty': 'Specialty',
    'table.clients': 'Clients',
    'table.rating': 'Rating',
    'table.reply': 'Reply',
    'table.plan': 'Plan',
    'table.split': 'Split',
    'table.days': 'Days',
    'table.goal': 'Goal',
    'table.level': 'Level',

    'pager.prev': 'Prev',
    'pager.next': 'Next',
    'pager.info': 'Page {page} of {pages} · {total} total',

    'settings.title': 'Settings',
    'settings.currency': 'Currency',
    'settings.currencyDesc': 'Used across all revenue and price figures.',
    'settings.symbolPosition': 'Symbol position',
    'settings.posBefore': 'Before amount (e.g. $100)',
    'settings.posAfter': 'After amount (e.g. 100 $)',
    'settings.save': 'Save settings',
    'settings.saved': 'Saved',
    'settings.saveFailed': 'Could not save',
    'settings.languages': 'Languages',
    'settings.languagesDesc':
      'Arabic, English and French are built in. Add more by downloading the template, translating the last column, then uploading it.',
    'settings.downloadTemplate': 'Download translation template (CSV)',
    'settings.addLanguage': 'Add / update a language',
    'settings.langCode': 'Language code',
    'settings.langCodePh': 'e.g. es, tr, de',
    'settings.langName': 'Language name',
    'settings.langNamePh': 'e.g. Español',
    'settings.direction': 'Text direction',
    'settings.ltr': 'Left-to-right',
    'settings.rtl': 'Right-to-left',
    'settings.csvFile': 'Translated CSV file',
    'settings.upload': 'Upload language',
    'settings.customLangs': 'Custom languages',
    'settings.noCustom': 'No custom languages yet.',
    'settings.delete': 'Delete',
    'settings.uploaded': 'Language added',
    'settings.needCode': 'Enter a language code and name.',
    'settings.badCsv': 'Could not read that CSV. Use the downloaded template.',
    'settings.confirmDelete': 'Delete this language?',

    'nav.users': 'Users',
    'users.title': 'User accounts',
    'users.subtitle': 'Create accounts, assign roles and control what each admin can access.',
    'users.add': 'Add user',
    'users.name': 'Name',
    'users.email': 'Email',
    'users.password': 'Password',
    'users.newPassword': 'New password',
    'users.newPasswordHint': 'Leave blank to keep the current password.',
    'users.role': 'Role',
    'users.status': 'Status',
    'users.permissions': 'Permissions',
    'users.permsHint': 'Permissions apply to admin accounts and decide which sections they can open. Leave all on for a full-access admin.',
    'users.created': 'Created',
    'users.actions': 'Actions',
    'users.edit': 'Edit',
    'users.delete': 'Delete',
    'users.save': 'Save',
    'users.cancel': 'Cancel',
    'users.none': 'No users found',
    'users.allRoles': 'All roles',
    'users.createdOk': 'User created',
    'users.updatedOk': 'Saved',
    'users.deletedOk': 'User deleted',
    'users.confirmDelete': 'Delete this account?',
    'users.fullAccess': 'Full access',
    'users.noConsole': 'No console access',
    'users.searchPh': 'Search by name or email…',
    'role.member': 'Member',
    'role.trainer': 'Trainer',
    'role.admin': 'Admin',
    'status.suspended': 'Suspended',
    'perm.members': 'Members',
    'perm.trainers': 'Trainers',
    'perm.plans': 'Plans',
    'perm.billing': 'Billing & revenue',
    'perm.settings': 'Settings',
    'perm.users': 'User accounts',

    'nav.roles': 'Roles',
    'nav.audit': 'Activity',
    'common.view': 'View',
    'common.manage': 'Manage',
    'users.access': 'Access',
    'users.fullAccessOpt': 'Full access (super admin)',
    'users.customOpt': 'Custom permissions',
    'roles.title': 'Roles',
    'roles.subtitle': 'Bundle permissions into a named role, then assign it to admin accounts.',
    'roles.add': 'Add role',
    'roles.name': 'Role name',
    'roles.namePh': 'e.g. Receptionist',
    'roles.key': 'Key',
    'roles.keyPh': 'auto from name',
    'roles.keyHint': 'A short identifier. Leave blank to generate it from the name.',
    'roles.permissions': 'Permissions',
    'roles.usersCount': 'Users',
    'roles.system': 'System',
    'roles.none': 'No custom roles yet.',
    'roles.edit': 'Edit',
    'roles.delete': 'Delete',
    'roles.save': 'Save role',
    'roles.cancel': 'Cancel',
    'roles.confirmDelete': 'Delete this role? Its users lose console access until reassigned.',
    'audit.title': 'Activity log',
    'audit.subtitle': 'Recent actions taken in the admin console.',
    'audit.who': 'Admin',
    'audit.action': 'Action',
    'audit.entity': 'Area',
    'audit.when': 'When',
    'audit.none': 'No activity yet',
    'action.create_user': 'Created a user',
    'action.update_user': 'Updated a user',
    'action.delete_user': 'Deleted a user',
    'action.update_member': 'Updated a member',
    'action.update_settings': 'Updated settings',
    'action.save_role': 'Saved a role',
    'action.delete_role': 'Deleted a role',
    'entity.users': 'Users',
    'entity.members': 'Members',
    'entity.app_settings': 'Settings',
    'entity.admin_roles': 'Roles',
    'entity.trainers': 'Trainers',
    'action.update_trainer': 'Updated a trainer',
    'freeze.freeze': 'Freeze',
    'freeze.unfreeze': 'Unfreeze',
    'freeze.suspended': 'Suspended',
    'freeze.confirmFreeze': "Freeze this account? They won't be able to sign in.",
    'freeze.confirmUnfreeze': 'Reactivate this account?',
    'table.actions': 'Actions',
  };

  const AR = {
    'common.language': 'اللغة',
    'common.noData': 'لا توجد بيانات بعد',
    'common.loading': 'جارٍ التحميل…',

    'login.title': 'لوحة التحكم',
    'login.subtitle': 'سجّل الدخول لإدارة الأعضاء والمدربين والفوترة.',
    'login.email': 'البريد الإلكتروني',
    'login.password': 'كلمة المرور',
    'login.signIn': 'تسجيل الدخول',
    'login.signingIn': 'جارٍ تسجيل الدخول…',
    'login.failed': 'فشل تسجيل الدخول',

    'nav.overview': 'نظرة عامة',
    'nav.members': 'الأعضاء',
    'nav.trainers': 'المدربون',
    'nav.plans': 'الخطط',
    'nav.system': 'النظام',
    'nav.settings': 'الإعدادات',
    'nav.logout': 'تسجيل الخروج',

    'head.admin': 'المشرف',

    'kpi.totalMembers': 'إجمالي الأعضاء',
    'kpi.active': 'نشط',
    'kpi.activeDesc': 'باشتراك نشط',
    'kpi.expiring': 'ينتهي خلال ٧ أيام',
    'kpi.expiringDesc': 'يحتاج متابعة',
    'kpi.mrr': 'الإيراد الشهري',
    'kpi.mrrDesc': '{trainers} مدرب · {sessions} جلسة اليوم',
    'card.growth': 'نمو الأعضاء',
    'card.growthSub': 'اشتراكات جديدة · آخر ١٢ أسبوعًا',
    'card.byTier': 'حسب الفئة',

    'members.searchPh': 'ابحث عن الأعضاء بالاسم أو البريد…',
    'members.allStatuses': 'كل الحالات',
    'members.none': 'لا يوجد أعضاء',
    'status.active': 'نشط',
    'status.frozen': 'مجمّد',
    'status.expired': 'منتهٍ',

    'table.member': 'العضو',
    'table.tier': 'الفئة',
    'table.trainer': 'المدرب',
    'table.status': 'الحالة',
    'table.renews': 'التجديد',
    'table.specialty': 'التخصص',
    'table.clients': 'العملاء',
    'table.rating': 'التقييم',
    'table.reply': 'الرد',
    'table.plan': 'الخطة',
    'table.split': 'التقسيم',
    'table.days': 'الأيام',
    'table.goal': 'الهدف',
    'table.level': 'المستوى',

    'pager.prev': 'السابق',
    'pager.next': 'التالي',
    'pager.info': 'صفحة {page} من {pages} · {total} إجمالًا',

    'settings.title': 'الإعدادات',
    'settings.currency': 'العملة',
    'settings.currencyDesc': 'تُستخدم في جميع أرقام الإيرادات والأسعار.',
    'settings.symbolPosition': 'موضع الرمز',
    'settings.posBefore': 'قبل المبلغ (مثال: $100)',
    'settings.posAfter': 'بعد المبلغ (مثال: 100 $)',
    'settings.save': 'حفظ الإعدادات',
    'settings.saved': 'تم الحفظ',
    'settings.saveFailed': 'تعذّر الحفظ',
    'settings.languages': 'اللغات',
    'settings.languagesDesc':
      'العربية والإنجليزية والفرنسية مدمجة. أضِف غيرها بتنزيل القالب وترجمة العمود الأخير ثم رفعه.',
    'settings.downloadTemplate': 'تنزيل قالب الترجمة (CSV)',
    'settings.addLanguage': 'إضافة / تحديث لغة',
    'settings.langCode': 'رمز اللغة',
    'settings.langCodePh': 'مثال: es، tr، de',
    'settings.langName': 'اسم اللغة',
    'settings.langNamePh': 'مثال: Español',
    'settings.direction': 'اتجاه النص',
    'settings.ltr': 'من اليسار لليمين',
    'settings.rtl': 'من اليمين لليسار',
    'settings.csvFile': 'ملف CSV المترجم',
    'settings.upload': 'رفع اللغة',
    'settings.customLangs': 'اللغات المُضافة',
    'settings.noCustom': 'لا توجد لغات مُضافة بعد.',
    'settings.delete': 'حذف',
    'settings.uploaded': 'تمت إضافة اللغة',
    'settings.needCode': 'أدخل رمز اللغة واسمها.',
    'settings.badCsv': 'تعذّرت قراءة ملف CSV. استخدم القالب المنزَّل.',
    'settings.confirmDelete': 'حذف هذه اللغة؟',

    'nav.users': 'المستخدمون',
    'users.title': 'حسابات المستخدمين',
    'users.subtitle': 'أنشئ الحسابات وحدّد الأدوار وتحكّم فيما يمكن لكل مشرف الوصول إليه.',
    'users.add': 'إضافة مستخدم',
    'users.name': 'الاسم',
    'users.email': 'البريد الإلكتروني',
    'users.password': 'كلمة المرور',
    'users.newPassword': 'كلمة مرور جديدة',
    'users.newPasswordHint': 'اتركها فارغة للإبقاء على كلمة المرور الحالية.',
    'users.role': 'الدور',
    'users.status': 'الحالة',
    'users.permissions': 'الصلاحيات',
    'users.permsHint': 'تنطبق الصلاحيات على حسابات المشرفين وتحدّد الأقسام التي يمكنهم فتحها. اترك الكل مفعّلًا لمشرف كامل الصلاحية.',
    'users.created': 'أُنشئ في',
    'users.actions': 'إجراءات',
    'users.edit': 'تعديل',
    'users.delete': 'حذف',
    'users.save': 'حفظ',
    'users.cancel': 'إلغاء',
    'users.none': 'لا يوجد مستخدمون',
    'users.allRoles': 'كل الأدوار',
    'users.createdOk': 'تم إنشاء المستخدم',
    'users.updatedOk': 'تم الحفظ',
    'users.deletedOk': 'تم حذف المستخدم',
    'users.confirmDelete': 'حذف هذا الحساب؟',
    'users.fullAccess': 'كامل الصلاحية',
    'users.noConsole': 'لا صلاحية للوحة',
    'users.searchPh': 'ابحث بالاسم أو البريد…',
    'role.member': 'عضو',
    'role.trainer': 'مدرب',
    'role.admin': 'مشرف',
    'status.suspended': 'موقوف',
    'perm.members': 'الأعضاء',
    'perm.trainers': 'المدربون',
    'perm.plans': 'الخطط',
    'perm.billing': 'الفوترة والإيرادات',
    'perm.settings': 'الإعدادات',
    'perm.users': 'حسابات المستخدمين',

    'nav.roles': 'الأدوار',
    'nav.audit': 'السجل',
    'common.view': 'عرض',
    'common.manage': 'تعديل',
    'users.access': 'الوصول',
    'users.fullAccessOpt': 'كامل الصلاحية (مشرف عام)',
    'users.customOpt': 'صلاحيات مخصّصة',
    'roles.title': 'الأدوار',
    'roles.subtitle': 'اجمع الصلاحيات في دور بِاسم، ثم أسنِده لحسابات المشرفين.',
    'roles.add': 'إضافة دور',
    'roles.name': 'اسم الدور',
    'roles.namePh': 'مثال: موظف استقبال',
    'roles.key': 'المعرّف',
    'roles.keyPh': 'يُولّد من الاسم',
    'roles.keyHint': 'معرّف قصير. اتركه فارغًا لتوليده من الاسم.',
    'roles.permissions': 'الصلاحيات',
    'roles.usersCount': 'المستخدمون',
    'roles.system': 'نظام',
    'roles.none': 'لا توجد أدوار مخصّصة بعد.',
    'roles.edit': 'تعديل',
    'roles.delete': 'حذف',
    'roles.save': 'حفظ الدور',
    'roles.cancel': 'إلغاء',
    'roles.confirmDelete': 'حذف هذا الدور؟ سيفقد مستخدموه صلاحية اللوحة حتى إعادة إسنادهم.',
    'audit.title': 'سجلّ الإجراءات',
    'audit.subtitle': 'أحدث الإجراءات في لوحة التحكم.',
    'audit.who': 'المشرف',
    'audit.action': 'الإجراء',
    'audit.entity': 'المجال',
    'audit.when': 'الوقت',
    'audit.none': 'لا يوجد نشاط بعد',
    'action.create_user': 'أنشأ مستخدمًا',
    'action.update_user': 'عدّل مستخدمًا',
    'action.delete_user': 'حذف مستخدمًا',
    'action.update_member': 'عدّل عضوًا',
    'action.update_settings': 'عدّل الإعدادات',
    'action.save_role': 'حفظ دورًا',
    'action.delete_role': 'حذف دورًا',
    'entity.users': 'المستخدمون',
    'entity.members': 'الأعضاء',
    'entity.app_settings': 'الإعدادات',
    'entity.admin_roles': 'الأدوار',
    'entity.trainers': 'المدربون',
    'action.update_trainer': 'عدّل مدربًا',
    'freeze.freeze': 'تجميد',
    'freeze.unfreeze': 'إلغاء التجميد',
    'freeze.suspended': 'مُجمّد',
    'freeze.confirmFreeze': 'تجميد هذا الحساب؟ لن يتمكّن من تسجيل الدخول.',
    'freeze.confirmUnfreeze': 'إعادة تفعيل هذا الحساب؟',
    'table.actions': 'إجراءات',
  };

  const FR = {
    'common.language': 'Langue',
    'common.noData': 'Aucune donnée',
    'common.loading': 'Chargement…',

    'login.title': "Console d'administration",
    'login.subtitle': 'Connectez-vous pour gérer membres, coachs et facturation.',
    'login.email': 'E-mail',
    'login.password': 'Mot de passe',
    'login.signIn': 'Se connecter',
    'login.signingIn': 'Connexion…',
    'login.failed': 'Échec de connexion',

    'nav.overview': "Vue d'ensemble",
    'nav.members': 'Membres',
    'nav.trainers': 'Coachs',
    'nav.plans': 'Programmes',
    'nav.system': 'Système',
    'nav.settings': 'Réglages',
    'nav.logout': 'Se déconnecter',

    'head.admin': 'Admin',

    'kpi.totalMembers': 'Membres au total',
    'kpi.active': 'Actifs',
    'kpi.activeDesc': 'avec un abonnement actif',
    'kpi.expiring': 'Expire ≤7 j',
    'kpi.expiringDesc': 'à relancer',
    'kpi.mrr': 'MRR',
    'kpi.mrrDesc': '{trainers} coachs · {sessions} séances aujourd’hui',
    'card.growth': 'Croissance des membres',
    'card.growthSub': 'nouvelles inscriptions · 12 dernières semaines',
    'card.byTier': 'Par formule',

    'members.searchPh': 'Rechercher par nom ou e-mail…',
    'members.allStatuses': 'Tous les statuts',
    'members.none': 'Aucun membre trouvé',
    'status.active': 'Actif',
    'status.frozen': 'Gelé',
    'status.expired': 'Expiré',

    'table.member': 'Membre',
    'table.tier': 'Formule',
    'table.trainer': 'Coach',
    'table.status': 'Statut',
    'table.renews': 'Renouvelle',
    'table.specialty': 'Spécialité',
    'table.clients': 'Clients',
    'table.rating': 'Note',
    'table.reply': 'Réponse',
    'table.plan': 'Programme',
    'table.split': 'Répartition',
    'table.days': 'Jours',
    'table.goal': 'Objectif',
    'table.level': 'Niveau',

    'pager.prev': 'Préc.',
    'pager.next': 'Suiv.',
    'pager.info': 'Page {page} sur {pages} · {total} au total',

    'settings.title': 'Réglages',
    'settings.currency': 'Devise',
    'settings.currencyDesc': 'Utilisée pour tous les montants de revenus et de prix.',
    'settings.symbolPosition': 'Position du symbole',
    'settings.posBefore': 'Avant le montant (ex. 100 $)',
    'settings.posAfter': 'Après le montant (ex. 100 $)',
    'settings.save': 'Enregistrer',
    'settings.saved': 'Enregistré',
    'settings.saveFailed': "Échec de l'enregistrement",
    'settings.languages': 'Langues',
    'settings.languagesDesc':
      "L'arabe, l'anglais et le français sont intégrés. Ajoutez-en d'autres en téléchargeant le modèle, en traduisant la dernière colonne puis en l'important.",
    'settings.downloadTemplate': 'Télécharger le modèle de traduction (CSV)',
    'settings.addLanguage': 'Ajouter / mettre à jour une langue',
    'settings.langCode': 'Code de langue',
    'settings.langCodePh': 'ex. es, tr, de',
    'settings.langName': 'Nom de la langue',
    'settings.langNamePh': 'ex. Español',
    'settings.direction': 'Sens du texte',
    'settings.ltr': 'Gauche à droite',
    'settings.rtl': 'Droite à gauche',
    'settings.csvFile': 'Fichier CSV traduit',
    'settings.upload': 'Importer la langue',
    'settings.customLangs': 'Langues personnalisées',
    'settings.noCustom': 'Aucune langue personnalisée.',
    'settings.delete': 'Supprimer',
    'settings.uploaded': 'Langue ajoutée',
    'settings.needCode': 'Saisissez un code et un nom de langue.',
    'settings.badCsv': 'Impossible de lire ce CSV. Utilisez le modèle téléchargé.',
    'settings.confirmDelete': 'Supprimer cette langue ?',

    'nav.users': 'Utilisateurs',
    'users.title': 'Comptes utilisateurs',
    'users.subtitle': 'Créez des comptes, attribuez des rôles et contrôlez l’accès de chaque admin.',
    'users.add': 'Ajouter un utilisateur',
    'users.name': 'Nom',
    'users.email': 'E-mail',
    'users.password': 'Mot de passe',
    'users.newPassword': 'Nouveau mot de passe',
    'users.newPasswordHint': 'Laissez vide pour conserver le mot de passe actuel.',
    'users.role': 'Rôle',
    'users.status': 'Statut',
    'users.permissions': 'Autorisations',
    'users.permsHint': 'Les autorisations s’appliquent aux comptes admin et déterminent les sections accessibles. Laissez tout activé pour un accès complet.',
    'users.created': 'Créé le',
    'users.actions': 'Actions',
    'users.edit': 'Modifier',
    'users.delete': 'Supprimer',
    'users.save': 'Enregistrer',
    'users.cancel': 'Annuler',
    'users.none': 'Aucun utilisateur',
    'users.allRoles': 'Tous les rôles',
    'users.createdOk': 'Utilisateur créé',
    'users.updatedOk': 'Enregistré',
    'users.deletedOk': 'Utilisateur supprimé',
    'users.confirmDelete': 'Supprimer ce compte ?',
    'users.fullAccess': 'Accès complet',
    'users.noConsole': 'Aucun accès console',
    'users.searchPh': 'Rechercher par nom ou e-mail…',
    'role.member': 'Membre',
    'role.trainer': 'Coach',
    'role.admin': 'Admin',
    'status.suspended': 'Suspendu',
    'perm.members': 'Membres',
    'perm.trainers': 'Coachs',
    'perm.plans': 'Programmes',
    'perm.billing': 'Facturation & revenus',
    'perm.settings': 'Réglages',
    'perm.users': 'Comptes utilisateurs',

    'nav.roles': 'Rôles',
    'nav.audit': 'Activité',
    'common.view': 'Voir',
    'common.manage': 'Gérer',
    'users.access': 'Accès',
    'users.fullAccessOpt': 'Accès complet (super admin)',
    'users.customOpt': 'Autorisations personnalisées',
    'roles.title': 'Rôles',
    'roles.subtitle': 'Regroupez des autorisations dans un rôle nommé, puis attribuez-le aux comptes admin.',
    'roles.add': 'Ajouter un rôle',
    'roles.name': 'Nom du rôle',
    'roles.namePh': 'ex. Réceptionniste',
    'roles.key': 'Clé',
    'roles.keyPh': 'auto depuis le nom',
    'roles.keyHint': 'Un identifiant court. Laissez vide pour le générer depuis le nom.',
    'roles.permissions': 'Autorisations',
    'roles.usersCount': 'Utilisateurs',
    'roles.system': 'Système',
    'roles.none': 'Aucun rôle personnalisé.',
    'roles.edit': 'Modifier',
    'roles.delete': 'Supprimer',
    'roles.save': 'Enregistrer le rôle',
    'roles.cancel': 'Annuler',
    'roles.confirmDelete': 'Supprimer ce rôle ? Ses utilisateurs perdent l’accès jusqu’à réattribution.',
    'audit.title': 'Journal d’activité',
    'audit.subtitle': 'Actions récentes dans la console d’administration.',
    'audit.who': 'Admin',
    'audit.action': 'Action',
    'audit.entity': 'Zone',
    'audit.when': 'Quand',
    'audit.none': 'Aucune activité',
    'action.create_user': 'A créé un utilisateur',
    'action.update_user': 'A modifié un utilisateur',
    'action.delete_user': 'A supprimé un utilisateur',
    'action.update_member': 'A modifié un membre',
    'action.update_settings': 'A modifié les réglages',
    'action.save_role': 'A enregistré un rôle',
    'action.delete_role': 'A supprimé un rôle',
    'entity.users': 'Utilisateurs',
    'entity.members': 'Membres',
    'entity.app_settings': 'Réglages',
    'entity.admin_roles': 'Rôles',
    'entity.trainers': 'Coachs',
    'action.update_trainer': 'A modifié un coach',
    'freeze.freeze': 'Geler',
    'freeze.unfreeze': 'Réactiver',
    'freeze.suspended': 'Gelé',
    'freeze.confirmFreeze': 'Geler ce compte ? Il ne pourra plus se connecter.',
    'freeze.confirmUnfreeze': 'Réactiver ce compte ?',
    'table.actions': 'Actions',
  };

  const BASE = { en: EN, ar: AR, fr: FR };
  const BASE_META = [
    { code: 'en', name: 'English', dir: 'ltr' },
    { code: 'ar', name: 'العربية', dir: 'rtl' },
    { code: 'fr', name: 'Français', dir: 'ltr' },
  ];

  // Curated currency list (code → symbol). Admins can pick position too.
  const CURRENCIES = [
    { code: 'USD', symbol: '$' },
    { code: 'EUR', symbol: '€' },
    { code: 'GBP', symbol: '£' },
    { code: 'SAR', symbol: 'ر.س' },
    { code: 'AED', symbol: 'د.إ' },
    { code: 'QAR', symbol: 'ر.ق' },
    { code: 'KWD', symbol: 'د.ك' },
    { code: 'BHD', symbol: '.د.ب' },
    { code: 'OMR', symbol: 'ر.ع' },
    { code: 'EGP', symbol: 'ج.م' },
    { code: 'LYD', symbol: 'ل.د' },
    { code: 'TND', symbol: 'د.ت' },
    { code: 'DZD', symbol: 'د.ج' },
    { code: 'MAD', symbol: 'د.م' },
    { code: 'JOD', symbol: 'د.ا' },
    { code: 'TRY', symbol: '₺' },
    { code: 'INR', symbol: '₹' },
  ];

  const LS_LOCALE = 'arete_locale';
  const LS_CUSTOM = 'arete_custom_locales'; // {code:{name,dir,strings}}
  const LS_CURRENCY = 'arete_currency';

  let current = localStorage.getItem(LS_LOCALE) || 'en';
  let custom = safeParse(localStorage.getItem(LS_CUSTOM)) || {};
  let currency =
    safeParse(localStorage.getItem(LS_CURRENCY)) ||
    { code: 'USD', symbol: '$', position: 'before' };

  function safeParse(s) {
    try { return s ? JSON.parse(s) : null; } catch (_) { return null; }
  }

  function dict(code) {
    if (BASE[code]) return BASE[code];
    if (custom[code]) return custom[code].strings || {};
    return EN;
  }

  // Translate a key with {var} interpolation; falls back to EN then the key.
  function t(key, vars) {
    const d = dict(current);
    let s = d[key];
    if (s == null) s = EN[key];
    if (s == null) s = key;
    if (vars) {
      s = s.replace(/\{(\w+)\}/g, (m, k) => (vars[k] != null ? vars[k] : m));
    }
    return s;
  }

  function dirOf(code) {
    if (code === 'ar') return 'rtl';
    const m = BASE_META.find((x) => x.code === code);
    if (m) return m.dir;
    if (custom[code]) return custom[code].dir || 'ltr';
    return 'ltr';
  }

  function getLocale() { return current; }

  function setLocale(code) {
    current = code;
    localStorage.setItem(LS_LOCALE, code);
    document.documentElement.lang = code;
    document.documentElement.dir = dirOf(code);
    apply(document);
  }

  function available() {
    const list = BASE_META.slice();
    Object.keys(custom).forEach((code) => {
      list.push({ code, name: custom[code].name || code, dir: custom[code].dir || 'ltr' });
    });
    return list;
  }

  // Apply translations to any element carrying data-i18n / data-i18n-ph.
  function apply(root) {
    (root || document).querySelectorAll('[data-i18n]').forEach((el) => {
      el.textContent = t(el.getAttribute('data-i18n'));
    });
    (root || document).querySelectorAll('[data-i18n-ph]').forEach((el) => {
      el.setAttribute('placeholder', t(el.getAttribute('data-i18n-ph')));
    });
    (root || document).querySelectorAll('[data-i18n-title]').forEach((el) => {
      el.setAttribute('title', t(el.getAttribute('data-i18n-title')));
    });
  }

  // ---- Currency ----
  function setCurrency(c) {
    currency = {
      code: c.code || 'USD',
      symbol: c.symbol || '$',
      position: c.position === 'after' ? 'after' : 'before',
    };
    localStorage.setItem(LS_CURRENCY, JSON.stringify(currency));
  }
  function getCurrency() { return currency; }
  function money(n) {
    const v = Number(n || 0).toLocaleString(undefined, { maximumFractionDigits: 2 });
    return currency.position === 'after' ? `${v} ${currency.symbol}` : `${currency.symbol}${v}`;
  }

  // ---- Custom locales (server-synced) ----
  function setCustomLocales(map) {
    custom = map || {};
    localStorage.setItem(LS_CUSTOM, JSON.stringify(custom));
  }
  function upsertCustom(code, entry) {
    custom[code] = entry;
    localStorage.setItem(LS_CUSTOM, JSON.stringify(custom));
  }
  function removeCustom(code) {
    delete custom[code];
    localStorage.setItem(LS_CUSTOM, JSON.stringify(custom));
  }

  // ---- CSV helpers (RFC-4180-ish, enough for translation tables) ----
  function keys() { return Object.keys(EN); }

  // Build the template: key, English, <locale or blank> columns.
  function buildTemplateCSV() {
    const rows = [['key', 'english', 'translation']];
    keys().forEach((k) => rows.push([k, EN[k], '']));
    return rows.map((r) => r.map(csvCell).join(',')).join('\r\n');
  }

  function csvCell(s) {
    s = s == null ? '' : String(s);
    if (/[",\r\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
    return s;
  }

  // Parse CSV text → array of rows (arrays of cells).
  function parseCSV(text) {
    const rows = [];
    let row = [], cell = '', i = 0, inQ = false;
    text = text.replace(/^﻿/, ''); // strip BOM
    while (i < text.length) {
      const c = text[i];
      if (inQ) {
        if (c === '"') {
          if (text[i + 1] === '"') { cell += '"'; i += 2; continue; }
          inQ = false; i++; continue;
        }
        cell += c; i++; continue;
      }
      if (c === '"') { inQ = true; i++; continue; }
      if (c === ',') { row.push(cell); cell = ''; i++; continue; }
      if (c === '\r') { i++; continue; }
      if (c === '\n') { row.push(cell); rows.push(row); row = []; cell = ''; i++; continue; }
      cell += c; i++;
    }
    if (cell.length || row.length) { row.push(cell); rows.push(row); }
    return rows;
  }

  // Turn a translated template into a {key: value} map. Uses the 3rd column
  // (translation); ignores the header and rows whose key isn't recognised.
  function stringsFromCSV(text) {
    const rows = parseCSV(text);
    if (!rows.length) return null;
    const known = new Set(keys());
    const out = {};
    let used = 0;
    rows.forEach((r, idx) => {
      if (idx === 0 && String(r[0]).toLowerCase() === 'key') return; // header
      const k = (r[0] || '').trim();
      const v = (r[2] != null ? r[2] : '').trim();
      if (k && known.has(k) && v) { out[k] = v; used++; }
    });
    return used ? out : null;
  }

  function download(filename, text) {
    const blob = new Blob([text], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename;
    document.body.appendChild(a); a.click();
    document.body.removeChild(a); URL.revokeObjectURL(url);
  }

  global.I18N = {
    t, apply, setLocale, getLocale, available, dirOf,
    setCurrency, getCurrency, money,
    setCustomLocales, upsertCustom, removeCustom,
    CURRENCIES, keys, buildTemplateCSV, stringsFromCSV, download,
  };
})(window);
