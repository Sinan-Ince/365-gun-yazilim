# Firewall (`nftables` / `ufw`) ve AWS security group mantığı

**Tanım:**
- **Firewall (güvenlik duvarı):** Gelen/giden paketlere kurala göre **izin ver (accept)** ya da **düşür (drop)** diyen filtre. Kurallar genelde şunlara bakar: yön (gelen / giden), protokol (TCP/UDP), port, kaynak/hedef IP (CIDR).
- **Varsayılan politika (default policy):** Hiçbir kurala uymayan pakete ne olacağı. Doğru yaklaşım: **gelen için varsayılan drop, sadece gerekenlere izin (allowlist)**.
- **Stateful (durum tutan):** Firewall kurulan bağlantıları hatırlar. Dışarı açtığın bağlantının **cevabı** otomatik içeri alınır, ayrı kural gerekmez (`ct state established,related accept`).
- **`nftables`:** Linux çekirdeğindeki modern paket filtresi (`iptables`'ın yerini aldı). Yapı: **table → chain (input / output / forward) → rule**.
- **`ufw` / `firewalld`:** nftables'ın üstünde daha basit arayüzler. Ubuntu'da `ufw`, RHEL/Fedora'da `firewalld`.
- **AWS security group (SG):** EC2'nin (ve RDS, ELB…) önündeki **sanal, stateful** firewall. Sadece **izin** kuralı yazılır, deny yoktur; kurala uymayan her şey zaten düşer. Kaynak olarak CIDR **veya başka bir SG** yazılabilir.
- **NACL (Network ACL):** Subnet seviyesindeki, **stateless**, allow + deny destekleyen, numara sırasıyla değerlendirilen ikinci katman.

**Neden önemli:** Gün 013/01'deki "zaman aşımı (timeout)" hatasının bir numaralı sebebi bu. AWS'de bir sunucuya erişemiyorsan ilk bakacağın yer security group. En sık güvenlik hatası da yine bu: `0.0.0.0/0` için 22 (SSH) veya 5432 (veritabanı) açmak. Terraform'da (Ay 8) en çok yazacağın kaynaklardan biri `aws_security_group`. Docker da arka planda nftables/iptables kuralları ekleyerek port yönlendirir, bu yüzden `ufw`'yu "atlatabilir".

## Katmanlar (dışarıdan içeriye)
```
İnternet
   │
[ NACL ]            subnet sınırı, stateless, allow+deny, sıra numarasıyla
   │
[ Security Group ]  instance (ENI) sınırı, stateful, sadece allow
   │
[ nftables/ufw ]    işletim sistemi içi firewall (çoğu AWS kurulumunda kapalı, SG yeterli)
   │
[ servis ]          ss -tlnp: 0.0.0.0'da mı 127.0.0.1'de mi dinliyor? (Gün 013/01)
```

## Security group vs NACL
| | Security Group | NACL |
|---|---|---|
| Seviye | instance (ağ arayüzü) | subnet |
| Durum | **stateful** (cevap otomatik izinli) | **stateless** (dönüş için de kural yaz: geçici portlar 1024-65535) |
| Kural türü | sadece allow | allow + deny |
| Değerlendirme | tüm kurallar birlikte, biri izin verirse geçer | numara sırasıyla, **ilk eşleşen** kazanır |
| Varsayılan | gelen: hepsi kapalı, giden: hepsi açık | varsayılan NACL hepsine izin verir |

## Tipik 3 katmanlı uygulama
| SG | Gelen kural | Kaynak |
|---|---|---|
| `sg-alb` (yük dengeleyici) | TCP 443, 80 | `0.0.0.0/0` |
| `sg-web` (EC2) | TCP 8080 | `sg-alb` (sadece ALB'den) |
| `sg-web` | TCP 22 | `88.1.2.3/32` (sadece benim IP'm) |
| `sg-db` (RDS) | TCP 5432 | `sg-web` (sadece web sunucularından) |
> Kaynağa CIDR yerine **SG yazmak**: web sunucuları ölçeklenip IP'leri değişse de kural doğru kalır.

## Linux'ta: `ufw` (basit)
```bash
sudo ufw default deny incoming       # varsayılan: gelen kapalı
sudo ufw default allow outgoing
sudo ufw allow from 88.1.2.3 to any port 22 proto tcp   # SSH sadece benim IP'mden
sudo ufw allow 443/tcp
sudo ufw enable                      # ÖNCE SSH kuralını ekle, yoksa uzaktaysan kilitlenirsin
sudo ufw status numbered
```

## Linux'ta: `nftables` (asıl motor)
```bash
sudo nft list ruleset               # tüm kuralları gör (Docker'ınkiler dahil)
```
```nft
# /etc/nftables.conf  (Arch: sudo systemctl enable --now nftables)
table inet filtre {                 # inet = IPv4 + IPv6 birlikte
    chain input {
        type filter hook input priority 0; policy drop;   # varsayılan: düşür

        iif lo accept                                # localhost'a her zaman izin
        ct state established,related accept          # stateful: cevaplar içeri
        ct state invalid drop
        ip protocol icmp accept                      # ping
        tcp dport 22 ip saddr 88.1.2.3 accept        # SSH sadece benim IP'mden
        tcp dport { 80, 443 } accept                 # web herkese
    }
}
```
```bash
sudo nft -c -f /etc/nftables.conf   # -c: sadece kontrol et, uygulama (sshd -t gibi)
sudo nft -f /etc/nftables.conf      # uygula
```

## AWS CLI ile security group
```bash
aws ec2 describe-security-groups --group-ids sg-0abc --query 'SecurityGroups[0].IpPermissions'
aws ec2 authorize-security-group-ingress --group-id sg-0abc \
    --protocol tcp --port 22 --cidr "$(curl -s ifconfig.me)/32"   # SSH'yi sadece kendi IP'ne aç
```

## Hata ayıklama
- **Timeout** → SG / NACL / nftables paketi düşürüyor. **Refused** → paket ulaştı, servis dinlemiyor.
- SG'de giden kural (egress) silindiyse sunucu `yum update` bile yapamaz.
- NACL'de dönüş trafiği için **geçici portları (ephemeral ports, 1024-65535)** açmayı unutmak klasik hata.
- Docker'da `-p 5432:5432` yazmak portu `ufw`'ya rağmen dışarı açabilir; sadece yerel istiyorsan `-p 127.0.0.1:5432:5432`.

Kod: [`02_firewall_ve_security_group.py`](02_firewall_ve_security_group.py). Security group ve NACL kurallarını Python'da modeller (`ipaddress` modülüyle CIDR eşleme), örnek paketlerin geçip geçmediğini ve **neden** geçtiğini gösterir, `0.0.0.0/0`'a açık riskli portları uyarır. Bu makinede dinleyen portları da (`ss`) okuyup hangilerinin dışarıya açık olduğunu listeler. Hiçbir kuralı değiştirmez.
