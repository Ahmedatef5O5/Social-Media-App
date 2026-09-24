# CI/CD — Social Media App

## الحالة قبل هذا التغيير

لا يوجد `.github/` في المستودع. تقرير V6 ذكر أن أساس CI/CD المصمَّم في V5 غير موجود فعلياً، وفحص الملفات يؤكد ذلك.

## المبدأ: بوابات متدرجة

```
PR
 ├── quality   (~2 دقيقة)   format + analyze        ← يفشل أولاً وأرخص
 ├── test      (~5 دقائق)   flutter test + coverage ← لا يحتاج أي سر
 └── build     (~12 دقيقة)  debug APK               ← يحتاج أسراراً، يُتخطّى على الـ forks
```

`quality` قبل `test` قبل `build`. لا معنى لصرف أربع دقائق على حل التبعيات ثم البناء لتفشل على فاصلة ناقصة.

| الوظيفة | تمنع الدمج؟ |
|---|---|
| `quality` | **نعم** |
| `test` | **نعم** |
| coverage gate (المسارات الحرجة) | **نعم** |
| `build` | نعم على المستودع الأصلي، **متخطّاة** على الـ forks |
| `release` | لا علاقة لها بالـ PR — على الوسوم فقط |

فعّل هذه في GitHub: *Settings → Branches → Branch protection rule* على `main`، واختر `quality` و `test` كـ required status checks.

## لماذا الاختبارات لا تحتاج أسراراً

`AppSecrets` يقرأ كل شيء عبر `String.fromEnvironment`، لكن `assertSecretsLoaded()` لا يُستدعى إلا داخل `initializeCoreServices()` — ولا يصل إليها أي اختبار وحدة. وكل تبعية خارجية خلف واجهة أو mock. النتيجة العملية: **مساهم من fork يحصل على تغذية راجعة كاملة على الاختبارات**، وهذه خاصية نادرة في مشاريع Flutter بهذا الحجم.

## الأسرار — الاستراتيجية الكاملة

### ما يبقى محلياً ولا يُرفع أبداً
```
.env                              أسرار Supabase/Cloudinary/Giphy/FCM
android/app/google-services.json  إعداد Firebase
lib/firebase_options.dart         مولَّد بـ flutterfire configure
android/key.properties            كلمات مرور التوقيع
*.jks / *.keystore                مادة التوقيع
```
تأكد أن `.gitignore` يغطيها كلها. (لم يكن `.gitignore` ضمن الـ repomix، فتحقق بنفسك.)

### GitHub Secrets المطلوبة

| الاسم | المحتوى | تُستخدم في |
|---|---|---|
| `DART_DEFINE_ENV_BASE64` | `.env` (بيئة dev/staging) مُرمَّز base64 | `ci.yml` |
| `DART_DEFINE_ENV_PROD_BASE64` | `.env` الإنتاج مُرمَّز base64 | `release.yml` |
| `GOOGLE_SERVICES_JSON_BASE64` | `google-services.json` مُرمَّز | كلاهما |
| `FIREBASE_OPTIONS_DART_BASE64` | `lib/firebase_options.dart` مُرمَّز | كلاهما |
| `ANDROID_KEYSTORE_BASE64` | ملف `.jks` مُرمَّز | `release.yml` |
| `ANDROID_STORE_PASSWORD` | نص | `release.yml` |
| `ANDROID_KEY_PASSWORD` | نص | `release.yml` |
| `ANDROID_KEY_ALIAS` | نص | `release.yml` |

### GitHub Variables (ليست أسراراً)
`FLUTTER_VERSION` إن أردت تغييره دون تعديل الـ YAML. حالياً مثبّت داخل الملف — **عدّله ليطابق مخرجات `flutter --version` لديك.** `pubspec.yaml` يثبّت `sdk: ^3.7.2` وهو إصدار Dart لا Flutter، فـ CI لا يستطيع استنتاجه.

### توليد قيمة base64 على Windows
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".env")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\google-services.json")) | Set-Clipboard
```

### قواعد الأمان المطبَّقة في الـ workflows
- لا سر يُطبع في أي سطر، ولا حتى للتشخيص.
- كل ملف حُقن يُحذف في خطوة `if: always()` — حتى لو فشل البناء.
- `release.yml` يستخدم GitHub Environment اسمه `production`. أضف إليه required reviewer: هذا ما يمنع وسماً بالخطأ من الشحن.
- البناء الموقَّع لا يحدث أبداً في سياق PR.

## الأداء

| الأسلوب | المكسب |
|---|---|
| `cache: true` في `subosito/flutter-action` | لا إعادة تنزيل للـ SDK |
| `actions/cache` على `~/.pub-cache` بمفتاح `pubspec.lock` | حل تبعيات شبه فوري |
| `actions/cache` على `~/.gradle` | أكبر توفير في وظيفة البناء |
| `concurrency` مع `cancel-in-progress` على الـ PRs فقط | لا تُهدر دقائق على commit متجاوَز؛ و`main` لا يُلغى لأنه يحرس الإصدارات |
| `needs:` متسلسل | لا تبدأ الوظيفة الغالية قبل نجاح الرخيصة |
| `timeout-minutes` على كل وظيفة | وظيفة معلّقة لا تستهلك ساعة |

## تشخيص فشل CI

| السؤال | الجواب |
|---|---|
| ما الذي فشل؟ | اسم الوظيفة والخطوة في ملخص التشغيل |
| لماذا؟ | `--reporter github` يحوّل فشل الاختبار إلى تعليق مباشر على السطر في الـ diff |
| أي أمر بالضبط؟ | كل خطوة في `ci.yml` فوقها تعليق `# Local equivalent: ...` |
| أي تقرير متاح؟ | الأداة `coverage-lcov` و `app-debug-<sha>` |
| كيف أعيد إنتاجه؟ | `.\scripts\local_ci.ps1` يشغّل البوابات نفسها بالترتيب نفسه |

## Fastlane — لماذا **لا** أوصي به الآن

لا يوجد أي أثر لـ Fastlane في الملفات المرفوعة. وإضافته اليوم تعني: Ruby على الـ runner، `Gemfile.lock` ثانٍ للصيانة، وطبقة إضافية بين خطأ CI وسببه.

ما يفعله Fastlane وGitHub Actions لا تفعله بسهولة هو `supply` — الرفع الآلي للـ Play Store. وهذا يحتاج service account بصلاحيات Play Developer API. **لا دليل لديّ أن هذا الحساب موجود.** التسلسل الصحيح:

1. الآن: GitHub Actions وحدها → artifacts + GitHub Releases. يكفي تماماً.
2. عند تجهيز service account: أضف Fastlane بـ lane واحدة (`deploy_internal`) فقط، بمسؤولية واحدة.
3. لا تنقل البناء إلى Fastlane. GitHub Actions تبني، Fastlane ترفع. حدود واضحة.

## ما لم أستطع التحقق منه

الـ repomix المرفوع يحتوي فقط `lib/` و `test/` و ملفَّي `AndroidManifest.xml` و `pubspec.yaml`. لم أرَ:

```
android/build.gradle(.kts)      android/app/build.gradle(.kts)
android/gradle.properties        gradle-wrapper.properties
.gitignore                       pubspec.lock
analysis_options.yaml            .vscode/launch.json
```

لذلك: إصدار Java (17 هو الافتراض المعقول لـ AGP 8.x)، وجود flavors، أسماء خصائص `signingConfig`، و plugin الـ Crashlytics — **كلها تحتاج تحققاً منك**. أرسل `android/app/build.gradle` وسأعطيك كتلة استبدال دقيقة بدل تخمين.
