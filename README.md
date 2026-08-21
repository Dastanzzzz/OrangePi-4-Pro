# Orange Pi Custom Modules For Debian Trixie Kernel  6.6.98-sun60iw2

A custom Debian package for **Orange Pi** that provides the required kernel modules and configuration to enable the following features:

* **TUN** — required by Tailscale
* **POSIX MQUEUE** — required for CIFS
* **OverlayFS** — required by Docker
* **UTF-8** — provides UTF-8 support through `nls_utf8`

## Installation

Install the package using:

```bash
sudo dpkg -i orangepi-custom-modules_1.0_arm64.deb
sudo depmod -a
sudo modprobe tun
sudo modprobe nls_utf8
```

## Verify Installation

After installation, verify that all required features are available:

```bash
echo "=== TUN ==="
test -c /dev/net/tun && echo "OK" || echo "NOT AVAILABLE"

echo "=== POSIX MQUEUE ==="
mountpoint -q /dev/mqueue && echo "OK" || echo "NOT ACTIVE"

echo "=== OVERLAYFS ==="
grep -qw overlay /proc/filesystems && echo "OK" || echo "NOT AVAILABLE"

echo "=== UTF-8 ==="
[ "$(locale charmap 2>/dev/null)" = "UTF-8" ] && echo "OK" || echo "NOT UTF-8"
```

Expected output:

```text
=== TUN ===
OK

=== POSIX MQUEUE ===
OK

=== OVERLAYFS ===
OK

=== UTF-8 ===
OK
```

## Supported Features

| Feature      | Status    | Use Case           |
| ------------ | --------- | ------------------ |
| TUN          | ✅ Enabled | Tailscale          |
| POSIX MQUEUE | ✅ Enabled | CIFS               |
| OverlayFS    | ✅ Enabled | Docker             |
| UTF-8        | ✅ Enabled | UTF-8 / `nls_utf8` |

## Requirements

* **Architecture:** ARM64
* **Platform:** Orange Pi
* **OS:** Debian-based Linux
* `dpkg`
* Root or `sudo` access

## Notes

Run `depmod` after installing the package to update the kernel module dependency database.

The required modules can then be loaded with:

```bash
sudo modprobe tun
sudo modprobe nls_utf8
```

This package is intended to resolve missing kernel feature/module requirements when running **Tailscale, CIFS, and Docker** on supported Orange Pi systems.
