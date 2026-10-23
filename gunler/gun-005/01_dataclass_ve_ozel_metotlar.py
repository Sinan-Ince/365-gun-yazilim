# Gün 005: Dataclass ve özel metotlar (dunder)
# Çalıştırmak için: python 01_dataclass_ve_ozel_metotlar.py
from dataclasses import dataclass, field

# --- 1) Elle yazılmış sınıf: özel metotlar ---
class SunucuEski:
    def __init__(self, ad, port=80):
        self.ad = ad
        self.port = port

    def __repr__(self):                     # geliştirici için: konsol, log
        return f"SunucuEski(ad={self.ad!r}, port={self.port})"

    def __str__(self):                      # kullanıcı için: print
        return f"{self.ad}:{self.port}"

    def __eq__(self, diger):                # a == b
        return (self.ad, self.port) == (diger.ad, diger.port)

a, b = SunucuEski("web1"), SunucuEski("web1")
print(repr(a), "|", a)                      # SunucuEski(ad='web1', port=80) | web1:80
print("a == b:", a == b, "| a is b:", a is b)   # True | False: içerik aynı, nesne farklı

# --- 2) Aynı sınıf, dataclass ile ---
@dataclass
class Sunucu:
    ad: str
    port: int = 80
    etiketler: list = field(default_factory=list)   # = [] yazma! Liste tüm nesnelerde paylaşılır

    def adres(self):                        # normal metotlar da eklenebilir
        return f"{self.ad}:{self.port}"

web1 = Sunucu("web1", etiketler=["prod"])
print(web1)                                 # Sunucu(ad='web1', port=80, etiketler=['prod'])
print(web1 == Sunucu("web1", etiketler=["prod"]))   # True: __eq__ hazır geldi
web1.port = 8080                            # normal dataclass değiştirilebilir
print(web1.adres())

# --- 3) frozen + order: değiştirilemez ve sıralanabilir ---
@dataclass(frozen=True, order=True)
class Surum:
    ana: int
    ara: int
    yama: int

    def __str__(self):
        return f"v{self.ana}.{self.ara}.{self.yama}"

surumler = [Surum(1, 10, 0), Surum(1, 2, 3), Surum(2, 0, 0)]
print("Sıralı:", [str(s) for s in sorted(surumler)])   # alanlar sırasıyla karşılaştırılır
print("En yeni:", max(surumler))

try:
    surumler[0].ana = 9                     # frozen olduğu için hata verir
except Exception as e:
    print("Değiştirilemez:", type(e).__name__)

# frozen nesne sözlükte anahtar olabilir (hash'lenebilir)
yayin_notu = {Surum(2, 0, 0): "Python 3.14 desteği"}
print(yayin_notu[Surum(2, 0, 0)])

# --- 4) Kompozisyon + dataclass: bir Kume, Sunucu nesnelerine SAHİPTİR ---
@dataclass
class Kume:
    ad: str
    sunucular: list[Sunucu] = field(default_factory=list)

    def __len__(self):                      # len(kume)
        return len(self.sunucular)

kume = Kume("eu-central", [Sunucu("web1"), Sunucu("web2", 8080)])
print(f"{kume.ad} kümesinde {len(kume)} sunucu:", [s.adres() for s in kume.sunucular])
