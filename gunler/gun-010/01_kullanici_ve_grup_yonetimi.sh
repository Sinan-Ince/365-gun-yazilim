#!/usr/bin/env bash
# Gün 010: Kullanıcı ve grup yönetimi
# Salt okunur: sistemde hiçbir şey değiştirmez, sudo istemez.
# Çalıştırmak için:
#   bash 01_kullanici_ve_grup_yonetimi.sh            -> kendi kullanıcın + sistem özeti
#   bash 01_kullanici_ve_grup_yonetimi.sh plan ali   -> "ali" için çalıştırılacak komutları YAZDIRIR (dry-run)
set -euo pipefail

kullanim() { echo "Kullanım: $0 [incele | plan <kullanici_adi>]" >&2; exit 2; }

ben() {
    echo "== Ben kimim =="
    echo "whoami: $(whoami) | UID=$(id -u) | birincil GID=$(id -g) ($(id -gn))"
    echo "Ek gruplar: $(id -Gn)"
    # getent: /etc/passwd'i doğrudan okumak yerine NSS üzerinden sorgular (LDAP vb. de dahil)
    getent passwd "$(whoami)" | awk -F: '{printf "home=%s | kabuk=%s\n", $6, $7}'
    echo
}

kullanicilar() {
    echo "== /etc/passwd: insan kullanıcılar (UID >= 1000) =="
    # Alanlar ":" ile ayrılır: 1 ad, 3 UID, 4 GID, 6 home, 7 kabuk. 65534 = nobody
    awk -F: '$3 >= 1000 && $3 != 65534 {printf "  %-12s UID=%-6s home=%-20s kabuk=%s\n", $1, $3, $6, $7}' /etc/passwd
    echo

    echo "== Sistem (servis) kullanıcıları: sayı ve örnekler =="
    awk -F: '$3 > 0 && $3 < 1000' /etc/passwd | wc -l | xargs echo "  Toplam:"
    # nologin/false kabuklu olanlar giriş yapamaz: servisler için doğru olan bu
    awk -F: '$3 > 0 && $3 < 1000 {printf "  %-20s UID=%-5s kabuk=%s\n", $1, $3, $7}' /etc/passwd | head -n 5 || true
    echo

    echo "== UID 0 olanlar (sadece root olmalı) =="
    awk -F: '$3 == 0 {print "  " $1}' /etc/passwd
    echo
}

guvenlik() {
    echo "== Dosya izinleri (Gün 007) =="
    # stat -c: %a sekizli izin, %U:%G sahip, %n ad
    for f in /etc/passwd /etc/group /etc/shadow; do
        [[ -e $f ]] && stat -c '  %a %U:%G %n' "$f"
    done
    if cat /etc/shadow >/dev/null 2>&1; then
        echo "  /etc/shadow okunabildi (root musun?)"
    else
        echo "  /etc/shadow okunamadı: beklenen durum, hash'ler sadece root'a açık"
    fi
    echo

    echo "== Yönetici grupları =="
    # Debian/Ubuntu: sudo, RHEL/Amazon Linux/Arch: wheel
    for g in sudo wheel docker; do
        if satir=$(getent group "$g"); then
            echo "  $g -> üyeler: ${satir##*:}"   # son ":"'dan sonrası üye listesi
        else
            echo "  $g -> bu sistemde yok"
        fi
    done
    echo

    echo "== sudo yetkim =="
    # -n: şifre sorma (etkileşimsiz). Şifre gerekiyorsa hata verir, betik durmasın diye || ile yakalıyoruz
    if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
        echo "  Şifresiz sudo var (EC2'deki ec2-user/ubuntu gibi)"
    elif id -Gn | grep -qwE 'sudo|wheel'; then
        echo "  sudo/wheel grubundasın: sudo kullanabilirsin, ama şifre sorar"
    else
        echo "  sudo yetkin görünmüyor"
    fi
}

# Dry-run: komutları çalıştırmaz, sadece ekrana basar. Gerçek betiklerde iyi bir alışkanlık.
plan() {
    local ad=$1
    # Linux kullanıcı adı kuralı: küçük harf/_ ile başlar, en fazla 32 karakter
    [[ $ad =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Geçersiz kullanıcı adı: $ad" >&2; exit 2; }
    if getent passwd "$ad" >/dev/null; then
        echo "UYARI: '$ad' zaten var, useradd başarısız olur (exit 9)" >&2
    fi
    cat <<EOF
# '$ad' için yeni geliştirici hesabı (çalıştırılmadı, sadece plan):
sudo useradd -m -s /bin/bash -c "Geliştirici" $ad
sudo usermod -aG docker $ad              # -a olmadan diğer ek gruplar silinir!
sudo install -d -m 700 -o $ad -g $ad /home/$ad/.ssh
echo "ssh-ed25519 AAAA... $ad@laptop" | sudo tee /home/$ad/.ssh/authorized_keys >/dev/null
sudo chown $ad:$ad /home/$ad/.ssh/authorized_keys
sudo chmod 600 /home/$ad/.ssh/authorized_keys
id $ad                                    # kontrol
# Ayrılırken: sudo usermod -L $ad  (kilitle)  veya  sudo userdel -r $ad  (sil)
EOF
}

case "${1:-incele}" in
    incele) ben; kullanicilar; guvenlik ;;
    plan)   [[ $# -eq 2 ]] || kullanim; plan "$2" ;;
    *)      kullanim ;;
esac
