# Linux Dosya Sistemi ve Temel Komutlar

**Tanım:**
- **Dosya sistemi hiyerarşisi:** Linux'ta her şey tek bir kökten (`/`) başlayan bir ağaçtır. Windows'taki gibi `C:`, `D:` sürücüleri yoktur. Diskler, USB'ler, hatta donanım bile bu ağacın bir yerine bağlanır (mount).
- **Shell (kabuk):** Komutları alıp işletim sistemine ileten program. En yaygınları: `bash` (sunucuların neredeyse hepsinde var), `zsh`, `sh`.
- **Mutlak ve göreli yol:** `/home/kiroschi/not.txt` köke göre yazılır, mutlaktır. `../not.txt` ise bulunduğun klasöre göre yazılır, görelidir.

**Neden önemli:** AWS EC2, Docker container'ları, Kubernetes node'ları ve CI runner'larının neredeyse hepsi Linux'tur ve çoğunda grafik arayüz yoktur. Sunucuya SSH ile bağlandığında elinde sadece terminal olur. DevOps'un temel dili budur.

## Önemli klasörler
| Klasör | İçinde ne var |
|---|---|
| `/` | Kök, her şey buradan başlar |
| `/home/<kullanıcı>` | Kullanıcının dosyaları. Kısaltması `~` |
| `/root` | root (yönetici) kullanıcısının ev klasörü |
| `/etc` | Sistem ayar dosyaları (`/etc/hosts`, `/etc/ssh/sshd_config`) |
| `/var/log` | Log dosyaları. Sunucuda sorun çıkınca ilk bakılan yer |
| `/usr/bin`, `/bin` | Programlar (`ls`, `python`, `git`) |
| `/tmp` | Geçici dosyalar, yeniden başlatınca silinebilir |
| `/opt` | Elle kurulan ek yazılımlar |
| `/proc`, `/sys` | Gerçek dosya değil; çekirdeğin (kernel) çalışan sistem hakkındaki bilgisi |
| `/dev` | Donanım aygıtları (`/dev/sda` disk, `/dev/null` "kara delik") |

## Temel komutlar
| Komut | İşi | Örnek |
|---|---|---|
| `pwd` | Şu an hangi klasördeyim | `pwd` |
| `ls` | Klasör içeriğini listele | `ls -la` (gizli dosyalar + ayrıntı) |
| `cd` | Klasör değiştir | `cd ~`, `cd ..`, `cd -` (önceki klasör) |
| `mkdir` | Klasör oluştur | `mkdir -p a/b/c` (ara klasörleri de oluşturur) |
| `touch` | Boş dosya oluştur | `touch not.txt` |
| `cp` | Kopyala | `cp -r kaynak/ hedef/` |
| `mv` | Taşı ya da yeniden adlandır | `mv eski.txt yeni.txt` |
| `rm` | Sil (**çöp kutusu yok!**) | `rm -r klasor/` |
| `cat`, `less` | Dosyayı göster | `less /var/log/syslog` (`q` ile çık) |
| `head`, `tail` | İlk / son satırlar | `tail -f app.log` (canlı izle) |
| `find` | Dosya ara | `find . -name "*.py"` |
| `which` | Komutun nerede olduğu | `which python` |
| `man`, `--help` | Yardım | `man ls`, `ls --help` |

> `rm -rf` geri alınamaz. Özellikle `rm -rf /` veya `rm -rf $DEGISKEN/` (değişken boşsa kök silinir) en ünlü felaketlerdendir. Silmeden önce `ls` ile ne sileceğini kontrol et.

## Gizli dosyalar
Adı `.` ile başlayan dosyalar gizlidir: `.gitignore`, `.bashrc`, `.ssh/`, `.env`. `ls` bunları göstermez, `ls -a` gösterir.

## Bash betiği (script) iskeleti
```bash
#!/usr/bin/env bash      # shebang: bu dosya hangi programla çalışacak
set -euo pipefail        # hata olursa dur, tanımsız değişkende dur, pipe hatasını yakala

ad="dünya"               # = etrafında BOŞLUK OLMAZ
echo "Merhaba $ad"
```
Çalıştırmak: `bash betik.sh` ya da çalıştırma izni verip `./betik.sh` (izinler bir sonraki konu).

## Windows karşılıkları
| Linux | Windows (PowerShell) |
|---|---|
| `ls` | `dir` / `Get-ChildItem` |
| `cat` | `type` / `Get-Content` |
| `rm` | `del` / `Remove-Item` |
| `/` ayırıcı | `\` ayırıcı |
