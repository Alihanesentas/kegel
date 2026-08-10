# Claude Code — başlangıç promptu

`CLAUDE.md` dosyasını repo köküne koyduktan sonra ilk oturumda aşağıdakini yapıştır.

---

Boş bir repoda sıfırdan bir iOS uygulaması kuruyoruz. Repo kökündeki `CLAUDE.md` dosyasını
oku — ürün kısıtları, modül yapısı, teknik kararlar ve çalışma kuralları orada.

İki kişi GitHub üzerinden paralel geliştireceğiz. İskelet, ikimizin farklı paketlerde aynı
anda çalışıp birbirini bloke etmeyeceği şekilde kurulmalı. Her şeyi tek dosyaya gömme.

## Ne yapıyoruz

Erkeklere yönelik pelvik taban egzersiz uygulaması. Piyasada bir sürü kegel zamanlayıcısı
var; hepsi aynı: kasıl-gevşe sayan bir ekran, biraz istatistik, paywall. Biz kategorinin
en iyisini yapıyoruz. Fark yaratacağımız yerler:

**1. Ekransız kullanım birinci sınıf vatandaş.** Bu egzersiz sırada beklerken, arabada,
masa başında yapılabiliyor — avantajı bu. Rakiplerde ekrana bakmak zorundasın. Bizde
karartılmış seans ekranı, Apple Watch'ta bilekten titreşim, Kilit Ekranı'nda Live Activity,
kulaklıkta sesli komut olacak.

**2. Doğru kası bulma ciddiye alınıyor.** Kullanıcıların çoğu karnını veya kalçasını
sıkıyor, sonuç alamıyor, uygulamayı siliyor. İlk deneyim rehberli bir doğrulama akışı
olacak — gömülü bir yardım maddesi değil.

**3. İlerleme gerçekten hissedilecek.** Streak sayacı kimseyi motive etmiyor. Kişisel
rekorlar, haftalık özet, kendi geçmişinle karşılaştırma, ana ekran widget'ı.

**4. Sürtünmesiz.** Hesap yok, kayıt yok, e-posta yok. Aç ve başla. Kimlik anonim bir
ID; Ayarlar'da destek için görünür. Cihazlar arası taşıma iCloud ile, sessizce.

**5. Erişilebilirlik zayıf nokta değil, güçlü nokta.** Kullanıcı kitlesi 45+. Dynamic
Type, VoiceOver, yüksek kontrast ve Reduce Motion ilk günden çalışacak, sonradan
yamalanmayacak.

## Bu oturumun hedefi (M0 + M1)

**Sırayla ilerle ve her adımdan sonra dur, bana göster.**

### Adım 1 — Repo iskeleti
- `project.yml` (XcodeGen), min iOS 17, Swift 6 language mode, strict concurrency
- `CLAUDE.md`'deki paket yapısını oluştur, her paket için `Package.swift` ve test hedefi
- `.gitignore` (`.xcodeproj` dahil), `.swiftformat`, `CODEOWNERS`, PR şablonu
- GitHub Actions: `xcodegen generate` → build → test → format kontrolü
- `README.md`: kurulum (xcodegen dahil), dal ve PR kuralları

Bittiğinde `xcodegen generate && xcodebuild build` temiz geçmeli. Doğrula.

### Adım 2 — Core: domain modelleri
`Core` paketinde, hiçbir platform framework'ü import etmeden:
- `Phase` (prepare / contract / hold / relax / rest / finished)
- `WorkoutStep`, `Level`, `SessionRecord`
- `Level.buildSteps()` — seviyeyi düz adım listesine çeviren fonksiyon
- Sürüm numaralı `content.json` şeması ve tip güvenli loader. Seviye parametreleri,
  egzersiz metinleri ve ücretsiz/ücretli sınırı buradan gelir, koda gömülmez.

Elimde bu modellerin bir taslağı var, `/seed` klasörüne koyacağım — referans al ama körü
körüne kopyalama, `CLAUDE.md`'deki yapıya uydur.

### Adım 3 — Core: WorkoutEngine
- Süre tick sayarak değil, adımın başlangıç tarihinden fark alınarak hesaplanır
- `Clock` protokolü enjekte edilir; testler `TestClock` ile gerçek zaman beklemeden çalışır
- Haptik/ses doğrudan çağrılmaz, `FeedbackEmitting` protokolü üzerinden
- Durumlar: idle / running / paused / finished. `start`, `pause`, `resume`, `stop`, `skipStep`
- Dışa verdikleri: mevcut faz, kalan süre, adım ilerlemesi (0–1), genel ilerleme,
  tamamlanan tekrar sayısı

### Adım 4 — Testler
`Core` için Swift Testing ile: adım listesi üretimi (tekrar/set sayısı, hold=0 durumu),
faz geçiş zamanlaması (`TestClock` ilerleterek), duraklat/devam süre korunumu, seans sonu
kaydı, yarıda kesilen seansta tamamlanan tekrar sayısı, bozuk `content.json`'da gömülü
kopyaya düşme. Testlerde `sleep` veya gerçek `Timer` kullanma.

### Adım 5 — DesignSystem temeli
Renk, tipografi, aralık token'ları + ortak bileşenler (buton, kart, ekran başlığı).
Dynamic Type ve karanlık mod ilk günden. Sabit punto yok.
Ton: klinik, sade, yüksek kontrast, geniş dokunma alanları. Pastel wellness estetiği değil.

### Adım 6 — Yürüyen dikey dilim
Tek ekran: seviye seç → seansı başlat → faz komutlarını gör → bitir. Nefes halkası
animasyonu dahil (Reduce Motion açıkken renk/metin geçişine düşsün). Kalıcılık,
onboarding, bildirim henüz yok — motorun uçtan uca çalıştığını görelim.

## Sonraki milestone'lar (şimdi yapma, planı bil)

- **M2 — Kalıcılık ve ilerleme:** seans kaydı, seviye listesi, ilerleme ekranı, kişisel
  rekorlar, haftalık özet, streak (haftalık hedef mantığıyla, katı gün zinciri değil)
- **M3 — Onboarding ve para:** sağlık uyarısı, doğru kası bulma rehberi, hedef seçimi,
  hatırlatma saati; RevenueCat + paywall (ilk seans sonrası tetiklenir); `RemoteContent`
- **M4 — Ekransız kullanım:** dim mode, sesli komutlar, Live Activity + Dynamic Island,
  Apple Watch uygulaması (bilekten haptik), App Intents ile "seansı başlat" Siri komutu
- **M5 — Cila:** WidgetKit ana ekran ve Kilit Ekranı widget'ı, akıllı hatırlatmalar,
  iCloud senkron, İngilizce/Türkçe lokalizasyon, erişilebilirlik geçişi, analitik
  olayları, App Store materyalleri, TestFlight

## Nasıl çalışmanı istiyorum

- Her adımdan sonra dur. Ben onaylamadan sonrakine geçme.
- Kod yazmadan önce kısa plan sun (dosya listesi + neden).
- Her adım kendi dalında ve commit'inde. Conventional commits.
- Ürün kararı gerektiren belirsizlikte uydurma, sor.
- `CLAUDE.md` bölüm 1'deki kısıtlara temas eden bir şey yazman gerekiyorsa önce uyar.
- Adım sonunda: ne yaptın, neyi test ettin, neyi test etmedin — kısaca yaz.

Adım 1'in planıyla başla.
