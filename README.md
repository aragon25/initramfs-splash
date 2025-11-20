# initramfs-splash

Lightweight initramfs splash/bootsplash installer and manager for Raspberry Pi systems.

---

## 📌 Features

- Install and remove framebuffer-based initramfs splash helpers into `initramfs-tools` (`--install`, `--remove`).
- Toggle boot cmdline flags that control splash and terminal cursor behaviour (`--cmdline_splash_*`, `--cmdline_termcursor_*`, `--cmdline_fastboot_*`).
- Rebuild initramfs and update boot entries (`--update_initramfs`).

---

## 🧰 Dependencies

Required on the host (Debian/Raspbian):

- `bash`
- `initramfs-tools`, `cpio`
- `sed`, `grep`, `cut`, `tee`, `cat`, `file`, `find`, `readlink`

The splash may require framebuffer utilities on the target device; verify the device supports the configured framebuffer and image formats.

---

## 📂 Installation

### Install via `.deb` (recommended for devices)

Download and install a release package (example):

```bash
wget https://github.com/aragon25/initramfs-splash/releases/download/v2.2-2/initramfs-splash_2.2-2_all.deb
sudo apt install ./initramfs-splash_2.2-2_all.deb
```

The package installs the installer script and supporting assets into system locations and registers packaging hooks where applicable.

---

## ⚙️ Usage

Run the script as root — it validates the environment (Raspberry Pi model, Raspbian release, required packages, boot partition) before changes.

```bash
sudo initramfs-splash --help
```

Common commands:

- `--install` : install splash helpers into `/etc/initramfs-tools` (scripts, hooks, image scripts).
- `--remove` : remove installed splash helpers.
- `--update_initramfs` : rebuild initramfs images and update boot `config.txt` entries.
- `--cmdline_splash_active|inactive` : enable/disable splash cmdline flag.
- `--cmdline_termcursor_active|inactive` : enable/disable terminal cursor in splash.
- `--cmdline_fastboot_active|inactive` : toggle fastboot-related cmdline flag.
- `-v|--version`, `-h|--help` : version/help.

Notes:
- The script installs files into `/etc/initramfs-tools/scripts/init-top/`, `/etc/initramfs-tools/hooks/` and the image script location used by `initramfs-tools`.
 - Inspect `src/` for helper scripts and any splash image assets used by the installer.

---

## 📁 Files of interest

- `src/initramfs-splash.sh` — main installer/manager script (entrypoint).
 
- `deploy/builder/` — packaging builder scripts (shared pattern with other projects).
- `deploy/config/build_deb.conf` — packaging config for `.deb` creation.
- `deploy/config/{preinst,postinst,prerm,postrm}.sh` — packaging hooks executed during package lifecycle — ALWAYS review before installing packages.

---

## 🔧 Developer workflows

 - Test install on a disposable device or VM:

```bash
sudo initramfs-splash --install
sudo initramfs-splash --update_initramfs
```

- Build a test `.deb` using the project's deploy helper:

```bash
cd deploy
./build_test_deb.sh
```

The test `.deb` will appear in `packages/`.

---

## ⚠️ Safety & recommendations

- This script modifies the boot partition and rebuilds initramfs images. Test changes on spare hardware or VM first.
- Run only as `root` and inspect packaging hooks (`deploy/config/*`) before installing packages on production devices.
 - If you customize splash images or scripts, verify the framebuffer utilities and permissions; splash code runs early in the boot process.

---

## Examples

Install installed splash and update initramfs:

```bash
sudo initramfs-splash --install
sudo initramfs-splash --update_initramfs
```
