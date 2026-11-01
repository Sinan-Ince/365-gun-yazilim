#!/usr/bin/env python3
"""Gün 013: Firewall ve AWS security group mantığı.

Security group (stateful, sadece allow) ve NACL (stateless, allow+deny, ilk eşleşen kazanır)
kurallarını modeller; örnek paketlerin geçip geçmediğini ve nedenini gösterir.
Sonra bu makinede dinleyen portları `ss` ile okuyup dışarıya açık olanları listeler.
Hiçbir firewall kuralını değiştirmez, sudo istemez.

Çalıştırmak için:
    python3 02_firewall_ve_security_group.py
    python3 02_firewall_ve_security_group.py dene 88.1.2.3 22   -> tek paketi sına
"""
from __future__ import annotations

import ipaddress
import shutil
import subprocess
import sys
from dataclasses import dataclass

# Herkese açılınca tehlikeli olan portlar
RISKLI_PORTLAR = {22: "SSH", 3306: "MySQL", 5432: "PostgreSQL", 6379: "Redis", 27017: "MongoDB"}


@dataclass(frozen=True)
class Kural:
    """Gelen (ingress) kuralı. kaynak bir CIDR ya da başka bir SG adı olabilir."""
    port_bas: int
    port_son: int
    kaynak: str
    aciklama: str = ""

    def port_uyar_mi(self, port: int) -> bool:
        return self.port_bas <= port <= self.port_son

    def kaynak_uyar_mi(self, ip: str, kaynak_sg: str | None) -> bool:
        if self.kaynak.startswith("sg-"):
            # SG referansı: IP'ye değil, paketi gönderen makinenin SG'sine bakılır
            return kaynak_sg == self.kaynak
        return ipaddress.ip_address(ip) in ipaddress.ip_network(self.kaynak)


@dataclass
class SecurityGroup:
    ad: str
    kurallar: list[Kural]

    def degerlendir(self, ip: str, port: int, kaynak_sg: str | None = None) -> tuple[bool, str]:
        # SG'de sıra yok: herhangi bir kural izin verirse geçer. Deny kuralı yoktur.
        for k in self.kurallar:
            if k.port_uyar_mi(port) and k.kaynak_uyar_mi(ip, kaynak_sg):
                return True, f"izin: {k.kaynak} -> {k.port_bas}-{k.port_son} ({k.aciklama})"
        return False, "hiçbir allow kuralına uymadı -> varsayılan drop (istemci zaman aşımı görür)"

    def riskli_kurallar(self) -> list[str]:
        uyarilar = []
        for k in self.kurallar:
            if k.kaynak in ("0.0.0.0/0", "::/0"):
                for port, ad in RISKLI_PORTLAR.items():
                    if k.port_uyar_mi(port):
                        uyarilar.append(f"{self.ad}: {ad} ({port}) tüm internete açık!")
        return uyarilar


@dataclass(frozen=True)
class NaclKural:
    numara: int
    izin: bool
    port_bas: int
    port_son: int
    cidr: str


def nacl_degerlendir(kurallar: list[NaclKural], ip: str, port: int) -> tuple[bool, str]:
    # NACL: numaraya göre sırala, İLK eşleşen karar verir (sonrakilere bakılmaz)
    for k in sorted(kurallar, key=lambda k: k.numara):
        if k.port_bas <= port <= k.port_son and ipaddress.ip_address(ip) in ipaddress.ip_network(k.cidr):
            return k.izin, f"kural #{k.numara} {'ALLOW' if k.izin else 'DENY'} {k.cidr}"
    return False, "kural * (varsayılan) DENY"


# Tipik 3 katmanlı mimari (md dosyasındaki tablo)
BENIM_IP = "88.1.2.3"
SG_ALB = SecurityGroup("sg-alb", [
    Kural(443, 443, "0.0.0.0/0", "HTTPS herkese"),
    Kural(80, 80, "0.0.0.0/0", "HTTP herkese, 443'e yönlendirilir"),
])
SG_WEB = SecurityGroup("sg-web", [
    Kural(8080, 8080, "sg-alb", "sadece yük dengeleyiciden"),
    Kural(22, 22, f"{BENIM_IP}/32", "SSH sadece benim IP'mden"),
])
SG_DB = SecurityGroup("sg-db", [
    Kural(5432, 5432, "sg-web", "sadece web sunucularından"),
])
SG_HATALI = SecurityGroup("sg-hatali", [
    Kural(0, 65535, "0.0.0.0/0", "tembel kural: her şey açık"),
])

NACL = [
    NaclKural(90, False, 0, 65535, "45.9.20.0/24"),   # bilinen kötü ağ: önce engelle
    NaclKural(100, True, 443, 443, "0.0.0.0/0"),
    NaclKural(110, True, 22, 22, f"{BENIM_IP}/32"),
    NaclKural(120, True, 1024, 65535, "0.0.0.0/0"),   # stateless: dönüş trafiği (geçici portlar)
]


def tablo(sg: SecurityGroup, ornekler: list[tuple[str, int, str | None, str]]) -> None:
    print(f"\n== {sg.ad} ==")
    for ip, port, kaynak_sg, kim in ornekler:
        gecti, neden = sg.degerlendir(ip, port, kaynak_sg)
        print(f"  {'✓' if gecti else '✗'} {kim:<28} {ip:>15}:{port:<5} {neden}")


def dinleyen_portlar() -> None:
    print("\n== Bu makine: dışarıya açık dinleyen TCP portları (ss -Htln) ==")
    if shutil.which("ss") is None:
        print("  ss yok (iproute2)")
        return
    cikti = subprocess.run(["ss", "-Htln"], capture_output=True, text=True, check=True).stdout
    acik = []
    for satir in cikti.splitlines():
        yerel = satir.split()[3]                 # 4. sütun: Local Address:Port
        adres, _, port = yerel.rpartition(":")
        adres = adres.strip("[]").split("%")[0]  # [::1] ve fe80::1%wlo1 biçimleri
        if ipaddress.ip_address(adres).is_loopback:
            continue                             # 127.0.0.1 / ::1: dışarıdan zaten erişilemez
        acik.append((int(port), adres))
    if not acik:
        print("  yok: hiçbir servis dış arayüzde dinlemiyor (firewall'dan önce en iyi koruma)")
    for port, adres in sorted(set(acik)):
        not_ = f"  <- {RISKLI_PORTLAR[port]}: firewall ile kaynağı daralt" if port in RISKLI_PORTLAR else ""
        print(f"  {adres:>15}:{port}{not_}")


def main() -> None:
    if len(sys.argv) == 4 and sys.argv[1] == "dene":
        ip, port = sys.argv[2], int(sys.argv[3])
        ipaddress.ip_address(ip)  # geçersizse ValueError ile durur
        for sg in (SG_ALB, SG_WEB, SG_DB):
            print(f"{sg.ad:<8} {sg.degerlendir(ip, port)[1]}")
        print(f"{'NACL':<8} {nacl_degerlendir(NACL, ip, port)[1]}")
        return

    tablo(SG_ALB, [("203.0.113.50", 443, None, "rastgele kullanıcı, HTTPS"),
                   ("203.0.113.50", 22, None, "rastgele kullanıcı, SSH")])
    tablo(SG_WEB, [("10.0.1.15", 8080, "sg-alb", "ALB'den uygulamaya"),
                   ("203.0.113.50", 8080, None, "internetten direkt uygulamaya"),
                   (BENIM_IP, 22, None, "ben, SSH"),
                   ("88.1.2.4", 22, None, "komşu IP, SSH")])
    tablo(SG_DB, [("10.0.1.20", 5432, "sg-web", "web sunucusundan veritabanına"),
                  ("10.0.1.99", 5432, None, "aynı VPC'de başka makine")])

    print("\n== NACL (stateless, ilk eşleşen kazanır) ==")
    for ip, port, kim in [("45.9.20.7", 443, "kötü ağ, HTTPS"),
                          ("203.0.113.50", 443, "normal kullanıcı, HTTPS"),
                          ("203.0.113.50", 80, "normal kullanıcı, HTTP"),
                          ("140.82.121.4", 51234, "GitHub'dan dönen cevap")]:
        gecti, neden = nacl_degerlendir(NACL, ip, port)
        print(f"  {'✓' if gecti else '✗'} {kim:<28} {ip:>15}:{port:<5} {neden}")
    print("  (#90 deny, #100 allow'dan önce geldiği için kötü ağ 443'e de giremez)")

    print("\n== Güvenlik denetimi ==")
    uyarilar = [u for sg in (SG_ALB, SG_WEB, SG_DB, SG_HATALI) for u in sg.riskli_kurallar()]
    for u in uyarilar or ["riskli kural yok"]:
        print(f"  ⚠ {u}")

    dinleyen_portlar()


if __name__ == "__main__":
    main()
