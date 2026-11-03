#!/usr/bin/env bash
# Gün 014: TLS ve HTTPS.
#
# Kullanım:
#   ./02_tls_ve_https.sh                 -> github.com sertifikasını incele
#   ./02_tls_ve_https.sh ornek.com 443   -> başka bir site
#   ./02_tls_ve_https.sh yerel           -> self-signed sertifika + yerel HTTPS sunucu testi
#
# Hiçbir sistem ayarını değiştirmez, sudo istemez. Yerel testte üretilen anahtarlar
# geçici klasörde durur ve çıkışta silinir.
set -euo pipefail

UYARI_GUN=30

gerekli() {
    for komut in "$@"; do
        command -v "$komut" >/dev/null || { echo "Hata: '$komut' kurulu değil" >&2; exit 1; }
    done
}

# ---------------------------------------------------------------------
# 1) Uzak bir sitenin sertifikasını incele
# ---------------------------------------------------------------------
incele() {
    local host=$1 port=${2:-443}
    gerekli openssl timeout
    echo "== $host:$port =="

    # -servername: SNI. Olmazsa tek IP'deki başka sitenin sertifikası gelebilir.
    # -showcerts: tüm zinciri bas. </dev/null: el sıkışmadan sonra hemen çık.
    local cikti
    if ! cikti=$(timeout 10 openssl s_client -connect "$host:$port" -servername "$host" \
                 -showcerts </dev/null 2>&1); then
        echo "Bağlanılamadı (DNS, firewall ya da TLS konuşmayan port):" >&2
        grep -m3 -iE 'error|errno|refused|unable|timeout|lookup|getaddrinfo|name' <<<"$cikti" >&2 || echo "  (zaman aşımı, 10 sn)" >&2
        exit 1
    fi

    # Zincirdeki ilk sertifika = sunucunun kendi sertifikası
    local sert
    sert=$(awk '/-----BEGIN CERTIFICATE-----/{s=1} s{print} /-----END CERTIFICATE-----/{exit}' <<<"$cikti")

    echo "Konu (subject):  $(openssl x509 -noout -subject <<<"$sert" | sed 's/^subject=//')"
    echo "İmzalayan CA:    $(openssl x509 -noout -issuer <<<"$sert" | sed 's/^issuer=//')"
    echo "SAN (alan adları):"
    openssl x509 -noout -ext subjectAltName <<<"$sert" 2>/dev/null \
        | tail -n +2 | tr ',' '\n' | sed 's/^ *//; s/^/    /' | head -8

    local tls zincir
    tls=$(grep -m1 -oE 'TLSv1\.[0-3]' <<<"$cikti" || echo "?")
    zincir=$(grep -c 'BEGIN CERTIFICATE' <<<"$cikti")
    echo "TLS sürümü:      $tls"
    echo "Zincir:          $zincir sertifika (sunucu + ara CA'lar; kök CA sistemde)"

    # Doğrulama sonucu: 0 (ok) değilse sebebini yazar
    grep -m1 -E 'Verify return code' <<<"$cikti" | sed 's/^ */Doğrulama:       /'

    # Bitiş tarihi -> kalan gün
    local bitis bitis_sn kalan
    bitis=$(openssl x509 -noout -enddate <<<"$sert" | cut -d= -f2)
    bitis_sn=$(date -d "$bitis" +%s)
    kalan=$(( (bitis_sn - $(date +%s)) / 86400 ))
    echo "Bitiş:           $bitis ($kalan gün kaldı)"

    # -checkend: verilen saniye içinde bitecekse exit 1. İzleme betiklerinde bu kullanılır.
    if openssl x509 -noout -checkend $((UYARI_GUN * 86400)) <<<"$sert" >/dev/null; then
        echo "Durum:           ✓ en az $UYARI_GUN gün geçerli"
    else
        echo "Durum:           ⚠ $UYARI_GUN günden az kaldı, yenile!"
        return 1
    fi
}

# ---------------------------------------------------------------------
# 2) Self-signed sertifika ile yerel HTTPS
# ---------------------------------------------------------------------
yerel() {
    gerekli openssl python3 curl
    local port=8443
    # dizin ve pid global: EXIT trap'i fonksiyon bittikten sonra çalışır, local'i göremez
    dizin=$(mktemp -d)
    pid=""
    # Çıkışta (hata olsa bile) sunucuyu kapat ve özel anahtarı sil
    trap 'kill "$pid" 2>/dev/null || true; rm -rf "$dizin"' EXIT

    echo "== 1. Self-signed sertifika üret ($dizin) =="
    openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
        -keyout "$dizin/test.key" -out "$dizin/test.pem" \
        -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" 2>/dev/null
    chmod 600 "$dizin/test.key"   # özel anahtar: sadece sahibi okur (Gün 007)
    openssl x509 -in "$dizin/test.pem" -noout -subject -issuer -enddate | sed 's/^/  /'
    echo "  (subject = issuer: kendini imzalamış, hiçbir CA tanımıyor)"

    echo
    echo "== 2. Python http.server'ı TLS ile 127.0.0.1:$port'ta başlat =="
    python3 - "$dizin" "$port" <<'PY' &
import http.server, ssl, sys, os
dizin, port = sys.argv[1], int(sys.argv[2])
os.chdir(dizin)
open("index.html", "w").write("merhaba, şifreli dünya\n")
sunucu = http.server.HTTPServer(("127.0.0.1", port), http.server.SimpleHTTPRequestHandler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.minimum_version = ssl.TLSVersion.TLSv1_2          # eski sürümleri kabul etme
ctx.load_cert_chain("test.pem", "test.key")
sunucu.socket = ctx.wrap_socket(sunucu.socket, server_side=True)
sunucu.RequestHandlerClass.log_message = lambda *a: None
sunucu.handle_error = lambda *a: None   # reddedilen el sıkışmalarda traceback basma
sunucu.serve_forever()
PY
    pid=$!
    # Sunucu hazır olana kadar bekle (en fazla 5 sn); port doluysa python hemen ölür
    for _ in {1..50}; do
        kill -0 "$pid" 2>/dev/null || { echo "Sunucu başlamadı (port $port dolu mu? ss -tlnp)" >&2; exit 1; }
        (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null && break
        sleep 0.1
    done

    echo
    echo "== 3. curl, CA'yı tanımadan =="
    if curl -sS https://127.0.0.1:$port/index.html 2>&1 | sed 's/^/  /'; then :; fi
    echo "  -> reddedildi: sertifikayı güvendiğim hiçbir CA imzalamamış"

    echo
    echo "== 4. curl --cacert test.pem (bu sertifikaya açıkça güven) =="
    curl -sS --cacert "$dizin/test.pem" "https://localhost:$port/index.html" | sed 's/^/  /'

    echo
    echo "== 5. Yanlış alan adı: SAN'da olmayan isimle =="
    curl -sS --cacert "$dizin/test.pem" --resolve "baska.local:$port:127.0.0.1" \
        "https://baska.local:$port/" 2>&1 | sed 's/^/  /' || true
    echo "  -> reddedildi: sertifika sadece localhost ve 127.0.0.1 için"

    echo
    echo "== 6. Aynı sunucuya openssl s_client ile bak =="
    openssl s_client -connect 127.0.0.1:$port -servername localhost </dev/null 2>/dev/null \
        | grep -E 'Protocol|Cipher is|Verify return' | sed 's/^ */  /'

    echo
    echo "Bitti, sunucu kapatılıyor ve $dizin siliniyor."
}

case "${1:-github.com}" in
    yerel) yerel ;;
    -h|--help) sed -n '2,10p' "$0" ;;
    *) incele "${1:-github.com}" "${2:-443}" ;;
esac
