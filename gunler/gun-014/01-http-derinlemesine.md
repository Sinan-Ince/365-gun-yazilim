# HTTP derinlemesine (metotlar, durum kodları, başlıklar, REST, `curl`)

**Tanım:**
- **HTTP (HyperText Transfer Protocol):** İstemci (client) ile sunucu (server) arasındaki **istek → cevap (request → response)** protokolü. TCP üstünde çalışır (Gün 013/01), varsayılan port 80, TLS ile 443 (Gün 014/02).
- **Durumsuz (stateless):** Her istek tek başınadır, sunucu öncekini hatırlamaz. "Oturum" hissini **cookie** veya **token** (`Authorization` başlığı) sağlar.
- **İstek (request):** `metot + yol + sürüm`, sonra **başlıklar (headers)**, boş satır, isteğe bağlı **gövde (body)**.
- **Cevap (response):** `sürüm + durum kodu + açıklama`, başlıklar, boş satır, gövde.
- **REST:** HTTP'yi kaynak (resource) odaklı kullanma tarzı. URL bir **kaynağı** (`/gorevler/3`), metot **ne yapılacağını** söyler. Veri genelde JSON.

**Neden önemli:** AWS'nin kendisi bir HTTP API'dir: `aws` CLI, Terraform, boto3 arka planda imzalı HTTPS istekleri atar. Yük dengeleyici (ALB) **health check**'i, Kubernetes **liveness/readiness probe**'u bir yola istek atıp **durum koduna** bakar. Loglarda (Gün 011) 5xx oranı alarm sebebidir, 4xx genelde istemci hatası. "Site açılmıyor" sorununda Gün 013'teki sıradan sonraki adım budur: port açık, peki **HTTP ne cevap veriyor?**

## Ham bir istek ve cevap
```http
GET /api/gorevler?durum=acik HTTP/1.1
Host: ornek.com
Accept: application/json
Authorization: Bearer eyJhbGciOi...

HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 42
Cache-Control: no-cache

[{"id": 1, "baslik": "nginx kur", "acik": true}]
```

## Metotlar
| Metot | Ne yapar | Gövde | Güvenli (safe) | İdempotent |
|---|---|---|---|---|
| `GET` | kaynağı oku | yok | ✓ | ✓ |
| `HEAD` | GET gibi, sadece başlıklar | yok | ✓ | ✓ |
| `POST` | yeni kaynak oluştur / işlem tetikle | var | ✗ | ✗ |
| `PUT` | kaynağı **tamamen** değiştir | var | ✗ | ✓ |
| `PATCH` | kaynağı **kısmen** değiştir | var | ✗ | ✗ (genelde) |
| `DELETE` | kaynağı sil | yok | ✗ | ✓ |
| `OPTIONS` | hangi metotlara izin var (CORS) | yok | ✓ | ✓ |

> **İdempotent:** Aynı isteği 1 kez de atsan 10 kez de atsan sonuç aynı. Ağ koptuğunda **yeniden deneme (retry)** sadece idempotent isteklerde güvenlidir: `DELETE /gorevler/3` iki kez gitse sorun yok, `POST /odeme` iki kez giderse iki kez ödeme alınır.

## Durum kodları
| Aralık | Anlam | Sık görülenler |
|---|---|---|
| **1xx** | bilgi | `101 Switching Protocols` (WebSocket) |
| **2xx** | başarılı | `200 OK`, `201 Created`, `204 No Content` |
| **3xx** | yönlendirme | `301` kalıcı, `302` geçici, `304 Not Modified` (önbellek) |
| **4xx** | **istemci** hatası | `400` bozuk istek, `401` kimlik yok, `403` yetki yok, `404` yok, `405` metot izinsiz, `409` çakışma, `429` çok fazla istek |
| **5xx** | **sunucu** hatası | `500` uygulama çöktü, `502 Bad Gateway`, `503` hizmet yok, `504 Gateway Timeout` |

- **401 vs 403:** 401 "kim olduğunu bilmiyorum" (giriş yap), 403 "kim olduğunu biliyorum ama izin yok".
- **502 vs 504:** İkisi de **proxy/ALB** önünde görülür. 502: arkadaki uygulama bozuk cevap verdi ya da bağlantıyı reddetti (uygulama çökmüş, yanlış port). 504: arkadaki uygulama zamanında cevap vermedi (yavaş sorgu, SG paketi düşürüyor).

## Önemli başlıklar
| Başlık | Yön | Ne işe yarar |
|---|---|---|
| `Host` | istek | Aynı IP'de birden çok site (nginx virtual host) |
| `Content-Type` | ikisi | Gövdenin biçimi: `application/json`, `text/html` |
| `Accept` | istek | İstemcinin kabul ettiği biçim |
| `Authorization` | istek | `Bearer <token>`, `Basic <base64>` |
| `User-Agent` | istek | İstemci kim (curl, tarayıcı, bot) |
| `Location` | cevap | 3xx ve 201'de "şuraya git / şurada oluştu" |
| `Cache-Control` | ikisi | Önbellek kuralı (`no-cache`, `max-age=3600`) |
| `Set-Cookie` / `Cookie` | cevap / istek | Oturum bilgisini taşır |
| `X-Forwarded-For` | istek | Proxy/ALB arkasında istemcinin gerçek IP'si |

## REST tasarımı
| İstek | Anlam | Başarılı cevap |
|---|---|---|
| `GET /gorevler` | listele | `200` + liste |
| `GET /gorevler/3` | tek kayıt | `200`, yoksa `404` |
| `POST /gorevler` | oluştur | `201` + `Location: /gorevler/4` |
| `PUT /gorevler/3` | tamamen değiştir | `200` |
| `PATCH /gorevler/3` | kısmen değiştir | `200` |
| `DELETE /gorevler/3` | sil | `204` (gövde yok) |

> URL'de fiil olmaz (`/gorevSil?id=3` yerine `DELETE /gorevler/3`), çoğul isim kullanılır.

## `curl` ile
```bash
curl -i https://api.github.com/users/octocat        # -i: cevap başlıklarını da göster
curl -I https://github.com                          # -I: sadece HEAD
curl -sS -o /dev/null -w '%{http_code}\n' https://github.com   # sadece durum kodu (health check)
curl -L http://github.com                           # -L: 301/302'yi takip et
curl -v https://github.com 2>&1 | less              # -v: DNS, TCP, TLS, başlıklar: hepsi
curl -X POST -H 'Content-Type: application/json' \
     -d '{"baslik": "nginx kur"}' localhost:8000/gorevler
curl -X DELETE localhost:8000/gorevler/1
curl --fail-with-body -sS localhost:8000/yok || echo "4xx/5xx: exit kodu 22"   # betikte hata yakalama
curl --retry 3 --max-time 5 https://ornek.com      # yeniden dene, en fazla 5 sn bekle
```

## Hata ayıklama
- `curl -v` çıktısı adım adım ilerler: `Trying 140.82.121.4:443` (DNS tamam) → `Connected` (TCP tamam) → `SSL connection` (TLS tamam) → `< HTTP/2 200` (uygulama cevap verdi). Nerede durduğu sorunun katmanını söyler.
- Betikte `curl` 404 alsa bile **exit 0** döner. `--fail` (veya `--fail-with-body`) koymazsan `set -e` (Gün 012) hatayı yakalamaz.
- API'den `429` geliyorsa `Retry-After` başlığına bak, döngüde bekleme koy.

Kod: [`01_http_derinlemesine.py`](01_http_derinlemesine.py). Sadece standart kütüphaneyle (`http.server` + `urllib`) `127.0.0.1` üzerinde küçük bir REST API (görev listesi) başlatır, sonra aynı betikten ona GET / POST / PUT / PATCH / DELETE istekleri atıp metot, durum kodu ve önemli başlıkları yazdırır. `sunucu` argümanıyla sadece sunucuyu açar, böylece `curl` ile kendin deneyebilirsin. İnternete çıkmaz.
