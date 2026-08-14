# CLAUDE.md

Bu dosya repo kökünde durur ve Claude Code her oturumda okur. Mimari kararlar, kurallar
ve kısıtlar burada yaşar. Değişiklik önerisi varsa önce bu dosyayı güncelleyip PR aç.

---

## 1. Ürün

iOS uygulaması: erkeklere yönelik pelvik taban egzersiz rehberi.

**Ne yapar:** Kademeli bir egzersiz programı sunar, seansı sesli/titreşimli komutlarla
yönetir, ilerlemeyi kaydeder, hatırlatma gönderir.

**Ne YAPMAZ (mimari kısıt, tercih değil):**
- Teşhis koymaz. Kullanıcıya "sende şu var" demez.
- Hastalık adı üzerinden vaat kurmaz ("idrar kaçırmayı tedavi eder" gibi metin YASAK).
- Semptom verisinden çıkarım yapıp yorum üretmez. Veriyi gösterir, yorumu kullanıcıya bırakır.
- Sunucuya sağlık verisi göndermez.

Bu kısıtlar uygulamayı tıbbi cihaz mevzuatının dışında tutmak içindir. Yeni bir özellik
bu sınırları zorluyorsa **kod yazma, önce sor.**

**Hedef kullanıcı:** 45+ erkekler, çoğu teknolojiye orta düzeyde hakim, konu hakkında
konuşmaktan çekiniyor. Bunun üç somut sonucu var:
- Büyük tipografi, yüksek kontrast, geniş dokunma alanları (min 44pt).
- Uygulama adı ve ikonu ana ekranda konuyu ele vermez.
- Dil klinik ve sade. Ne wellness pastelliği ne spor salonu tonu.

**Diller:** Base = İngilizce (birincil pazar). Türkçe ikinci dil. Kod, tanımlayıcılar,
yorumlar, commit mesajları ve PR açıklamaları İngilizce.

---

## 2. Teknik kararlar

| Konu | Karar |
|---|---|
| Min iOS | 17.0 |
| UI | SwiftUI (UIKit yalnızca köprü gerekirse) |
| Durum yönetimi | `@Observable` (Observation framework), `@State` / `@Environment` |
| Eşzamanlılık | Swift concurrency. Swift 6 language mode, strict concurrency açık |
| Kalıcılık | `Codable` + JSON dosya, `Repository` protokolü arkasında. SwiftData YOK |
| 3. parti bağımlılık | Sadece RevenueCat + analitik SDK. Başkası için PR'da gerekçe |
| Proje dosyası | XcodeGen (`project.yml`). `.xcodeproj` repoya commit EDİLMEZ |
| Test | Swift Testing (`import Testing`). Core paketinde zorunlu |

**Neden SwiftData değil:** Veri modelimiz küçük ve düz; SwiftData'nın strict concurrency
ile sürtüşmesi bize hiçbir şey kazandırmıyor. `Repository` protokolü sayesinde ileride
değiştirmek tek dosyalık iş.

**Neden XcodeGen:** İki kişi paralel çalışırken `.pbxproj` çakışmaları en büyük zaman
kaybı. Dosya listesi `project.yml`'de tutulunca çakışma neredeyse sıfırlanıyor.
`.xcodeproj` `.gitignore`'da. Kurulum: `brew install xcodegen && xcodegen generate`.

**Neden RevenueCat:** StoreKit 2 satın almayı cihazda hallediyor, ama yenileme/iptal/iade
bildirimlerini (App Store Server Notifications V2) dinleyecek bir sunucu olmadan abone
durumu güvenilir tutulamıyor. Kendi backend'imizi yazmak yerine bunu satın alıyoruz.
Uygulama kodu RevenueCat'i doğrudan tanımaz — `Purchases` paketindeki
`SubscriptionProviding` protokolünün arkasında durur, ileride değiştirmek tek dosyalık iş.

---

## 3. Modül yapısı

Kod, yerel Swift Package'lara bölünür. Bu hem paralel çalışmayı hem test edilebilirliği
sağlar. **Her tip kendi dosyasında.** Dosya başına ~200 satırı geçme; geçiyorsa böl.

```
PelvicApp/
├── project.yml
├── CLAUDE.md
├── App/                          # ince kabuk: entry point, DI, root navigation
│   ├── PelvicApp.swift
│   ├── AppEnvironment.swift      # bağımlılıkların bir araya getirildiği yer
│   └── RootView.swift
├── Packages/
│   ├── Core/                     # saf domain. UIKit/SwiftUI import ETMEZ
│   │   └── Sources/Core/
│   │       ├── Models/           # Phase, WorkoutStep, Level, SessionRecord, Program
│   │       ├── Engine/           # WorkoutEngine, Clock
│   │       ├── Screening/        # ScreeningQuestion, ScreeningRouter, RedFlag
│   │       └── Program/          # ProgramBuilder, ProgressionRule
│   ├── Persistence/              # Repository protokolleri + JSON implementasyonları
│   ├── Feedback/                 # CoreHaptics, AVSpeechSynthesizer, AVAudioSession
│   ├── Notifications/            # UNUserNotificationCenter sarmalayıcı
│   ├── Purchases/                # SubscriptionProviding + RevenueCat implementasyonu
│   ├── RemoteContent/            # content.json indirme, doğrulama, önbellek, fallback
│   ├── Analytics/                # AnalyticsTracking protokolü + implementasyon
│   ├── LiveSession/              # Live Activity + Dynamic Island
│   ├── Sync/                     # iCloud (CloudKit private DB) — M5
├── Widgets/                      # WidgetKit extension (ana ekran + kilit ekranı)
├── Watch/                        # watchOS uygulaması — bilekten haptik seans
│   ├── DesignSystem/             # renk, tipografi, aralık token'ları + ortak bileşenler
│   └── Features/                 # ekranlar, özellik başına klasör
│       └── Sources/Features/
│           ├── Onboarding/
│           ├── Workout/
│           ├── Progress/
│           ├── Paywall/
│           └── Settings/
└── Tests/                        # her paketin kendi test hedefi
```

**Bağımlılık yönü tek yönlü:** `App` → `Features` → `DesignSystem` / `Core` /
`Persistence` / `Feedback` / `Notifications` / `Purchases` / `RemoteContent` / `Analytics`.
`Core` hiçbir şeye bağlı değil ve platform framework'ü import etmez. Ters yönde import
görürsen düzelt.

**Üçüncü parti SDK'lar tek bir pakette hapsedilir.** RevenueCat yalnızca `Purchases`
içinde, analitik SDK yalnızca `Analytics` içinde import edilir. `Features` bu SDK'ları
hiçbir zaman doğrudan görmez, sadece protokolleri görür.

---

## 4. Sahiplik ve git akışı

İki geliştirici var. Çakışmayı azaltmak için modül sahipliği:

- **Dev A:** `Core`, `Persistence`, `RemoteContent`, `Notifications`, testler
- **Dev B:** `DesignSystem`, `Features`, `Feedback`, `Purchases`, `Analytics`, `App`

`CODEOWNERS` bunu yansıtır. Başkasının modülünde değişiklik gerekiyorsa küçük tut ve
PR'da açıkça belirt.

**Akış:**
- `main` korumalı. Doğrudan push yok, force push yok.
- Dal isimleri: `feat/workout-engine`, `fix/haptic-timing`, `chore/ci`
- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`
- PR küçük olsun — tek özellik, ideal olarak 400 satır altı. Büyükse böl.
- Her PR bir gözden geçirme ister. CI yeşil olmadan merge yok.
- Merge stratejisi: squash.

**CI (GitHub Actions):** her PR'da `xcodegen generate`, build, test, SwiftFormat/SwiftLint
kontrolü.

---

## 5. Domain kuralları

### Faz akışı
`prepare → (contract → [hold] → relax) × reps → rest → ... → finished`

### Motor (WorkoutEngine)
- `Core` paketinde, **platform framework'ü import etmeden**. Haptik/ses dışarıdan
  enjekte edilen bir protokol üzerinden çağrılır (`FeedbackEmitting`).
- Zaman hesabı tick sayarak DEĞİL, adımın başlangıç tarihinden `Date()` farkı alınarak
  yapılır. Timer'lar kayar ve tick atlar.
- Test edilebilmesi için `Clock` protokolü enjekte edilir. Testler `TestClock` ile
  gerçek zaman beklemeden çalışır. Testte `sleep` kullanma.
- Durumlar: `idle`, `running`, `paused`, `finished`. Geçişler tek yerde.

### Program yapısı
- Seviyeler kademeli: kısa kasılmalarla başlar, süre ve set sayısı yukarı doğru artar.
  Parametreler `content.json`'dan gelir, koda gömülmez.
- İlk seviye "temel" seviyedir: doğru kası bulma, nefesi tutmama, tam gevşeyebilme.
  Bu bir güvenlik kapısı değil, antrenman tasarımı — kullanıcı isterse ileri seviyeye
  doğrudan geçebilir.
- İlerleme kullanıcının tamamladığı seansa göre açılır. Karmaşık dallanma yok.

### Onboarding
Kısa tutulur: sağlık uyarısı → hedef/seviye seçimi → hatırlatma saati → ilk seans.
Soru sorup dallanan akış YOK.

### Kimlik
Kayıt, giriş, e-posta veya şifre YOK. Kullanıcı uygulamayı açar açmaz kullanmaya başlar.
Anonim bir ID üretilir, Ayarlar ekranında destek için görünür ve kopyalanabilir.
"Satın alımları geri yükle" butonu Ayarlar'da bulunur.

### Ekransız kullanım
Bu ürünün ayırt edici özelliği. Üç katman:
- **Dim mode:** uygulama önplanda kalır, ekran neredeyse siyah bir seans görünümüne geçer,
  `isIdleTimerDisabled = true`. Tek dokunuş duraklatır.
- **Live Activity:** seans süresince Kilit Ekranı ve Dynamic Island'da faz ve kalan süre.
- **Apple Watch:** bilekten haptik. Telefon kilitliyken gerçek ekransız kullanımın tek yolu
  (bkz. bölüm 7 — CoreHaptics arka planda çalışmaz).

### Sağlık uyarısı ekranı
Onboarding'de tek ekran, geçilebilir: bunun tıbbi tavsiye olmadığı, ağrı veya şikayet
durumunda hekime danışılması gerektiği. Ayarlar'dan tekrar okunabilir. Bu bir kapı değil,
standart bir bilgilendirme — App Store sağlık kategorisinde beklenen asgari.

### İçerik dışarıda tutulur
Egzersiz metinleri ve seviye parametreleri **koda gömülmez** — versiyonlu bir
`content.json` içinde durur ve `Core` tarafından tip güvenli şekilde parse edilir.

Yükleme sırası (`RemoteContent` paketi):
1. Uygulamayla gelen gömülü kopya her zaman vardır — internetsiz ilk açılış çalışır.
2. Açılışta uzaktaki dosya çekilir, şema doğrulamasından geçerse önbelleğe yazılır.
3. Uzaktaki sürüm numarası gömülü olandan büyükse kullanılır, değilse gömülü kalır.
4. **Doğrulamadan geçmeyen içerik sessizce yok sayılır ve gömülü kopyaya düşülür.**
   Bozuk bir JSON yayınlandığında uygulama kırılmamalı. Bunun testi zorunlu.

> Egzersiz metinleri klinik iddia içermez. Claude Code bu içeriği kendiliğinden
> "şunu tedavi eder / şu şikayeti giderir" biçiminde genişletmemeli.

---

## 6. Backend, abonelik ve analitik

**Kendi backend'imiz yok.** Gerekli parçaları hazır servislerden alıyoruz:

| İhtiyaç | Çözüm |
|---|---|
| Satın alma ve abone durumu | StoreKit 2 + RevenueCat |
| İçerik güncelleme | CDN'de statik `content.json` (bölüm 5) |
| Analitik | Analitik SDK, `AnalyticsTracking` protokolü arkasında |
| Hatırlatmalar | Local notification. Uzak push YOK |
| Kullanıcı hesabı | YOK. Anonim ID (RevenueCat App User ID) |
| Cihazlar arası senkron | MVP'de yok. İleride CloudKit private DB |

**Sağlık verisi asla sunucuya gitmez.** Seans kayıtları cihazda kalır. Analitik yalnızca
davranış olayı taşır (ekran görüntülenmesi, seans başladı/bitti, paywall görüldü/dönüştü);
egzersiz içeriği, seviye geçmişi veya kişisel veri taşımaz. Bu hem KVKK/GDPR yükünü
düşürüyor hem de "verin hiçbir yere gitmiyor" satış argümanını doğru kılıyor.

**Paywall yerleşimi:** ilk seans **tamamlandıktan sonra** gösterilir, indirme anında değil.
Kullanıcı değeri hissetmeden ödeme ekranı görürse dönüşüm düşer.

**Ücretsiz/ücretli sınırı** `content.json`'dan gelir, koda gömülmez — denemeden sonra
ayarlayabilelim. Varsayılan: ilk seviyeler ve temel zamanlayıcı ücretsiz; ileri seviyeler,
ilerleme ekranı ve dim mode ücretli.

---

## 7. Bilinen platform kısıtları

Bunlar tasarımı doğrudan etkiliyor, planlarken hesaba kat:

- **CoreHaptics arka planda çalışmaz.** Uygulama background'a düştüğünde veya cihaz
  kilitlendiğinde haptik motor durur. Dolayısıyla "ekran kapalı titreşimli seans"
  doğrudan mümkün değil.
  Çözüm: *dim mode* — uygulama önplanda kalır, ekran neredeyse siyah bir seans görünümüne
  geçer, `isIdleTimerDisabled = true`. Gerçek kilitli kullanım Apple Watch işi (Faz 2).
- **Sesli komutlar arka planda çalışabilir** — `UIBackgroundModes: audio` + AVAudioSession
  `.playback` ile. Bunu yalnızca gerçekten ses çalıyorsak etkinleştir; boş ses döngüsüyle
  arka planda kalma numarası App Store reddi riski taşır.
- `AVAudioSession` mutlaka `.mixWithOthers` + `.duckOthers` ile yapılandırılır. Kullanıcının
  müziğini kesmiyoruz.
- Bildirimler seansı yürütemez, sadece hatırlatır.

---

## 8. Kalite eşiği

Her PR'ın karşılaması gereken minimum:

- **Dynamic Type** en büyük erişilebilirlik boyutuna kadar bozulmadan çalışır. Sabit
  `font(.system(size:))` kullanma, `DesignSystem` token'larını kullan.
- **VoiceOver:** her etkileşimli öğenin etiketi var; seans ekranında faz değişimi
  `accessibilityAnnouncement` ile duyurulur.
- **Reduce Motion** açıkken nefes animasyonu durur, yerine metin/renk geçişi kullanılır.
- Karanlık mod her ekranda çalışır.
- Kullanıcıya görünen tüm metinler String Catalog'da (`Localizable.xcstrings`).
  Kodda çıplak string YOK.
- `Core` içindeki her yeni mantık için test.

---

## 9. Claude Code çalışma biçimi

- **Önce oku, sonra planla, sonra yaz.** Kod yazmadan önce ilgili modülleri incele ve
  kısa bir plan sun.
- Tek PR'da tek konu. "Bu arada şunu da düzelttim" yapma.
- Her şeyi tek dosyaya gömme. Yeni bir tip = yeni bir dosya, doğru pakette.
- `ContentView` diye bir dosya olmayacak. Ekranlar `Features` altında anlamlı isimlerle.
- Emin olmadığın ürün kararını uydurma — sor.
- Bölüm 1'deki kısıtlara temas eden bir şey isteniyorsa yazmadan önce uyar.
- İş bitince ne yaptığını ve neyi test etmediğini açıkça yaz.

## 10. Subagent Architecture

**All subagents are auto-configured.** See `.claude/agents/CLAUDE.md` and `.claude/agents/README.md`
for project-specific rules that guide subagent behavior.

**Key facts:**
- 158+ global agents available in `~/.claude/agents/` (from awesome-claude-code-subagents)
- Claude Code auto-selects agents based on task context
- Every agent reads this root CLAUDE.md + `.claude/agents/CLAUDE.md` for constraints
- Common mappings: UI work → `frontend-developer` + `ui-designer`, performance → `performance-engineer`, etc.

**Examples:**
```
"Add dark mode to Settings" → frontend-developer + ui-designer (auto)
"Code review this diff" → code-reviewer (auto)
"Ask the swift-expert: actor isolation patterns" → swift-expert (explicit)
```

Agents know:
- Never claim health diagnosis
- Core = pure domain (no platform imports)
- RevenueCat behind protocol abstraction
- Swift Testing mandatory
- Health data on-device only
- etc.

For full agent role map and invocation patterns, see `.claude/agents/README.md`.
