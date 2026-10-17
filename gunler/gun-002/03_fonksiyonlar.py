# Gün 002: Fonksiyonlar
# Çalıştırmak için: python 03_fonksiyonlar.py

def topla(a, b):
    """İki sayıyı toplar."""        # docstring: fonksiyonun açıklaması
    return a + b

def selam(isim="dünya"):           # varsayılan değer
    return f"Merhaba {isim}!"

def istatistik(sayilar):
    """Birden fazla değer döndürür (aslında bir tuple)."""
    return min(sayilar), max(sayilar), sum(sayilar) / len(sayilar)

print(topla(3, 4))
print(selam())
print(selam("Sinan"))

en_kucuk, en_buyuk, ortalama = istatistik([4, 8, 15, 16, 23, 42])
print(en_kucuk, en_buyuk, round(ortalama, 2))

# İsimli argüman: sıraya bağlı kalmadan çağırma
print(selam(isim="Kiroschi"))

# Scope: fonksiyon içindeki değişken dışarıda yoktur
def sayac():
    adet = 10
    return adet

print(sayac())
# print(adet)  # NameError verir, çünkü adet sadece fonksiyonun içinde var

# Fonksiyonlar da birer değerdir: başka fonksiyona verilebilir
def uygula(islem, x, y):
    return islem(x, y)

print(uygula(topla, 10, 20))
