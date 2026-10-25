# Linux: Process Yönetimi ve Sinyaller

**Tanım:**
- **Process (süreç):** Çalışmakta olan bir programın örneği. Her birinin bir **PID**'i (process ID), bir **PPID**'i (parent PID, onu başlatan süreç), sahibi (user), durumu (state) ve kaynak kullanımı vardır. Tüm süreçler `PID 1`'den (genelde `systemd`) türeyen bir ağaçtır.
- **Sinyal (signal):** Çekirdeğin veya başka bir sürecin bir sürece gönderdiği kısa mesaj: "dur", "kapan", "ayarlarını yeniden oku" gibi. `kill` komutu aslında **sinyal gönderir**, adı yanıltıcıdır.
- **İş kontrolü (job control):** Kabuğun (shell) süreçleri ön plan (foreground) ve arka plan (background) arasında taşıması: `&`, `jobs`, `fg`, `bg`, `Ctrl+Z`.

**Neden önemli:** Sunucuda "uygulama yanıt vermiyor", "CPU %100", "port zaten kullanımda" sorunlarının ilk adımı süreci bulmak (`ps`, `top`, `ss -tlnp`) ve doğru sinyalle durdurmaktır. Docker `docker stop` önce **SIGTERM** gönderir, 10 sn sonra **SIGKILL**. Kubernetes pod kapatırken aynısını yapar (`terminationGracePeriodSeconds`). Uygulaman SIGTERM'i yakalayıp bağlantıları düzgün kapatmazsa (graceful shutdown) deploy sırasında istekler yarıda kesilir. Container'da uygulaman **PID 1** olur, sinyalleri doğru işlemek zorundadır.

## Süreçleri görmek
| Komut | İşe yarar |
|---|---|
| `ps aux` | Tüm süreçler (user, PID, %CPU, %MEM, komut) |
| `ps -ef --forest` | PPID ile ağaç görünümü |
| `ps -o pid,ppid,stat,cmd -p 1234` | Seçili sütunlar |
| `pgrep -a nginx` | Ada göre PID bul |
| `top` / `htop` | Canlı izleme (`P` CPU'ya, `M` belleğe göre sırala, `k` kill, `q` çık) |
| `pstree -p` | Süreç ağacı |
| `ss -tlnp` | Hangi süreç hangi portu dinliyor |
| `/proc/<PID>/` | Çekirdeğin süreç bilgisi (Gün 007: `/proc` sanal dosya sistemi) |

```bash
$ ps -o pid,ppid,stat,cmd -p $$
    PID    PPID STAT CMD
   4210    4180 Ss   -zsh
```

**Durumlar (STAT):** `R` çalışıyor (running), `S` uyuyor/bekliyor (sleeping), `D` kesilemez bekleme (genelde disk I/O), `T` durduruldu (stopped), `Z` **zombi** (bitti ama ebeveyni `wait` etmedi). Ek harfler: `s` oturum lideri, `+` ön planda.

## Sinyaller
| Sinyal | No | Varsayılan | Ne zaman |
|---|---|---|---|
| `SIGHUP` | 1 | Sonlandır | Terminal kapandı. Daemon'larda "config'i yeniden oku" (`nginx -s reload`) |
| `SIGINT` | 2 | Sonlandır | `Ctrl+C` |
| `SIGKILL` | 9 | Sonlandır | **Yakalanamaz**, temizlik yapılamaz. Son çare |
| `SIGTERM` | 15 | Sonlandır | `kill`'in varsayılanı. "Lütfen düzgünce kapan" |
| `SIGSTOP` | 19 | Durdur | Yakalanamaz duraklatma |
| `SIGTSTP` | 20 | Durdur | `Ctrl+Z` |
| `SIGCONT` | 18 | Devam | `fg` / `bg` |
| `SIGCHLD` | 17 | Yok say | Çocuk süreç bitti (ebeveyn `wait` etmeli) |

Gün 008 bağlantısı: sinyalle ölen sürecin exit kodu **128 + N**. `Ctrl+C` → `130`, `kill -9` → `137` (K8s'te `OOMKilled`), SIGTERM → `143`.

```bash
kill 1234            # SIGTERM (15): önce hep bunu dene
kill -HUP 1234       # config'i yeniden yükle
kill -9 1234         # SIGKILL: süreç 5-10 sn'de kapanmazsa
pkill -f "python app.py"   # komut satırına göre
kill -l              # tüm sinyallerin listesi
```

## Sinyal yakalamak: `trap`
```bash
temizle() { echo "SIGTERM geldi, bağlantılar kapatılıyor"; rm -f /tmp/app.lock; exit 0; }
trap temizle TERM INT       # SIGTERM ve Ctrl+C gelince temizle() çalışır
trap 'echo "HUP: config yeniden okundu"' HUP
```
Python karşılığı: `signal.signal(signal.SIGTERM, handler)`.

## Ön plan / arka plan (job control)
```bash
sleep 300 &          # & : arka planda başlat, kabuk hemen döner. $! = son arka plan PID'i
jobs -l              # [1]+ 5123 Running  sleep 300 &
fg %1                # ön plana al
# Ctrl+Z             # durdur (SIGTSTP), arka planda "Stopped" kalır
bg %1                # arka planda devam ettir (SIGCONT)
kill %1              # iş numarasıyla sinyal
wait                 # tüm arka plan işleri bitene kadar bekle
nohup ./uzun.sh > cikti.log 2>&1 &   # terminal kapansa da (SIGHUP) çalışmaya devam
```

> `nohup` ve `&` hızlı çözüm. Sunucuda kalıcı, çökünce yeniden başlayan servis için doğru araç **systemd** (bir sonraki kavram).

## Öncelik: `nice` / `renice`
`nice -n 10 ./yedek.sh` düşük öncelikle başlatır (-20 en yüksek, 19 en düşük). `renice -n 5 -p 1234` çalışanı değiştirir. Yedekleme gibi işleri sunucuyu yormadan çalıştırmak için.
