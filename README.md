# initramfs-splash

Lightweight initramfs splash/bootsplash installer and manager for 
Raspberry Pi systems.

---

## 📌 Features

- Install and remove framebuffer-based initramfs splash helpers for
	`initramfs-tools`.
- Toggle boot `cmdline.txt` flags that control splash, terminal cursor and
	fastboot behavior.
- Rebuild initramfs images and update `config.txt` entries for kernel
	variants.
- Optional Plymouth integration: the script can detect a plymouth-based
	environment, and optionally install plymouth-friendly helpers.

---

## 🧰 Dependencies

Required on the host (Raspbian):

- `initramfs-tools`, `cpio`
- `plymouth`, `plymouth-themes`
- Common utilities: `bash`, `sed`, `grep`, `cut`, `tee`, `cat`, `file`, 
    `find`, `readlink`

The splash may require framebuffer utilities on the target device; verify
the device supports the configured framebuffer and image formats.

---

## 📂 Installation

### Install via `.deb` (recommended)

Download and install a release package (example):

```bash
wget https://github.com/aragon25/initramfs-splash/releases/download/v2.3-1/initramfs-splash_2.3-1_all.deb
sudo apt install ./initramfs-splash_2.3-1_all.deb
```

The package installs the installer script and supporting assets to system
locations and may register packaging hooks. 

---

## ⚙️ Usage

Run the script as `root`. The script validates the environment (Raspberry Pi
model, Debian/Raspbian release, required packages and the boot partition)
before making changes.

```bash
sudo initramfs-splash --help
```

Common commands (reflects `src/initramfs-splash.sh`):

- `-c, --clean`                       : remove initramfs splash helpers,
										unset splash-related cmdline flags
										and rebuild images.
- `-i, --initramfs_active`            : install files into initramfs and
										rebuild images.
- `-I, --initramfs_inactive`          : remove installed initramfs files and
										rebuild images.
- `-f, --cmdline_fastboot_active`     : add `fastboot` to `cmdline.txt`.
- `-F, --cmdline_fastboot_inactive`   : remove `fastboot` from `cmdline.txt`.
- `-s, --cmdline_splash_active`       : add splash flags (`logo.nologo quiet
										splash loglevel=3`) to `cmdline.txt`.
- `-S, --cmdline_splash_inactive`     : remove splash-related flags from
										`cmdline.txt`.
- `-t, --cmdline_termcursor_active`   : add `vt.global_cursor_default=0`
										(hide terminal cursor).
- `-T, --cmdline_termcursor_inactive` : remove `vt.global_cursor_default`.
- `-v, --version`                     : print script version.
- `-h, --help`                        : show help.

Notes:
- The script installs files into `/etc/initramfs-tools/scripts/init-top/`,
	`/etc/initramfs-tools/hooks/` and other hook locations used by
	`initramfs-tools`.
- When Plymouth is present the installer will attempt to avoid theme
	collisions by unsetting or adjusting the active plymouth theme during the
	update flow — see `src/initramfs-splash.sh` for exact behavior.

---

## 📁 Files of interest

- `src/initramfs-splash.sh` — main installer/manager script (entrypoint).
- `/etc/initramfs-tools/scripts/init-top/fbsplash` — installed init-top
	script that runs early during initramfs boot.
- `/etc/initramfs-tools/hooks/fbsplash` and
	`/etc/initramfs-tools/hooks/splash/*` — hook scripts and helper files.
- `deploy/builder/`, `deploy/config/` — packaging helpers and lifecycle
	hooks (preinst/postinst/prerm/postrm).

---

## 🔧 Developer workflows

- Test install on a disposable device or VM:

```bash
sudo initramfs-splash --update
```

- Pack a payload directory (to embed assets into the script):

```bash
# prepare '<scriptname>_payload' directory with fbsplash assets
tar -czf payload.tar.gz -C <scriptname>_payload .
mv payload.tar.gz src/payload.tar.gz
sudo initramfs-splash --payload_pack
```

- Extract an embedded payload for inspection or packaging:

```bash
sudo initramfs-splash --payload_unpack
```

- Build a test `.deb` using the project's deploy helper:

```bash
cd deploy
./build_test_deb.sh
```

The test `.deb` will appear in `packages/`.

---

## ⚠️ Safety & recommendations

- This script modifies the boot partition and rebuilds initramfs images.
	Test changes on spare hardware or a VM first.
- Run only as `root` and inspect packaging hooks (`deploy/config/*`) before
	installing generated packages on production devices.
- If you use Plymouth, ensure compatible themes are installed. The script may
	temporarily unset a plymouth theme to ensure the framebuffer splash works
	correctly during early boot.

---

## Examples

Install initramfs splash helpers and update initramfs:

```bash
sudo initramfs-splash -i
sudo initramfs-splash --update
```

Remove installed splash helpers and related cmdline flags:

```bash
sudo initramfs-splash -c
```

Pack and embed a payload into the script:

```bash
tar -czf payload.tar.gz -C <scriptname>_payload .
mv payload.tar.gz src/payload.tar.gz
sudo initramfs-splash --payload_pack
```

Extract embedded payload:

```bash
sudo initramfs-splash --payload_unpack
```
