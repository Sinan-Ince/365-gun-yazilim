# Gün 002: Döngüler
# Çalıştırmak için: python 02_donguler.py

# for: koleksiyon üzerinde
diller = ["Python", "Bash", "Go", "Java"]
for dil in diller:
    print("Öğrenilecek:", dil)

# for + range: belli sayıda tekrar
for i in range(1, 4):
    print(f"{i}. tur")

# enumerate: hem sıra numarası hem eleman
for sira, dil in enumerate(diller, start=1):
    print(sira, dil)

# while: koşul doğru olduğu sürece
deneme = 0
while deneme < 3:
    deneme += 1
    print(f"Bağlantı denemesi {deneme}")

# break ve continue
for sayi in range(10):
    if sayi % 2 == 0:
        continue          # çift sayıları atla
    if sayi > 7:
        break             # 7'den sonra dur
    print("Tek sayı:", sayi)
