# 365 Gün Yazılım: Günlük Prosedür

Bu repo 1 yıllık öğrenme serüveni. Bu dosya, Telegram botunun `claude -p` ile
başlattığı otomatik "günlük adım" oturumu içindir. Etkileşim yok, soru sorma,
eksik bilgi varsa makul varsayımla devam et.

## Kullanıcı
Bilgisayar mühendisliği öğrencisi, hedef DevOps + AWS. Temelleri biliyor, temel
konuları kısa ve yoğun anlat. Dil: Türkçe. Teknik terimlerin İngilizcesini parantezde ver.

## 1. Kaldığın günü bul
- `README.md` → "📈 İlerleme" tablosunun son satırı = son tamamlanan gün.
  Yeni gün = son gün + 1 (NNN, 3 hane).
- Konu seçimi: Obsidian'daki son gün notunun (`Günler/Gün NNN.md`) "Sonraki gün"
  görevi + README'deki yol haritası (ay sırası). Daha önce işlenmiş kavramı tekrarlama.

## 2. Repo dosyaları: `gunler/gun-NNN/`
- Günde **2 kavram** (gerekirse en fazla 3).
- Her kavram için:
  - `NN-<kavram-kebab>.md`: **Tanım**, **Neden önemli** (DevOps/AWS bağlantısı), örnek, tablo/diyagram
  - Kod: `NN_<kavram_snake>.py` (Bash konularında `.sh`, ilk satır shebang). Kod
    çalışır ve yorumlu o (Git gibi) yalnızca
`.md` yeterli.
- Mevcut günlerdeki üslugunler/gun-007/`).
- `README.md` → İlerleme
  `| [NNN](gunler/gun-NNKavram 2 |`

## 3. Obsidian: `~/Notla/`
- `Günler/Gün NNN.md`: önceki linkleri,
Kavramlar,
  Görevler, Kendi notlarım). Görevlerde alıştırma ve "Sonraki gün (NNN+1):
<konu>" olsun.
- `Kavramlar/<Kavram Adıtiketler, ilk görüldüğü
gün,
  ilgili kavramlara `[[l cümlelerimle" başlığı.
- Ana not `365 Gün Yazıluna satır ekle
  (Push sütunu: `⏳` — onaydan sonra güncellenir).                            
## 4. Bot dosyaları: `.bot/` (git'e girmez)
### `.bot/telegram.html`                                                       Telegram'a gidecek özet. - Sadece şu etiketler: `<a href> <blockquote>` - Metindeki `<`, `>`, `&` `&amp;` yaz (kod içinde de).
- `<br>`, `<p>`, `<ul>`, başlık etiketi YOK. Satır sonu için düz newline
kullan.
- Toplam en fazla ~3500 karakter.
Format:
```
📅 <b>Gün NNN: <konu baş

1️⃣ <b>Kavram 1</b>
2-4 cümle tanım + neden önemli.
<pre>kısa örnek kod (≤10 satır)</pre>

2️⃣ <b>Kavram 2</b>
...

✍️ <b>Alıştırma</b>
Kullanıcının kendi çözecerme).
```

### `.bot/plan.json`
Botun commit'leri buna gN, başka hiçbir şeyyazma:
```json
{
  "gun": 8,
  "commits": [
    {"files": ["gunler/g-008/01_...sh"],
     "mesaj": "feat(gun-008): <kavram 1> eklendi"},
    {"files": ["gunler/g],
     "mesaj": "feat(gun-blosu"}
  ],
  "ekler": ["gunler/gun-008/01_...sh"]
}
```
- Her kavram bir commit.er.
- Commit mesajı formatı:türkçe açıklama>`
  (sadece .md ise `docs`
- `ekler`: Telegram'a dosya olarak gönderilecek kod dosyaları.

## Yapma
- git komutu çalıştırma,onaydan sonra yapar.
- `gunler/` dışındaki mevcut dosyaları silme veya yeniden yazma (README'ye sadece satır ekle).
- `.env`, `*.pem`, `*.key` dosyalarına dokunma.
