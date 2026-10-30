#!/usr/bin/env bash
# Gün 012: SSH anahtarları ve ~/.ssh/config
# Salt okunur: ~/.ssh'ta hiçbir şeyi değiştirmez, özel anahtarların İÇERİĞİNİ okumaz,
# hiçbir sunucuya bağlanmaz. Demo anahtarı geçici klasörde üretilip silinir.
# Çalıştırmak için:
#   bash 02_ssh_anahtar_ve_config.sh              -> denetim + demo
#   bash 02_ssh_anahtar_ve_config.sh coz github   -> 'ssh github' yazınca hangi ayarlar kullanılır
set -euo pipefail

SSH_DIR="$HOME/.ssh"
baslik() { printf '\n== %s ==\n' "$1"; }

# Dosyanın izni beklenenden geniş mi? izin_kontrol <yol> <en_fazla_izin>
izin_kontrol() {
    local yol=$1 beklenen=$2 izin
    izin=$(stat -c '%a' "$yol")
    # Beklenende olmayan bir bit dosyada açıksa sorun var: (izin & ~beklenen) != 0
    if (( (8#$izin & ~8#$beklenen) != 0 )); then
        printf '  ✗ %-28s %s  (en fazla %s olmalı -> chmod %s "%s")\n' "${yol/#$HOME/\~}" "$izin" "$beklenen" "$beklenen" "${yol/#$HOME/\~}"
    else
        printf '  ✓ %-28s %s\n' "${yol/#$HOME/\~}" "$izin"
    fi
}

denetle() {
    baslik "~/.ssh izinleri"
    if [[ ! -d $SSH_DIR ]]; then
        echo "  ~/.ssh yok. Oluşturmak için: ssh-keygen -t ed25519 -C \"ad@makine\""
        return
    fi
    izin_kontrol "$SSH_DIR" 700
    local f
    for f in "$SSH_DIR"/*; do
        [[ -f $f ]] || continue
        case $f in
            *.pub)                      izin_kontrol "$f" 644 ;;
            */known_hosts*|*/config)    izin_kontrol "$f" 644 ;;
            *)                          izin_kontrol "$f" 600 ;;  # özel anahtar, authorized_keys, .pem
        esac
    done

    baslik "Açık anahtarlar ve parmak izleri"
    local bulundu=0
    for f in "$SSH_DIR"/*.pub; do
        [[ -f $f ]] || continue
        bulundu=1
        # Çıktı: <bit> SHA256:<iz> <yorum> (<tür>)
        printf '  %s\n    %s\n' "$(basename "$f")" "$(ssh-keygen -lf "$f")"
        [[ -f ${f%.pub} ]] && echo "    eşi olan özel anahtar: $(basename "${f%.pub}") ✓"
    done
    (( bulundu )) || echo "  .pub dosyası yok"

    baslik "known_hosts"
    if [[ -f $SSH_DIR/known_hosts ]]; then
        echo "  $(grep -cv '^#' "$SSH_DIR/known_hosts") kayıtlı sunucu anahtarı"
        # Satırlar hash'li (|1|...) olabilir; anahtar türlerini say
        awk '{print $2}' "$SSH_DIR/known_hosts" | sort | uniq -c | sed 's/^/   /'
    else
        echo "  henüz hiçbir sunucuya bağlanılmamış"
    fi

    baslik "~/.ssh/config içindeki Host'lar"
    if [[ -f $SSH_DIR/config ]]; then
        grep -iE '^\s*Host\s' "$SSH_DIR/config" | awk '{for (i=2; i<=NF; i++) print "  " $i}'
    else
        echo "  config yok. Örnek için README'deki ~/.ssh/config bölümüne bak"
    fi

    baslik "ssh-agent"
    if [[ -n ${SSH_AUTH_SOCK:-} ]]; then
        ssh-add -l 2>/dev/null | sed 's/^/  /' || echo "  agent çalışıyor ama yüklü anahtar yok (ssh-add)"
    else
        echo "  agent yok: eval \"\$(ssh-agent -s)\" && ssh-add"
    fi
}

demo() {
    baslik "Demo: geçici klasörde anahtar çifti + config"
    local gecici
    gecici=$(mktemp -d)
    # shellcheck disable=SC2064  # $gecici şimdi açılsın diye çift tırnak
    trap "rm -rf '$gecici'" EXIT

    # -N '' parolasız (sadece demo!), -q sessiz
    ssh-keygen -t ed25519 -C "demo@gun012" -N '' -q -f "$gecici/demo_key"
    echo "  oluşan dosyalar:"
    ls -l "$gecici" | tail -n +2 | awk '{printf "    %s  %s\n", $1, $NF}'
    echo "  açık anahtar (sunucuya bu gider):"
    echo "    $(cut -c1-60 "$gecici/demo_key.pub")..."
    echo "  özel anahtar ilk satırı (içeriği asla paylaşma):"
    echo "    $(head -n1 "$gecici/demo_key")"

    cat > "$gecici/config" <<EOF
Host web
    HostName 3.120.4.7
    User ec2-user
    IdentityFile $gecici/demo_key
    IdentitiesOnly yes

Host db
    HostName 10.0.2.15
    User ubuntu
    ProxyJump web

Host *
    ServerAliveInterval 60
    User varsayilan
EOF
    echo
    echo "  'ssh db' çözülünce (ssh -G, bağlanmaz):"
    # -F: bu config dosyasını kullan. "User varsayilan" db'ye uygulanmaz: ilk eşleşen kazanır
    ssh -F "$gecici/config" -G db 2>/dev/null | grep -E '^(hostname|user|port|proxyjump|serveraliveinterval) ' | sed 's/^/    /'
}

coz() {
    baslik "'ssh $1' hangi ayarlarla bağlanır (bağlanmaz)"
    ssh -G "$1" 2>/dev/null | grep -E '^(hostname|user|port|identityfile|proxyjump) ' | sed 's/^/  /'
}

case ${1:-incele} in
    incele) denetle; demo ;;
    coz)
        [[ $# -eq 2 ]] || { echo "Kullanım: $0 coz <host>" >&2; exit 2; }
        coz "$2" ;;
    *) echo "Kullanım: $0 [incele | coz <host>]" >&2; exit 2 ;;
esac
