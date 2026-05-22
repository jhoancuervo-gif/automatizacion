"""Respaldo centralizado de MACs: mac.txt local + backups_macs por familia."""
import csv
import re
from datetime import datetime
from pathlib import Path

MAC_PATTERN = re.compile(r"^([0-9A-F]{2}:){5}[0-9A-F]{2}$")


def normalize_mac(mac: str) -> str | None:
    if not mac:
        return None
    m = mac.strip().upper().replace("-", ":")
    return m if MAC_PATTERN.match(m) else None


class MacBackup:
    def __init__(
        self,
        script_dir: str | Path,
        familia: str,
        mac_file: str | Path | None = None,
        mac_filename: str = "mac.txt",
    ):
        self.script_dir = Path(script_dir).resolve()
        self.root_dir = self.script_dir.parent
        self.familia = familia.strip()
        if mac_file is not None:
            self.mac_file = Path(mac_file).resolve()
        else:
            self.mac_file = self.script_dir / mac_filename
        self.backup_dir = self.root_dir / "backups_macs"
        self.historial_dir = self.backup_dir / "historial"
        self.sesiones_dir = self.backup_dir / "sesiones"
        self.session: list[dict] = []
        self.started_at = datetime.now()

        for d in (self.backup_dir, self.historial_dir, self.sesiones_dir):
            d.mkdir(parents=True, exist_ok=True)

        if not self.mac_file.exists():
            self.mac_file.touch()

        master = self.backup_dir / "produccion_master.csv"
        if not master.exists():
            with master.open("w", newline="", encoding="utf-8") as f:
                csv.writer(f).writerow(
                    ["Fecha", "Hora", "Familia", "MAC", "Resultado", "Script"]
                )

    def save(self, mac: str, resultado: str = "OK") -> bool:
        mac_norm = normalize_mac(mac)
        if not mac_norm:
            return False

        now = datetime.now()
        fecha = now.strftime("%Y-%m-%d")
        hora = now.strftime("%H:%M:%S")

        with self.mac_file.open("a", encoding="utf-8") as f:
            f.write(f"{mac_norm}\n")

        historial = self.historial_dir / f"{self.familia}_{fecha}.txt"
        with historial.open("a", encoding="utf-8") as f:
            f.write(f"{hora} | {self.familia} | {mac_norm} | {resultado}\n")

        master = self.backup_dir / "produccion_master.csv"
        try:
            with master.open("a", newline="", encoding="utf-8") as f:
                csv.writer(f).writerow(
                    [fecha, hora, self.familia, mac_norm, resultado, self.script_dir.name]
                )
        except OSError as e:
            print(f"⚠️ Error al escribir en produccion_master.csv: {e}")

        self.session.append(
            {
                "Fecha": fecha,
                "Hora": hora,
                "Familia": self.familia,
                "MAC": mac_norm,
                "Resultado": resultado,
            }
        )
        return True

    def export_session(self) -> Path | None:
        if not self.session:
            print(" [BACKUP] Sin MACs en esta sesión; no se exporta archivo de sesión.")
            return None

        now = datetime.now()
        fecha = now.strftime("%Y-%m-%d")
        hora_tag = now.strftime("%H%M%S")
        export_file = self.sesiones_dir / f"{self.familia}_{fecha}_{hora_tag}.csv"

        with export_file.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f, fieldnames=["Fecha", "Hora", "Familia", "MAC", "Resultado"]
            )
            writer.writeheader()
            writer.writerows(self.session)

        resumen = self.backup_dir / "resumen_por_familia.csv"
        write_header = not resumen.exists()
        with resumen.open("a", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            if write_header:
                w.writerow(["Fecha", "Hora", "Familia", "Cantidad", "Archivo_Sesion"])
            w.writerow(
                [
                    fecha,
                    now.strftime("%H:%M:%S"),
                    self.familia,
                    len(self.session),
                    export_file.name,
                ]
            )

        print(
            f"\n [BACKUP] Sesión exportada: {export_file} ({len(self.session)} MACs)"
        )
        return export_file
