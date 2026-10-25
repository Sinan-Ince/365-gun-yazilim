# Dosya İzinleri: chmod, chown, sudo

**Tanım:**
- **İzin (permission):** Linux'ta her dosyanın bir **sahibi** (user), bir **grubu** (group) ve **diğerleri** (others) için ayrı ayrı belirlenmiş üç hakkı vardır: **okuma (r)**, **yazma (w)** ve **çalıştırma (x)**.
- **chmod:** İzinleri değiştirir. **chown:** Sahibi ve grubu değiştirir.
- **root ve sudo:** `root` her şeye yetkisi olan yönetici kullanıcıdır. `sudo` tek bir komutu root yetkisiyle çalıştırır.

**Neden önemli:**
- **Güvenlik:** AWS'de EC2'ye bağlanırken kullandığın `.pem` anahtarının izni `400` değilse SSH bağlanmayı reddeder ("UNPROTECTED PRIVATE KEY FILE!").
- **Betikler:** Yazdığın `deploy.sh` dosyası `x` izni olmadan `./deploy.sh` ile çalışmaz.
- **Docker ve sunucu hataları:** "Permission denied" DevOps'ta en sık görülen hatalardan biridir. Genelde sebebi yanlış sahip ya da eksik izindir.
- **En az yetki ilkesi:** Herkes sadece ihtiyacı olan kadar yetkiye sahip olmalı. AWS IAM'de (6. ay) de aynı fikir var.

## `ls -l` çıktısını okumak
```
-rwxr-x---  1  sinan  dev  1024  Eki 25 10:00  deploy.sh
│└┬┘└┬┘└┬┘     └─┬─┘  └┬┘
│ │  │  │        │     └─ grup
│ │  │  │        └─ sahip
│ │  │  └─ diğerleri: --- (hiçbir şey)
│ │  └─ grup: r-x (oku, çalıştır)
│ └─ sahip: rwx (oku, yaz, çalıştır)
└─ tür: - dosya, d klasör, l kısayol (symlink)
```

## Sayısal (octal) gösterim
Her hak bir sayıdır: **r = 4, w = 2, x = 1**. Toplanır.

| Sayı | Haklar | Tipik kullanım |
|---|---|---|
| `7` | rwx | Sahip için betik |
| `6` | rw- | Sahip için normal dosya |
| `5` | r-x | Okuyup çalıştırabilir |
| `4` | r-- | Sadece okur |
| `0` | --- | Hiçbir şey |

| Komut | Sonuç | Ne zaman |
|---|---|---|
| `chmod 755 betik.sh` | `rwxr-xr-x` | Herkesin çalıştırabileceği betik |
| `chmod 644 not.txt` | `rw-r--r--` | Normal dosya (varsayılan) |
| `chmod 600 .env` | `rw-------` | Sadece benim okuyacağım gizli dosya |
| `chmod 400 anahtar.pem` | `r--------` | SSH anahtarı (AWS EC2) |
| `chmod 700 ~/.ssh` | `rwx------` | SSH klasörü |

## Harfli gösterim
```bash
chmod +x betik.sh        # herkese çalıştırma ekle
chmod u+x betik.sh       # sadece sahibe (u=user, g=group, o=others, a=all)
chmod go-w dosya         # grup ve diğerlerinden yazmayı kaldır
chmod -R 755 klasor/     # -R: içindekilerin hepsine uygula
```

## Klasörlerde izinlerin anlamı farklıdır
| Hak | Dosyada | Klasörde |
|---|---|---|
| r | İçeriği oku | İçindekileri listele (`ls`) |
| w | Değiştir | İçine dosya ekle / sil |
| x | Program olarak çalıştır | İçine **gir** (`cd`) |

## Sahip ve sudo
```bash
sudo chown sinan:dev dosya    # sahibi sinan, grubu dev yap
sudo chown -R www-data /var/www   # web sunucusu kullanıcısına ver
id                            # kim olduğum ve hangi gruplarda olduğum
sudo komut                    # tek bir komutu root olarak çalıştır
```

> `chmod 777` "çalışmıyor, herkese her izni vereyim" çözümüdür ve **yanlıştır**. Herkes dosyayı değiştirebilir hale gelir. Sorunun asıl sebebini (sahip mi, grup mu) bul.

## Git ve izinler
Git sadece çalıştırma (`x`) iznini kaydeder. Bu günün `.sh` dosyaları `chmod +x` ile commit'lendi; repoyu klonlayan herkes `./01_dosya_sistemi.sh` ile çalıştırabilir. `git ls-files -s` çıktısında `100755` çalıştırılabilir, `100644` normal dosya demektir.
