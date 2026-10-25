# Gün 006: 01_moduller_ve_paketler.py tarafından import edilen yardımcı modül

VARSAYILAN_PORT = 80


def selamla(ad):
    return f"Merhaba {ad}"


def adres(sunucu, port=VARSAYILAN_PORT):
    return f"{sunucu}:{port}"


print(f"[araclar] yüklendi, __name__ = {__name__!r}")

# Sadece "python araclar.py" ile doğrudan çalıştırılınca çalışır, import edilince çalışmaz
if __name__ == "__main__":
    print("araclar.py doğrudan çalıştırıldı, deneme:")
    print(selamla("dünya"), "|", adres("web1"))
