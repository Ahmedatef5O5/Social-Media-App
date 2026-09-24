# المساهمة في Social Media App

## قبل أول push

```powershell
flutter pub get
.\scripts\local_ci.ps1
```

إن مرّ هذا، سيمرّ CI. إن لم يمرّ، لن يمرّ CI.

## تشغيل التطبيق

الأسرار تُحقن عبر `--dart-define-from-file`، لا عبر ملف مرصود في Git:

```powershell
flutter run --dart-define-from-file=.env
```

بدونها يُطلق `AppSecrets.assertSecretsLoaded()` تأكيداً بالرسالة الصحيحة.

## القواعد الأربع التي تحرسها المراجعة

### 1. لا `catch` ينتهي عند `debugPrint`
`debugPrint` غير موجود في الإنتاج. كل `catch` جديد يمر عبر:

```dart
obs.recordError(e, s, feature: 'chat', operation: 'sendMessage');
// أو
_log.error(e, s, operation: 'sendMessage');
```

إن كان الخطأ متوقعاً فعلاً (إلغاء من المستخدم مثلاً)، مرّره بـ `category: ErrorCategory.businessExpected` — التصريح مطلوب، والصمت ليس خياراً.

### 2. كل استعلام `.select()` له حدّ
الإحصاء الحالي: 101 `.select()` مقابل 15 `.range()/.limit()`. لا تزد الرقم الأول. إن كان الاستعلام محدوداً بطبيعته (`.eq('id', x).maybeSingle()`)، اكتب تعليقاً يقول ذلك.

### 3. كل اشتراك يُلغى، وكل قناة تُسجَّل
```dart
_sub = stream.listen(...);
RealtimeDiagnostics.instance.onChannelCreated(topic, ownerUserId: currentUserId);

@override
Future<void> close() {
  _sub?.cancel();
  RealtimeDiagnostics.instance.onChannelClosed(topic);
  return super.close();
}
```
`analysis_options.yaml` يرفع `cancel_subscriptions` و `close_sinks` إلى مستوى error، فـ CI تمسك أغلب الحالات — لكن ليس كلها.

### 4. لا singleton جديد في مسار قابل للاختبار
إن احتجت خدمة داخل Cubit، مرّرها عبر المُنشئ مع قيمة افتراضية:

```dart
MyCubit({NetworkStatusService? networkStatus})
  : _networkStatus = networkStatus ?? NetworkStatusService.instance;
```

## تسمية الفروع والـ commits

```
feat/…    إضافة
fix/…     إصلاح
test/…    اختبارات فقط
chore/…   بنية تحتية، CI، توثيق
```

## إصلاح عطل إنتاجي

الترتيب غير قابل للتفاوض:

1. اقرأ issue في Crashlytics — المفاتيح والـ breadcrumbs.
2. **اكتب اختباراً يفشل.** لا تلمس كود الإنتاج قبل رؤيته أحمر.
3. أصلح.
4. أرفق رابط Crashlytics ومسار ملف الاختبار في وصف الـ PR.

اختبار كُتب بعد الإصلاح يثبت أن الكود يفعل ما يفعله — لا أن الخطأ اختفى.
