# Orange Pi Custom Modules for Debian Trixie Kernel 6.6.98-sun60iw2

A custom Debian package set for **Orange Pi** that provides additional kernel modules and configuration required to enable the following features:

* **TUN** — required by Tailscale
* **POSIX MQUEUE** — required by CIFS
* **OverlayFS** — required by Docker
* **UTF-8** — provides UTF-8 support through `nls_utf8`
* **WireGuard** — provides the WireGuard kernel module for VPN support
* **CIFS** — provides the CIFS/SMB filesystem kernel module

## Installation

Install the custom kernel modules package:

```bash
sudo dpkg -i ~/orangepi-custom-modules_1.0_arm64.deb
```

Install the WireGuard kernel module package:

```bash
sudo dpkg -i ~/wireguard-6.6.98-sun60iw2.deb
```

Install the CIFS kernel module package:

```bash
sudo dpkg -i ~/cifs-6.6.98-sun60iw2.deb
```

Update the kernel module dependency database:

```bash
sudo depmod -a
```

Load the required kernel modules:

```bash
sudo modprobe tun
sudo modprobe nls_utf8
sudo modprobe wireguard
sudo modprobe cifs
```

> **Note:** The `wireguard-6.6.98-sun60iw2.deb` and `cifs-6.6.98-sun60iw2.deb` packages are built specifically for kernel `6.6.98-sun60iw2`. Make sure the running kernel matches this version.

Check the running kernel version:

```bash
uname -r
```

Expected:

```text
6.6.98-sun60iw2
```

## Verify Installation

### TUN

Verify that the TUN device is available:

```bash
echo "=== TUN ==="
test -c /dev/net/tun && echo "OK" || echo "NOT AVAILABLE"
```

### POSIX MQUEUE

Verify that the POSIX message queue filesystem is mounted:

```bash
echo "=== POSIX MQUEUE ==="
mountpoint -q /dev/mqueue && echo "OK" || echo "NOT ACTIVE"
```

### OverlayFS

Verify that OverlayFS is supported by the kernel:

```bash
echo "=== OVERLAYFS ==="
grep -qw overlay /proc/filesystems && echo "OK" || echo "NOT AVAILABLE"
```

### UTF-8

Verify UTF-8 locale support:

```bash
echo "=== UTF-8 ==="
[ "$(locale charmap 2>/dev/null)" = "UTF-8" ] && echo "OK" || echo "NOT UTF-8"
```

### WireGuard

Verify that the WireGuard kernel module is loaded:

```bash
echo "=== WIREGUARD ==="
lsmod | grep -qw wireguard && echo "OK" || echo "NOT LOADED"
```

If the module is not loaded:

```bash
sudo modprobe wireguard
```

Then verify:

```bash
lsmod | grep wireguard
```

### CIFS

Load the CIFS kernel module:

```bash
sudo modprobe cifs
```

Verify the CIFS module and its related dependencies:

```bash
lsmod | grep -E 'cifs|netfs|dns_resolver|cifs_md4|cifs_arc4'
```

The output should include `cifs` and its required dependencies where applicable.

## Quick Verification

All features can also be checked together:

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

echo "=== CIFS ==="
lsmod | grep -qw cifs && echo "OK" || echo "NOT LOADED"
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

=== CIFS ===
OK
```

## Supported Features

| Feature      | Status    | Module / Component | Use Case                |
| ------------ | --------- | ------------------ | ----------------------- |
| TUN          | ✅ Enabled | `tun`              | Tailscale               |
| POSIX MQUEUE | ✅ Enabled | `mqueue`           | CIFS / POSIX IPC        |
| OverlayFS    | ✅ Enabled | `overlay`          | Docker                  |
| UTF-8        | ✅ Enabled | `nls_utf8`         | UTF-8 filename support  |
| WireGuard    | ✅ Enabled | `wireguard`        | VPN / WireGuard         |
| CIFS         | ✅ Enabled | `cifs`             | SMB/CIFS network shares |

## Kernel Modules

The following modules are provided or required by the package set:

```text
tun
nls_utf8
wireguard
cifs
netfs
dns_resolver
cifs_md4
cifs_arc4
```

Some modules, such as `netfs`, `dns_resolver`, `cifs_md4`, and `cifs_arc4`, may be automatically loaded as dependencies when `cifs` is loaded.

Check the currently loaded modules with:

```bash
lsmod | grep -E 'tun|nls_utf8|wireguard|cifs|netfs|dns_resolver|cifs_md4|cifs_arc4'
```

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
cifs-6.6.98-sun60iw2.deb
```

The WireGuard and CIFS packages are kernel-version specific and must match the running kernel:

```text
Kernel:    6.6.98-sun60iw2
WireGuard: wireguard-6.6.98-sun60iw2.deb
CIFS:      cifs-6.6.98-sun60iw2.deb
```

## Notes

Run `depmod` after installing kernel module packages to update the kernel module dependency database:

```bash
sudo depmod -a
```

The required modules can then be loaded manually:

```bash
sudo modprobe tun
sudo modprobe nls_utf8
sudo modprobe wireguard
sudo modprobe cifs
```

For CIFS, loading `cifs` may automatically load required dependency modules such as:

```text
netfs
dns_resolver
cifs_md4
cifs_arc4
```

Verify the loaded modules with:

```bash
lsmod | grep -E 'cifs|netfs|dns_resolver|cifs_md4|cifs_arc4'
```

This package set is intended to resolve missing kernel feature and module requirements when running **Tailscale, CIFS/SMB, Docker, and WireGuard** on supported Orange Pi systems.
