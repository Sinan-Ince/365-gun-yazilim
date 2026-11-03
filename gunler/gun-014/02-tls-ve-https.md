# TLS ve HTTPS (sertifika, zincir, `openssl`)

**Tanım:**
- **TLS (Transport Layer Security):** TCP bağlantısını **şifreleyen** ve karşı tarafın **kimliğini doğrulayan** katman. Eski adı SSL (artık kullanılmıyor, ama isim kaldı: "SSL sertifikası"). Güncel sürümler **TLS 1.2** ve **TLS 1.3**.
- **HTTPS:** HTTP'nin TLS içinde taşınması. Varsayılan port 443. HTTP mesajları (Gün 014/01) aynı, sadece "boru" şifreli.
- **Üç garanti:** **Gizlilik (confidentiality)**: araya giren okuyamaz. **Bütünlük (integrity)**: değiştiremez. **Kimlik doğrulama (authentication)**: gerçekten `github.com` ile konuşuyorsun.
- **Sertifika (X.509):** "Bu açık anahtar (public key) şu alan adına aittir" diyen, bir **CA (Certificate Authority)** tarafından imzalanmış belge. İçinde: `Subject`, **SAN** (geçerli alan adları), `Issuer` (imzalayan CA), `notBefore` / `notAfter` (geçerlilik).
- **Güven zinciri (chain of trust):** Sunucu sertifikası → **ara (intermediate) CA** → **kök (root) CA**. Kök sertifikalar işletim sisteminde/tarayıcıda hazır gelir (`/etc/ssl/certs`). Sunucu, kendi sertifikasıyla birlikte **ara sertifikaları da** göndermelidir.
- **Açık / özel anahtar (public / private key):** SSH'deki mantığın aynısı (Gün 012/02). Özel anahtar (`.key`) sunucuda kalır, **asla** paylaşılmaz ve git'e girmez.

**Neden önemli:** Üretimdeki her şey HTTPS'tir. AWS'de sertifikayı **ACM (Certificate Manager)** ücretsiz verir ve **ALB**'ye takarsın: TLS orada **sonlandırılır (TLS termination)**, ALB arkadaki EC2'ye çoğu zaman düz HTTP ile gider (Gün 013/02'deki `sg-web` 8080). Kubernetes'te **cert-manager** + **Let's Encrypt** sertifikaları otomatik yeniler. En sık kesinti sebeplerinden biri: **süresi dolmuş sertifika**. Bu yüzden izlemede (monitoring) "sertifikanın bitmesine kaç gün kaldı" alarmı standarttır.

## TLS 1.3 el sıkışması (handshake), basitleştirilmiş
```
İstemci                                          Sunucu
   │ ── ClientHello ─────────────────────────────▶ │  desteklenen şifreler, SNI: "github.com",
   │                                               │  anahtar değişimi için geçici açık anahtar
   │ ◀──────────────────────────── ServerHello ─── │  seçilen şifre + kendi geçici anahtarı
   │ ◀── Certificate + CertificateVerify ───────── │  sertifika zinciri + "özel anahtar bende" imzası
   │ ◀────────────────────────────── Finished ──── │
   │  (istemci zinciri doğrular: CA güvenilir mi,  │
   │   alan adı SAN'da mı, süresi geçerli mi)      │
   │ ── Finished ────────────────────────────────▶ │
   │ ══ şifreli HTTP: GET / HTTP/1.1 ... ════════▶ │  simetrik anahtarla (AES/ChaCha20), hızlı
```
- **Asimetrik** şifreleme sadece el sıkışmada (kimlik + anahtar anlaşması), sonrası **simetrik** (hızlı).
- **SNI (Server Name Indication):** İstemci hangi alan adını istediğini baştan söyler; böylece tek IP'de birden çok HTTPS sitesi barınır (Gün 014/01'deki `Host` başlığının TLS karşılığı).
- **Forward secrecy:** Her bağlantıda geçici anahtar üretilir. Özel anahtar yarın çalınsa bile bugünkü kayıtlı trafik çözülemez.

## Sertifika türleri
| Tür | Kim imzalar | Nerede |
|---|---|---|
| Genel CA (Let's Encrypt, ACM, DigiCert) | güvenilen CA | internete açık siteler |
| Self-signed (kendinden imzalı) | kendisi | yerel test; tarayıcı uyarı verir |
| Özel CA (private CA) | şirketin kendi CA'sı | iç servisler, **mTLS** (iki taraf da sertifika gösterir: servis mesh, Kubernetes) |
| Wildcard `*.ornek.com` | herhangi biri | tek seviye alt alan adlarının hepsi |

## `openssl` ile
```bash
# Sunucuya bağlan, el sıkışmayı ve zinciri gör (Ctrl+C ya da </dev/null ile çık)
openssl s_client -connect github.com:443 -servername github.com </dev/null

# Sadece sertifika bilgisi: kime, kim imzalamış, ne zamana kadar
openssl s_client -connect github.com:443 -servername github.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -ext subjectAltName

# Bitmesine 30 günden az kaldıysa exit 1 (izleme betikleri için)
openssl x509 -in sertifika.pem -noout -checkend $((30*24*3600))

# Yerel test için self-signed sertifika + özel anahtar (1 gün geçerli)
openssl req -x509 -newkey rsa:2048 -nodes -keyout test.key -out test.pem \
  -days 1 -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```
```bash
curl -v https://github.com 2>&1 | grep -E 'SSL|TLS|subject|issuer|expire'   # curl'ün gözünden
curl -k https://localhost:8443          # -k: doğrulamayı atla. SADECE yerel testte!
curl --cacert test.pem https://localhost:8443   # doğru yol: bu CA'ya güven
```

## Sık hatalar
| Hata | Sebep |
|---|---|
| `certificate has expired` | süre dolmuş, yenilenmemiş (cron/cert-manager çalışmamış) |
| `hostname mismatch` / `no alternative certificate subject name matches` | istenen alan adı SAN listesinde yok (`www.` unutulmuş) |
| `unable to get local issuer certificate` | sunucu **ara sertifikayı** göndermiyor ya da self-signed |
| `wrong version number` | 443 yerine HTTP portuna TLS ile gidiliyor (veya tersi) |
| Tarayıcıda "Mixed content" | HTTPS sayfa içinde `http://` kaynak yükleniyor |

> **Güvenlik:** `curl -k`, Python'da `verify=False` ve "sertifika hatasını yoksay" ayarları üretimde **yasak**: TLS'nin kimlik doğrulama garantisini tamamen kaldırır, araya girme (MITM) saldırısına kapı açar. `.key` dosyaları `.gitignore`'a girmeli (Gün 004'te ertelenen `*.key`, `*.pem` satırları).

Kod: [`02_tls_ve_https.sh`](02_tls_ve_https.sh). Verilen alan adının (varsayılan `github.com`) sertifikasını `openssl s_client` ile çeker; konu, SAN, imzalayan CA, TLS sürümü, zincir uzunluğu ve **bitmesine kaç gün kaldığını** yazdırır, 30 günden azsa uyarır. `yerel` argümanıyla geçici bir klasörde self-signed sertifika üretir, Python'un `http.server`'ını 127.0.0.1'de HTTPS olarak açar ve `curl`'ün `--cacert` ile geçip `--cacert` olmadan neden reddettiğini gösterir. Anahtarları iş bitince siler.
