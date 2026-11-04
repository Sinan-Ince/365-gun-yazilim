#!/usr/bin/env bash
# Gün 015: Reverse proxy, yük dengeleme ve TLS sonlandırma.
#
# Kullanım:
#   ./02_reverse_proxy.sh
#
# Açtığı portlar (hepsi 127.0.0.1): 8080 (HTTP), 8443 (HTTPS), 9001-9002 (backend).
# sudo istemez, sistemdeki nginx ayarlarına dokunmaz. Sertifika, anahtar ve
# config geçici klasörde durur, çıkışta her şey kapatılıp silinir.
set -euo pipefail

HTTP_PORT=8080
HTTPS_PORT=8443
BACKEND_PORTLARI=(9001 9002)

for komut in nginx curl openssl python3; do
    command -v "$komut" >/dev/null || { echo "Hata: '$komut' kurulu değil" >&2; exit 1; }
done

TMP=$(mktemp -d)
declare -A BACKEND_PID=()
temizle() {
    for pid in "${BACKEND_PID[@]}"; do kill "$pid" 2>/dev/null || true; done
    [[ -f $TMP/nginx.pid ]] && kill -QUIT "$(cat "$TMP/nginx.pid")" 2>/dev/null || true
    sleep 0.3
    rm -rf "$TMP"
}
trap temizle EXIT

port_bekle() {   # port cevap verene kadar bekle (en fazla 3 sn)
    for _ in {1..30}; do
        (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null && return 0
        sleep 0.1
    done
    echo "Hata: 127.0.0.1:$1 açılmadı (port dolu olabilir: ss -ltnp | grep :$1)" >&2
    exit 1
}

# ---------------------------------------------------------------------
# 1) Backend: gelen isteği ve başlıkları JSON olarak geri döndüren mini uygulama
# ---------------------------------------------------------------------
cat > "$TMP/backend.py" <<'EOF'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

AD, PORT = sys.argv[1], int(sys.argv[2])

class Isleyici(BaseHTTPRequestHandler):
    def do_GET(self):
        govde = json.dumps({
            "backend": AD,
            "yol": self.path,
            "baglanan_ip": self.client_address[0],   # nginx'in IP'si, istemcinin değil
            "Host": self.headers.get("Host"),
            "X-Real-IP": self.headers.get("X-Real-IP"),
            "X-Forwarded-For": self.headers.get("X-Forwarded-For"),
            "X-Forwarded-Proto": self.headers.get("X-Forwarded-Proto"),
        }, ensure_ascii=False).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(govde)))
        self.end_headers()
        self.wfile.write(govde)

    def log_message(self, *args):   # terminali kirletmesin
        pass

HTTPServer(("127.0.0.1", PORT), Isleyici).serve_forever()
EOF

backend_baslat() {   # ad port
    python3 "$TMP/backend.py" "$1" "$2" &
    BACKEND_PID[$1]=$!
    port_bekle "$2"
}
backend_baslat a "${BACKEND_PORTLARI[0]}"
backend_baslat b "${BACKEND_PORTLARI[1]}"

# ---------------------------------------------------------------------
# 2) Self-signed sertifika (Gün 014/02). Gerçekte: Let's Encrypt ya da ACM.
# ---------------------------------------------------------------------
openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
    -keyout "$TMP/test.key" -out "$TMP/test.pem" -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>/dev/null
chmod 600 "$TMP/test.key"

# ---------------------------------------------------------------------
# 3) nginx config
# ---------------------------------------------------------------------
cat > "$TMP/nginx.conf" <<'EOF'
worker_processes 1;
pid       @TMP@/nginx.pid;
error_log @TMP@/error.log warn;
events { worker_connections 64; }

http {
    default_type text/plain;
    server_tokens off;
    access_log @TMP@/access.log;
    client_body_temp_path @TMP@/tmp/body;
    proxy_temp_path       @TMP@/tmp/proxy;
    fastcgi_temp_path     @TMP@/tmp/fastcgi;
    uwsgi_temp_path       @TMP@/tmp/uwsgi;
    scgi_temp_path        @TMP@/tmp/scgi;

    upstream uygulama {
        server 127.0.0.1:@B1@ max_fails=1 fail_timeout=5s;
        server 127.0.0.1:@B2@ max_fails=1 fail_timeout=5s;
        keepalive 8;
    }

    # HTTP -> HTTPS
    server {
        listen 127.0.0.1:@HTTP@;
        server_name localhost;
        return 301 https://$host:@HTTPS@$request_uri;
    }

    server {
        listen 127.0.0.1:@HTTPS@ ssl;
        server_name localhost;

        ssl_certificate     @TMP@/test.pem;
        ssl_certificate_key @TMP@/test.key;
        ssl_protocols TLSv1.2 TLSv1.3;

        location /statik/ {
            return 200 "nginx bunu kendisi verdi, backend'e gitmedi\n";
        }

        location / {
            proxy_pass http://uygulama;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 2s;
            proxy_read_timeout    10s;
            add_header X-Upstream $upstream_addr always;   # hangi backend'e gitti (öğrenmek için)
        }
    }
}
EOF
mkdir -p "$TMP/tmp"
sed -i "s|@TMP@|$TMP|g; s|@HTTP@|$HTTP_PORT|g; s|@HTTPS@|$HTTPS_PORT|g;
        s|@B1@|${BACKEND_PORTLARI[0]}|g; s|@B2@|${BACKEND_PORTLARI[1]}|g" "$TMP/nginx.conf"

NGINX=(nginx -p "$TMP" -c "$TMP/nginx.conf" -e "$TMP/error.log")
"${NGINX[@]}" -t 2>/dev/null || { "${NGINX[@]}" -t; exit 1; }
"${NGINX[@]}"
port_bekle "$HTTPS_PORT"

# Self-signed sertifikaya -k ile DEĞİL, --cacert ile güveniyoruz (Gün 014/02)
CURL=(curl -s --cacert "$TMP/test.pem" --resolve "localhost:$HTTPS_PORT:127.0.0.1")
URL="https://localhost:$HTTPS_PORT"

# İstek at, "kod  backend  X-Upstream" satırı bas
istek() {
    local cikti kod upstream backend
    cikti=$("${CURL[@]}" -i "$URL${1:-/}")
    kod=$(head -1 <<<"$cikti" | awk '{print $2}')
    upstream=$(grep -i '^x-upstream:' <<<"$cikti" | cut -d' ' -f2- | tr -d '\r' || true)
    backend=$(grep -o '"backend": "[a-z]*"' <<<"$cikti" | cut -d'"' -f4 || true)
    printf '  %s  backend=%-2s X-Upstream=%s\n' "$kod" "${backend:--}" "${upstream:--}"
}

echo "== 1) HTTP -> HTTPS yönlendirmesi =="
curl -s -o /dev/null -w '  %{http_code} -> Location: %{redirect_url}\n' "http://127.0.0.1:$HTTP_PORT/sepet?id=7" -H 'Host: localhost'

echo
echo "== 2) Round robin: 4 istek, sırayla a ve b =="
for _ in 1 2 3 4; do istek /; done

echo
echo "== 3) /statik/ backend'e hiç gitmiyor =="
printf '  %s\n' "$("${CURL[@]}" "$URL/statik/logo.png")"

echo
echo "== 4) Backend'in gördüğü başlıklar (istemci sahte X-Forwarded-For gönderiyor) =="
"${CURL[@]}" -H 'X-Forwarded-For: 6.6.6.6' "$URL/kullanici/42" \
    | python3 -m json.tool --no-ensure-ascii | sed 's/^/  /'
echo "  -> baglanan_ip nginx'in adresi. Sahte 6.6.6.6 zincirin başında duruyor,"
echo "     güvenilir olan sadece nginx'in eklediği son halka (ve X-Real-IP)."

echo
echo "== 5) Backend b çöktü: nginx onu devreden çıkarıp a'ya yolluyor =="
kill "${BACKEND_PID[b]}"; wait "${BACKEND_PID[b]}" 2>/dev/null || true; unset 'BACKEND_PID[b]'
for _ in 1 2 3 4; do istek /; done
echo "  (İlk istek b'yi denedi, bağlanamayınca aynı isteği a'ya iletti: proxy_next_upstream)"

echo
echo "== 6) İkisi de çöktü: 502 Bad Gateway =="
kill "${BACKEND_PID[a]}"; wait "${BACKEND_PID[a]}" 2>/dev/null || true; unset 'BACKEND_PID[a]'
istek /
echo
echo "== error.log (502'nin sebebi burada yazar) =="
grep -m2 -oE 'connect\(\) failed[^,]*|no live upstreams[^,]*' "$TMP/error.log" | sort -u | sed 's/^/  /'
