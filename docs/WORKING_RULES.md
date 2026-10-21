# Minecraft Skin Viewer — Çalışma Kuralları

Bu belge `nusretm/minecraft_skin_viewer` için authoritative çalışma standardıdır.

## 1. Kapsam ve sorumluluklar

- Flutter paketi `mtn_minecraft_skin_viewer` bağımsız ve yeniden kullanılabilir olmalıdır.
- Hedef: Minecraft Java Edition skin ve cape dokularının 2D ve etkileşimli 3D görüntülenmesi.
- İlk gerçek doğrulama Windows desktop üzerinde; diğer Flutter platformları sonradan ayrı doğrulanır.
- Hesap sağlayıcıları, Microsoft/Xbox token işlemleri, ağ çağrıları, cache, persistence ve launcher orkestrasyonu paketin sorumluluğu değildir.
- Giriş olarak bytes/dokular kullanılır. URL/fetch gerekiyorsa üst katman sorumluluğu veya açıkça tasarlanmış bir adapter olarak ayrıca değerlendirilir.

## 2. Onay ve Git workflow

- Çalışma başlamadan önce repository, bu dosya ve continuity okunur.
- Analiz/öneri, source code değişikliği veya dependency ekleme onayı değildir. Kullanıcının açıkça onayladığı kapsam uygulanır.
- Özellikler anlamlı, sınırları belirli checkpoint'ler halinde planlanır. Gereksiz mikro-adımlara bölünmez.
- Feature branch -> ilgili test/smoke -> review/draft PR -> kullanıcı kabulü -> **ayrı merge onayı** -> squash merge ve continuity kapanışı.
- Force push, kapsam dışı refactor ve çalışan başka repo içeriklerinin değiştirilmesi açık onay olmadan yapılmaz.
- İlk release tamamlanana kadar gereksiz backward compatibility shim oluşturulmaz.

## 3. Mimari

- Doku decode/validation ve Minecraft atlas/UV bilgisi 2D ve 3D widget'lardan bağımsız tutulur.
- Model türü Classic (4px kol) ve Slim (3px kol) explicit seçilir; PNG boyutundan Slim güvenilir biçimde tahmin edilmez.
- Legacy 64x32 ve modern 64x64 farklı biçimler olarak doğrulanır.
- 2D: Flutter çizim API'leri. 3D: render backend'i ayrı tutulan GPU/scene adapter.
- Head, body, arms, legs, overlay ve cape koordinatları açık, test edilebilir geometry/UV verileri olmalıdır.
- Transparan overlay, render order, nearest-neighbor pixel filtering, atlas mapping ve kaynak temizliği göz ardı edilmez.
- Test amaçlı sahne/asset API'si, kalıcı public API olarak erken ilan edilmez.

## 4. Kodlama ve adlandırma

- Abstract class: `Abs` son eki; somut ortak base class: `Base` son eki.
- Concrete specialization kavramsal prefix'i korur; sınıf sayısını sırf soyutlama uğruna artırma.
- Tek bir state için tek owner; controller ve widget lifecycle'ı açıkça tasarlanır.
- Flutter uygulama bağımlılıkları yalnız ihtiyaç ve uyumluluk kanıtıyla eklenir.
- Pure Dart üzerinde otomatik `dart format` çalıştırılmaz. Flutter tarafında da kullanıcı mevcut biçimlendirme tercihine saygı gösterilir.
- `.gitignore` üretilen dosyaları dışarıda tutar; kaynak, manifest ve gerekli lockfile yanlışlıkla ignore edilmez.

## 5. Doğrulama disiplini

- `flutter --version`, `flutter pub get`, `flutter analyze` ve odaklı `flutter test` raporlanır.
- Windows üzerinde gerçek `flutter run -d windows` (GPU flag/runner ayarıyla) ve ayrıca **release build + executable smoke** yapılmadan Windows çalışıyor denmez.
- Merely compiling does not prove rendering, UV correctness, transparency or disposal.
- Test fixtures mümkünse üretilmiş/lisansı uygun örneklerdir. Gerçek kullanıcı skin/cape verileri izinsiz repository'ye eklenmez.
- Git kontrolü: `git diff --check`, `git status -sb`, changed-files review; başarı/başarısızlık/blokaj açık yazılır.

## 6. Proje sürekliliği

- `docs/continuity/CURRENT_TARGET.md`: branch, HEAD, aktif kapsam, doğrulanmış ve doğrulanmamış sonuçlar, engeller, sonraki adım.
- `docs/continuity/ARCHITECTURE.md`: geçerli mimari sınırlar ve onaylı tasarım.
- Checkpoint notları `docs/continuity/` altında tutulur.
- Durum etiketleri: PROPOSED, APPROVED, IMPLEMENTED, SYNTHETICALLY_VALIDATED, LIVE_VALIDATED, BLOCKED, DEFERRED.
- Kod/CI veya smoke yapılmadıysa başarı iddiasında bulunma.

## 7. R1 özel kuralı

`R1_RENDERER_FOUNDATION.md` kapsamında `flutter_scene` güncel kararlı sürümü incelenecek. Windows Flutter GPU release opt-in için Flutter 3.47.1+ gerekir. Flutter SDK sürümünü geliştirici makinesinde kontrol et; uyumsuzsa otomatik sürüm yükseltme yerine kullanıcıya engeli raporla. GPU motoru sadece prototip/example düzeyinde değerlendirilir; production API kararı R1 sonucuna bağlıdır.
