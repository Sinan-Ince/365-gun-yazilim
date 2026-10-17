# Gün 002: Koşullar
# Çalıştırmak için: python 01_kosullar.py

def harf_notu(puan):
    if puan >= 85:
        return "AA"
    elif puan >= 70:
        return "BB"
    elif puan >= 50:
        return "CC"
    else:
        return "FF"

for puan in (92, 74, 50, 31):
    print(puan, "->", harf_notu(puan))

# Mantık operatörleri
yas, ogrenci = 21, True
if yas >= 18 and ogrenci:
    print("Öğrenci indirimi uygulanır")

# Truthy / falsy
sunucular = []
if not sunucular:
    print("Liste boş, hiç sunucu yok")

# Tek satırda koşul (ternary)
durum = "geçti" if harf_notu(74) != "FF" else "kaldı"
print("Durum:", durum)
