# systemd ve Servisler (`systemctl`, `journalctl`)

**Tanım:**
- **systemd:** Modern Linux dağıtımlarının (Ubuntu, Debian, RHEL, Amazon Linux, Arch) **init sistemi**. Çekirdekten sonra ilk başlayan süreçtir (**PID 1**), diğer tüm servisleri başlatır, izler, çökünce yeniden başlatır ve loglarını toplar.
- **Unit (birim):** systemd'nin yönettiği her şey bir `.ini` benzeri dosyadır: `.service` (servis), `.timer` (zamanlayıcı, cron alternatifi), `.socket`, `.target` (grup/hedef, ör. `multi-user.target`), `.mount`.
- **Servis (service / daemon):** Arka planda sürekli çalışan program: `sshd`, `nginx`, `docker`, senin API'n.
- **journald:** systemd'nin log servisi. Servisin stdout/stderr'i otomatik olarak journal'a gider, `journalctl` ile okunur.

**Neden önemli:** EC2'ye bir uygulama kurduğunda onu `nohup ... &` ile değil, **systemd servisi** olarak çalıştırırsın: sunucu yeniden başlayınca otomatik açılır, çökerse `Restart=` ile kalkar, logları tek yerde toplanır. `docker`, `kubelet`, `amazon-ssm-agent`, `amazon-cloudwatch-agent` ve CodeDeploy agent'ı EC2 üzerinde systemd servisi olarak çalışır. Bir Kubernetes node'u "NotReady" olduğunda ilk bakılacak yer `systemctl status kubelet` ve `journalctl -u kubelet`'tir. Ansible'ın `service` modülü de arka planda `systemctl` çağırır.

## `systemctl`: servisleri yönetmek
| Komut | Ne yapar |
|---|---|
| `systemctl status nginx` | Durum, PID, bellek, son log satırları |
| `sudo systemctl start / stop / restart nginx` | Şimdi başlat / durdur / yeniden başlat |
| `sudo systemctl reload nginx` | Config'i yeniden oku (genelde SIGHUP gönderir, Kavram 1) |
| `sudo systemctl enable --now nginx` | Açılışta otomatik başlat + şimdi başlat |
| `sudo systemctl disable nginx` | Açılışta başlatma |
| `systemctl is-active / is-enabled nginx` | Betiklerde kontrol (exit kodu 0/0 dışı, Gün 008) |
| `systemctl list-units --type=service --state=running` | Çalışan servisler |
| `systemctl --failed` | Çöken unit'ler |
| `systemctl cat nginx` | Unit dosyasının içeriği |
| `sudo systemctl daemon-reload` | Unit dosyasını değiştirdikten sonra **şart** |

> `start` ≠ `enable`. `start` şimdi çalıştırır, `enable` açılışta çalışmasını sağlar. Sunucu reboot'tan sonra servisin kalkmadıysa muhtemelen `enable` etmeyi unuttun.

## Unit dosyası yazmak
Konum: kendi servislerin `/etc/systemd/system/`, paketlerinki `/usr/lib/systemd/system/`, kullanıcı servisleri `~/.config/systemd/user/`.

> Dikkat: unit dosyalarında yorum **sadece satır başında** `#` ile yazılır. `Restart=always  # açıklama` yazarsan yorum değerin parçası sayılır.

```ini
# /etc/systemd/system/benim-api.service
[Unit]
Description=Benim Flask API'm
# ağ hazır olduktan sonra başla
After=network-online.target
Wants=network-online.target

[Service]
# simple: süreç ön planda çalışır, systemd onu izler
Type=simple
# root ile çalıştırma (güvenlik)
User=appuser
WorkingDirectory=/opt/benim-api
Environment=ORTAM=prod
# secret'lar repoda değil burada; baştaki "-": dosya yoksa hata verme
EnvironmentFile=-/etc/benim-api.env
ExecStart=/opt/benim-api/venv/bin/python app.py
# exit kodu 0 dışıysa veya sinyalle öldüyse 5 sn sonra yeniden başlat
Restart=on-failure
RestartSec=5
# stop: önce SIGTERM, 10 sn içinde kapanmazsa SIGKILL (Kavram 1)
TimeoutStopSec=10

[Install]
# enable edilince normal açılışta başlar
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now benim-api
systemctl status benim-api
```

**`Restart=` seçenekleri:** `no` (varsayılan), `on-failure` (0 dışı exit veya sinyal), `always` (her durumda), `on-abnormal`. Gün 008'deki exit kodu kuralı burada da geçerli: `exit 0` ile biten servis "başarılı bitti" sayılır, `on-failure` onu yeniden başlatmaz.

## `journalctl`: loglar
```bash
journalctl -u benim-api              # bir servisin tüm logları
journalctl -u benim-api -f           # canlı takip (tail -f gibi)
journalctl -u benim-api --since "10 min ago"
journalctl -u benim-api -n 50 -p err # son 50 satır, sadece hatalar
journalctl -b                        # bu açılıştan beri (Gün 007 alıştırması)
```

## Timer: cron'un systemd karşılığı
```ini
# yedek.timer  (yanında aynı adlı yedek.service olmalı)
[Timer]
# her gün 03:00
OnCalendar=*-*-* 03:00:00
# makine kapalıyken kaçırdıysa açılınca çalıştır
Persistent=true

[Install]
WantedBy=timers.target
```
`systemctl list-timers` ile hepsini görürsün. Cron'a göre artısı: loglar journal'da, `Persistent`, bağımlılıklar.

## Karşılaştırma
| | `nohup ./app &` | systemd servisi | Docker / K8s |
|---|---|---|---|
| Reboot sonrası açılır | ✗ | ✓ (`enable`) | ✓ (`restart: always` / Deployment) |
| Çökünce yeniden başlar | ✗ | ✓ (`Restart=`) | ✓ (restart policy) |
| Log | dosyaya elle | `journalctl` | `docker logs` / `kubectl logs` |
| Kaynak limiti | ✗ | `MemoryMax=`, `CPUQuota=` (cgroups) | `--memory`, `resources.limits` (yine cgroups) |
