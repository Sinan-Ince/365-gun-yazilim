# Gün 001: Değişken ve veri tipi
# Çalıştırmak için: python 01_degisken_ve_veri_tipi.py

yas = 21              # int: tam sayı
boy = 1.78            # float: ondalıklı sayı
isim = "Kiroschi"     # str: metin
ogrenci = True        # bool: True veya False

for deger in (yas, boy, isim, ogrenci):
    print(f"{deger!r:>12} -> {type(deger).__name__}")

# Tip, yapılabilecek işlemi belirler
print("5" * 3)        # 555 (metin tekrarı)
print(5 * 3)          # 15  (çarpma)

# Tip dönüşümü (casting)
print(int("42") + 1)  # 43
print(str(42) + "1")  # 421
