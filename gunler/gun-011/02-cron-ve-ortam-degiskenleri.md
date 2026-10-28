# Linux: Cron ve Ortam Değişkenleri (`crontab`, `export`, `PATH`, `.bashrc`)

**Tanım:**
- **Ortam değişkeni (environment variable):** Bir process'e (Gün 009) başlarken verilen `AD=değer` çiftleri. Process'in **ortamı (environment)** çocuk process'lere **kopyalanır**, ama çocuk değiştirirse ebeveyn etkilenmez.
- **`export`:** Kabuk değişkenini (shell variable) ortam değişkeni yapar, yani çocuk process'lere geçmesini sağlar. `export` edilmeyen değişken sadece o kabukta yaşar.
- **`PATH`:** `:` ile ayrılmış klasör listesi. `ls` yazınca kabuk bu klasörlerde soldan sağa `ls` adlı çalıştırılabilir dosya arar. İlk bulunan kazanır.
- **Kabuk başlangıç dosyaları (startup files):** `~/.bashrc` (her etkileşimli bash), `~/.bash_profile` / `~/.profile` (login kabuğu), zsh'te `~/.zshrc`. Kalıcı `export`'lar buraya yazılır.
- **cron:** Zamanlanmış görev (scheduled job) çalıştıran servis (daemon). Her kullanıcının bir **crontab**'ı vardır; satır biçimi: `dakika saat gün ay haftanın_günü komut`.

**Neden önemli:** **12-factor app** kuralı: config koda değil ortama yazılır. Docker'da `-e`/`ENV`, docker compose'da `environment:` / `.env`, Kubernetes'te `env:` + ConfigMap/Secret, GitHub Actions'ta `env:` ve `secrets.*`, AWS Lambda'da environment variables, systemd'de `Environment=` (Gün 009): hepsi aynı mekanizma. Telegram botundaki `BOT_TOKEN` da `.env`'den gelir. "Bende çalışıyor, cron'da çalışmıyor" hatasının %90'ı ortam farkıdır (`PATH` kısa, `.bashrc` okunmaz). cron ise yedekleme, log temizliği, sertifika yenileme (`certbot renew`) gibi işlerin klasik aracıdır; Kubernetes `CronJob`, GitHub Actions `schedule:` ve AWS EventBridge aynı **cron sözdizimini** kullanır.

## Ortam değişkenleri
```bash
AD=ali                 # kabuk değişkeni: sadece bu kabukta
bash -c 'echo "[$AD]"' # []  -> çocuk görmüyor
export AD              # artık ortamda
bash -c 'echo "[$AD]"' # [ali]

DEBUG=1 python app.py  # sadece BU komutun ortamına ekle, kabuğa kalmaz
env                    # tüm ortam değişkenleri
printenv HOME          # tek değişken
env -i bash -c 'env'   # boş ortamla başlat (cron'a benzer test)
unset AD               # sil

echo "${PORT:-8080}"   # PORT yoksa/boşsa varsayılan 8080
: "${BOT_TOKEN:?BOT_TOKEN tanımlı değil}"   # yoksa hata verip çık (betik başında kontrol)
```

## PATH
```bash
echo "$PATH" | tr ':' '\n'      # klasörleri alt alta gör
command -v python               # hangi python çalışacak (betikte which yerine bunu kullan)
type -a python                  # PATH'teki tüm python'lar + alias/fonksiyon
export PATH="$HOME/.local/bin:$PATH"   # başa ekle: kendi araçların önce bulunur
```
> `PATH`'e `.` (bulunduğun klasör) ekleme: biri klasöre `ls` adlı zararlı dosya koyarsa sen çalıştırırsın. Bu yüzden `./betik.sh` yazıyoruz.

## Hangi dosya ne zaman okunur
| Dosya | Ne zaman | Ne konur |
|---|---|---|
| `~/.bashrc` | her etkileşimli, login olmayan bash (yeni terminal sekmesi) | alias, prompt, `export` |
| `~/.bash_profile` / `~/.profile` | login kabuğu (SSH ile giriş, TTY) | genelde `. ~/.bashrc` + `PATH` |
| `/etc/environment` | sistem geneli, PAM tarafından | `AD=değer` (kabuk sözdizimi yok) |
| `~/.zshrc` | etkileşimli zsh | zsh için hepsi |
| **cron, systemd, Docker** | **hiçbiri okunmaz** | ortamı kendin ver |

Değişiklikten sonra mevcut kabukta geçerli olsun diye: `source ~/.bashrc`.

## cron sözdizimi
```
┌───────── dakika (0-59)
│ ┌─────── saat (0-23)
│ │ ┌───── ayın günü (1-31)
│ │ │ ┌─── ay (1-12)
│ │ │ │ ┌─ haftanın günü (0-7, 0 ve 7 = Pazar)
│ │ │ │ │
* * * * *  komut
```
| İfade | Anlamı |
|---|---|
| `*/5 * * * *` | her 5 dakikada |
| `0 3 * * *` | her gün 03:00 |
| `30 9 * * 1-5` | hafta içi 09:30 |
| `0 0 1 * *` | her ayın 1'i gece yarısı |
| `0 */6 * * *` | 6 saatte bir (00, 06, 12, 18) |
| `@reboot` | açılışta bir kez |

```bash
crontab -l        # kendi görevlerini listele
crontab -e        # düzenle (EDITOR değişkenindeki editörle)
crontab -r        # HEPSİNİ sil, onay sormaz! (-e ile karıştırma)
```

## Doğru bir cron satırı
```cron
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
MAILTO=""
# Her gece 03:15'te yedek al, çıktıyı ve hataları loga yaz
15 3 * * * /home/ali/bin/yedek.sh >> /home/ali/log/yedek.log 2>&1
```
cron tuzakları:
- **Ortam çok kısa:** `PATH=/usr/bin:/bin`, `.bashrc` yok. Mutlak yol kullan veya crontab başında `PATH=` ver.
- **Çıktı kaybolur:** yönlendirme yoksa çıktı mail'e gider (genelde hiçbir yere). `>> log 2>&1` (Gün 007) ekle.
- **`%` özel karakter:** cron satırında `%` yeni satır demektir. `date +%F` yazacaksan `\%` kaç veya betiğe taşı.
- **Saat dilimi:** sunucunun saat dilimi geçerlidir (EC2'de genelde UTC).
- **Üst üste binme:** iş uzun sürerse bir sonraki başlar. `flock -n /tmp/yedek.lock yedek.sh` ile tek kopya çalıştır.

## cron mu systemd timer mı?
Arch'ta cron varsayılan kurulu değil (`cronie` paketi), systemd **timer** kullanılır: `systemctl list-timers`. Timer'ın artıları: loglar `journalctl`'da, kaçırılan çalıştırmayı telafi (`Persistent=true`), servis bağımlılıkları. cron'un artısı: her yerde var ve tek satır. Bulutta aynı fikir: K8s `CronJob` (`schedule: "15 3 * * *"`), GitHub Actions `on: schedule: - cron: '15 3 * * *'` (her zaman UTC).

Kod: [`02_cron_ve_ortam_degiskenleri.sh`](02_cron_ve_ortam_degiskenleri.sh). Ortam/`export` farkını gösterir, `PATH`'i inceler, cron ifadelerini Türkçe açıklar. Sisteme hiçbir şey eklemez.
