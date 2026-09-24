# دليل الاختبارات — Social Media App

## لماذا نختبر هنا وليس في مكان آخر

قاعدة الكود ~130 ألف سطر عبر 955 ملفاً في `lib/`. تغطية شاملة ليست هدفاً واقعياً ولا مفيداً. الهدف: **أن يكون كل مسار قادر على إتلاف بيانات أو تسريب حساب في حساب آخر محمياً باختبار حتمي يعمل في ثوانٍ.**

## نموذج الأولويات

| المستوى | المعنى | أمثلة من هذا المشروع |
|---|---|---|
| **P0** | إتلاف بيانات، أمان، عزل الحسابات | `MessageReconciler`، `ChatHelper.buildConversationId`، `RealtimeDiagnostics`، `ChatDetailsCubit` |
| **P1** | منطق أعمال أساسي | `FeedPaginator`، `SupabaseErrorMapper`، `ErrorClassifier`، `ReelPlayerControllerPool` |
| **P2** | تدفقات إنتاج عالية التكرار | `PresenceService.isConsideredOnline`، `AuthCubit`، `HomeCubit` |
| **P3** | حماية انحدار في الواجهة | حالات loading / error / empty للشاشات الحرجة |
| **P4** | كود عرض منخفض الخطورة | لا نختبره |

القاعدة العملية: **إن كان الخطأ صامتاً في الإنتاج، فهو P0 أو P1.** خطأ يرمي استثناءً مرئياً أقل خطورة من خطأ يكتب في كاش خاطئ بهدوء.

## الطبقات

### الطبقة 1 — اختبارات وحدة (منطق نقي)
لا شبكة، لا Supabase، لا Hive، لا `DateTime.now()` داخل الـ fixtures.

```
test/core/messaging/message_reconciler_test.dart
test/core/helpers/chat_helper_test.dart
test/core/presence/presence_service_test.dart
test/core/errors/supabase_error_mapper_test.dart      (موجود مسبقاً)
test/core/observability/error_classifier_test.dart
test/features/posts/helpers/feed_paginator_test.dart
```

### الطبقة 2 — اختبارات Cubit/BLoC
تركّز على آلات الحالة والسباقات غير المتزامنة.

```
test/features/auth/cubits/auth_cubit_test.dart         (موجود مسبقاً)
test/features/home/cubits/home_cubit_test.dart         (موجود مسبقاً)
test/features/single_chats/cubits/chat_details_cubit_test.dart
```

### الطبقة 3 — اختبارات Widget
**لم تُضف بعد، وهذا قرار وليس إغفالاً.** اختبار Widget يحمي من الانحدار فقط إذا كان الويدجت مستقراً. الشاشات هنا (`chat_details_view.dart`، `home_feed_with_reels.dart`) تعتمد على `BlocProvider` متعدد + `ValueNotifier` + `ScrollablePositionedList` + مشغّلات فيديو. الطريق الصحيح: ابدأ بويدجت واحد معزول له حالات واضحة (فقاعة الرسالة مثلاً) بعد استقرار الطبقتين 1 و2.

### الطبقة 4 — اختبارات تكامل
انظر التعليق المفصّل في `integration_test/critical_flows_test.dart`. مختصره: لا تكتبها قبل وجود بيئة staging وحسابات اختبار قابلة للتصفير.

## قاعدة الحتمية

كل اختبار في هذه المجموعة يلتزم بـ:

1. **لا `Future.delayed` عشوائي.** التبادل بين الأحداث غير المتزامنة يتم بـ `Future<void>.delayed(Duration.zero)` (دورة microtask واحدة) أو `fakeAsync`.
2. **لا `DateTime.now()` في الـ fixtures.** استخدم `kEpoch` و `at(seconds)` من `test/helpers/message_factory.dart`. رسالتان تُنشآن في نفس السطر قد تقعان على نفس الميلي ثانية على runner سريع، فيصبح الترتيب غير حتمي.
3. **لا Supabase حقيقي.** `LocalSnapshotStore` يُرجع `[]` ولا يكتب شيئاً وهو غير مهيّأ، فلا صندوق Hive يُفتح.
4. **لا Firebase.** كل شيء يمر عبر واجهة `CrashReporter`؛ الاختبارات تستخدم `RecordingCrashReporter`.
5. **كل `StreamController` يُغلق في `tearDown`**، وكل Cubit يُغلق بـ `addTearDown(cubit.close)`.

## المنافذ (Seams) — متى تضيف واحداً

عندما يمنعك singleton من الاختبار، **لا تعيد كتابة الـ singleton**. أضف مُعاملاً اختيارياً يفترض السلوك الحالي. هذا النمط مستقر في المشروع بالفعل:

```dart
// موجود مسبقاً
HomeCubit(currentUserIdProvider: () => 'user-1')
NetworkStatusService.withDio(dio)

// مضاف في هذه الدفعة
ChatDetailsCubit(..., currentUserIdProvider: () => 'user-me')
ReelPlayerControllerPool(playerFactory: (id, {required autoPlay}) => FakePlayer(...))
```

الشرط: كل موقع نداء إنتاجي يبقى دون تعديل.

## الأوامر (PowerShell على Windows)

```powershell
flutter test                                    # كل شيء
flutter test test/core/messaging                # مجلد واحد
flutter test --plain-name "H-05"                # اختبار باسمه
flutter test --coverage
dart run tool/check_coverage.dart               # بوابة المسارات الحرجة
.\scripts\local_ci.ps1                          # كل ما تشغّله CI
```

## من عطل إنتاجي إلى اختبار انحداري

هذه الحلقة هي الهدف النهائي للنظام كله:

1. Crashlytics يعرض issue. افتحه واقرأ المفاتيح: `feature`، `screen`، `environment`، `realtime_active_channels`، وسلسلة الـ breadcrumbs.
2. حدّد الدالة النقية أو الـ Cubit المسؤول.
3. اكتب اختباراً **يفشل الآن**. لا تصلح الكود قبل أن تراه أحمر.
4. أصلح الكود. الاختبار يخضرّ.
5. إن كان الملف من المسارات الحرجة، أضفه إلى `criticalPaths` في `tool/check_coverage.dart`.
6. ادمج. كل PR لاحق يعيد تشغيله.
