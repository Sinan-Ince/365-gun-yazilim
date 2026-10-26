# Linux: Kullanıcı ve Grup Yönetimi (`useradd`, `usermod`, `sudo`)

**Tanım:**
- **Kullanıcı (user):** Sistemdeki her kimliğin bir **UID**'i (user ID) vardır. Çekirdek isimle değil numarayla çalışır: dosya sahipliği (Gün 007) ve süreç sahipliği (Gün 009) UID'dir. `root` = **UID 0**, her izni aşar.
- **Grup (group):** Kullanıcıları bir araya toplayan kimlik, **GID** ile tanınır. Her kullanıcının bir **birincil grubu** (primary group, yeni dosyaların grubu) ve istediği kadar **ek grubu** (supplementary groups) olur.
- **Sistem kullanıcısı (system user):** İnsan değil servis içindir (`nginx`, `postgres`, `sshd`). Genelde UID < 1000, kabuğu `/usr/sbin/nologin`, şifresi yoktur.
- **sudo:** İzin verilen kullanıcının **başka bir kullanıcı adına** (varsayılan root) komut çalıştırmasını sağlar. Kim neyi çalıştırabilir `/etc/sudoers`'ta yazar, her kullanım loglanır.

**Neden önemli:** "Root ile çalıştırma" kuralı her yerde karşına çıkar: Gün 009'daki unit dosyasında `User=appuser`, Dockerfile'da `USER app`, Kubernetes'te `runAsNonRoot: true`. Amazon Linux AMI'de varsayılan kullanıcı `ec2-user`, Ubuntu AMI'de `ubuntu`'dur; ikisi de şifresiz `sudo` yetkisine sahiptir. Ekibe sunucu erişimi vermek = kullanıcı açmak, SSH anahtarını `~/.ssh/authorized_keys`'e koymak, gerekirse `sudo` grubuna eklemek. Ansible'ın `user` ve `group` modülleri ve EC2 `user_data` betikleri bu komutları çalıştırır. IAM'deki "en az yetki" (least privilege) ilkesinin Linux'taki karşılığı budur.

## Bilgilerin tutulduğu dosyalar
| Dosya | İçerik | İzin |
|---|---|---|
| `/etc/passwd` | Kullanıcılar: `ad:x:UID:GID:açıklama:home:kabuk` | `644` (herkes okur) |
| `/etc/shadow` | Şifre **hash**'leri, son değişim, süre dolumu | `640` / `600` (sadece root) |
| `/etc/group` | Gruplar: `grup:x:GID:üye1,üye2` | `644` |
| `/etc/sudoers`, `/etc/sudoers.d/` | sudo kuralları | `440`, sadece `visudo` ile düzenle |
| `/etc/skel/` | Yeni kullanıcının home'una kopyalanan şablon (`.bashrc` vb.) | |

```text
$ grep '^ec2-user:' /etc/passwd
ec2-user:x:1000:1000:EC2 Default User:/home/ec2-user:/bin/bash
#  ad    şifre UID  GID  açıklama          home          kabuk
```
`x`: şifre `shadow`'da. `/etc/passwd`'deki şifre alanı tarihi bir kalıntı: eskiden hash herkesin okuyabildiği bu dosyadaydı.

## Komutlar
| Komut | Ne yapar |
|---|---|
| `id`, `id ali` | UID, GID ve gruplar |
| `whoami`, `groups ali` | Mevcut kullanıcı / gruplar |
| `getent passwd ali` | Kullanıcıyı sorgula (LDAP/AD gibi kaynakları da görür, `grep`'ten iyidir) |
| `sudo useradd -m -s /bin/bash ali` | Kullanıcı oluştur (`-m` home aç, `-s` kabuk) |
| `sudo useradd -r -s /usr/sbin/nologin appuser` | Sistem (servis) kullanıcısı |
| `sudo passwd ali` | Şifre ata/değiştir |
| `sudo usermod -aG docker ali` | Ek gruba **ekle**. `-a` unutulursa diğer ek gruplardan **çıkarılır** |
| `sudo usermod -L ali` / `-U` | Hesabı kilitle / aç |
| `sudo userdel -r ali` | Sil (`-r` home'u da siler) |
| `sudo groupadd devops`, `gpasswd -d ali devops` | Grup oluştur / gruptan çıkar |
| `sudo -i`, `sudo -u postgres psql` | root kabuğu / başka kullanıcı olarak çalıştır |
| `sudo -l` | Bana hangi komutlar izinli |

> Grup değişikliği **yeni oturumda** geçerli olur. `usermod -aG docker ben` sonrası `docker ps` hâlâ "permission denied" diyorsa çıkış yapıp tekrar gir (veya `newgrp docker`).

> Ubuntu/Debian'da yöneticiler `sudo` grubunda, RHEL/Amazon Linux/Arch'ta `wheel` grubundadır. `adduser` (Debian) etkileşimli bir sarmalayıcıdır; betiklerde `useradd` kullan.

## sudoers
```text
# visudo -f /etc/sudoers.d/deploy   (sözdizimi hatası sudo'yu kilitler, visudo kontrol eder)
# kullanıcı  makine=(hangi kullanıcı olarak)  komutlar
%wheel   ALL=(ALL:ALL) ALL
deploy   ALL=(root) NOPASSWD: /usr/bin/systemctl restart benim-api
```
İkinci satır least privilege örneği: CI/CD'nin kullandığı `deploy` kullanıcısı şifresiz ama **sadece** servisi yeniden başlatabilir.

## Örnek: EC2'de servis kullanıcısı (user_data)
```bash
#!/bin/bash
useradd -r -m -d /opt/benim-api -s /usr/sbin/nologin appuser   # giriş yapamaz
chown -R appuser:appuser /opt/benim-api                       # Gün 007: sahiplik
chmod 750 /opt/benim-api
# unit dosyasında: User=appuser  (Gün 009)
```

## Karşılaştırma
| | Linux | Docker | Kubernetes | AWS |
|---|---|---|---|---|
| Kimlik | UID/GID | `USER 1000` | `runAsUser: 1000` | IAM user / role |
| Yetki yükseltme | `sudo` | `--privileged` (kaçın) | `privileged: true` (kaçın) | `sts:AssumeRole` |
| Gruplama | grup | | ServiceAccount + RBAC | IAM group |
