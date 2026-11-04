# Reverse Proxy ve TLS Sonlandırma (`proxy_pass`, upstream, `X-Forwarded-For`)

**Tanım:**
- **Forward proxy:** İstemcinin önünde durur, istemci adına dışarıya çıkar (şirket proxy'si, VPN). Sunucu gerçek istemciyi görmez.
- **Reverse proxy (ters vekil):** Sunucuların önünde durur. İstemci sadece proxy'yi görür, proxy isteği arkadaki uygulamaya (**backend / upstream**) iletir ve cevabı geri taşır. nginx'te `proxy_pass`.
- **Upstream ve yük dengeleme (load balancing):** `upstream` bloğunda birden çok backend tanımlanır. nginx istekleri varsayılan olarak **round robin** (sırayla) dağıtır. Diğer seçenekler: `least_conn` (en az bağlantılı), `ip_hash` (aynı istemci aynı backend'e: yapışkan oturum / sticky session).
- **TLS sonlandırma (TLS termination):** HTTPS bağlantısı proxy'de çözülür (sertifika ve `.key` sadece orada durur, Gün 014/02). Arkadaki uygulama düz HTTP konuşur, TLS ile hiç uğraşmaz.
- **`X-Forwarded-*` başlıkları:** Proxy araya girince backend, istemci IP'si olarak **proxy'nin** IP'sini görür. Gerçek bilgiyi taşımak için:
  - `X-Real-IP`: istemcinin IP'si
  - `X-Forwarded-For`: geçilen IP zinciri, `istemci, proxy1, proxy2`
  - `X-Forwarded-Proto`: istemci `http` mi `https` mi geldi (yönlendirme ve cookie `Secure` kararları için)
  - `Host`: nginx varsayılan olarak `proxy_pass`'teki adı gönderir, orijinal alan adını korumak için `proxy_set_header Host $host;` gerekir.

**Neden önemli:** Uygulamalar (Flask, Node, Spring) genelde 3000/5000/8080 gibi bir portta, root olmadan, TLS'siz çalışır. Önlerine reverse proxy konur: 443'ü dinler, TLS'i sonlandırır, statik dosyaları kendisi verir, yükü birden çok kopyaya dağıtır, çökeni devreden çıkarır. AWS'de bu rol **ALB** (ACM sertifikası + target group + health check), Kubernetes'te **Ingress** + **Service**. ALB de arkaya `X-Forwarded-For` ve `X-Forwarded-Proto` gönderir; uygulama loglarında gerçek istemci IP'sini görmek ve rate limit yapmak bunlara bağlıdır.

## Akış
```
                         TLS burada biter                     düz HTTP
İstemci ── https:443 ──▶ [ nginx  (reverse proxy) ] ──┬──▶ uygulama-a 127.0.0.1:9001
  │                       sertifika + .key            └──▶ uygulama-b 127.0.0.1:9002
  └ http:80 ──▶ 301 https://...                           (round robin, çökeni atla)

Backend'in gördüğü:  client_address = 127.0.0.1 (nginx)
                     X-Real-IP = 203.0.113.7, X-Forwarded-Proto = https
```

## Config
```nginx
upstream uygulama {
    server 127.0.0.1:9001 max_fails=1 fail_timeout=5s;  # 1 hata -> 5 sn devreden çık
    server 127.0.0.1:9002 max_fails=1 fail_timeout=5s;
    # least_conn;   # ya da ip_hash;
    keepalive 16;                                       # backend'e açık bağlantı havuzu
}

server {                                    # HTTP -> HTTPS yönlendirme
    listen 80;
    server_name api.ornek.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.ornek.com;

    ssl_certificate     /etc/letsencrypt/live/api.ornek.com/fullchain.pem;  # sertifika + ara CA'lar
    ssl_certificate_key /etc/letsencrypt/live/api.ornek.com/privkey.pem;    # chmod 600, git'e GİRMEZ
    ssl_protocols TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security "max-age=31536000" always;        # HSTS: tarayıcı hep HTTPS

    location /statik/ {                     # statik dosyayı nginx verir, uygulamayı yormaz
        root /srv/api;
    }

    location / {
        proxy_pass http://uygulama;         # sonda "/" YOK: yol olduğu gibi gider
        proxy_http_version 1.1;
        proxy_set_header Connection "";     # keepalive için
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 2s;
        proxy_read_timeout    30s;
    }
}
```

### `proxy_pass` sonundaki `/` tuzağı
| Config | İstek | Backend'e giden |
|---|---|---|
| `location /api/ { proxy_pass http://app; }` | `/api/kullanici` | `/api/kullanici` |
| `location /api/ { proxy_pass http://app/; }` | `/api/kullanici` | `/kullanici` (önek kesildi) |

## Proxy hata kodları
| Kod | Anlamı | Nereye bakılır |
|---|---|---|
| `502 Bad Gateway` | backend'e bağlanılamadı ya da bozuk cevap verdi | backend ayakta mı? port doğru mu? `error.log`: `connect() failed (111: Connection refused)` |
| `504 Gateway Timeout` | backend `proxy_read_timeout` içinde cevap vermedi | yavaş sorgu, kilitlenmiş uygulama |
| `413 Request Entity Too Large` | gövde `client_max_body_size` (varsayılan 1 MB) sınırını aştı | dosya yükleme uç noktaları |

## Sertifika: Let's Encrypt ile
```bash
sudo certbot --nginx -d api.ornek.com      # sertifikayı alır, nginx config'ine ekler
sudo certbot renew --dry-run               # yenileme testi (90 günde bir otomatik yenilenir)
```

> **Güvenlik:** `X-Forwarded-For` istemci tarafından **sahte gönderilebilir**. `$proxy_add_x_forwarded_for` gelen değerin sonuna ekler, yani zincirin sadece **son** (senin proxy'nin eklediği) halkası güvenilirdir. IP'ye göre yetki/limit verirken `X-Real-IP` ya da güvenilir proxy listesi (`set_real_ip_from`) kullan. Backend portları (9001, 9002) dışarıya açık olmamalı: `127.0.0.1`'e bağlan ya da security group'ta sadece proxy'ye izin ver (Gün 013/02).

> Betik (`02_reverse_proxy.sh`) iki küçük Python backend, self-signed sertifika ve nginx açar: HTTP→HTTPS yönlendirmesini, round robin dağıtımı, backend'in gördüğü başlıkları, bir backend çöktüğünde devreden çıkarılmasını ve ikisi de çökünce 502'yi gösterir.
