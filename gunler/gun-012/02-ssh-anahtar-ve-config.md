# Linux: SSH (anahtar çifti, `~/.ssh/config`, `scp` / `rsync`)

**Tanım:**
- **SSH (Secure Shell):** Başka bir makineye şifreli bağlantıyla girip komut çalıştırma protokolü (varsayılan port 22). Sunucuda `sshd` servisi (Gün 009) çalışır, sen `ssh` istemcisiyle bağlanırsın.
- **Anahtar çifti (key pair):** Asimetrik şifreleme. **Özel anahtar (private key)** `~/.ssh/id_ed25519` sende kalır, kimseyle paylaşılmaz. **Açık anahtar (public key)** `id_ed25519.pub` sunucudaki `~/.ssh/authorized_keys` dosyasına eklenir. Bağlanırken sunucu bir soru sorar, sadece özel anahtarı olan doğru cevabı imzalayabilir. Şifre ağdan hiç geçmez.
- **`known_hosts`:** Daha önce bağlandığın sunucuların parmak izleri (fingerprint). Sunucu değişirse SSH "REMOTE HOST IDENTIFICATION HAS CHANGED" der: ortadaki adam (man-in-the-middle) saldırısına karşı koruma.
- **`~/.ssh/config`:** Takma ad (alias) ve bağlantı ayarları dosyası. `ssh -i ~/.ssh/aws.pem ec2-user@3.120.4.7` yerine `ssh web` yazarsın.
- **`scp` / `rsync`:** SSH üzerinden dosya kopyalama. `rsync` sadece **değişen kısımları** gönderir, yarıda kalırsa devam eder.

**Neden önemli:** Bulut sunucusuna (AWS EC2) erişimin temel yolu SSH. EC2 açarken seçtiğin **key pair**'in `.pem` dosyası, aslında bir özel anahtar. GitHub'a `git@github.com:...` ile push da SSH anahtarıyla olur. Ansible tamamen SSH ile çalışır, CI/CD'den sunucuya deploy (`rsync` + `ssh 'systemctl restart app'`) yine SSH. Güvenlik grubu (security group) 22. portu dünyaya açmak ve şifreyle giriş, en sık yapılan hatalar.

## Anahtar oluşturma ve sunucuya ekleme
```bash
ssh-keygen -t ed25519 -C "sinan@laptop"     # ed25519: modern, kısa, hızlı (RSA yerine)
# -> ~/.ssh/id_ed25519 (özel) ve ~/.ssh/id_ed25519.pub (açık). Parola (passphrase) koy!

ssh-copy-id kullanici@sunucu                  # .pub'ı sunucunun authorized_keys'ine ekler
ssh kullanici@sunucu                          # artık şifresiz (anahtarla) girersin

ssh-keygen -lf ~/.ssh/id_ed25519.pub          # parmak izi: SHA256:...
cat ~/.ssh/id_ed25519.pub                     # GitHub > Settings > SSH keys'e bunu yapıştır
ssh -T git@github.com                         # "Hi Sinan-Ince! You've successfully authenticated"
```

## İzinler (Gün 007): yanlışsa SSH reddeder
| Yol | İzin | Neden |
|---|---|---|
| `~/.ssh/` | `700` (`drwx------`) | klasöre sadece sen girebilirsin |
| `~/.ssh/id_ed25519` | `600` (`-rw-------`) | özel anahtar: başkası okursa senin yerine girer |
| `~/.ssh/*.pub` | `644` | açık anahtar, okunabilir |
| `~/.ssh/authorized_keys` (sunucu) | `600` | |
| `aws.pem` | `400` | AWS'nin önerdiği; `chmod 400 aws.pem` |
```
WARNING: UNPROTECTED PRIVATE KEY FILE!  Permissions 0644 for 'aws.pem' are too open.
```
Bu hatanın çözümü: `chmod 400 aws.pem`.

## `~/.ssh/config`
```sshconfig
Host web                          # ssh web
    HostName 3.120.4.7
    User ec2-user
    IdentityFile ~/.ssh/aws.pem
    IdentitiesOnly yes            # sadece bu anahtarı dene

Host db                           # özel ağdaki sunucuya web üzerinden atlayarak gir
    HostName 10.0.2.15
    User ubuntu
    ProxyJump web                 # bastion / jump host

Host *                            # herkes için varsayılanlar (en sona)
    ServerAliveInterval 60        # bağlantı boşta kopmasın
    AddKeysToAgent yes
```
```bash
ssh -G web | grep -E '^(hostname|user|identityfile) '   # config'in çözülmüş halini gör
```
Kural: **ilk eşleşen değer kazanır**, bu yüzden `Host *` en sona yazılır.

## Uzakta komut, dosya taşıma, tünel
```bash
ssh web 'uptime && df -h /'                  # gir, komutu çalıştır, çık (betiklerde)
ssh web 'sudo systemctl restart app'

scp app.tar.gz web:/tmp/                     # tek dosya gönder
scp web:/var/log/app.log .                   # tek dosya al

rsync -avz --delete ./site/ web:/var/www/site/   # klasörü eşitle
#  -a arşiv (izin, zaman), -v ayrıntı, -z sıkıştır, --delete hedefte fazla olanı sil
rsync -avzn --delete ./site/ web:/var/www/site/  # -n: dry run, önce NE yapacağını gör

ssh -L 5432:localhost:5432 db                # yerel tünel: sunucudaki Postgres'e localhost:5432'den eriş
```
> `rsync` sonundaki `/` önemli: `site/` = klasörün **içeriği**, `site` = klasörün **kendisi**.

## ssh-agent: parolayı bir kez gir
```bash
eval "$(ssh-agent -s)"     # agent başlat
ssh-add ~/.ssh/id_ed25519  # parolayı bir kez sor, oturum boyunca hatırla
ssh-add -l                 # yüklü anahtarlar
```

## Sunucu tarafı sertleştirme (`/etc/ssh/sshd_config`)
```
PasswordAuthentication no     # sadece anahtarla giriş
PermitRootLogin no            # root ile direkt giriş yok, sudo kullan
```
Değişiklikten sonra `sudo sshd -t` (sözdizimi kontrolü) ve `sudo systemctl reload sshd`. **Mevcut oturumu kapatmadan** yeni bir terminalden girişi dene, yoksa kendini dışarıda bırakırsın. AWS'de: security group'ta 22'yi sadece kendi IP'ne aç ya da hiç açma, **SSM Session Manager** kullan.

Kod: [`02_ssh_anahtar_ve_config.sh`](02_ssh_anahtar_ve_config.sh). `~/.ssh` izinlerini denetler, anahtarların parmak izini gösterir (özel anahtarı okumaz), `config`'teki Host'ları listeler, geçici klasörde örnek anahtar üretip `ssh -G` ile çözülmüş ayarları gösterir. Hiçbir sunucuya bağlanmaz.
