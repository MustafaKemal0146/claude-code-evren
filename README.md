<h1 align="center">claude-code-evren</h1>

<p align="center">
  <b>Claude Code'u EVREN'in açık ağırlıklı model filosuna bağla.</b><br>
  Tek komutla kurulum, tek komutla geri alma. Linux, macOS ve Windows.
</p>

<p align="center">
  <img src="assets/flow.svg" alt="Claude Code, EVREN geçidi ve model filosu arasındaki istek akışı (animasyonlu)" width="920">
</p>

<p align="center">
  <img alt="Lisans: MIT" src="https://img.shields.io/badge/lisans-MIT-blue">
  <img alt="Linux: doğrulandı" src="https://img.shields.io/badge/Linux-do%C4%9Frulandı-brightgreen">
  <img alt="Windows: doğrulanmadı" src="https://img.shields.io/badge/Windows-do%C4%9Frulanmad%C4%B1-lightgrey">
</p>

> **Resmi olmayan topluluk rehberidir.** EVREN'in kendi dokümanı her zaman önceliklidir.
> Son doğrulama: **2026-11-01**. EVREN'de tüm modeller **1 Aralık 2026**'ya kadar ücretsiz (günlük 15M token).

---

## ⚡ Hızlı kurulum (Linux / macOS)

```bash
git clone https://github.com/MustafaKemal0146/claude-code-evren.git
cd claude-code-evren
bash scripts/install.sh
source ~/.bashrc        # zsh kullanıyorsan: source ~/.zshrc
```

Script sana API anahtarını sorar (yazarken görünmez), şunları yapar:

- `~/.config/evren/evren.sh` dosyasına `evren` komutunu koyar
- Anahtarı `~/.config/evren/env` dosyasına yazar (izin `600`, sadece sana okunur)
- `~/.bashrc` (zsh için `~/.zshrc`) içine **işaretli tek bir blok** ekler. Tekrar çalıştırırsan çoğaltmaz

Sonra iki adım kaldı: **şartları onayla**, **`evren` yaz**.

## 📜 Şartları onayla (hesap başına bir kez, zorunlu)

Bunu atlarsan her istek `403 terms_not_accepted` döner. Metni oku, onayı kendin ver:

```bash
source ~/.config/evren/env
BASE="https://evren-llmapi.ssyz.org.tr"

# 1) Güncel sürümü öğren (current_version)
curl -s "$BASE/v1/terms/status" -H "X-API-Key: $EVREN_API_KEY"

# 2) Metni oku
curl -s "$BASE/v1/terms/text" -H "X-API-Key: $EVREN_API_KEY"

# 3) Kabul et (version = 1. adımdaki current_version)
curl -s -X POST "$BASE/v1/terms/accept" \
  -H "X-API-Key: $EVREN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"version": 1}'
```

Panelde **Test Alanı**'ndaki anahtar kutusu bu üç adımı tek tıkla yapar.

## 🚀 Kullanım

```bash
evren                        # menü açılır, 1 = deepseek-v4.1-flash
evren deepseek-v4.1-flash    # menüsüz, direkt aç
evren glm-5.3 -p "selam"     # model + Claude Code argümanları
```

`evren` her çalıştığında ayarları **sadece o oturum için** verir. Normal `claude` komutun (kendi Anthropic hesabın) hiç değişmez. `ANTHROPIC_API_KEY` tanımlıysa (örn. `.bashrc`'de) `evren` onu sadece kendi oturumunda siler, dosyana dokunmaz.

### Bağlantıyı Claude Code'dan önce test et

```bash
source ~/.config/evren/env
BASE="https://evren-llmapi.ssyz.org.tr"

curl -s "$BASE/v1/models" -H "X-API-Key: $EVREN_API_KEY"     # açık modeller
curl -s "$BASE/v1/quota"  -H "X-API-Key: $EVREN_API_KEY"     # kalan günlük kota

# Claude Code'un konuşacağı uç (Anthropic Messages formatı)
curl -s "$BASE/v1/messages" \
  -H "x-api-key: $EVREN_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"deepseek-v4.1-flash","max_tokens":2048,"messages":[{"role":"user","content":"Merhaba"}]}'
```

`max_tokens` en az 2048 olsun. Düşünen modellerde düşünme ve yanıt aynı bütçeyi paylaşır, düşük verirsen yanıt boş ya da yarım gelir.

## 🧠 Nasıl çalışıyor?

Claude Code, Anthropic Messages API'sini konuşur. EVREN geçidi de aynı API'yi (`POST /v1/messages`) uyguladığı için Claude Code'a sadece üç şey vermek yeter:

| Değişken | Değer | Anlamı |
|---|---|---|
| `ANTHROPIC_BASE_URL` | `https://evren-llmapi.ssyz.org.tr` | İstekler Anthropic yerine EVREN'e gider. Sonuna **`/v1` yazılmaz**, Claude Code kendisi ekler |
| `ANTHROPIC_AUTH_TOKEN` | `evren_llm_...` | API anahtarın |
| `ANTHROPIC_MODEL` | `deepseek-v4.1-flash` vb. | Hangi model cevap verecek. Claude model adları tanınmaz |

Claude Code arka plan işleri ve alt ajanlar için ayrı model adları da kullanır. Bunlar tanımlanmazsa istekler Claude model adıyla gider ve geçitte tanınmaz. `evren` komutu bunları da (`ANTHROPIC_DEFAULT_*`, `CLAUDE_CODE_SUBAGENT_MODEL`) kendisi ayarlar.

## 🤖 Model seçimi

| Kısa kimlik | Bağlam | Not |
|---|---|---|
| `deepseek-v4.1-flash` | 1M | Kod ve ajan işleri, görsel girdi. **Gerçek bağlantıda test edildi** |
| `glm-5.3` | 512K | Amiral model, sadece metin. Yoğun saatlerde `503 model_capacity_exhausted` verebilir |
| `mimo-v2.6-pro` | 1M | Uzun soluklu ajan, görsel/video/ses girdisi |
| `qwen3.8-flash-next` | 256K | Hızlı ve yüksek eşzamanlılık. Haiku (arka plan) işleri için kullanılır |

Model adı olarak tablodaki kısa kimliği yaz. `deepseek-v4-flash` eski adı **1 Ocak 2027'de kapanıyor**, `deepseek-v4.1-flash` kullan. Hesabına açık güncel liste için `GET /v1/models`.

## ↩️ Geri alma

```bash
bash scripts/uninstall.sh            # anahtar dosyasını silmeden önce sorar
bash scripts/uninstall.sh --purge    # anahtar dosyasını da sormadan siler
unset -f evren                       # açık terminalde komutu hemen kaldırır
```

`uninstall.sh` şunları yapar:

- `~/.bashrc` (veya `~/.zshrc`) içindeki işaretli bloğu siler. Dosyanın geri kalanı olduğu gibi kalır (yedek: `*.evren-uninstall.bak`)
- `~/.config/evren/evren.sh` dosyasını siler
- `~/.claude/settings.json` içinde **sadece EVREN'den kalan** `model` ve `env` satırlarını temizler (yedek: `settings.json.evren.bak`). Başka ayarlarına dokunmaz

Dokunmadıkları: `ANTHROPIC_API_KEY` ve proje içi `.claude/settings.local.json` dosyaları. Anahtarı artık kullanmayacaksan EVREN panelinde **API Anahtarları** sayfasından da sil.

> `/model` komutunu `evren` oturumlarında kullanma: seçilen modeli varsayılan olarak `~/.claude/settings.json`'a kaydeder ve normal `claude`'u bozabilir. Modeli `evren <model>` ile ver. Bozulduysa `uninstall.sh` bunu temizler.

## 🪟 Windows

İki yol var. Kolayı **WSL**, yerel olanı **PowerShell**.

### Yol 1: WSL (önerilen)

WSL içinde Linux gibi çalışır, yukarıdaki her şey aynen geçerli:

```powershell
wsl --install            # bir kez, sonra bilgisayarı yeniden başlat
```

WSL terminalini aç ve **Hızlı kurulum** adımlarını orada yap. Projelerini `/mnt/c/...` altında değil, WSL içinde (`~/projeler`) tut, dosya erişimi çok daha hızlı olur.

### Yol 2: PowerShell (yerel)

> **Doğrulanmadı.** Bu bölüm Windows'ta denenmeden yazıldı. Denersen sonucu issue olarak yaz, etiketi kaldıralım.

```powershell
# 1) Anahtarı kalıcı yaz (yeni terminalde geçerli olur)
[Environment]::SetEnvironmentVariable("EVREN_API_KEY", "evren_llm_BURAYA_KENDI_ANAHTARIN", "User")

# 2) Betiği yerine kopyala
git clone https://github.com/MustafaKemal0146/claude-code-evren.git
cd claude-code-evren
New-Item -ItemType Directory -Force "$HOME\.config\evren" | Out-Null
Copy-Item windows\evren.ps1 "$HOME\.config\evren\evren.ps1"

# 3) PowerShell profiline ekle
if (!(Test-Path $PROFILE)) { New-Item -Force $PROFILE | Out-Null }
Add-Content $PROFILE ". `"$HOME\.config\evren\evren.ps1`""

# 4) Yerel betiklere izin ver (bir kez)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Yeni bir PowerShell aç. Şartları onaylamak için (PowerShell'de `curl` takma addır, bu yüzden `Invoke-RestMethod`):

```powershell
$BASE = "https://evren-llmapi.ssyz.org.tr"
$H = @{ "X-API-Key" = $env:EVREN_API_KEY }

Invoke-RestMethod "$BASE/v1/terms/status" -Headers $H
Invoke-RestMethod "$BASE/v1/terms/text"   -Headers $H
Invoke-RestMethod "$BASE/v1/terms/accept" -Method Post -Headers $H -ContentType "application/json" -Body '{"version": 1}'
```

Kullanım Linux'takiyle aynı:

```powershell
evren
evren deepseek-v4.1-flash
```

PowerShell sürümü ayarları Claude kapanınca eski haline **geri yükler** (`try/finally`).

**Windows'ta geri alma:**

```powershell
notepad $PROFILE      # ". ...evren.ps1" satırını sil
Remove-Item "$HOME\.config\evren\evren.ps1"
[Environment]::SetEnvironmentVariable("EVREN_API_KEY", $null, "User")
```

`%USERPROFILE%\.claude\settings.json` içinde `glm-5.3` gibi bir EVREN modeli `model` olarak kayıtlıysa o satırı da sil.

## 🛠️ Sorun giderme

- **`403 terms_not_accepted`**: Şartları onayla (yukarıdaki bölüm).
- **`Invalid API key` veya "Both ANTHROPIC_AUTH_TOKEN and ANTHROPIC_API_KEY set"**: Kabukta eski bir `ANTHROPIC_API_KEY` var. `evren` bunu otomatik siler. Elle çalıştırıyorsan komutun başına `env -u ANTHROPIC_API_KEY` ekle.
- **`503 model_capacity_exhausted` veya `API error · Retrying`**: O model sunucuda dolu. Birkaç dakika bekle ya da başka model seç.
- **`404 model_not_found`**: Model adı yanlış. `GET /v1/models` ile hesabına açık olanlara bak.
- **`429 daily_token_limit_exceeded`**: Günlük kota doldu. `GET /v1/quota` ile sıfırlanma zamanına bak.
- **Açılışta `Model "..." isn't recognized`**: Claude Code'un kendi uyarısı, çalışmayı etkilemez. Bağlam 200K varsayılır ama model gerçekte daha fazlasını taşır.
- **Yanıtlar çok yavaş**: Düşünen modeller kısa mesajda bile onlarca saniye düşünebilir. Panelde **API Anahtarları → anahtar satırı → Düşünme modu**'nu kapat. Yetmezse başka model dene.
- **Adres hatası**: Anthropic istemcilerinde adres `/v1` olmadan yazılır. OpenAI istemcilerinde `/v1` ile.
- **Yanıt boş veya yarım (`finish_reason: "length"`)**: Düşünme bütçeyi yedi, `max_tokens` değerini yükselt.

## 📊 Limitler

- Günlük **15M token**, dakikada **500k token**. Kalanı görmek için `GET /v1/quota`.
- Önbellekten gelen girdi token'ları kotaya **%3 ağırlıkla** yazılır. Claude Code gibi ajan araçları için iyi haber.
- `429` ile birlikte `Retry-After` gelirse o kadar bekle.

## 🔒 Güvenlik

- Anahtarı koda, repoya, ekran görüntüsüne, sohbete **yazma**. Tek yeri `~/.config/evren/env` (izin `600`).
- `.gitignore` anahtar dosyalarını dışarıda tutar, yine de `git add` yapmadan önce `git status` bak.
- Anahtar sızarsa EVREN panelinden sil, yenisini üret.
- `install.sh` ve `uninstall.sh` kısa ve okunabilir. Çalıştırmadan önce oku.

## 📁 Repo yapısı

```
claude-code-evren/
├── assets/flow.svg          # animasyonlu akış diyagramı
├── scripts/
│   ├── install.sh           # kurulum (tekrar çalıştırmak güvenli)
│   ├── uninstall.sh         # geri alma
│   └── evren.sh             # `evren` komutu (install.sh kopyalar)
├── windows/evren.ps1        # PowerShell sürümü
├── LICENSE
└── README.md
```

## 🤝 Katkı

Issue ve PR açabilirsin. Özellikle istenenler: **Windows PowerShell** ve **WSL** sonuçları, macOS denemeleri, yeni model eklemeleri.

## 📄 Lisans

[MIT](LICENSE)
