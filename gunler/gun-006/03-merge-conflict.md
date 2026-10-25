# Git: Merge Conflict Çözmek

**Tanım:**
- **Merge conflict (birleştirme çakışması):** İki dal **aynı dosyanın aynı satırlarını** farklı şekilde değiştirdiğinde ortaya çıkar. Git hangisinin doğru olduğuna kendisi karar veremez ve merge işlemini durdurup kararı sana bırakır.
- Farklı dosyalarda ya da aynı dosyanın farklı satırlarında yapılan değişiklikler çakışma yaratmaz. Git bunları kendisi birleştirir.

**Neden önemli:** Ekip çalışmasında çakışma kaçınılmazdır. Biri `main`'de config dosyasını değiştirir, sen de kendi dalında aynı satırı değiştirirsin. Çakışmadan korkmamak ve doğru çözmek günlük bir iştir. Yanlış çözülen bir çakışma, birinin yaptığı değişikliğin sessizce kaybolması demektir.

## Çakışma işaretleri
Git çakışan dosyanın içine şu işaretleri koyar:
```
<<<<<<< HEAD
port = 8080
=======
port = 9090
>>>>>>> ozellik
```
| Bölüm | Anlamı |
|---|---|
| `<<<<<<< HEAD` ile `=======` arası | **Senin** bulunduğun dalın (örneğin `main`) hali |
| `=======` ile `>>>>>>> ozellik` arası | **Birleştirmeye çalıştığın** dalın hali |

Çözmek için dosyayı düzenlersin: birini seçer, ikisini birleştirir ya da yeni bir şey yazarsın. Sonra **bütün işaretleri silersin**.

## Kendin dene (güvenli, ayrı bir klasörde)
```bash
mkdir /tmp/conflict-deneme && cd /tmp/conflict-deneme
git init -b main
echo "port = 80" > ayar.txt
git add . && git commit -m "ilk ayar"

git switch -c ozellik                 # dal aç, aynı satırı değiştir
echo "port = 9090" > ayar.txt
git commit -am "port 9090 yapıldı"

git switch main                       # main'e dön, AYNI satırı başka türlü değiştir
echo "port = 8080" > ayar.txt
git commit -am "port 8080 yapıldı"

git merge ozellik                     # CONFLICT (content): Merge conflict in ayar.txt
git status                            # "both modified: ayar.txt"
cat ayar.txt                          # işaretleri gör
```

## Çözüm adımları
```bash
# 1. Dosyayı aç, işaretleri sil, doğru hali bırak (ör. "port = 9090")
nano ayar.txt                         # ya da VS Code: "Accept Current / Incoming / Both"

# 2. Çözüldüğünü Git'e bildir
git add ayar.txt

# 3. Merge'i tamamla (Git hazır bir mesaj önerir)
git commit

git log --oneline --graph             # iki dalın birleştiği merge commit'ini gör
```

| Durum | Komut |
|---|---|
| Vazgeç, merge'den önceki hale dön | `git merge --abort` |
| Hepsinde benim halimi al | `git checkout --ours ayar.txt` |
| Hepsinde gelen halini al | `git checkout --theirs ayar.txt` |
| Çakışan dosyaları listele | `git diff --name-only --diff-filter=U` |

## Çakışmayı azaltmak için
- Dalları kısa ömürlü tut, sık sık merge et.
- Kendi dalında çalışırken `main`'deki yenilikleri düzenli olarak al: `git pull origin main`.
- Büyük dosyaları ve dosyaların tamamını yeniden biçimlendiren (format) değişiklikleri ayrı commit yap.
- GitHub'da PR açtığında çakışma varsa "This branch has conflicts" uyarısı çıkar. Ya GitHub'ın web editöründe ya da yerelde yukarıdaki adımlarla çözülür.
