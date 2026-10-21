# Minecraft Skin Viewer — Çalışma Kuralları

**Kaynak çalışma standardı:** `nusretm/mtn_launcher_app/docs/WORKING_RULES.md` (`main`, 2026-10-22 incelemesi).
**Bu repository için yetkili belge:** `nusretm/minecraft_skin_viewer/docs/WORKING_RULES.md`.
Kaynak repository'ye özgü Game List, `MtnLauncherService`, `MtnLauncherBloc`, pencere dosyası ve UI ayrıntıları burada birebir kopyalanmaz; yalnız uyarlanabilir süreç, sahiplik ve kalite kuralları aktarılır.

## 1. Proje kapsamı ve tek repository otoritesi

- Geliştirme repository'si `nusretm/minecraft_skin_viewer`, Flutter paket adı `mtn_minecraft_skin_viewer`.
- 2D skin/head/cape önizlemeleri ve etkileşimli 3D Minecraft Java karakteri hedeflenir; Windows masaüstü ilk canlı doğrulama platformudur.
- Kaynak verisi `Uint8List`/yerel PNG doku olabilir. Çevrim içi profil edinimi, network/cache, depolama, oturum ve launcher UI bu paketin sorumluluğu değildir.
- `mtn_launcher_app`, `minecraft_accounts`, `minecraft_tools`, `minecraft_models`, `remvibe_flutter_ui`, `mtn_launcher` gibi ilgili repository'ler yalnız **okuma/bağımlılık** içindir. Açık kullanıcı talebi/onayı olmadan bu repository'lere kod yazılmaz.

## 2. Onay kapısı ve anlamlı checkpoint

- Önce mevcut repo, çalışan API, açık PR, dependency durumu, gereksinim ve continuity okunur; sonra kapsam, risk, owner, non-goal ve kabul ölçütleri belirlenir.
- Analiz, plan, prompt ve Draft PR varlığı **kod uygulama onayı değildir**. Implementation, bağımlılık ekleme ve SDK yükseltme mevcut açık kullanıcı kapsam/onayına bağlıdır. Kullanıcı 2026-10-22 tarihinde **gerektiğinde merge yapma yetkisini açıkça devretmiştir**; kabul kriterleri doğrulanan ve kapsamı önceden onaylanmış değişikliklerde, ayrıca merge izni istemek zorunlu değildir. Bu delegasyon kod yazma veya kapsam genişletme izni vermez.
- Onaylanmış işi küçük ama **anlamlı ve tamamlanabilir** checkpoint'lere ayır; test edilebilir tek özelliği gereksiz mikro-adımlarla uzatma.
- Yan görev veya mimari refactor'a izinsiz geçme. Kullanıcının kapsamını sessiz genişletme.
- İlk sürüm tamamlanana kadar gereksiz backward-compatibility shim oluşturma.

## 3. Tek entegrasyon kapısı ve doğru sıra

Normal akış:

```text
onaylı kapsam → feature branch → reviewable commit → Draft PR
→ Windows analyze + odaklı test + gerçek UI/GPU smoke
→ doğrulanmış kabul kriterleri + risk incelemesi (gerekirse kullanıcı görüşü)
→ squash merge → main HEAD doğrulaması
→ CURRENT_TARGET kapanışı → yerel main pull / branch temizliği
→ yeni bağımsız iş
```

- Kullanıcının güncel yetki devri, yalnız önceden onaylanmış feature kapsamlarında ve anlamlı doğrulama kanıtı olduğunda **koşullu squash merge** izni verir. Açık kullanıcı kabulü veya devredilen koşullu yetki geçerli olabilir. Sadece test geçmiş olması, başarısız/askıda kontrolün gizlenmesi veya PR açılmış olması otomatik merge gerekçesi değildir.
- Merge için kabul kriterleri sağlandığında, kod diff'i, CI/lokal testler, platform smoke gereksinimi ve riskleri kontrol et. Başarısız veya kritik doğrulanmamış kontrollerde merge yapma; gerçek sonucu bildir. Onaylı kapsam tamamlandıysa ve değerlendirme olumluysa koşullu yetkiyle merge edebilirsin. Merge sonrası `main` HEAD ve continuity doğrulanır; yeni bağımsız işe geçmeden önce entegrasyon kapısı kapanır.
- Birden çok PR gerekiyorsa bağımlı branch'leri ve ortak dosya çakışmalarını incele; eski `main` üzerinden sessizce merge etme.
- Force push, geçmişi yeniden yazma, ilgisiz refactor, kapsam dışı dosya silme ve başka repository'yi değiştirme ayrı onay ister. Merge yetkisi bunları kapsamaz. Branch temizliğinde kullanıcının yerel çalışmalarına dokunma.
- Yerel kullanıcı dosyaları/IDE ayarları/özel fixture'lar korunur; kaynak repository'nin `window_pos.json` istisnasını buraya aynen taşımaya gerek yoktur. Bu repoda gerçekten mevcut özel kullanıcı dosyaları için eşdeğer koruma uygulanır.

## 4. Mimari ve kaynak otoritesi

- Skin/cape PNG decode ve doğrulama, Minecraft UV/atlas mapping, karakter geometrisi, renderer ve widget/controller lifecycle ayrı sorumluluklardır.
- Aynı skin/kamera/pose durumu için iki bağımsız source of truth yaratma.
- 2D ve 3D renderer aynı doğrulanmış UV/geometry verisine dayanır; 3D GPU bağımlılıkları domain modellerini ve public API'yi kirletmez.
- Model türü Classic (4px kol) veya Slim (3px kol) açıkça belirtilir; 64x64 PNG boyutundan Slim çıkarımı yapılmaz. 64x32 legacy uyumluluğu ayrı test edilir.
- Outer layers ve cape için transparency, occlusion, UV orientation, texture nearest sampling, render order ve kaynak temizliği güvenli ele alınır.
- Ağ, hesap ve oturum state'i UI render paketine kopyalanmaz; API verisi gösterecek bileşen varmış gibi sahte sonuç üretme.
- Yeni model, listener, service, registry veya adapter tasarlamadan önce mevcut sorumluluğu ve upstream API'leri kontrol et; gereksiz proxy/forwarding sınıfları oluşturma.

## 5. Sınıf adlandırma ve kod stili

- **Abstract:** `Abs` son eki, ör. `MtnMinecraftSkinRendererAbs`.
- **Somut ortak temel:** `Base` son eki; somut uzmanlaşmalar aile önekini korur.
- Aynı davranış gerçekten paylaşılıyorsa uygun yere taşı; sadece teorik genişletilebilirlik için hiyerarşi kurma.
- Saf Dart dosyalarında otomatik `dart format` çalıştırma; ilgili kullanıcı tercihini bozma.
- Flutter-specific kodu da geniş ölçekli yeniden formatlama veya ilgisiz değişiklik için bahane etme.
- Yeni paket/dependency ancak ihtiyaç, platform desteği ve bakım riski incelendikten sonra onaylı kapsamda eklenir.
- Flutter SDK yükseltmesi kullanıcı sorumluluğudur. Flutter sürümünü raporla; otomatik `flutter upgrade` çalıştırma.
- Paket standart `lib/`, `test/`, `example/`, `docs/` düzeninde; kullanılmayan `rust/`, `dart/`, `ui/` katmanlarını boş yere yaratma.
- `.gitignore` generated `build/`, `.dart_tool/` vb. dosyaları kapsar; gerçek kaynak, manifest ve gerekli lockfile takip kuralları kontrol edilir.

## 6. Windows-first gerçek doğrulama

- Her checkpoint için en az uygun `flutter --version`, `flutter pub get`, `flutter analyze`, hedefli `flutter test`, `git diff --check`, `git status -sb` ve diff review kanıtı belirtilir.
- Windows 3D renderer: gerçek `flutter run -d windows --enable-flutter-gpu`; ayrıca Windows **release build + doğrudan EXE başlatıp görsel etkileşim testi** yapılmadan `LIVE_VALIDATED` yazma.
- CI, yalnızca gerçekten çalıştırdığı kontrolleri kanıtlar. Analiz başarısı, rendering veya gerçek kullanıcı etkileşimi başarısı değildir.
- Başarısız analiz/build adımının adı, hata nedeni, ilgili run URL'si ve atlanmış sonraki adımlar continuity'ye yazılır.
- Gerçek tekstür testlerinde UV/alpha/nearest sampling, Classic/Slim, legacy atlas, resize, zoom, dispose ve tekrarlı mount/unmount için hedefli testler tercih edilir.
- Fixture'lar sentetik veya uygun lisanslı olmalı; gerçek oyuncu skin/cape kaynaklarını izinsiz commit etme. Gerekmedikçe yavaş, geniş kapsamlı test döngüleri üretme.
- Test yapılmadıysa `NOT RUN`, hata varsa `FAILED/BLOCKED`, platform smoke kanıtı varsa `LIVE_VALIDATED` olarak ayrı kaydet.

## 7. Continuity — kaynak `mtn_launcher_app` yaklaşımına uyarlama

- `docs/continuity/CURRENT_TARGET.md` yeni sohbetin **ilk handoff dosyasıdır**; en güncel, tarihli durum **en üstte** olur.
- Kayıtlar branch/commit/PR, onay sınırı, uygulanan dosya/kapsam, gerçek test çıktısı, Windows smoke, açık blokaj, deferred işler ve kesin sonraki işi içerir.
- Geçmiş girdileri silip önceki durumu olduğundan farklı gösterme; kapanan işleri `CLOSED` belirt. Dosyayı dev bir log'a çevirmemek için uzun plan/teknik raporları ayrı belgelere böl.
- `ARCHITECTURE.md`: kalıcı onaylı sınırlar ve henüz doğrulanmamış tasarımlar ayrılır.
- `R1_RENDERER_FOUNDATION.md`: mevcut onaylı checkpoint, kapsam/kabul ve doğrulama kayıtları.
- `PLANNED_YYYY-MM-DD_<TOPIC>.md`: gelecekteki, **henüz implementation onayı olmayan** konu planları; bunlar yanlışlıkla onaylı iş kabul edilmez.
- Durum sözcükleri: `PROPOSED`, `APPROVED`, `IMPLEMENTED`, `SYNTHETICALLY_VALIDATED`, `LIVE_VALIDATED`, `BLOCKED`, `DEFERRED`, `CLOSED`.
- Her önemli karar, test sonucu, merge veya blokajda `CURRENT_TARGET.md` güncellenir; sohbet hafızası tek gerçek kaynak değildir.
- Yeni sohbet: rules → current target (en yeni girdi) → ilgili plan/architecture → actual repo/PR/CI doğrulaması sırası.

## 8. PowerShell ve kullanıcı ortamı

PowerShell komut gruplarının ilk satırı:

```powershell
cd D:\development\cross-platform\minecraft_skin_viewer
```

- Branch switch/pull öncesi `git status -sb` kontrol et; local uncommitted değişiklikleri sessizce overwrite etme.
- Kullanıcının Flutter upgrade'i sırasında proje bağımlılığı/lockfile veya generated Windows runner değişiklikleri otomatik normalize edilmez. Yeniden üretimden sonra `git status` ile beklenen ve beklenmeyen dosyalar ayrılır.

## 9. R1 özel sözleşme

- Güncel kapsam `docs/continuity/R1_RENDERER_FOUNDATION.md` ve `CURRENT_TARGET.md` ile sınırlıdır.
- `flutter_scene` sadece `example/` içinde GPU fizibilite denemesidir; production renderer/API kararı verilmiş sayılmaz.
- Windows release GPU opt-in için Flutter 3.47.1+ hedefi gereklidir; geliştirici makinesindeki mevcut sürüm kontrol edilir.
- R1 Windows debug + release smoke ve gerçek texture sampling/transparency/lifecycle kanıtı olmadan "tamamlandı" denmez.
