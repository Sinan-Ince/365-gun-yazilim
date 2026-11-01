# Ağ temelleri (IP, CIDR, port, DNS, `ip` / `ss` / `curl` / `dig`)

**Tanım:**
- **IP adresi:** Ağdaki bir makinenin adresi. IPv4 `192.168.1.20` (32 bit, 4 oktet), IPv6 `2a02:...` (128 bit).
- **Özel (private) ve genel (public) IP:** `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` internete çıkmaz, sadece yerel ağda geçerli. Evdeki modem (router) **NAT** ile hepsini tek bir genel IP arkasına saklar. `127.0.0.1` (**localhost / loopback**) makinenin kendisi.
- **CIDR (`/24` gibi):** Adresin kaç bitinin **ağ** kısmı olduğu. `/24` = ilk 24 bit sabit, son 8 bit makinelere: 256 adres. `/32` tek bir adres, `/0` tüm internet.
- **Port:** Bir makinede hangi programla konuşulacağı (0-65535). IP = apartman, port = daire numarası. `1024` altı **iyi bilinen (well-known)** portlar, root ister.
- **TCP / UDP:** TCP bağlantılı ve güvenilir (sıra, tekrar gönderme: HTTP, SSH, veritabanı). UDP bağlantısız ve hızlı (DNS, video, oyun).
- **DNS:** Alan adını IP'ye çeviren sistem (`github.com` → `140.82.121.4`). Linux'ta sıra: `/etc/hosts` → `/etc/resolv.conf`'taki DNS sunucusu.
- **Gateway (ağ geçidi):** Kendi ağın dışına giden paketlerin gönderildiği router. `ip route`'taki `default via ...` satırı.

**Neden önemli:** DevOps'taki sorunların büyük kısmı "bağlanamıyorum" sorunudur ve cevabı hep aynı sırayla aranır: **DNS çözülüyor mu → IP'ye ulaşılıyor mu → port açık mı → servis dinliyor mu → uygulama doğru cevap veriyor mu.** AWS'de **VPC** bir CIDR bloğudur (`10.0.0.0/16`), **subnet**'ler onun parçalarıdır (`10.0.1.0/24`), security group kuralları CIDR ile yazılır (Gün 013/02). Docker container'ları kendi özel ağlarında çalışır, port yönlendirme (`-p 8080:80`) yaparsın. Kubernetes servisleri DNS ile birbirini bulur.

## Sık portlar
| Port | Protokol | Servis |
|---|---|---|
| 22 | TCP | SSH (Gün 012) |
| 53 | UDP/TCP | DNS |
| 80 / 443 | TCP | HTTP / HTTPS |
| 3306 / 5432 | TCP | MySQL / PostgreSQL |
| 6379 | TCP | Redis |
| 8080, 3000, 8000 | TCP | geliştirme sunucuları |

## CIDR hesabı
| CIDR | Maske | Adres sayısı | Örnek |
|---|---|---|---|
| `/32` | 255.255.255.255 | 1 | sadece benim IP'm (`88.1.2.3/32`) |
| `/24` | 255.255.255.0 | 256 | bir subnet (`10.0.1.0/24`) |
| `/16` | 255.255.0.0 | 65 536 | bir VPC (`10.0.0.0/16`) |
| `/0` | 0.0.0.0 | hepsi | tüm internet (`0.0.0.0/0`) |
> Formül: adres sayısı = 2^(32 − önek). AWS her subnet'te 5 adresi kendine ayırır (`/24` → 251 kullanılabilir).

## Komutlar
```bash
ip -br addr                 # arayüzler ve IP'leri (kısa): lo, wlan0, eth0, docker0
ip route                    # yönlendirme tablosu; "default via 192.168.1.1" = gateway
curl -s ifconfig.me         # dışarıdan görünen genel IP'm (NAT sonrası)

ss -tulpn                   # dinleyen portlar: -t tcp -u udp -l listen -p process -n sayısal
ss -tn state established    # kurulmuş TCP bağlantıları

getent hosts github.com     # sistemin çözümleme sırasıyla (/etc/hosts + DNS)
dig +short github.com       # sadece DNS'e sor (paket: bind / dnsutils)
dig github.com MX           # kayıt türü: A, AAAA, CNAME, MX, TXT, NS
resolvectl query github.com # systemd-resolved kullanıyorsan

ping -c 3 1.1.1.1           # ICMP: makineye ulaşılıyor mu (AWS'de çoğu zaman kapalı!)
curl -I https://github.com  # sadece HTTP başlıkları: durum kodu
curl -v http://localhost:8080/health   # bağlantının her adımını göster
nc -zv sunucu 5432          # port açık mı (netcat)
```

## `ss -tulpn` çıktısını okumak
```
Netid State  Local Address:Port  Process
tcp   LISTEN 127.0.0.1:5432      users:(("postgres",...))   # sadece bu makineden erişilir
tcp   LISTEN 0.0.0.0:22          users:(("sshd",...))       # tüm arayüzlerden erişilir
tcp   LISTEN [::]:80             users:(("nginx",...))      # IPv6 tüm arayüzler
```
> En sık hata: uygulama `127.0.0.1`'de dinliyor, sen dışarıdan bağlanmaya çalışıyorsun. Docker içinde uygulama `0.0.0.0`'da dinlemeli.

## Sorun giderme sırası
```
1. DNS      getent hosts api.ornek.com     -> IP dönüyor mu?
2. Ulaşım   ping / ip route                -> paket gidiyor mu?
3. Port     nc -zv api.ornek.com 443       -> "succeeded" mı, "refused" mı, zaman aşımı mı?
4. Servis   (sunucuda) ss -tlnp | grep 443 -> dinleyen var mı, hangi adreste?
5. Uygulama curl -v https://api.ornek.com  -> HTTP 200 mü, 502 mi?
```
- **Connection refused:** makineye ulaşıldı ama o portta kimse dinlemiyor (servis kapalı).
- **Zaman aşımı (timeout):** paket yolda düşürülüyor, büyük ihtimalle **firewall / security group** (Gün 013/02).

Kod: [`01_ag_temelleri.sh`](01_ag_temelleri.sh). Makinenin IP'lerini, gateway'i, DNS sunucusunu, dinleyen portları gösterir; bir alan adını çözüp ilk dört adımı uygular. `dig` yoksa `getent` kullanır. Sadece okur, hiçbir ayarı değiştirmez.
