# nginx ve Virtual Host (server block, location, statik dosya)

**Tanım:**
- **Web sunucusu (web server):** 80/443 portunu dinleyip HTTP isteklerine (Gün 014/01) cevap veren program. En yaygınları **nginx**, Apache, Caddy. nginx olay tabanlı (event-driven) çalışır: birkaç **worker** process binlerce bağlantıyı aynı anda taşır.
- **master / worker:** `master` process root olarak başlar, config'i okur, 80/443'ü açar; isteklere bakan `worker`'lar yetkisiz kullanıcıyla (`http`/`www-data`) çalışır (Gün 009 process, Gün 010 kullanıcılar).
- **Virtual host (sanal sunucu, nginx'te `server` bloğu):** Tek IP ve tek portta **birden çok site** barındırmak. nginx, isteğin `Host` başlığına bakıp (Gün 014/01) eşleşen `server_name`'i seçer. HTTPS'te aynı işi **SNI** yapar (Gün 014/02).
- **`default_server`:** Hiçbir `server_name` eşleşmezse (ör. biri doğrudan IP ile gelirse) cevap veren blok. Tanımlamazsan dosyadaki **ilk** blok cevap verir, yanlış site görünebilir.
- **`location`:** Bir `server` içinde URL yoluna göre ne yapılacağını seçer: dosya ver, yönlendir, proxy'le (Gün 015/02).
- **`root` + `try_files`:** `root /srv/blog;` ile `/a.html` isteği `/srv/blog/a.html` dosyasına karşılık gelir. `try_files $uri $uri/ =404;` sırayla dener, hiçbiri yoksa 404 döner.

**Neden önemli:** Neredeyse her üretim sisteminin önünde nginx (ya da onun işini yapan bir şey) vardır: statik dosyaları verir, uygulamaya proxy'ler, TLS'i sonlandırır. Kubernetes'in en yaygın Ingress Controller'ı **ingress-nginx**'tir, oradaki `host:` ve `path:` kuralları buradaki `server_name` ve `location` ile aynı fikir. AWS'de **ALB host-based / path-based routing** de aynı işi yönetilen (managed) servis olarak yapar. Bir EC2'ye nginx kurmak, yönetilen servise geçmeden önce mekanizmayı anlamanın en iyi yolu.

## Dosya düzeni (Arch / Debian-Ubuntu)
| | Arch | Debian/Ubuntu |
|---|---|---|
| Ana config | `/etc/nginx/nginx.conf` | `/etc/nginx/nginx.conf` |
| Site config'leri | `nginx.conf` içine `include` | `sites-available/` → `sites-enabled/`'a symlink |
| Varsayılan web kökü | `/usr/share/nginx/html` | `/var/www/html` |
| Loglar | `/var/log/nginx/access.log`, `error.log` | aynı |
| Worker kullanıcısı | `http` | `www-data` |

## Config yapısı
```nginx
worker_processes auto;            # CPU çekirdeği kadar worker
events { worker_connections 1024; }

http {                            # bağlam (context) iç içe: http > server > location
    log_format kisa '$remote_addr "$host" "$request" $status';
    access_log /var/log/nginx/access.log kisa;
    server_tokens off;            # hata sayfasında nginx sürümünü gizle

    server {                      # 1) bilinmeyen Host'lar buraya düşer
        listen 80 default_server;
        server_name _;
        return 404;
    }

    server {                      # 2) blog.ornek.com
        listen 80;
        server_name blog.ornek.com www.blog.ornek.com;
        root /srv/blog;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }
        location = /saglik {      # "=" tam eşleşme: health check uç noktası
            default_type application/json;
            return 200 '{"durum":"ok"}';
        }
        location ~ /\. {          # "~" regex: .git, .env gibi gizli dosyaları verme
            deny all;
        }
    }

    server {                      # 3) app.ornek.com: tek sayfa uygulaması (SPA)
        listen 80;
        server_name app.ornek.com;
        root /srv/app;
        location / {
            try_files $uri /index.html;   # React/Vue router: bilinmeyen yol -> index.html
        }
        location /eski-sayfa { return 301 /yeni-sayfa; }
    }
}
```

### `location` eşleşme önceliği
| Yazım | Anlamı | Öncelik |
|---|---|---|
| `location = /saglik` | tam eşleşme | 1 (bulursa hemen durur) |
| `location ^~ /statik/` | önek (prefix), bulursa regex'e bakmaz | 2 |
| `location ~ \.php$` / `~*` | regex (büyük/küçük harf duyarlı / duyarsız), dosyadaki sıraya göre | 3 |
| `location /api/` | en uzun eşleşen önek | 4 |

## Günlük komutlar
```bash
sudo nginx -t                    # config sözdizimi testi. Reload'dan ÖNCE her zaman!
sudo nginx -T | less             # include'lar dahil son (birleşik) config'i göster
sudo systemctl reload nginx      # bağlantıları koparmadan yeni config'e geç (Gün 009: SIGHUP)
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
curl -H 'Host: blog.ornek.com' http://SUNUCU_IP/    # DNS olmadan virtual host testi
```
- **reload vs restart:** `reload` master'a SIGHUP gönderir: yeni config'le yeni worker'lar açılır, eskiler elindeki istekleri bitirip kapanır. Kesinti (downtime) yok. Config hatalıysa eski config'le çalışmaya devam eder. `restart` ise süreci tamamen kapatıp açar.
- `nginx -t` hatası tipik olarak dosya + satır numarası verir: `unexpected "}" in /etc/nginx/nginx.conf:42`. En sık sebep: satır sonunda unutulan `;`.

## Sık hatalar
| Belirti | Sebep |
|---|---|
| Yanlış site açılıyor | `server_name` eşleşmedi, ilk blok / `default_server` cevap verdi |
| `403 Forbidden` | worker kullanıcısı dosyayı okuyamıyor (Gün 007 izinler: dizinlerde `x` biti) ya da `index` dosyası yok |
| `404` ama dosya orada | `root` yanlış ya da `location` içinde `alias`/`root` karışmış |
| `bind() to 0.0.0.0:80 failed (98: Address already in use)` | port başka process'te (`ss -ltnp \| grep :80`) |
| `bind() ... (13: Permission denied)` | 1024 altı port root ister |

> Betik (`01_nginx_virtual_host.sh`) sistemdeki nginx'e dokunmaz: geçici bir klasörde root olmadan, 8080 portunda kendi nginx'ini açar, üç virtual host kurar, `curl -H 'Host: ...'` ile test eder ve kapatır.
