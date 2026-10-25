# 365 Gün Yazılım: Günlük Prosedür

Bu repo 1 yıllık bir öğrenme serüveni. Bu dosya, Telegram botunun `claude -p` ile
başlattığı otomatik "günlük adım" oturumu için yazıldı. Oturum etkileşimsiz: soru
sorma, eksik bilgi varsa makul bir varsayımla devam et.

## Kullanıcı
Bilgisayar mühendisliği öğrencisi, hedefi DevOps + AWS. Temelleri biliyor, temel
konuları kısa ve yoğun anlat. Dil Türkçe. Teknik terimlerin İngilizcesini parantez
içinde ver.

## 1. Kaldığın günü bul
- `README.md` dosyasındaki "📈 İlerleme" tablosunun son satırı, son tamamlanan
  gündür. Yeni gün = son gün + 1 (NNN, 3 hane).
- `gunler/gun-NNN/` klasörü zaten varsa ama README'de satırı yoksa, o gün yarım
  kalmış demektir. O günü tamamla, eksik dosyaları ekle. Yeni bir gün açma.
- Konu seçimi: Obsidian'daki son gün notunda (`Günler/Gün NNN.md`) yazan
  "Sonraki gün" görevi ve README'deki yol haritası (ay sırası). Daha önce
  işlenmiş bir kavramı tekrarlama.

## 2. Repo dosyaları: `gunler/gun-NNN/`
- Günde **2 kavram** işle (gerekirse en fazla 3).
- Her kavram için:
  - `NN-<kavram-kebab>.md`: **Tanım**, **Neden önemli** (DevOps/AWS bağlantısı),
    örnek, gerekiyorsa tablo veya diyagram.
  - Kod: `NN_<kavram_snake>.py` (Bash konularında `.sh`, ilk satırı shebang).
    Kod çalışır ve yorumlu olmalı. Kavram sadece teorikse (Git konuları gibi)
    yalnızca `.md` yeterli.
- Üslup ve uzunluk için mevcut günleri örnek al (ör. `gunler/gun-007/`).
- `README.md` → İlerleme tablosuna bir satır ekle:
  `| [NNN](gunler/gun-NNN) | YYYY-AA-GG | Kavram 1 · Kavram 2 |`

## 3. Obsidian: `~/Notlar/10 Projeler/365 Gün Yazılım/`
- `Günler/Gün NNN.md`: önceki günlerin formatını kullan (Üst/Önceki linkleri,
  Kavramlar, Görevler, Kendi notlarım). Görevlerde alıştırma ve
  "Sonraki gün (NNN+1): <konu>" maddesi olsun.
- `Kavramlar/<Kavram Adı>.md`: her kavram ayrı bir not. Etiketler, ilk görüldüğü
  gün, ilgili kavramlara `[[link]]`, en sonda boş bir "## Kendi cümlelerimle"
  başlığı.
- Ana not `365 Gün Yazılım.md` → "## İlerleme" tablosuna bir satır ekle
  (Push sütunu `⏳` olsun, onaydan sonra güncellenir).

## 4. Bot dosyaları: `.bot/` (git'e girmez)
Klasör yoksa oluştur. Önceki çalıştırmadan kalan dosyaların üzerine yaz.

### `.bot/telegram.html`
Telegram'a gidecek özet. **Telegram HTML** kurallarına uy:
- Yalnızca şu etiketler kullanılabilir:
  `<b> <i> <u> <s> <code> <pre> <a href="..."> <blockquote>`
- Metindeki `<`, `>` ve `&` karakterlerini `&lt;`, `&gt;`, `&amp;` olarak yaz
  (kod içinde de).
- `<br>`, `<p>`, `<ul>`, `<h1>` gibi etiketler YASAK. Satır sonu için düz newline
  kullan.
- Toplam en fazla ~3500 karakter.

Format:
```
📅 <b>Gün NNN: konu başlığı</b>

1️⃣ <b>Kavram 1</b>
2-4 cümle tanım + neden önemli.
<pre>kısa örnek kod (en fazla 10 satır)</pre>

2️⃣ <b>Kavram 2</b>
...

✍️ <b>Alıştırma</b>
Kullanıcının kendisinin çözeceği küçük bir görev (çözümü verme).
```

### `.bot/plan.json`
Botun commit'leri atarken izleyeceği plan. Geçerli JSON olmalı, içine başka
hiçbir şey yazma:
```json
{
  "gun": 8,
  "commits": [
    {
      "files": ["gunler/gun-008/01-ornek.md", "gunler/gun-008/01_ornek.sh"],
      "mesaj": "feat(gun-008): örnek kavram 1 eklendi"
    },
    {
      "files": ["gunler/gun-008/02-ornek.md", "gunler/gun-008/02_ornek.sh", "README.md"],
      "mesaj": "feat(gun-008): örnek kavram 2, ilerleme tablosu"
    }
  ],
  "ekler": ["gunler/gun-008/01_ornek.sh", "gunler/gun-008/02_ornek.sh"]
}
```
- Her kavram bir commit. `README.md` son commit'e girer.
- Commit mesajı formatı: `feat|docs|chore(gun-NNN): <Türkçe açıklama>`.
  Commit'te sadece `.md` dosyaları varsa `docs` kullan.
- `ekler`: Telegram'a dosya olarak gönderilecek kod dosyaları.
- Dosya yolları repo köküne göre yazılmalı.

## Yapma
- git komutu çalıştırma, commit veya push yapma. Bunları bot, kullanıcı onay
  verdikten sonra yapar.
- `gunler/` dışındaki mevcut dosyaları silme ya da baştan yazma. README'ye
  sadece satır ekle.
- `.env`, `*.pem` ve `*.key` dosyalarına dokunma.
