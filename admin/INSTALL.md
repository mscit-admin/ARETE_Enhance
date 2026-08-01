# دليل تثبيت لوحة إدارة ARETE على الخادم

خطوات كاملة من سحب المشروع من GitHub حتى تشغيل اللوحة على الخادم
(مثال: `161.97.78.116`). الأوامر لنظام **Ubuntu/Debian**.

---

## 0) الدخول إلى الخادم

```bash
ssh root@161.97.78.116
# أو مستخدم عادي:  ssh youruser@161.97.78.116
```

---

## 1) تثبيت المتطلّبات (Node 18+، PostgreSQL، Git)

```bash
sudo apt update
sudo apt install -y git curl postgresql

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# تأكيد
node -v        # يجب أن يكون 18 أو أحدث
psql --version
```

---

## 2) سحب المشروع من GitHub ووضعه في مجلده الخاص

سننشئ مجلدًا مخصّصًا في `/opt/arete`:

```bash
sudo mkdir -p /opt/arete
sudo chown "$USER":"$USER" /opt/arete
cd /opt/arete
```

استنساخ المستودع داخل هذا المجلد:

```bash
git clone https://github.com/mscit-admin/arete_enhance.git .
```

> **المستودع خاص (private)** — لذلك يطلب مصادقة. استخدم أحد الخيارين:
>
> **أ) عبر Personal Access Token (الأسهل):**
> ```bash
> git clone https://<GITHUB_TOKEN>@github.com/mscit-admin/arete_enhance.git .
> ```
> أنشئ التوكن من: GitHub → Settings → Developer settings → Personal access tokens (صلاحية `repo`).
>
> **ب) عبر مفتاح SSH:**
> ```bash
> ssh-keygen -t ed25519 -C "arete-server"      # ثم أضف المفتاح العام في GitHub → Deploy keys
> git clone git@github.com:mscit-admin/arete_enhance.git .
> ```

اختَر فرع العمل الحالي:

```bash
git checkout claude/fitness-app-phase-1-design-3jz9c6
```

الآن مجلد الخادم موجود في: `/opt/arete/admin/server`

---

## 3) تشغيل المُنصّب التفاعلي

```bash
cd /opt/arete/admin/server
sudo bash install.sh
```

سيسألك عن (اضغط Enter لقبول القيمة بين الأقواس):

| السؤال | القيمة المقترحة |
|---|---|
| HTTP port | `4000` |
| Bind address | `0.0.0.0` |
| **Public IP or domain name** | `161.97.78.116` |
| PostgreSQL host | `localhost` |
| PostgreSQL port | `5432` |
| Database name | `arete` |
| Database user | `arete` |
| Database password | *(اختر كلمة مرور)* |
| JWT secret | *(اترك فارغًا ليُولّد تلقائيًا)* |
| Token lifetime | `12h` |
| Admin email | `admin@arete.fit` |
| Admin password | *(اختر كلمة مرور ≥ 6 أحرف)* |
| Create the database and role now? | `y` ← ثم superuser: `postgres` |
| Load sample demo data? | `N` للإنتاج، `y` للتجربة |
| Install a systemd service? | `Y` |
| Open port in ufw? | `Y` (إن كان الجدار الناري مُفعّلًا) |

في النهاية سيطبع:

```
Admin console:  http://161.97.78.116:4000
Sign in with:   admin@arete.fit
```

---

## 4) الدخول والتحقق

افتح من المتصفح: **http://161.97.78.116:4000**
وسجّل الدخول ببريد وكلمة مرور الأدمن اللذين أدخلتهما.

فحص سريع من الطرفية:

```bash
curl http://localhost:4000/api/health        # {"ok":true}
systemctl status arete-admin                  # حالة الخدمة
journalctl -u arete-admin -f                  # السجلات الحية (Ctrl+C للخروج)
```

---

## 5) إدارة الخدمة

```bash
sudo systemctl restart arete-admin     # إعادة تشغيل
sudo systemctl stop arete-admin        # إيقاف
sudo systemctl start arete-admin       # تشغيل
sudo systemctl disable arete-admin     # تعطيل الإقلاع التلقائي
```

---

## 6) تحديث النسخة لاحقًا

```bash
cd /opt/arete
git pull
cd admin/server
npm install --omit=dev
npm run migrate                        # يطبّق أي تغييرات في المخطط
sudo systemctl restart arete-admin
```

---

## حل المشكلات

- **المنفذ لا يُفتح من الخارج:** افتحه في الجدار الناري:
  `sudo ufw allow 4000/tcp` — وتأكّد أن مزوّد الخادم لا يحجب المنفذ.
- **فشل الاتصال بقاعدة البيانات:** تأكّد أن PostgreSQL يعمل (`sudo systemctl status postgresql`)
  وأن المستخدم/القاعدة موجودان (المُنصّب ينشئهما إن اخترت `y`).
- **إعادة الإدخال:** أعِد تشغيل `sudo bash install.sh` — سيسألك قبل استبدال `.env`.
- **إنشاء/تغيير الأدمن فقط دون مسح بيانات:**
  ```bash
  cd /opt/arete/admin/server
  ADMIN_EMAIL=you@club.com ADMIN_PASSWORD=يكلمةمرور npm run create-admin
  ```

---

## ملاحظة أمان

هذا يعمل حاليًا عبر **HTTP** على IP مباشر. عند حصولك على **دومين**، يُنصح بوضع اللوحة خلف
**HTTPS** عبر reverse proxy (Nginx أو Caddy) وشهادة Let's Encrypt مجانية. أخبرني وسأجهّز الإعداد.
