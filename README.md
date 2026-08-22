# Orange Pi Custom Modules for Debian Trixie Kernel 6.6.98-sun60iw2

A custom Debian package for **Orange Pi** that provides the required kernel modules and configuration to enable the following features:

* **TUN** — required by Tailscale
* **POSIX MQUEUE** — required by CIFS
* **OverlayFS** — required by Docker
* **UTF-8** — provides UTF-8 support through `nls_utf8`
* **WireGuard** — provides the WireGuard kernel module for VPN support

## Installation

Install the custom kernel modules package and the WireGuard kernel module package:

```bash
sudo dpkg -i orangepi-custom-modules_1.0_arm64.deb
sudo dpkg -i wireguard-6.6.98-sun60iw2.deb
```

Update the kernel module dependency database:

```bash
sudo depmod -a
```

Load the required modules:

```bash
sudo modprobe tun
sudo modprobe nls_utf8
sudo modprobe wireguard
```

> **Note:** The `wireguard-6.6.98-sun60iw2.deb` package is built specifically for kernel `6.6.98-sun60iw2`. Make sure the running kernel matches this version before loading the WireGuard module.

Check the running kernel version with:

```bash
uname -r
```

Expected:

```text
6.6.98-sun60iw2
```

## Verify Installation

After installation, verify that all required features and kernel modules are available:

```bash
echo "=== TUN ==="
test -c /dev/net/tun && echo "OK" || echo "NOT AVAILABLE"

echo "=== POSIX MQUEUE ==="
mountpoint -q /dev/mqueue && echo "OK" || echo "NOT ACTIVE"

echo "=== OVERLAYFS ==="
grep -qw overlay /proc/filesystems && echo "OK" || echo "NOT AVAILABLE"

echo "=== UTF-8 ==="
[ "$(locale charmap 2>/dev/null)" = "UTF-8" ] && echo "OK" || echo "NOT UTF-8"

echo "=== WIREGUARD ==="
lsmod | grep -qw wireguard && echo "OK" || echo "NOT LOADED"
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

=== WIREGUARD ===
OK
```

If the WireGuard module is not loaded, load it manually:

```bash
sudo modprobe wireguard
```

Then verify:

```bash
lsmod | grep wireguard
```

## Supported Features

| Feature      | Status    | Use Case           |
| ------------ | --------- | ------------------ |
| TUN          | ✅ Enabled | Tailscale          |
| POSIX MQUEUE | ✅ Enabled | CIFS               |
| OverlayFS    | ✅ Enabled | Docker             |
| UTF-8        | ✅ Enabled | UTF-8 / `nls_utf8` |
| WireGuard    | ✅ Enabled | VPN / WireGuard    |

## Requirements

* **Architecture:** ARM64
* **Platform:** Orange Pi
* **OS:** Debian Trixie / Debian-based Linux
* **Kernel:** `6.6.98-sun60iw2`
* `dpkg`
* Root or `sudo` access

## Packages

The installation requires the following Debian packages:

```text
orangepi-custom-modules_1.0_arm64.deb
wireguard-6.6.98-sun60iw2.deb
```

The WireGuard package is kernel-version specific and must match the running kernel:

```text
Kernel:  6.6.98-sun60iw2
Module:  wireguard
Package: wireguard-6.6.98-sun60iw2.deb
```

## Notes

Run `depmod` after installing kernel module packages to update the kernel module dependency database:

```bash
sudo depmod -a
```

The required modules can then be loaded with:

```bash
sudo modprobe tun
sudo modprobe nls_utf8
sudo modprobe wireguard
```

To check whether the modules are currently loaded:

```bash
lsmod | grep -E '^(tun|nls_utf8|wireguard)'
```

This package set is intended to resolve missing kernel feature and module requirements when running **Tailscale, CIFS, Docker, and WireGuard** on supported Orange Pi systems.
