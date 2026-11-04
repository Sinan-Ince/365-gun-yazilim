#!/usr/bin/env bash
# Gün 015: nginx temelleri ve virtual host.
#
# Kullanım:
#   ./01_nginx_virtual_host.sh          -> 8080 portunda dene
#   ./01_nginx_virtual_host.sh 8090     -> başka port
#
# sudo istemez, sistemdeki nginx ayarlarına dokunmaz. Geçici bir klasörde root
# olmayan bir nginx açar (-p prefix, -c config, -e error log), üç virtual host
# kurar, curl ile Host başlığını değiştirerek test eder ve çıkışta kapatıp siler.
set -euo pipefail

PORT=${1:-8080}

for komut in nginx curl; do
    command -v "$komut" >/dev/null || {
        echo "Hata: '$komut' kurulu değil (Arch: sudo pacman -S $komut, Ubuntu: sudo apt install $komut)" >&2
        exit 1
    }
done

TMP=$(mktemp -d)
temizle() {
    # pid dosyası varsa nginx'i nazikçe kapat (SIGQUIT = graceful shutdown)
    if [[ -f $TMP/nginx.pid ]]; then
        kill -QUIT "$(cat "$TMP/nginx.pid")" 2>/dev/null || true
        sleep 0.3
    fi
    rm -rf "$TMP"
}
trap temizle EXIT

# ---------------------------------------------------------------------
# 1) Site içerikleri
# ---------------------------------------------------------------------
mkdir -p "$TMP"/www/{blog,app/assets} "$TMP/tmp"
echo '<h1>Blog ana sayfa</h1>'          > "$TMP/www/blog/index.html"
echo '<h1>Blog yazısı: nginx</h1>'      > "$TMP/www/blog/nginx.html"
echo 'SIFRE=cok-gizli'                  > "$TMP/www/blog/.env"     # yanlışlıkla web köküne düşmüş gizli dosya
echo '<div id="app">SPA index.html</div>' > "$TMP/www/app/index.html"
echo 'body { color: teal; }'            > "$TMP/www/app/assets/stil.css"

# ---------------------------------------------------------------------
# 2) Config. Tırnaklı heredoc: nginx'in $uri, $host değişkenleri Bash'te
#    genişlemesin. @TMP@ ve @PORT@ yer tutucularını sonra sed ile dolduruyoruz.
# ---------------------------------------------------------------------
cat > "$TMP/nginx.conf" <<'EOF'
worker_processes 1;
pid       @TMP@/nginx.pid;
error_log @TMP@/error.log warn;
events { worker_connections 64; }

http {
    types { text/html html; text/css css; application/json json; }
    default_type text/plain;
    server_tokens off;

    log_format kisa '$remote_addr "$host" "$request" $status $body_bytes_sent';
    access_log @TMP@/access.log kisa;

    # root olmadan çalışabilmek için geçici dosya yolları da bizim klasörde
    client_body_temp_path @TMP@/tmp/body;
    proxy_temp_path       @TMP@/tmp/proxy;
    fastcgi_temp_path     @TMP@/tmp/fastcgi;
    uwsgi_temp_path       @TMP@/tmp/uwsgi;
    scgi_temp_path        @TMP@/tmp/scgi;

    # 1) Tanınmayan Host (ya da doğrudan IP) buraya düşer
    server {
        listen 127.0.0.1:@PORT@ default_server;
        server_name _;
        return 404 "bilinmeyen site\n";
    }

    # 2) Statik blog
    server {
        listen 127.0.0.1:@PORT@;
        server_name blog.local www.blog.local;
        root  @TMP@/www/blog;
        index index.html;

        location / {
            try_files $uri $uri.html $uri/ =404;   # /nginx -> nginx.html
        }
        location = /saglik {
            default_type application/json;
            return 200 '{"durum":"ok"}\n';
        }
        location ~ /\. {                           # .env, .git ...
            deny all;
        }
    }

    # 3) Tek sayfa uygulaması (SPA)
    server {
        listen 127.0.0.1:@PORT@;
        server_name app.local;
        root @TMP@/www/app;

        location /assets/ {
            add_header Cache-Control "public, max-age=86400";
        }
        location / {
            try_files $uri /index.html;            # /profil/42 -> index.html (router JS'te)
        }
        location = /eski-sayfa {
            return 301 /yeni-sayfa;
        }
    }
}
EOF
sed -i "s|@TMP@|$TMP|g; s|@PORT@|$PORT|g" "$TMP/nginx.conf"

NGINX=(nginx -p "$TMP" -c "$TMP/nginx.conf" -e "$TMP/error.log")

# ---------------------------------------------------------------------
# 3) Önce sözdizimi testi, sonra başlat
# ---------------------------------------------------------------------
echo "== nginx -t =="
"${NGINX[@]}" -t 2>&1 | sed 's/^/  /'

"${NGINX[@]}"          # varsayılan: arka plana geçer (daemon), pid dosyasını yazar
for _ in {1..20}; do
    curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break
    sleep 0.1
done
echo
echo "== Process'ler (master + worker) =="
ps -o pid,ppid,user,cmd --ppid "$(cat "$TMP/nginx.pid")" -p "$(cat "$TMP/nginx.pid")" | sed 's/^/  /'

# ---------------------------------------------------------------------
# 4) Testler: aynı IP:port, farklı Host başlığı -> farklı site
# ---------------------------------------------------------------------
dene() {
    local host=$1 yol=$2 cikti kod govde ekstra
    cikti=$(curl -s -i -H "Host: $host" "http://127.0.0.1:$PORT$yol")
    kod=$(head -1 <<<"$cikti" | awk '{print $2}')
    govde=$(awk 'f{print; exit} /^\r?$/{f=1}' <<<"$cikti" | tr -d '\r')
    ekstra=$(grep -iE '^(location|cache-control):' <<<"$cikti" | tr -d '\r' | tr '\n' ' ' || true)
    printf '  %-16s %-17s %-4s %-32s %s\n' "$host" "$yol" "$kod" "${govde:0:32}" "$ekstra"
}

echo
echo "== Virtual host testleri (hepsi 127.0.0.1:$PORT) =="
printf '  %-16s %-17s %-4s %-32s %s\n' "Host" "Yol" "Kod" "Gövde" "Önemli başlık"
dene blog.local      /
dene www.blog.local  /nginx
dene blog.local      /yok
dene blog.local      /saglik
dene blog.local      /.env
dene app.local       /profil/42
dene app.local       /assets/stil.css
dene app.local       /eski-sayfa
dene 127.0.0.1       /
dene kotu.site       /

echo
echo "== access.log (log_format kisa) =="
sed 's/^/  /' "$TMP/access.log"

echo
echo "Not: /.env 403 döndü, çünkü 'location ~ /\\.' kuralı gizli dosyaları engelliyor."
echo "Bu kural olmasa SIFRE=cok-gizli herkese açık olurdu."
