# Linux: Paket Yönetimi (`apt`, `dnf`, `pacman`)

**Tanım:**
- **Paket (package):** Bir programın derlenmiş dosyaları + üst verisi (metadata: ad, sürüm, bağımlılıklar, kurulum betikleri) tek arşivde: `.deb` (Debian/Ubuntu), `.rpm` (RHEL/Amazon Linux/Fedora), `.pkg.tar.zst` (Arch).
- **Paket yöneticisi (package manager):** Paketi indirir, **bağımlılıkları (dependencies) çözer**, dosyaları yerine koyar, hangi dosyanın hangi pakete ait olduğunu kaydeder ve kaldırırken temizler. İki katman vardır: düşük seviye (`dpkg`, `rpm`) tek dosyayla çalışır, yüksek seviye (`apt`, `dnf`) depodan bağımlılıklarıyla çeker.
- **Depo (repository):** Paketlerin ve imzalı indeksin bulunduğu sunucu. Paket yöneticisi indeksi **GPG imzasıyla** doğrular, yani sahte paket kurulmaz.
- **Sürüm sabitleme (pinning / version lock):** Bir paketin belli bir sürümde kalmasını, otomatik güncellenmemesini sağlamak.

**Neden önemli:** Her sunucu kurulumu, Dockerfile ve CI job'u bir paket kurulumuyla başlar: `RUN apt-get update && apt-get install -y curl`, EC2 `user_data`'da `dnf install -y nginx`, GitHub Actions runner'da `sudo apt-get install`. Docker'ın resmi kurulumu kendi deposunu ve GPG anahtarını eklemekle başlar. Üretimde "dün çalışıyordu, bugün build kırıldı" sorunlarının bir kısmı sabitlenmemiş sürümlerden gelir; Kubernetes kurulumunda `kubelet`/`kubeadm` paketleri bu yüzden **hold**'a alınır. Güvenlik yamaları (`CVE`) da paket güncellemesiyle gelir. Amazon Linux 2023 `dnf` kullanır, Ubuntu AMI'leri `apt`.

## Aileler
| Aile | Dağıtımlar | Düşük seviye | Yüksek seviye | Paket |
|---|---|---|---|---|
| Debian | Debian, Ubuntu | `dpkg` | `apt` / `apt-get` | `.deb` |
| Red Hat | RHEL, Amazon Linux, Fedora, Rocky | `rpm` | `dnf` (eski: `yum`) | `.rpm` |
| Arch | Arch, Manjaro | | `pacman` | `.pkg.tar.zst` |
| Alpine | Alpine (küçük Docker image'ları) | | `apk` | `.apk` |

## Komut karşılıkları
| İş | `apt` | `dnf` | `pacman` |
|---|---|---|---|
| İndeksi yenile | `apt update` | `dnf makecache` | `pacman -Sy` |
| Kur | `apt install nginx` | `dnf install nginx` | `pacman -S nginx` |
| Sil | `apt remove` / `purge` (config dahil) | `dnf remove` | `pacman -Rns` |
| Hepsini güncelle | `apt upgrade` | `dnf upgrade` | `pacman -Syu` |
| Ara | `apt search redis` | `dnf search redis` | `pacman -Ss redis` |
| Bilgi / sürüm | `apt show nginx` | `dnf info nginx` | `pacman -Si nginx` |
| Kurulu mu | `dpkg -s nginx` | `rpm -q nginx` | `pacman -Q nginx` |
| Paketin dosyaları | `dpkg -L nginx` | `rpm -ql nginx` | `pacman -Ql nginx` |
| Bu dosya kimin | `dpkg -S /usr/bin/curl` | `rpm -qf /usr/bin/curl` | `pacman -Qo /usr/bin/curl` |
| Gereksizleri sil | `apt autoremove` | `dnf autoremove` | `pacman -Rns $(pacman -Qdtq)` |
| Sürüm sabitle | `apt-mark hold kubelet` | `dnf versionlock add kubelet` | `/etc/pacman.conf` → `IgnorePkg` |

> `update` ≠ `upgrade`. `apt update` sadece **listeyi** yeniler, hiçbir şey kurmaz. `apt upgrade` paketleri gerçekten günceller. Arch'ta `pacman -Sy paket` (listeyi yenileyip tek paket kurmak) **kısmi güncelleme** yaratıp sistemi bozabilir, her zaman `-Syu`.

> Betiklerde `apt` yerine `apt-get` kullan: `apt` etkileşimli kullanım içindir ve çıktısının değişebileceğini kendisi uyarır.

## Depo eklemek ve sürüm sabitlemek (Debian/Ubuntu)
```bash
# Docker'ın resmi deposu: önce imza anahtarı, sonra depo satırı
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release; echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update

apt-cache policy docker-ce                         # hangi sürümler var, hangisi kurulu
sudo apt-get install -y docker-ce=5:27.3.1-1~ubuntu.24.04~noble   # belirli sürüm
sudo apt-mark hold docker-ce                       # upgrade'de dokunma
apt-mark showhold
```

## Dockerfile'da doğru kullanım
```dockerfile
# Tek RUN: update ile install aynı katmanda (aksi hâlde eski indeks cache'ten gelir)
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
# -y: soru sorma (CI/Docker etkileşimsiz)
# --no-install-recommends: önerilen ekstra paketleri kurma, image küçük kalır
# rm lists: indeks dosyalarını sil, image'dan ~40 MB düşer
```
Alpine karşılığı: `RUN apk add --no-cache curl`.

## Dil paket yöneticileriyle ilişkisi
Sistem paket yöneticisi **işletim sistemini** yönetir (root ister, tüm sisteme kurar). Dillerin kendi yöneticileri **projeyi** yönetir: `pip` (Gün 006, `venv` içinde), `npm`, `go mod`, `maven`. Python kütüphanesini `sudo pip install` ile sisteme kurma; Debian/Ubuntu/Arch bunu artık `externally-managed-environment` hatasıyla engeller. Kural: sistem araçları için `apt/dnf`, proje bağımlılıkları için dilin yöneticisi + `venv`/container.
