# Orange Pi Custom Modules for Debian Trixie Kernel 6.6.98-sun60iw2

A custom Debian package set for **Orange Pi** running Debian Trixie with kernel `6.6.98-sun60iw2`.

This package set provides additional kernel modules and configuration required to enable:

* **TUN**
* **POSIX MQUEUE**
* **OverlayFS**
* **UTF-8**
* **WireGuard**
* **CIFS/SMB**
* **OpenVPN DCO**

> **Important:** All kernel modules and packages in this package set are built specifically for kernel `6.6.98-sun60iw2`. They are not intended for use with other kernel versions.

## Requirements

* **Architecture:** ARM64
* **Platform:** Orange Pi
* **OS:** Debian Trixie / Debian-based Linux
* **Kernel:** `6.6.98-sun60iw2`
* `dpkg`
* Root or `sudo` access

Before installing, verify the running kernel:

```bash
uname -r
```

Expected:

```text
6.6.98-sun60iw2
```

> **Do not install these packages if `uname -r` does not return `6.6.98-sun60iw2`.**

## Packages

The package set contains the following Debian packages:

```text
orangepi-custom-modules_1.0_arm64.deb
wireguard-6.6.98-sun60iw2.deb
cifs-6.6.98-sun60iw2.deb
overlayfs-config-6.6.98-sun60iw2.deb
ovpn-backports-kmod_7.1.0-1_arm64.deb
```

All packages are intended to be used with:

```text
Kernel: 6.6.98-sun60iw2
Architecture: ARM64
```

| Package                                 | Purpose                                     |
| --------------------------------------- | ------------------------------------------- |
| `orangepi-custom-modules_1.0_arm64.deb` | Additional kernel modules and configuration |
| `wireguard-6.6.98-sun60iw2.deb`         | WireGuard kernel module                     |
| `cifs-6.6.98-sun60iw2.deb`              | CIFS/SMB kernel module                      |
| `overlayfs-config-6.6.98-sun60iw2.deb`  | OverlayFS configuration                     |
| `ovpn-backports-kmod_7.1.0-1_arm64.deb` | OpenVPN DCO kernel module                   |

## Installation
### Using Install.sh

The easiest way to install the required kernel modules is using the included `install.sh` script.

Clone the repository:

```bash
git clone https://github.com/Dastanzzzz/OrangePi-4-Pro.git
cd OrangePi-4-Pro
chmod +x install.sh
./install.sh
```

### Manualy 
### 1. Verify the Kernel

Check the currently running kernel:

```bash
uname -r
```

The output must be:

```text
6.6.98-sun60iw2
```

If a different kernel version is detected, **do not continue with the installation**.

### 2. Install the Packages

Install the custom kernel modules:

```bash
sudo dpkg -i ~/orangepi-custom-modules_1.0_arm64.deb
```

Install WireGuard:

```bash
sudo dpkg -i ~/wireguard-6.6.98-sun60iw2.deb
```

Install CIFS:

```bash
sudo dpkg -i ~/cifs-6.6.98-sun60iw2.deb
```

Install OverlayFS configuration:

```bash
sudo dpkg -i ~/overlayfs-config-6.6.98-sun60iw2.deb
```

Install OpenVPN DCO:

```bash
sudo dpkg -i ~/ovpn-backports-kmod_7.1.0-1_arm64.deb
```

### 3. Update the Module Dependency Database

After installing all packages:

```bash
sudo depmod -a
```

### 4. Load the Required Modules

```bash
sudo modprobe tun
sudo modprobe nls_utf8
sudo modprobe wireguard
sudo modprobe cifs
sudo modprobe ovpn
```

## Verify Installation

### TUN

Verify that the TUN device is available:

```bash
test -c /dev/net/tun && echo "OK" || echo "NOT AVAILABLE"
```

### POSIX MQUEUE

Verify that the POSIX message queue filesystem is mounted:

```bash
mountpoint -q /dev/mqueue && echo "OK" || echo "NOT ACTIVE"
```

### OverlayFS

Verify that OverlayFS is supported by the kernel:

```bash
grep -qw overlay /proc/filesystems && echo "OK" || echo "NOT AVAILABLE"
```

### UTF-8

Verify the current locale:

```bash
[ "$(locale charmap 2>/dev/null)" = "UTF-8" ] && echo "locale: OK" || echo "locale: NOT UTF-8"
```

Verify the UTF-8 NLS module:

```bash
lsmod | grep -qw nls_utf8 && echo "nls_utf8: OK" || echo "nls_utf8: NOT LOADED"
```

### WireGuard

Verify the WireGuard kernel module:

```bash
lsmod | grep -qw wireguard && echo "OK" || echo "NOT LOADED"
```

### CIFS

Verify the CIFS kernel module:

```bash
lsmod | grep -qw cifs && echo "cifs: OK" || echo "cifs: NOT LOADED"
```

Check related dependencies:

```bash
lsmod | grep -E 'netfs|dns_resolver|cifs_md4|cifs_arc4'
```

### OpenVPN DCO

Verify the OpenVPN DCO kernel module:

```bash
lsmod | grep -qw ovpn && echo "ovpn: OK" || echo "ovpn: NOT LOADED"
```

Verify the `strparser` dependency:

```bash
lsmod | grep -qw strparser && echo "strparser: OK" || echo "strparser: NOT LOADED"
```

Additional module information:

```bash
modinfo ovpn | grep -E 'filename|version|depends|vermagic'
modinfo strparser | grep -E 'filename|vermagic'
```

## Quick Verification

All features can be checked together:

```bash
echo "=== KERNEL ==="
uname -r

echo
echo "=== TUN ==="
test -c /dev/net/tun && echo "OK" || echo "NOT AVAILABLE"

echo
echo "=== POSIX MQUEUE ==="
mountpoint -q /dev/mqueue && echo "OK" || echo "NOT ACTIVE"

echo
echo "=== OVERLAYFS ==="
grep -qw overlay /proc/filesystems && echo "OK" || echo "NOT AVAILABLE"

echo
echo "=== UTF-8 ==="
[ "$(locale charmap 2>/dev/null)" = "UTF-8" ] && echo "locale: OK" || echo "locale: NOT UTF-8"
lsmod | grep -qw nls_utf8 && echo "nls_utf8: OK" || echo "nls_utf8: NOT LOADED"

echo
echo "=== WIREGUARD ==="
lsmod | grep -qw wireguard && echo "OK" || echo "NOT LOADED"

echo
echo "=== CIFS ==="
lsmod | grep -qw cifs && echo "OK" || echo "NOT LOADED"

echo
echo "=== OVPN DCO ==="
lsmod | grep -qw ovpn && echo "ovpn: OK" || echo "ovpn: NOT LOADED"
lsmod | grep -qw strparser && echo "strparser: OK" || echo "strparser: NOT LOADED"
```

Expected output:

```text
=== KERNEL ===
6.6.98-sun60iw2

=== TUN ===
OK

=== POSIX MQUEUE ===
OK

=== OVERLAYFS ===
OK

=== UTF-8 ===
locale: OK
nls_utf8: OK

=== WIREGUARD ===
OK

=== CIFS ===
OK

=== OVPN DCO ===
ovpn: OK
strparser: OK
```

## Supported Features

| Feature      | Status    | Module / Component | Use Case                    |
| ------------ | --------- | ------------------ | --------------------------- |
| TUN          | ✅ Enabled | `tun`              | VPN / tunneling             |
| POSIX MQUEUE | ✅ Enabled | `mqueue`           | POSIX IPC                   |
| OverlayFS    | ✅ Enabled | `overlay`          | Docker / container storage  |
| UTF-8        | ✅ Enabled | `nls_utf8`         | UTF-8 filename support      |
| WireGuard    | ✅ Enabled | `wireguard`        | VPN                         |
| CIFS         | ✅ Enabled | `cifs`             | SMB/CIFS network shares     |
| OpenVPN DCO  | ✅ Enabled | `ovpn`             | OpenVPN kernel acceleration |

## Kernel Modules

The package set provides or requires the following kernel modules:

```text
tun
nls_utf8
wireguard
cifs
netfs
dns_resolver
cifs_md4
cifs_arc4
ovpn
strparser
```

Some modules are loaded automatically as dependencies when their parent module is loaded.

For example, loading `cifs` may automatically load:

```text
netfs
dns_resolver
cifs_md4
cifs_arc4
```

Similarly, `ovpn` may require:

```text
strparser
```

## Kernel Compatibility

All modules and packages in this repository are built for:

```text
Kernel:      6.6.98-sun60iw2
Architecture: ARM64
```

Before installing or loading any module, verify:

```bash
uname -r
```

The kernel must exactly match:

```text
6.6.98-sun60iw2
```

Using these packages with another kernel version may result in module loading errors, incompatible `vermagic`, or missing kernel symbols.

## Purpose

This package set is intended to provide missing kernel features and modules required by applications and services running on supported Orange Pi systems, including:

* VPN and tunneling
* WireGuard
* OpenVPN DCO
* CIFS/SMB network shares
* Docker / OverlayFS
* UTF-8 filename support
* POSIX IPC
