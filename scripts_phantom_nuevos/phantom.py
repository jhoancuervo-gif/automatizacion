# ==============================================================================
# MASS ROUTER FLASHER V2.9 - ESTABLE + RAPIDO + REGISTRO COMPLETO
# Detecta routers por 192.168.1.1, fija ARP de forma robusta y guarda
# todas las MACs con detalle de estado.
# ==============================================================================

import asyncio
import asyncssh
import csv
import ctypes
import logging
import os
import re
import subprocess
import sys
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Optional


class Config:
    INTERFACE_NAME = "AUTO"  # "AUTO" intenta descubrir la interfaz correcta
    MAC_PREFIX = "04-8F-00"
    ROUTER_IP = "192.168.1.1"
    SSH_USERNAME = "root"
    SSH_PASSWORD = ""

    FIRMWARE_PATH = "Firmware_PHANTOM.bin"
    FIRMWARE_VERSION = "24.10.3-PHANTOM"
    REMOTE_PATH = "/tmp/"

    MAC_TXT_FILE = "macs.txt"
    MAC_CSV_FILE = "flash_log.csv"
    FAILED_MACS_FILE = "failed_macs.txt"

    SCAN_INTERVAL = 0.35
    SCAN_TIMEOUT_MS = 220
    PING_BURST = 2
    IDLE_TIMEOUT = 20
    BATCH_PAUSE = 0.25
    FAILURE_COOLDOWN = 8

    SSH_CONNECT_TIMEOUT = 8
    SCP_TIMEOUT = 20
    COMMAND_TIMEOUT = 4
    MAX_RETRIES_PER_ROUTER = 2
    REQUIRE_ADMIN = True
    AUTO_ELEVATE = True


class RouterState(Enum):
    WAITING = "Esperando router"
    SCANNING = "Escaneando objetivo"
    CONNECTING = "Conectando"
    UPLOADING = "Subiendo firmware"
    FLASHING = "Flasheando"
    COMPLETED = "Completado"
    FAILED = "Fallido"


@dataclass
class SessionMetrics:
    total_processed: int = 0
    successful: int = 0
    failed: int = 0
    current_mac: Optional[str] = None
    state: RouterState = RouterState.WAITING
    start_time: datetime = None
    processing_times: deque = field(default_factory=lambda: deque(maxlen=50))

    def __post_init__(self):
        self.start_time = datetime.now()

    def avg_time(self) -> float:
        if not self.processing_times:
            return 0.0
        return sum(self.processing_times) / len(self.processing_times)


@dataclass
class MacRecord:
    mac: str
    first_seen: str
    last_seen: str
    last_status: str
    success_count: int = 0
    fail_count: int = 0
    firmware_from: str = "UNKNOWN"
    firmware_to: str = Config.FIRMWARE_VERSION
    last_error: str = ""


def setup_logger():
    logger = logging.getLogger("FlasherV2.9")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s", "%H:%M:%S"))
    logger.addHandler(handler)
    logging.addLevelName(25, "SUCCESS")
    setattr(logger, "success", lambda msg, *args: logger.log(25, msg, *args))
    return logger


logger = setup_logger()
MAC_REGEX = re.compile(r"([0-9A-Fa-f]{2}(?:[:-][0-9A-Fa-f]{2}){5})")
FW_REGEX = re.compile(r"DISTRIB_RELEASE=['\"]?([^'\"\n]+)")


def normalize_mac(raw_mac: Optional[str]) -> Optional[str]:
    if not raw_mac:
        return None
    match = MAC_REGEX.search(raw_mac)
    if not match:
        return None
    return match.group(1).replace("-", ":").upper()


def mac_for_netsh(mac: str) -> str:
    return mac.replace(":", "-").upper()


def now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def is_windows_admin() -> bool:
    if os.name != "nt":
        return True
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def get_python_candidates_for_elevation() -> list[str]:
    candidates = []

    if sys.executable:
        candidates.append(sys.executable)

    base_dir = os.path.dirname(sys.executable or "")
    if base_dir:
        for name in ("python3.12.exe", "python.exe"):
            candidate = os.path.join(base_dir, name)
            if candidate not in candidates:
                candidates.append(candidate)

    windows_apps = os.path.expandvars(r"%LOCALAPPDATA%\Microsoft\WindowsApps")
    for name in ("python3.12.exe", "python.exe"):
        candidate = os.path.join(windows_apps, name)
        if candidate not in candidates:
            candidates.append(candidate)

    return [candidate for candidate in candidates if candidate and os.path.exists(candidate)]


def relaunch_as_admin() -> bool:
    script_path = os.path.abspath(__file__)
    args = [script_path, *sys.argv[1:]]
    cmdline = subprocess.list2cmdline(args)
    for python_executable in get_python_candidates_for_elevation():
        result = ctypes.windll.shell32.ShellExecuteW(
            None,
            "runas",
            python_executable,
            cmdline,
            None,
            1,
        )
        if result > 32:
            logger.info(f"Elevacion solicitada usando: {python_executable}")
            return True
    return False


def ensure_admin() -> bool:
    if not Config.REQUIRE_ADMIN or os.name != "nt":
        return True
    if is_windows_admin():
        return True

    logger.error("Este flasher necesita permisos de administrador para fijar ARP por MAC.")
    if Config.AUTO_ELEVATE:
        logger.info("Solicitando elevacion por UAC...")
        if relaunch_as_admin():
            logger.info("Se abrio una nueva ventana con permisos de administrador.")
            return False
        logger.error("No se pudo solicitar elevacion automaticamente. Abre PyCharm o PowerShell como administrador.")
    else:
        logger.error("Ejecuta Python o PyCharm como administrador y vuelve a intentarlo.")
    return False


def verify_firmware() -> bool:
    if not os.path.exists(Config.FIRMWARE_PATH):
        logger.error(f"Firmware no encontrado: {Config.FIRMWARE_PATH}")
        return False

    size = os.path.getsize(Config.FIRMWARE_PATH)
    if size < 1024 * 1024:
        logger.error(f"Firmware demasiado pequeno: {size} bytes")
        return False

    logger.info(f"Firmware OK ({size / 1024 / 1024:.1f} MB)")
    return True


def initialize_csv():
    if os.path.exists(Config.MAC_CSV_FILE):
        return
    with open(Config.MAC_CSV_FILE, "w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow([
            "timestamp",
            "candidate_mac",
            "router_mac",
            "interface",
            "firmware_from",
            "firmware_to",
            "status",
            "attempt",
            "duration_seconds",
            "error_message",
        ])


def load_mac_registry() -> dict[str, MacRecord]:
    registry: dict[str, MacRecord] = {}
    if not os.path.exists(Config.MAC_TXT_FILE):
        return registry

    with open(Config.MAC_TXT_FILE, "r", encoding="utf-8", errors="ignore") as file:
        for line in file:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            mac = normalize_mac(line)
            if not mac:
                continue

            status_match = re.search(r"status=([A-Z_]+)", line)
            ok_match = re.search(r"ok=(\d+)", line)
            fail_match = re.search(r"fail=(\d+)", line)
            first_match = re.search(r"first=([^|]+)", line)
            last_match = re.search(r"last=([^|]+)", line)
            fw_from_match = re.search(r"fw_from=([^|]+)", line)
            fw_to_match = re.search(r"fw_to=([^|]+)", line)
            err_match = re.search(r"error=(.+)$", line)

            registry[mac] = MacRecord(
                mac=mac,
                first_seen=(first_match.group(1).strip() if first_match else now_str()),
                last_seen=(last_match.group(1).strip() if last_match else now_str()),
                last_status=(status_match.group(1).strip() if status_match else "SUCCESS"),
                success_count=int(ok_match.group(1)) if ok_match else 1,
                fail_count=int(fail_match.group(1)) if fail_match else 0,
                firmware_from=(fw_from_match.group(1).strip() if fw_from_match else "UNKNOWN"),
                firmware_to=(fw_to_match.group(1).strip() if fw_to_match else Config.FIRMWARE_VERSION),
                last_error=(err_match.group(1).strip() if err_match else ""),
            )

    logger.info(f"Cargadas {len(registry)} MACs registradas previamente")
    return registry


def write_mac_registry(registry: dict[str, MacRecord]):
    with open(Config.MAC_TXT_FILE, "w", encoding="utf-8") as file:
        file.write("# Registro de MACs detectadas por el flasher\n")
        file.write("# Formato: MAC | status= | ok= | fail= | first= | last= | fw_from= | fw_to= | error=\n")
        for record in registry.values():
            error_text = record.last_error.replace("\n", " ").replace("|", "/").strip()
            file.write(
                f"{record.mac} | status={record.last_status} | ok={record.success_count} | "
                f"fail={record.fail_count} | first={record.first_seen} | last={record.last_seen} | "
                f"fw_from={record.firmware_from} | fw_to={record.firmware_to} | error={error_text}\n"
            )


def append_csv_attempt(candidate_mac: str, router_mac: str, interface_name: str,
                       firmware_from: str, status: str, attempt: int,
                       duration_seconds: float, error_message: str):
    with open(Config.MAC_CSV_FILE, "a", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow([
            now_str(),
            candidate_mac,
            router_mac,
            interface_name,
            firmware_from,
            Config.FIRMWARE_VERSION,
            status,
            attempt,
            f"{duration_seconds:.2f}",
            error_message,
        ])


def append_failed_mac(mac: str, error_message: str):
    with open(Config.FAILED_MACS_FILE, "a", encoding="utf-8") as file:
        file.write(f"{now_str()} | {mac} | {error_message}\n")


def update_registry(registry: dict[str, MacRecord], mac: str, status: str,
                    firmware_from: str = "UNKNOWN", error_message: str = ""):
    timestamp = now_str()
    record = registry.get(mac)
    if record is None:
        record = MacRecord(
            mac=mac,
            first_seen=timestamp,
            last_seen=timestamp,
            last_status=status,
            success_count=0,
            fail_count=0,
            firmware_from=firmware_from,
            firmware_to=Config.FIRMWARE_VERSION,
            last_error=error_message,
        )
        registry[mac] = record

    record.last_seen = timestamp
    record.last_status = status
    record.firmware_from = firmware_from or record.firmware_from
    record.firmware_to = Config.FIRMWARE_VERSION
    record.last_error = error_message.strip()
    if status == "SUCCESS":
        record.success_count += 1
    elif status == "FAILED":
        record.fail_count += 1

    write_mac_registry(registry)


async def run_command(*args: str, capture_output: bool = False, timeout: Optional[float] = None) -> tuple[int, str]:
    def _run():
        return subprocess.run(
            args,
            stdout=subprocess.PIPE if capture_output else subprocess.DEVNULL,
            stderr=subprocess.PIPE if capture_output else subprocess.DEVNULL,
            check=False,
            timeout=timeout,
        )

    process = await asyncio.to_thread(_run)
    if not capture_output:
        return process.returncode, ""

    output = (process.stdout or b"").decode("cp1252", errors="ignore")
    error_output = (process.stderr or b"").decode("cp1252", errors="ignore")
    combined = output if output else error_output
    return process.returncode, combined.strip()


async def clear_target_neighbor():
    try:
        await run_command("arp", "-d", Config.ROUTER_IP)
    except Exception:
        pass


async def ping_target() -> bool:
    returncode, _ = await run_command(
        "ping", "-n", "1", "-w", str(Config.SCAN_TIMEOUT_MS), Config.ROUTER_IP
    )
    return returncode == 0


def extract_target_macs(raw_text: str) -> list[str]:
    found = []
    for line in raw_text.splitlines():
        if Config.ROUTER_IP not in line:
            continue
        if Config.MAC_PREFIX.lower() not in line.lower():
            continue
        mac = normalize_mac(line)
        if mac and mac not in found:
            found.append(mac)
    return found


async def list_connected_interfaces() -> list[str]:
    returncode, output = await run_command("netsh", "interface", "show", "interface", capture_output=True)
    if returncode != 0:
        return []

    interfaces = []
    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("Estado") or line.startswith("-"):
            continue
        parts = re.split(r"\s{2,}", line)
        if len(parts) < 4:
            continue
        if parts[0].lower().startswith("habilitado") and parts[1].lower().startswith("conectado"):
            interfaces.append(parts[3])
    return interfaces


async def resolve_candidate_interfaces() -> list[str]:
    connected = await list_connected_interfaces()
    if not connected:
        return [Config.INTERFACE_NAME] if Config.INTERFACE_NAME != "AUTO" else []

    prioritized = []
    for interface_name in connected:
        _, output = await run_command(
            "netsh", "interface", "ipv4", "show", "neighbors", interface_name, capture_output=True
        )
        if Config.ROUTER_IP in output and Config.MAC_PREFIX.lower() in output.lower():
            prioritized.append(interface_name)

    if Config.INTERFACE_NAME != "AUTO" and Config.INTERFACE_NAME in connected and Config.INTERFACE_NAME not in prioritized:
        prioritized.insert(0, Config.INTERFACE_NAME)

    for interface_name in connected:
        if interface_name not in prioritized:
            prioritized.append(interface_name)

    return prioritized


async def scan_current_router() -> tuple[Optional[str], Optional[str]]:
    await clear_target_neighbor()

    for _ in range(Config.PING_BURST):
        await ping_target()
        await asyncio.sleep(0.05)

    candidate_interfaces = await resolve_candidate_interfaces()
    for interface_name in candidate_interfaces:
        _, output = await run_command(
            "netsh", "interface", "ipv4", "show", "neighbors", interface_name, capture_output=True
        )
        macs = extract_target_macs(output)
        if macs:
            return macs[0], interface_name

    _, arp_output = await run_command("arp", "-a", capture_output=True)
    macs = extract_target_macs(arp_output)
    if macs:
        return macs[0], None

    return None, None


async def read_neighbor_mac(interface_name: Optional[str] = None) -> Optional[str]:
    if interface_name:
        _, output = await run_command(
            "netsh", "interface", "ipv4", "show", "neighbors", interface_name, capture_output=True
        )
        macs = extract_target_macs(output)
        if macs:
            return macs[0]

    _, arp_output = await run_command("arp", "-a", capture_output=True)
    macs = extract_target_macs(arp_output)
    if macs:
        return macs[0]

    return None


async def bind_arp(mac: str) -> tuple[bool, str, str]:
    neighbor_mac = mac_for_netsh(mac)
    candidate_interfaces = await resolve_candidate_interfaces()
    if Config.INTERFACE_NAME != "AUTO" and Config.INTERFACE_NAME not in candidate_interfaces:
        candidate_interfaces.insert(0, Config.INTERFACE_NAME)

    last_error = ""
    for interface_name in candidate_interfaces:
        await run_command("netsh", "interface", "ipv4", "delete", "neighbors", interface_name, Config.ROUTER_IP)
        await asyncio.sleep(0.05)
        returncode, output = await run_command(
            "netsh", "interface", "ipv4", "add", "neighbors", interface_name, Config.ROUTER_IP, neighbor_mac,
            capture_output=True,
        )
        if returncode == 0:
            await asyncio.sleep(0.10)
            await run_command("ssh-keygen", "-R", Config.ROUTER_IP)
            return True, interface_name, ""
        last_error = output or f"netsh returncode={returncode}"

    return False, "", last_error


async def get_router_info() -> tuple[Optional[str], str]:
    remote_mac_cmd = (
        "uci -q get network.lan.macaddr || "
        "uci -q get network.@device[0].macaddr || "
        "cat /sys/class/net/br-lan/address 2>/dev/null || "
        "cat /sys/class/net/eth0/address 2>/dev/null"
    )
    remote_fw_cmd = "cat /etc/openwrt_release 2>/dev/null"

    async with asyncssh.connect(
        Config.ROUTER_IP,
        username=Config.SSH_USERNAME,
        password=Config.SSH_PASSWORD,
        known_hosts=None,
        connect_timeout=Config.SSH_CONNECT_TIMEOUT,
        server_host_key_algs=["ssh-rsa", "ssh-ed25519", "ecdsa-sha2-nistp256"],
    ) as conn:
        mac_result = await conn.run(remote_mac_cmd, check=False, timeout=Config.COMMAND_TIMEOUT)
        fw_result = await conn.run(remote_fw_cmd, check=False, timeout=Config.COMMAND_TIMEOUT)

    router_mac = normalize_mac(mac_result.stdout.strip())
    fw_match = FW_REGEX.search(fw_result.stdout or "")
    firmware_from = fw_match.group(1).strip() if fw_match else "UNKNOWN"
    return router_mac, firmware_from


async def flash_router() -> None:
    firmware_name = os.path.basename(Config.FIRMWARE_PATH)

    await asyncssh.scp(
        Config.FIRMWARE_PATH,
        (Config.ROUTER_IP, Config.REMOTE_PATH),
        username=Config.SSH_USERNAME,
        password=Config.SSH_PASSWORD,
        known_hosts=None,
        connect_timeout=Config.SSH_CONNECT_TIMEOUT,
    )

    remote_cmd = (
        f"(sleep 1; ifconfig br-lan 192.168.1.254; "
        f"sysupgrade -n {Config.REMOTE_PATH}{firmware_name}) >/dev/null 2>&1 &"
    )

    try:
        async with asyncssh.connect(
            Config.ROUTER_IP,
            username=Config.SSH_USERNAME,
            password=Config.SSH_PASSWORD,
            known_hosts=None,
            connect_timeout=Config.SSH_CONNECT_TIMEOUT,
            server_host_key_algs=["ssh-rsa", "ssh-ed25519", "ecdsa-sha2-nistp256"],
        ) as conn:
            await conn.run(remote_cmd, timeout=2, check=False)
    except (asyncssh.ConnectionLost, asyncssh.TimeoutError):
        pass


class StableFlasher:
    def __init__(self):
        self.metrics = SessionMetrics()
        self.registry = load_mac_registry()
        self.retry_after: dict[str, datetime] = {}
        initialize_csv()

    def _should_skip_mac(self, mac: str) -> bool:
        record = self.registry.get(mac)
        if record and record.success_count > 0:
            return True

        retry_after = self.retry_after.get(mac)
        if retry_after and retry_after > datetime.now():
            return True

        return False

    def _print_banner(self):
        print("\n" + "=" * 70)
        print("MASS FLASHER V2.9 - ESTABLE + RAPIDO + DETALLADO")
        print(f"Firmware: {Config.FIRMWARE_VERSION}")
        print(f"Objetivo: {Config.ROUTER_IP} | Interfaz: {Config.INTERFACE_NAME}")
        print("=" * 70 + "\n")

    def _print_dashboard(self):
        avg = self.metrics.avg_time()
        print("\n" + "=" * 70)
        print(
            f"Procesados: {self.metrics.total_processed} | "
            f"OK: {self.metrics.successful} | FAIL: {self.metrics.failed}"
        )
        print(f"Promedio: {avg:.1f}s | Estado: {self.metrics.state.value}")
        if self.metrics.current_mac:
            print(f"MAC actual: {self.metrics.current_mac}")
        print("=" * 70 + "\n")

    async def wait_for_next_mac(self) -> tuple[Optional[str], Optional[str]]:
        idle_started = datetime.now()
        last_logged_idle = -1

        while True:
            self.metrics.state = RouterState.SCANNING
            candidate_mac, detected_interface = await scan_current_router()

            if candidate_mac and not self._should_skip_mac(candidate_mac):
                return candidate_mac, detected_interface

            idle_seconds = int((datetime.now() - idle_started).total_seconds())
            if idle_seconds >= Config.IDLE_TIMEOUT:
                return None, None

            if idle_seconds >= 10 and idle_seconds % 10 == 0 and idle_seconds != last_logged_idle:
                last_logged_idle = idle_seconds
                logger.info(f"Buscando equipos... [{idle_seconds}s/{Config.IDLE_TIMEOUT}s]")

            await asyncio.sleep(Config.SCAN_INTERVAL)

    async def process_router(self, candidate_mac: str, detected_interface: Optional[str]) -> bool:
        self.metrics.current_mac = candidate_mac
        last_error = ""
        router_mac = candidate_mac
        firmware_from = "UNKNOWN"
        bound_interface = detected_interface or ""

        for attempt in range(1, Config.MAX_RETRIES_PER_ROUTER + 1):
            started = datetime.now()
            try:
                self.metrics.state = RouterState.CONNECTING
                logger.info(
                    f"Nuevo router detectado: {candidate_mac} "
                    f"(intento {attempt}/{Config.MAX_RETRIES_PER_ROUTER})"
                )

                arp_ok, interface_name, arp_error = await bind_arp(candidate_mac)
                if not arp_ok:
                    raise RuntimeError(f"No se pudo fijar ARP: {arp_error or 'sin detalle'}")

                bound_interface = interface_name
                logger.info(f"   ARP fijado en interfaz: {bound_interface}")

                router_mac, firmware_from = await get_router_info()
                router_mac = router_mac or candidate_mac
                logger.info(f"   MAC real: {router_mac}")
                logger.info(f"   Firmware actual: {firmware_from}")

                self.metrics.state = RouterState.UPLOADING
                logger.info(f"   Subiendo firmware {Config.FIRMWARE_VERSION}...")
                await flash_router()

                elapsed = (datetime.now() - started).total_seconds()
                self.metrics.processing_times.append(elapsed)
                self.metrics.total_processed += 1
                self.metrics.successful += 1
                self.metrics.state = RouterState.COMPLETED

                update_registry(self.registry, router_mac, "SUCCESS", firmware_from, "")
                append_csv_attempt(
                    candidate_mac, router_mac, bound_interface, firmware_from,
                    "SUCCESS", attempt, elapsed, ""
                )

                logger.success(f"   {router_mac} flasheado en {elapsed:.1f}s")
                return True

            except Exception as exc:
                elapsed = (datetime.now() - started).total_seconds()
                last_error = str(exc)
                self.metrics.processing_times.append(elapsed)
                logger.error(f"   Fallo intento {attempt}: {last_error}")
                append_csv_attempt(
                    candidate_mac, router_mac, bound_interface, firmware_from,
                    "FAILED", attempt, elapsed, last_error
                )

                if attempt < Config.MAX_RETRIES_PER_ROUTER:
                    await run_command("ssh-keygen", "-R", Config.ROUTER_IP)
                    await asyncio.sleep(0.6)

        self.metrics.total_processed += 1
        self.metrics.failed += 1
        self.metrics.state = RouterState.FAILED

        update_registry(self.registry, router_mac, "FAILED", firmware_from, last_error)
        append_failed_mac(router_mac, last_error)
        self.retry_after[router_mac] = datetime.now() + timedelta(seconds=Config.FAILURE_COOLDOWN)
        logger.error(f"   {router_mac} quedo como fallido. Reintento despues de {Config.FAILURE_COOLDOWN}s")
        return False

    async def run(self):
        if not verify_firmware():
            return

        self._print_banner()
        last_activity = datetime.now()

        while True:
            candidate_mac, detected_interface = await self.wait_for_next_mac()
            if not candidate_mac:
                idle = int((datetime.now() - last_activity).total_seconds())
                logger.info(f"Inactividad de {idle}s. Finalizando.")
                break

            last_activity = datetime.now()
            logger.info(f"MAC candidata detectada: {candidate_mac}")
            await self.process_router(candidate_mac, detected_interface)

            if self.metrics.total_processed % 3 == 0:
                self._print_dashboard()

            await asyncio.sleep(Config.BATCH_PAUSE)

        total_time = (datetime.now() - self.metrics.start_time).total_seconds()
        print("\n" + "=" * 70)
        print("SESION FINALIZADA")
        print(f"Exitosos: {self.metrics.successful}")
        print(f"Fallidos: {self.metrics.failed}")
        print(f"Total procesados: {self.metrics.total_processed}")
        print(f"Promedio: {self.metrics.avg_time():.1f}s por router")
        print(f"Tiempo total: {total_time / 60:.1f} minutos")
        print(f"CSV: {Config.MAC_CSV_FILE}")
        print(f"MACs: {Config.MAC_TXT_FILE}")
        print("=" * 70)


async def main():
    if not ensure_admin():
        return
    flasher = StableFlasher()
    await flasher.run()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Detenido por usuario")
