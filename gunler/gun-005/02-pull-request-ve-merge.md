# Pull Request ve Merge

**Tanım:**
- **Merge (birleştirme):** Bir daldaki commit'leri başka bir dala almaktır. Genelde bir özellik dalı (`gun-005`) `main` dalına birleştirilir.
- **Pull Request (PR):** GitHub'da açılan bir **birleştirme isteğidir**: "Bu daldaki değişiklikleri `main`'e al." Değişiklikler yan yana gösterilir, ekip arkadaşları yorum yapar ve onay verir. Sonra **Merge** düğmesine basılır. GitLab'da bunun adı **Merge Request (MR)**.

**Neden önemli:**
- **Ekip çalışması:** Bir kişi habersizce `main`'i değiştirip başkasının kullandığı bir dosyayı silemez.
- **Kod incelemesi (code review):** Hatalar `main`'e girmeden önce yakalanır.
- **Otomasyon:** CI/CD (5. ay) testleri PR açılınca çalıştırır. Testler geçmezse merge engellenebilir.
- **Kayıt:** Her değişikliğin neden yapıldığı PR açıklamasında ve yorumlarda durur.

> Bu kavramı 23 Ekim'de bitirme projesinde yaşadım: dal açıldı, push'landı, Arda'yla konuşulup `main`'e alındı, dal silindi.

## Akış
```
main ───●───●──────────────●   (merge sonrası)
             \            /
gun-005       ●───●───●──      (özellik dalı)
```
```bash
git switch -c gun-005                 # 1. dal aç
git add . && git commit -m "..."      # 2. çalış, commit'le
git push -u origin gun-005            # 3. dalı GitHub'a gönder
# 4. GitHub'da "Compare & pull request" → açıklama yaz → Create pull request
#    (ya da terminalden: gh pr create --fill)
# 5. İnceleme, yorumlar, gerekirse yeni commit'ler (PR otomatik güncellenir)
# 6. GitHub'da "Merge pull request"
git switch main && git pull           # 7. yerel main'i güncelle
git branch -d gun-005                 # 8. dalı sil (yerel)
git push origin --delete gun-005      #    dalı sil (GitHub)
```

## Merge türleri
| Tür | Ne olur | Ne zaman |
|---|---|---|
| **Fast-forward** | `main` başka bir yere ilerlemediyse, işaretçisi doğrudan dalın son commit'ine kayar. Ekstra commit oluşmaz, geçmiş düz kalır | Dal açıldıktan sonra `main`'e kimse bir şey eklemediyse. `git merge --ff-only` |
| **Merge commit** | İki dalı birleştiren yeni bir commit oluşur ("Merge pull request #3") | GitHub'daki varsayılan. Dalın varlığı geçmişte görünür |
| **Squash and merge** | Daldaki bütün commit'ler tek commit'e sıkıştırılır | Daldaki "düzelttim, tekrar düzelttim" commit'leri `main`'i kirletmesin istenirse |
| **Rebase and merge** | Dalın commit'leri `main`'in ucuna tek tek yeniden yazılır, düz bir geçmiş oluşur | Düz geçmiş isteyen ekipler. 2. ayda rebase ayrıca anlatılacak |

## İyi bir PR
- **Küçük ve tek konulu olsun.** 50 satırlık bir PR incelenir, 2.000 satırlık bir PR "onaylandı" deyip geçilir.
- **Başlık ne yapıldığını söylesin:** `feat(gun-005): dataclass eklendi`.
- **Açıklamada üç şey olsun:** ne değişti, neden değişti, nasıl test edildi.
- **Bilerek silinen ya da riskli şeyler** açıklamada ayrıca belirtilsin.

## Merge conflict (çakışma)
İki dal aynı dosyanın aynı satırını farklı şekilde değiştirirse Git hangisinin doğru olduğunu bilemez ve durur. Dosyada şöyle işaretler çıkar:
```
<<<<<<< HEAD
port = 80
=======
port = 8080
>>>>>>> gun-005
```
Doğru hali elle yazılır, işaretler silinir, sonra `git add` ve `git commit` yapılır. Ayrıntısı 2. ayda.

## Ne zaman PR'sız?
Tek başına çalıştığın bir repoda (bu repo gibi) doğrudan `main`'e merge etmek normaldir. Ekipte ise `main` genelde **korumalıdır** (branch protection): PR ve onay olmadan push kabul edilmez.
