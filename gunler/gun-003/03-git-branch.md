# Git Branch

**Tanım:** Branch (dal), projenin ana çizgisini bozmadan ayrı bir çizgide çalışmanı sağlar. Aslında bir commit'i gösteren hafif bir etikettir.

**Neden önemli:** Sektörde kimse doğrudan `main`'e kod yazmaz. Her özellik ya da düzeltme için branch açılır, iş bitince Pull Request (PR) ile `main`'e birleştirilir (merge). Böylece `main` her zaman çalışır durumda kalır.

## Temel komutlar
```bash
git branch                      # dalları listele (* şu an bulunduğun)
git switch -c gun-003           # yeni dal aç ve ona geç
git switch main                 # main'e dön
git merge gun-003               # gun-003'teki commit'leri bulunduğun dala al
git branch -d gun-003           # birleşmiş dalı sil
git push -u origin gun-003      # dalı GitHub'a gönder (-u: takip et)
git log --oneline --graph --all # dalları grafik olarak gör
```
> `git checkout -b` eski yazımdır, aynı işi yapar. Yeni komut `git switch`.

## Görsel
```
main:     A---B-----------M      (M = merge commit)
               \         /
gun-003:        C---D---E
```

## İsimlendirme
| Önek | Örnek |
|---|---|
| `feature/` | `feature/login-sayfasi` |
| `fix/` | `fix/port-hatasi` |
| `docs/` | `docs/readme-guncelleme` |

## Merge türleri
- **Fast-forward:** `main`'de yeni commit yoksa Git sadece etiketi ileri kaydırır, merge commit oluşmaz.
- **3-way merge:** İki dalda da yeni commit varsa Git bir merge commit oluşturur.
- **Conflict:** Aynı satır iki dalda farklı değiştiyse Git sana sorar. Dosyada `<<<<<<<`, `=======`, `>>>>>>>` işaretlerini görürsün, doğru hâli seçip kaydeder, `git add` ve `git commit` yaparsın.
