#!/usr/bin/env bash
# Gün 013: Ağ temelleri. Makinenin ağ durumunu özetler, bir hedefe sorun giderme adımlarını uygular.
# Sadece okur: hiçbir ağ ayarını değiştirmez, sudo istemez.
# Çalıştırmak için:
#   bash 01_ag_temelleri.sh                    -> bu makinenin ağ özeti
#   bash 01_ag_temelleri.sh kontrol github.com 443   -> DNS -> port -> HTTP adımları
set -euo pipefail

baslik() { printf '\n== %s ==\n' "$1"; }
var_mi() { command -v "$1" >/dev/null 2>&1; }

ozet() {
    baslik "Arayüzler ve IP'ler (ip -br addr)"
    # -br: kısa çıktı. Sütunlar: arayüz, durum, adresler
    ip -br addr | sed 's/^/  /'

    baslik "Gateway (ip route)"
    # "default via 192.168.1.1 dev wlan0 ..." -> 3. alan gateway, 5. alan arayüz
    ip route show default | awk '{printf "  gateway %s, arayüz %s\n", $3, $5}'
    [[ -n $(ip route show default) ]] || echo "  varsayılan rota yok: internete çıkış yok"

    baslik "Özel mi genel mi?"
    local adres
    # ip -4 -o addr: her satır bir IPv4 adresi; 4. alan "192.168.1.20/24"
    for adres in $(ip -4 -o addr show | awk '{print $4}'); do
        printf '  %-20s %s\n' "$adres" "$(ip_turu "${adres%/*}")"
    done

    baslik "DNS sunucuları (/etc/resolv.conf)"
    grep -E '^nameserver' /etc/resolv.conf | awk '{print "  " $2}' || echo "  nameserver satırı yok"
    # 127.0.0.53 görürsen: systemd-resolved yerel bir aracı, asıl sunucular resolvectl status'ta
    if grep -q '127.0.0.53' /etc/resolv.conf && var_mi resolvectl; then
        echo "  (systemd-resolved) asıl sunucular:"
        resolvectl dns 2>/dev/null | grep -v ':$' | sed 's/^/    /' || true
    fi

    baslik "Dinleyen portlar (ss -tuln)"
    # -p olmadan çalıştırıyoruz: başka kullanıcıların process adını görmek sudo ister
    # Sütun 5 = Local Address:Port. Sondaki port, öncesi adres
    ss -Htuln | awk '{print $1, $5}' | sort -u | while read -r proto yerel; do
        local port=${yerel##*:} adr=${yerel%:*}
        local erisim="DIŞARIYA AÇIK"
        case $adr in
            127.*|'[::1]'|'[::ffff:127.'*) erisim="sadece bu makine" ;;
        esac
        printf '  %-4s %-6s %-26s %s\n' "$proto" "$port" "$adr" "$erisim"
    done
}

# ip_turu <ipv4>: RFC1918 özel aralıkları, loopback, yoksa genel
ip_turu() {
    local a b
    IFS=. read -r a b _ _ <<<"$1"
    if   (( a == 127 ));                     then echo "loopback (localhost)"
    elif (( a == 10 ));                      then echo "özel  10.0.0.0/8"
    elif (( a == 172 && b >= 16 && b <= 31 )); then echo "özel  172.16.0.0/12 (Docker genelde burada)"
    elif (( a == 192 && b == 168 ));         then echo "özel  192.168.0.0/16 (ev ağı)"
    elif (( a == 169 && b == 254 ));         then echo "link-local (DHCP alamadı / AWS metadata 169.254.169.254)"
    else echo "GENEL (internetten görünür)"
    fi
}

# kontrol <host> <port>: sorun giderme sırası
kontrol() {
    local host=$1 port=$2 ip

    baslik "1. DNS: $host"
    if var_mi dig; then
        ip=$(dig +short "$host" A | grep -E '^[0-9.]+$' | head -n1 || true)
        echo "  dig +short: ${ip:-çözülemedi}"
    else
        # getent, /etc/hosts'u da okur: uygulamaların gördüğü sonuç budur
        ip=$(getent ahostsv4 "$host" | awk 'NR==1 {print $1}' || true)
        echo "  getent (dig kurulu değil, Arch: sudo pacman -S bind): ${ip:-çözülemedi}"
    fi
    [[ -n $ip ]] || { echo "  ✗ DNS çözülmedi, gerisine bakmanın anlamı yok"; return 1; }
    echo "  ✓ $host -> $ip ($(ip_turu "$ip"))"

    baslik "2. Rota: $ip adresine hangi yoldan gidilir"
    ip route get "$ip" | head -n1 | sed 's/^/  /'

    baslik "3. Port: $ip:$port"
    # Bash'in /dev/tcp özelliği: nc olmadan TCP bağlantısı açar. timeout ile 3 sn sınır
    local sonuc=0
    timeout 3 bash -c "exec 3<>/dev/tcp/$ip/$port" 2>/dev/null || sonuc=$?
    case $sonuc in
        0)   echo "  ✓ açık: bağlantı kuruldu" ;;
        124) echo "  ✗ zaman aşımı: paket düşürülüyor, büyük ihtimalle firewall / security group" ;;
        *)   echo "  ✗ reddedildi (refused): makineye ulaşıldı ama bu portta dinleyen yok" ;;
    esac

    if (( sonuc == 0 )) && [[ $port == 80 || $port == 443 ]]; then
        baslik "4. Uygulama: HTTP cevabı"
        local sema=http; [[ $port == 443 ]] && sema=https
        # -s sessiz, -o çıktıyı at, -w sadece istediğimiz bilgileri yaz, -m 5 sn sınır
        curl -s -o /dev/null -m 5 \
            -w '  durum kodu %{http_code}, toplam %{time_total} sn (DNS %{time_namelookup}, bağlantı %{time_connect})\n' \
            "$sema://$host/" || echo "  ✗ curl başarısız"
    fi
}

case ${1:-ozet} in
    ozet) ozet ;;
    kontrol)
        [[ $# -eq 3 ]] || { echo "Kullanım: $0 kontrol <host> <port>" >&2; exit 2; }
        [[ $3 =~ ^[0-9]+$ ]] && (( $3 >= 1 && $3 <= 65535 )) || { echo "port 1-65535 olmalı" >&2; exit 2; }
        kontrol "$2" "$3" ;;
    *) echo "Kullanım: $0 [ozet | kontrol <host> <port>]" >&2; exit 2 ;;
esac
