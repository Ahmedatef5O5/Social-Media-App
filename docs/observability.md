# المراقبة الإنتاجية — Social Media App

## التشخيص: المشكلة ليست غياب Crashlytics

المعالجات موجودة فعلاً في `main.dart` منذ البداية:

```dart
FlutterError.onError = (details) { ... };
PlatformDispatcher.instance.onError = (error, stack) { ... };
runZonedGuarded(...)
```

لكنها تنتهي كلها إلى `debugPrint`. و`debugPrint` **غير موجود في الإنتاج** — لا يذهب إلى أي مكان يمكنك قراءته.

المشكلة المعمارية الأعمق: `Firebase.initializeApp()` كان يُستدعى داخل `initializeCoreServices()`، التي تعمل **بعد** `runApp()`. أي إضافة مباشرة لـ Crashlytics في `main.dart` كانت ستفشل صامتة على أعطال بدء التشغيل — وهي أثمن دلو أخطاء لديك.

## البنية

```
main.dart
  │ يثبّت المعالجات في أول سطر
  ▼
Observability (واجهة + طابور مؤقت محدود)
  │   ├─ قبل الربط: يخزّن حتى 64 حدثاً
  │   └─ بعد الربط: يفرّغها ثم يمرر مباشرة
  ▼
CrashReporter (واجهة مجردة)
  ├─ CrashlyticsReporter   ← الإنتاج، الملف الوحيد الذي يستورد Firebase
  ├─ NoopCrashReporter     ← debug / ما قبل التهيئة
  └─ RecordingCrashReporter ← الاختبارات
```

الطابور هو ما يحل مشكلة الترتيب: عطل أثناء `Firebase.initializeApp` نفسه يُلتقط ويُرسل بعد نجاح التهيئة.

## تصنيف الأخطاء

`ErrorClassifier.classify(error)` يحوّل أي كائن إلى `ErrorCategory`، وكل فئة لها سياسة ثابتة:

| الفئة | السياسة | لماذا |
|---|---|---|
| `fatalCrash` | Crashlytics **fatal** | أطاح بإطار أو عزلة |
| `handledException` | Crashlytics non-fatal | تعافى التطبيق، لكن الهندسة يجب أن ترى |
| `authentication` | non-fatal | فشل تحديث جلسة = مشكلة حقيقية |
| `realtime` | non-fatal | قنوات مكررة/zombie = C-02 و H-02 |
| `database` | non-fatal | ما عدا `PGRST116` |
| `parsing` | non-fatal | هذه هي التي تسمّم كاش Hive بصمت |
| `cache` | non-fatal | أخطاء صناديق Hive |
| `mediaUpload` | non-fatal | فشل Cloudinary/Storage |
| `aiProvider` | non-fatal | فشل مزوّد الذكاء |
| `network` | **breadcrumb فقط** | نفق المترو، ليس خطأنا — لكنه يبقى في المسار الزمني لأي عطل لاحق |
| `businessExpected` | **يُتجاهل** | كلمة مرور خاطئة، إلغاء رفع من المستخدم، `PGRST116` |

الخطأ غير المعروف يسقط على `handledException` — أي **يُبلَّغ عنه**. خطأ مجهول لا يُهمَل بصمت أبداً.

## السياق الآمن

يُرسل مع كل تقرير:

```
environment  app_version  build_number  commit_sha
feature      screen       operation     session_state
network_online            realtime_active_channels
last_<operation>_ms
```

هوية المستخدم: **لا يُخزَّن الـ UUID الخام أبداً.** `Observability.setSessionUser` يُطبّق SHA-256 ويأخذ أول 12 حرفاً. هذا كافٍ للإجابة على "هل هذا مستخدم واحد أم ألف؟" دون أن يكون التقرير معرّفاً للهوية.

**ممنوع منعاً باتاً في السياق أو الـ breadcrumbs:** نص الرسائل، محتوى المحادثات، رموز الوصول، البريد الإلكتروني، أرقام الهواتف، روابط الوسائط الموقّعة، أي مفتاح من `AppSecrets`.

## مراقبة Realtime

التطبيق يفتح قنوات من **12 ملفاً** (20 استدعاء `.channel()`). عدة خدمات تدور يدوياً على `getChannels()` لحذف قناة بنفس الاسم قبل الاشتراك — وهذا دليل بذاته على أن التكرار كان مشكلة إنتاج.

`RealtimeDiagnostics` سجل مركزي يجيب على ما لم يكن أحد يعرفه:

```dart
RealtimeDiagnostics.instance.onChannelCreated(topic, ownerUserId: uid);
RealtimeDiagnostics.instance.onChannelSubscribed(topic);
RealtimeDiagnostics.instance.onChannelError(topic, error, stack);
RealtimeDiagnostics.instance.onChannelClosed(topic);
RealtimeDiagnostics.instance.detectZombies(currentUserId);   // بعد تبديل الحساب
```

ثلاث إشارات تلقائية:
- **`DuplicateRealtimeSubscription`** — اشتراك ثانٍ على نفس الموضوع وهو حيّ. هذا هو مصدر "الرسالة تظهر مرتين" و"عداد غير المقروء مضاعف".
- **`ZombieRealtimeChannels`** — قناة نجت من تبديل حساب. هذه هي C-02 حرفياً.
- **`RealtimeChannelPressure`** — تجاوز 24 قناة نشطة.

**التوصيل مطلوب يدوياً.** لم أعدّل الـ 12 ملفاً — ذلك تغيير واسع يستحق PR خاصاً به. ابدأ بالأعلى قيمة: `chat_presence_service.dart`، `group_realtime_sync_mixin.dart`، `posts_services.dart`.

## مراقبة الأداء

```dart
final posts = await obs.trace(
  'feed_load',
  () => _postsServices.fetchPosts(),
  feature: 'feed',
  slowAfter: const Duration(seconds: 5),
);
```

- دائماً: breadcrumb + مفتاح `last_feed_load_ms`.
- عند التجاوز: issue باسم `SlowOperationException: feed_load took 8231ms`.
- عند الفشل: التقرير يحمل `failed after 8231ms` ثم يُعاد رمي الاستثناء — معالجة الأخطاء القائمة عند المستدعي لا تتغير.

مرشحون واضحون للتغليف: `fetchPosts`، `sendMessage`، رفع Cloudinary، طلبات الذكاء، `initializeCoreServices`.

## التسجيل

`AppLogger` واجهة صغيرة عمداً. المشروع فيه مئات `debugPrint` — **لا تحوّلها دفعة واحدة**. ذلك PR ضخم بلا فائدة سلوكية ويخفي التغييرات الحقيقية في المراجعة. القاعدة: حوّل سطراً عندما تلمسه لسبب آخر.

```dart
const _log = AppLogger('chat_details');

_log.debug('...');   // debug فقط، لا يغادر الجهاز
_log.info('...');    // breadcrumb
_log.warn('...');    // breadcrumb بعلامة
_log.error(e, s, operation: 'sendMessage');   // مصنَّف ومُبلَّغ عنه
```

## التحقق

```powershell
# إجبار عطل تجريبي في debug — يجب أن يظهر في Crashlytics خلال دقائق
# (فعّل collectionEnabled مؤقتاً في _initObservability)
flutter run --dart-define-from-file=.env
```

الاختبارات التي تثبت أن الأنبوب يعمل دون Firebase إطلاقاً:
```
test/core/observability/observability_test.dart
test/core/observability/error_classifier_test.dart
test/core/observability/realtime_diagnostics_test.dart
```
