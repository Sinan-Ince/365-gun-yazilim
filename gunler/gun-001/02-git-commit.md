# Git Commit

**Tanım:** Commit, projenin belirli bir andaki fotoğrafıdır. Neyin, kim tarafından ve neden değiştiğini kaydeder.

**Neden önemli:** Hata yapınca eski bir hâle geri dönebilirsin. Ekipte kimin neyi değiştirdiği görünür. İyi commit mesajı sektörde dikkat edilen bir şeydir.

## Temel akış
```bash
git status                     # ne değişti?
git add dosya.py               # değişikliği sahneye al (staging)
git commit -m "feat: ..."      # fotoğrafı çek
git push                       # GitHub'a gönder
git log --oneline              # geçmişi gör
```

## Üç alan
```
Çalışma dizini  --git add-->  Staging  --git commit-->  Yerel repo  --git push-->  GitHub
```

## Mesaj yazımı (Conventional Commits)
| Önek | Ne zaman |
|---|---|
| `feat:` | Yeni içerik veya özellik |
| `fix:` | Hata düzeltme |
| `docs:` | Sadece doküman |
| `refactor:` | Davranışı değiştirmeden yeniden düzenleme |
| `chore:` | Ayar ve bakım işleri |

- ✅ `feat(gun-001): değişken ve veri tipi örneği eklendi`
- ✅ `docs: README ilerleme tablosu güncellendi`
- ❌ `update`, `asdasd`, `son hali`
