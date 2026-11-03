#!/usr/bin/env python3
"""Gün 014: HTTP derinlemesine (metotlar, durum kodları, başlıklar, REST).

Standart kütüphaneyle 127.0.0.1 üzerinde küçük bir REST API (görev listesi) açar,
sonra ona farklı metotlarla istek atıp durum kodunu ve önemli başlıkları gösterir.
İnternete çıkmaz, dışarıya port açmaz (sadece localhost'ta dinler).

Çalıştırmak için:
    python3 01_http_derinlemesine.py              -> sunucuyu aç, örnek istekleri at, kapat
    python3 01_http_derinlemesine.py sunucu 8000  -> sadece sunucu, curl ile sen dene (Ctrl+C)
"""
from __future__ import annotations

import json
import sys
import threading
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# Bellekteki "veritabanı": id -> görev
GOREVLER: dict[int, dict] = {1: {"id": 1, "baslik": "nginx kur", "acik": True}}
SONRAKI_ID = 2
KILIT = threading.Lock()  # ThreadingHTTPServer: istekler aynı anda gelebilir


class GorevAPI(BaseHTTPRequestHandler):
    """Her HTTP metodu bir do_<METOT> fonksiyonuna düşer."""

    server_version = "Gun014API/1.0"  # cevaptaki Server başlığı

    # ---- yardımcılar -------------------------------------------------
    def _cevap(self, kod: int, govde: object | None = None, basliklar: dict | None = None) -> None:
        veri = b"" if govde is None else json.dumps(govde, ensure_ascii=False).encode()
        self.send_response(kod)  # durum satırı: HTTP/1.1 <kod> <açıklama>
        if govde is not None:
            self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(veri)))
        for ad, deger in (basliklar or {}).items():
            self.send_header(ad, deger)
        self.end_headers()  # boş satır: başlıklar bitti, gövde başlıyor
        self.wfile.write(veri)

    def _govde_oku(self) -> dict | None:
        uzunluk = int(self.headers.get("Content-Length", 0))
        if "application/json" not in self.headers.get("Content-Type", ""):
            return None
        try:
            veri = json.loads(self.rfile.read(uzunluk) or b"{}")
        except json.JSONDecodeError:
            return None
        return veri if isinstance(veri, dict) else None

    def _id_al(self) -> int | None:
        # /gorevler/3 -> 3, /gorevler -> None
        parcalar = self.path.split("?")[0].strip("/").split("/")
        if len(parcalar) == 2 and parcalar[0] == "gorevler" and parcalar[1].isdigit():
            return int(parcalar[1])
        return None

    def _koleksiyon_mu(self) -> bool:
        return self.path.split("?")[0].rstrip("/") == "/gorevler"

    def log_message(self, *args) -> None:  # varsayılan erişim logunu sustur
        pass

    # ---- metotlar ----------------------------------------------------
    def do_GET(self) -> None:
        if self.path == "/saglik":  # ALB health check / k8s probe buraya bakar
            return self._cevap(200, {"durum": "ok"})
        if self._koleksiyon_mu():
            with KILIT:
                return self._cevap(200, list(GOREVLER.values()))
        gid = self._id_al()
        with KILIT:
            if gid is not None and gid in GOREVLER:
                return self._cevap(200, GOREVLER[gid])
        self._cevap(404, {"hata": "bulunamadı"})

    def do_POST(self) -> None:
        global SONRAKI_ID
        if not self._koleksiyon_mu():
            return self._cevap(405, {"hata": "POST sadece /gorevler"}, {"Allow": "GET, PUT, PATCH, DELETE"})
        veri = self._govde_oku()
        if not veri or not isinstance(veri.get("baslik"), str):
            return self._cevap(400, {"hata": "JSON gövdede 'baslik' gerekli"})
        with KILIT:
            gorev = {"id": SONRAKI_ID, "baslik": veri["baslik"], "acik": True}
            GOREVLER[SONRAKI_ID] = gorev
            SONRAKI_ID += 1
        # 201 Created + Location: yeni kaynağın adresi
        self._cevap(201, gorev, {"Location": f"/gorevler/{gorev['id']}"})

    def do_PUT(self) -> None:
        gid, veri = self._id_al(), self._govde_oku()
        if gid is None:
            return self._cevap(405, {"hata": "PUT tek kayda yapılır"}, {"Allow": "GET, POST"})
        if not veri or set(veri) != {"baslik", "acik"}:
            return self._cevap(400, {"hata": "PUT tüm alanları ister: baslik, acik"})
        with KILIT:
            if gid not in GOREVLER:
                return self._cevap(404, {"hata": "bulunamadı"})
            GOREVLER[gid] = {"id": gid, **veri}  # tamamen değiştir
            return self._cevap(200, GOREVLER[gid])

    def do_PATCH(self) -> None:
        gid, veri = self._id_al(), self._govde_oku()
        if gid is None or not veri:
            return self._cevap(400, {"hata": "PATCH /gorevler/<id> + JSON gövde"})
        with KILIT:
            if gid not in GOREVLER:
                return self._cevap(404, {"hata": "bulunamadı"})
            izinli = {k: v for k, v in veri.items() if k in ("baslik", "acik")}
            GOREVLER[gid].update(izinli)  # sadece gelen alanları değiştir
            return self._cevap(200, GOREVLER[gid])

    def do_DELETE(self) -> None:
        gid = self._id_al()
        with KILIT:
            if gid is None or gid not in GOREVLER:
                return self._cevap(404, {"hata": "bulunamadı"})
            del GOREVLER[gid]
        self._cevap(204)  # No Content: gövde yok


# ---- istemci tarafı --------------------------------------------------
def istek(taban: str, metot: str, yol: str, govde: dict | None = None) -> None:
    veri = None if govde is None else json.dumps(govde).encode()
    req = urllib.request.Request(taban + yol, data=veri, method=metot)
    req.add_header("Accept", "application/json")
    if veri is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=5) as cev:
            kod, basliklar, icerik = cev.status, cev.headers, cev.read()
    except urllib.error.HTTPError as hata:  # 4xx/5xx urllib'de istisna olarak gelir
        kod, basliklar, icerik = hata.code, hata.headers, hata.read()
    sinif = {2: "başarılı", 3: "yönlendirme", 4: "istemci hatası", 5: "sunucu hatası"}[kod // 100]
    print(f"\n{metot:<6} {yol}" + (f"  gövde={json.dumps(govde, ensure_ascii=False)}" if govde else ""))
    print(f"  -> {kod} ({sinif})")
    for ad in ("Content-Type", "Location", "Allow"):
        if basliklar.get(ad):
            print(f"     {ad}: {basliklar[ad]}")
    if icerik:
        print(f"     {icerik.decode()}")


def main() -> None:
    if len(sys.argv) >= 2 and sys.argv[1] == "sunucu":
        port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
        sunucu = ThreadingHTTPServer(("127.0.0.1", port), GorevAPI)
        print(f"http://127.0.0.1:{port}/gorevler dinleniyor (Ctrl+C ile kapat)")
        print(f"  dene: curl -i 127.0.0.1:{port}/gorevler")
        try:
            sunucu.serve_forever()
        except KeyboardInterrupt:
            print("\nkapatıldı")
        return

    # Port 0: işletim sistemi boş bir port seçer, çakışma olmaz
    sunucu = ThreadingHTTPServer(("127.0.0.1", 0), GorevAPI)
    taban = f"http://127.0.0.1:{sunucu.server_address[1]}"
    threading.Thread(target=sunucu.serve_forever, daemon=True).start()
    print(f"Sunucu: {taban}")

    istek(taban, "GET", "/saglik")                                  # 200: health check
    istek(taban, "GET", "/gorevler")                                # 200: liste
    istek(taban, "POST", "/gorevler", {"baslik": "TLS öğren"})      # 201 + Location
    istek(taban, "POST", "/gorevler", {"yanlis": 1})                # 400: bozuk istek
    istek(taban, "PATCH", "/gorevler/1", {"acik": False})           # 200: kısmi
    istek(taban, "PUT", "/gorevler/2", {"baslik": "HTTPS öğren"})   # 400: PUT tam ister
    istek(taban, "PUT", "/gorevler/2", {"baslik": "HTTPS öğren", "acik": True})  # 200
    istek(taban, "DELETE", "/gorevler/1")                           # 204: gövde yok
    istek(taban, "DELETE", "/gorevler/1")                           # 404: idempotent, durum aynı
    istek(taban, "POST", "/gorevler/2", {"baslik": "x"})            # 405 + Allow
    istek(taban, "GET", "/gorevler")                                # son durum

    sunucu.shutdown()


if __name__ == "__main__":
    main()
