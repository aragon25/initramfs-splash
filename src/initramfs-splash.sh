#!/bin/bash
##############################################
##                                          ##
##  initramfs-splash                        ##
##  update payload lines in script:         ##
##  - payload.tar.gz is in same dir         ##
##  - run script with --payload_pack        ##
##  extract payload.tar.gz from script:     ##
##  - run script with --payload_unpack      ##
##                                          ##
##############################################

#get some variables
SCRIPT_TITLE="initramfs-splash"
SCRIPT_VERSION="2.3"

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
UNPACK_DIR="/tmp/unpack-$SCRIPT_NAME"
if mountpoint -q "/boot/firmware"; then 
  BOOT_DIR=/boot/firmware
elif mountpoint -q "/boot"; then
  BOOT_DIR=/boot
fi
EXITCODE=0

#!!!RUN RESTRICTIONS!!!
#only for raspberry pi (rpi5|rpi4|rpi3|all) can combined!
raspi="all"
#only for Raspbian OS (bookworm|bullseye|all) can combined!
rasos="trixie|bookworm|bullseye"
#only for cpu architecture (i386|armhf|amd64|arm64) can combined!
cpuarch=""
#only for os architecture (32|64) can NOT combined!
bsarch=""
#this aptpaks need to be installed!
aptpaks=( initramfs-tools cpio sed plymouth plymouth-themes )

#check commands
for i in "$@"
do
  case $i in
    --update)
    cmd="${cmd}update"
    shift # past argument
    ;;
    -c|--clean)
    cmd="${cmd}clean"
    shift # past argument
    ;;
    -i|--initramfs_active)
    cmd="${cmd}initramfs_active"
    shift # past argument
    ;;
    -I|--initramfs_inactive)
    cmd="${cmd}initramfs_inactive"
    shift # past argument
    ;;
    -p|--plymouth_active)
    cmd="${cmd}plymouth_active"
    shift # past argument
    ;;
    -P|--plymouth_inactive)
    cmd="${cmd}plymouth_inactive"
    shift # past argument
    ;;
    -f|--cmdline_fastboot_active)
    cmd="${cmd}cmdline_fastboot_active"
    shift # past argument
    ;;
    -F|--cmdline_fastboot_inactive)
    cmd="${cmd}cmdline_fastboot_inactive"
    shift # past argument
    ;;
    -s|--cmdline_splash_active)
    cmd="${cmd}cmdline_splash_active"
    shift # past argument
    ;;
    -S|--cmdline_splash_inactive)
    cmd="${cmd}cmdline_splash_inactive"
    shift # past argument
    ;;
    -t|--cmdline_termcursor_active)
    cmd="${cmd}cmdline_termcursor_active"
    shift # past argument
    ;;
    -T|--cmdline_termcursor_inactive)
    cmd="${cmd}cmdline_termcursor_inactive"
    shift # past argument
    ;;
    --payload_pack)
    cmd="${cmd}payload_pack"
    shift # past argument
    ;;
    --payload_unpack)
    cmd="${cmd}payload_unpack"
    shift # past argument
    ;;
    -v|--version)
    cmd="${cmd}version"
    shift # past argument
    ;;
    -h|--help)
    cmd="${cmd}help"
    shift # past argument
    ;;
    *)
    if [ "$i" != "" ]
    then
      echo "Unknown option: $i"
      exit 1
    fi
    ;;
  esac
done
if [[ "$cmd" =~ "initramfs_active" ]] && [[ "$cmd" =~ "initramfs_inactive" ]]; then
  echo "option initramfs_active and initramfs_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "plymouth_active" ]] && [[ "$cmd" =~ "plymouth_inactive" ]]; then
  echo "option plymouth_active and plymouth_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "cmdline_fastboot_active" ]] && [[ "$cmd" =~ "cmdline_fastboot_inactive" ]]; then
  echo "option cmdline_fastboot_active and cmdline_fastboot_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "cmdline_splash_active" ]] && [[ "$cmd" =~ "cmdline_splash_inactive" ]]; then
  echo "option cmdline_splash_active and cmdline_splash_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "cmdline_termcursor_active" ]] && [[ "$cmd" =~ "cmdline_termcursor_inactive" ]]; then
  echo "option cmdline_termcursor_active and cmdline_termcursor_inactive can not combined!"
  cmd="help"
fi
if [[ "$cmd" =~ "clean" ]] && [[ "$cmd" != "clean" ]]; then
  echo "option clean can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "update" ]] && [[ "$cmd" != "update" ]]; then
  echo "option update can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "payload_pack" ]] && [[ "$cmd" != "payload_pack" ]]; then
  echo "option payload_pack can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "payload_unpack" ]] && [[ "$cmd" != "payload_unpack" ]]; then
  echo "option payload_unpack can not combined with other options!"
  cmd="help"
fi
if [[ "$cmd" =~ "help" ]] || [ "$cmd" == "" ]; then
  cmd="help"
fi
if [[ "$cmd" =~ "version" ]]; then
  cmd="version"
fi

function set_base_perms() {
  local filetype
  local entry
  local test
  IFS=$'\n'
  test=($(find "$1"))
  if [ "${#test[@]}" != "0" ]; then
    for entry in ${test[@]}; do
      chown -f 0:0 "$entry"
      if [ -f "$entry" ]; then
        filetype=$(file -b --mime-type "$entry" 2>/dev/null)
        if [[ "$filetype" =~ "executable" ]] || [[ "$filetype" =~ "script" ]] || 
           [[ "$entry" == *".desktop" ]] || [[ "$entry" == *".sh" ]]|| [[ "$entry" == *".py" ]]; then
          chmod -f 755 "$entry"
        else
          chmod -f 644 "$entry"
        fi
      elif [ -d "$entry" ]; then
        chmod -f 755 "$entry"
      fi
    done
  fi
  unset IFS
}

function do_check_start() {
  #check if superuser
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    exit 1
  fi
  #check if raspberry pi 
  if [ "$raspi" != "" ]; then
    raspi_v="$(tr -d '\0' 2>/dev/null < /proc/device-tree/model)"
    local raspi_res="false"
    [[ "$raspi_v" =~ "Raspberry Pi" ]] && [[ "$raspi" =~ "all" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 3" ]] && [[ "$raspi" =~ "rpi3" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 4" ]] && [[ "$raspi" =~ "rpi4" ]] && raspi_res="true"
    [[ "$raspi_v" =~ "Raspberry Pi 5" ]] && [[ "$raspi" =~ "rpi5" ]] && raspi_res="true"
    if [ "$raspi_res" == "false" ]; then
      echo "This Device seems not to be an Raspberry Pi ($raspi)! Can not continue with this script!"
      exit 1
    fi
  fi
  #check if raspbian
  if [ "$rasos" != "" ]
  then
    rasos_v="$(lsb_release -d -s 2>/dev/null)"
    [ -f /etc/rpi-issue ] && rasos_v="Raspbian ${rasos_v}"
    local rasos_res="false"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos" =~ "all" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bullseye" ]] && [[ "$rasos" =~ "bullseye" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "bookworm" ]] && [[ "$rasos" =~ "bookworm" ]] && rasos_res="true"
    [[ "$rasos_v" =~ "Raspbian" ]] && [[ "$rasos_v" =~ "trixie" ]] && [[ "$rasos" =~ "trixie" ]] && rasos_res="true"
    if [ "$rasos_res" == "false" ]; then
      echo "You need to run Raspbian OS ($rasos) to run this script! Can not continue with this script!"
      exit 1
    fi
  fi
  #check cpu architecture
  if [ "$cpuarch" != "" ]; then
    cpuarch_v="$(dpkg --print-architecture 2>/dev/null)"
    if [[ ! "$cpuarch" =~ "$cpuarch_v" ]]; then
      echo "Your CPU Architecture ($cpuarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check os architecture
  if [ "$bsarch" == "32" ] || [ "$bsarch" == "64" ]; then
    bsarch_v="$(getconf LONG_BIT 2>/dev/null)"
    if [ "$bsarch" != "$bsarch_v" ]; then
      echo "Your OS Architecture ($bsarch_v) is not supported! Can not continue with this script!"
      exit 1
    fi
  fi
  #check apt paks
  local apt
  local apt_res
  IFS=$' '
  if [ "${#aptpaks[@]}" != "0" ]; then
    for apt in ${aptpaks[@]}; do
      [[ ! "$(dpkg -s $apt 2>/dev/null)" =~ "Status: install" ]] && apt_res="${apt_res}${apt}, "
    done
    if [ "$apt_res" != "" ]; then
      echo "Not installed apt paks: ${apt_res%?%?}! Can not continue with this script!"
      exit 1
    fi
  fi
  unset IFS
  #check boot partition mount
  if [ -z "$BOOT_DIR" ]; then 
    echo "Could not find bootpartition! exit."
    exit 1
  fi
  #bootro state
  if findmnt -n -o OPTIONS "$BOOT_DIR" | egrep "^ro,|,ro,|,ro$" &>/dev/null; then
    BOOT_READONLY="true"
  fi
}

function set_boot_rw() {
  [ -n "$BOOT_READONLY" ] && mount -o remount,rw $BOOT_DIR
}

function set_boot_ro() {
  [ -n "$BOOT_READONLY" ] && mount -o remount,ro $BOOT_DIR
}

function extract_files() {
  local PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' "$SCRIPT_PATH")
  [ -z "$PAYLOAD_LINE" ] && return 1
  rm -rf "$UNPACK_DIR"
  mkdir -p "$UNPACK_DIR"
  tail -n +${PAYLOAD_LINE} "$SCRIPT_PATH" | base64 -d | tar -zpvx -C "$UNPACK_DIR" &>/dev/null
  local result=$?
  set_base_perms "$UNPACK_DIR"
  return $result
}

function cmd_payload_pack() {
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    EXITCODE=1
    return 1
  fi
  local payload_dirname="$(basename "$SCRIPT_NAME" ".sh")_payload"
  local PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR; exit 0; }' "$SCRIPT_PATH")
  if [ -d "${SCRIPT_DIR}/${payload_dirname}" ]; then
    rm -f "/tmp/payload.tar.gz"
    #( cd "${SCRIPT_DIR}/${payload_dirname}" && tar -czf "/tmp/payload.tar.gz" * )
    ( cd "${SCRIPT_DIR}/${payload_dirname}" && tar -czf "/tmp/payload.tar.gz" . )
    rm -rf "${SCRIPT_DIR}/${payload_dirname}"
  fi
  if [ -f "$SCRIPT_DIR/payload.tar.gz" ]; then
    rm -f "/tmp/payload.tar.gz"
    mv -f "$SCRIPT_DIR/payload.tar.gz" "/tmp/payload.tar.gz"
  fi
  if [ ! -f "/tmp/payload.tar.gz" ]; then
    echo "... Could not find 'payload'. EXIT ..."
    EXITCODE=1
    return 1
  fi
  if [ -z "$PAYLOAD_LINE" ]; then
    echo "__PAYLOAD_BEGINS__" >> "$SCRIPT_PATH"
    PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR; exit 0; }' "$SCRIPT_PATH")
  fi
  cp -f "$SCRIPT_PATH" "/tmp/payload_tmp"
  head -n +${PAYLOAD_LINE} /tmp/payload_tmp > "$SCRIPT_PATH"
  base64 "/tmp/payload.tar.gz" >> "$SCRIPT_PATH"
  rm -f "/tmp/payload_tmp"
  rm -f "/tmp/payload.tar.gz"
}

function cmd_payload_unpack() {
  if [ $UID -ne 0 ]; then
    echo "Please run this script with Superuser privileges!"
    EXITCODE=1
    return 1
  fi
  local u="${SUDO_USER:-$(logname 2>/dev/null)}"
  local g="$(id -gn "$u" 2>/dev/null)"
  local payload_dirname="$(basename "$SCRIPT_NAME" ".sh")_payload"
  local PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' "$SCRIPT_PATH")
  [ -z "$PAYLOAD_LINE" ] && EXITCODE=1 && return 1
  rm -rf "${SCRIPT_DIR}/${payload_dirname}"
  mkdir -p "${SCRIPT_DIR}/${payload_dirname}"
  tail -n +${PAYLOAD_LINE} "$SCRIPT_PATH" | base64 -d | tar -zpvx -C "${SCRIPT_DIR}/${payload_dirname}" &>/dev/null
  set_base_perms "${SCRIPT_DIR}/${payload_dirname}"
  #chown -fR $(logname):$(groups $(logname) | awk '{print $3}') "${SCRIPT_DIR}/${payload_dirname}"
  [ -n "$u" ] && [ -n "$g" ] && chown -fR "$u:$g" "${SCRIPT_DIR}/${payload_dirname}" 2>/dev/null
}

function cmd_clean() {
  cmd_initramfs_inactive
  cmd_plymouth_inactive
  cmd_cmdline_splash_inactive
  cmd_cmdline_termcursor_inactive
}

function cmd_update() {
  if [ -e "/etc/initramfs-tools/hooks/splash/fbsplash" ]; then
    install_initramfs >/dev/null 2>&1
    update_initramfs >/dev/null 2>&1
  fi
  if [ -e "/usr/share/plymouth/themes/initramfs-splash" ]; then
    create_plymouth_theme >/dev/null 2>&1
  fi
}

function create_plymouth_theme() {
  remove_plymouth_theme >/dev/null 2>&1
  extract_files >/dev/null 2>&1
  mkdir -p "/usr/share/plymouth/themes/initramfs-splash" >/dev/null 2>&1
  cp -af "$UNPACK_DIR/fbsplash.png" /usr/share/plymouth/themes/initramfs-splash/splash.png >/dev/null 2>&1
  rm -rf "$UNPACK_DIR"
  if [ ! -f "/usr/share/plymouth/themes/initramfs-splash/splash.png" ]; then
    rm -rf "/usr/share/plymouth/themes/initramfs-splash"
    echo "... Could not create plymouth theme! (extract error) ..."
    EXITCODE=1
    return 1
  fi
  chmod -f 644 "/usr/share/plymouth/themes/initramfs-splash/splash.png" >/dev/null 2>&1
  cat >>"/usr/share/plymouth/themes/initramfs-splash/initramfs-splash.plymouth" <<EOF
[Plymouth Theme]
Name=initramfs-splash
Description=This is a plymouth theme which simply displays an image
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/initramfs-splash
ScriptFile=/usr/share/plymouth/themes/initramfs-splash/initramfs-splash.script
EOF
  chmod -f 644 "/usr/share/plymouth/themes/initramfs-splash/initramfs-splash.plymouth" >/dev/null 2>&1
  cat >>"/usr/share/plymouth/themes/initramfs-splash/initramfs-splash.script" <<EOF
image = Image("splash.png");

pos_x = Window.GetWidth()/2 - image.GetWidth()/2;
pos_y = Window.GetHeight()/2 - image.GetHeight()/2;

sprite = Sprite(image);
sprite.SetX(pos_x);
sprite.SetY(pos_y);

fun refresh_callback () {
  sprite.SetOpacity(1);
  sprite.SetZ(15);
}

Plymouth.SetRefreshFunction (refresh_callback);
EOF
  chmod -f 644 "/usr/share/plymouth/themes/initramfs-splash/initramfs-splash.script" >/dev/null 2>&1
  echo "plymouth theme created!"
}

function remove_plymouth_theme() {
  rm -rf "/usr/share/plymouth/themes/initramfs-splash" >/dev/null 2>&1
  echo "plymouth theme removed!"
}

function set_plymouth_theme() {
  if command -v plymouth-set-default-theme >/dev/null; then
    local current_theme="$(plymouth-set-default-theme)"
    if [ "$current_theme" != "initramfs-splash" ]; then
      mkdir -p "/usr/lib/initramfs-splash" >/dev/null 2>&1
      echo "$current_theme" >"/usr/lib/initramfs-splash/plymouth_savedtheme" 2>/dev/null
      plymouth-set-default-theme -R initramfs-splash >/dev/null 2>&1
    fi
  elif command -v update-alternatives >/dev/null; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/initramfs-splash/initramfs-splash.plymouth 140 >/dev/null 2>&1
    update-alternatives --set default.plymouth /usr/share/plymouth/themes/initramfs-splash/initramfs-splash.plymouth >/dev/null 2>&1
    update-initramfs -u >/dev/null 2>&1
  else
    echo "... No suitable command found to set plymouth theme! ..."
    remove_plymouth_theme >/dev/null 2>&1
    EXITCODE=1
    return 1
  fi
  echo "plymouth theme set!"
}

function unset_plymouth_theme() {
  if command -v plymouth-set-default-theme >/dev/null; then
    local current_theme="$(plymouth-set-default-theme)"
    local saved_theme="$(awk 'NR==1 {print $1}' /usr/lib/initramfs-splash/plymouth_savedtheme 2>/dev/null)"
    if [ "$current_theme" == "initramfs-splash" ]; then
      if [ "$saved_theme" != "" ]; then
        if ! plymouth-set-default-theme -R "$saved_theme" >/dev/null 2>&1; then
          plymouth-set-default-theme -R details >/dev/null 2>&1
        fi
      else
        plymouth-set-default-theme -R details >/dev/null 2>&1
      fi
    fi
  elif command -v update-alternatives >/dev/null; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/details/details.plymouth 50 >/dev/null 2>&1
    update-alternatives --remove default.plymouth /usr/share/plymouth/themes/initramfs-splash/initramfs-splash.plymouth >/dev/null 2>&1
    update-initramfs -u >/dev/null 2>&1
  else
    echo "... No suitable command found to set plymouth theme! ..."
    EXITCODE=1
    return 1
  fi
  rm -f "/usr/lib/initramfs-splash/plymouth_savedtheme" >/dev/null 2>&1
  echo "plymouth theme unset!"
}

function update_initramfs() {
  local exitcode=0
  local distib="$(lsb_release -d -s 2>/dev/null)"
  [ -f /etc/rpi-issue ] && distib="Raspbian ${distib}"
  set_boot_rw
  sed -i '/^initramfs /d' "$BOOT_DIR/config.txt"
  sed -i '/^include config-initramfs.txt/d' "$BOOT_DIR/config.txt"
  sed -i '/^include config-custom.txt/d' "$BOOT_DIR/config.txt"
  sed -i '/\[all\][^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\ninclude config-custom.txt/' "$BOOT_DIR/config.txt"
  [ -e "$BOOT_DIR/config-custom.txt" ] || touch "$BOOT_DIR/config-custom.txt"
  rm -f "$BOOT_DIR/config-initramfs.txt" >/dev/null 2>&1
  if [[ "$distib" =~ "bullseye" ]]; then
    local suffix_long
    local suffix_short
    local kernel_version=$(basename $(ls -dv /lib/modules/* 2>/dev/null | tail -n1) 2>/dev/null | sed 's/-.*//')
    for suffix_long in "+" "-v7+" "-v7l+" "-v8+"; do
      [ "$suffix_long" == "+" ] && suffix_short=""
      [ "$suffix_long" == "-v7+" ] && suffix_short="7"
      [ "$suffix_long" == "-v7l+" ] && suffix_short="7l"
      [ "$suffix_long" == "-v8+" ] && suffix_short="8"
      if [ -e "/lib/modules/${kernel_version}${suffix_long}" ]; then
        update-initramfs -c -k "${kernel_version}${suffix_long}"
        if [ $? -eq 0 ]; then
          echo "$BOOT_DIR/initrd.img-${kernel_version}${suffix_long} -> $BOOT_DIR/initramfs${suffix_short}"
          mv -f "$BOOT_DIR/initrd.img-${kernel_version}${suffix_long}" "$BOOT_DIR/initramfs${suffix_short}"
        else
          echo "... updating initramfs image for ${kernel_version}${suffix_long} failed ..."
          exitcode=1
        fi
      fi
    done
    if [ $exitcode -eq 0 ]; then
      local kernel_suf=$([ "$(getconf LONG_BIT 2>/dev/null)" = "64" ] && echo "8" || echo "7l")
      sed -i '/\[all\][^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\ninclude config-initramfs.txt/' "$BOOT_DIR/config.txt"
      [ -f "$BOOT_DIR/kernel.img" ] && [ -f "$BOOT_DIR/initramfs" ] && cat >>"$BOOT_DIR/config-initramfs.txt" <<EOF
[all]
kernel=kernel.img
initramfs initramfs followkernel
EOF
      [ -f "$BOOT_DIR/kernel7.img" ] && [ -f "$BOOT_DIR/initramfs7" ] && cat >>"$BOOT_DIR/config-initramfs.txt" <<EOF
[pi2]
kernel=kernel7.img
initramfs initramfs7 followkernel
[pi3]
kernel=kernel7.img
initramfs initramfs7 followkernel
EOF
      [ -f "$BOOT_DIR/kernel${kernel_suf}.img" ] && [ -f "$BOOT_DIR/initramfs${kernel_suf}" ] && cat >>"$BOOT_DIR/config-initramfs.txt" <<EOF
[pi3+]
kernel=kernel${kernel_suf}.img
initramfs initramfs${kernel_suf} followkernel
[pi4]
kernel=kernel${kernel_suf}.img
initramfs initramfs${kernel_suf} followkernel
EOF
    else
      echo "... updating initramfs image/s failed ..."
      EXITCODE=1
      return 1
    fi
  elif [[ "$distib" =~ "bookworm" ]] || [[ "$distib" =~ "trixie" ]]; then
    mkdir -p "/etc/initramfs-tools/conf.d"
    echo "MODULES=most" > "/etc/initramfs-tools/conf.d/imgldr"
    update-initramfs -u
    if [ $? -eq 0 ]; then
      sed -i '/\[all\][^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\ninclude config-initramfs.txt/' "$BOOT_DIR/config.txt"
      echo "[all]" > "$BOOT_DIR/config-initramfs.txt"
      echo "auto_initramfs=1" >> "$BOOT_DIR/config-initramfs.txt"
    else
      echo "... updating initramfs image/s failed ..."
      EXITCODE=1
      return 1
    fi
  fi
  set_boot_ro
  echo "initramfs image/s updated."
}

function install_initramfs() {
  local files_ok="true"
  remove_initramfs >/dev/null 2>&1
  extract_files
  if [ $? -ne 0 ]; then 
    echo "... Could not install splash to initramfs-tools directory! (extract error) ..."
    EXITCODE=1
    return 1
  fi
  mkdir -p "/etc/initramfs-tools/scripts/init-top"
  mkdir -p "/etc/initramfs-tools/hooks/splash"
  cp -af "$UNPACK_DIR/fbsplash-run" "/etc/initramfs-tools/scripts/init-top/fbsplash"
  [ -f "/etc/initramfs-tools/scripts/init-top/fbsplash" ] || files_ok="false"
  cp -af "$UNPACK_DIR/fbsplash-cp" "/etc/initramfs-tools/hooks/fbsplash"
  [ -f "/etc/initramfs-tools/hooks/fbsplash" ] || files_ok="false"
  cp -af "$UNPACK_DIR/fbsplash" "/etc/initramfs-tools/hooks/splash/fbsplash"
  [ -f "/etc/initramfs-tools/hooks/splash/fbsplash" ] || files_ok="false"
  cp -af "$UNPACK_DIR/fbsplash.png" "/etc/initramfs-tools/hooks/splash/fbsplash.png"
  [ -f "/etc/initramfs-tools/hooks/splash/fbsplash.png" ] || files_ok="false"
  chmod +x "/etc/initramfs-tools/scripts/init-top/fbsplash"
  chmod +x "/etc/initramfs-tools/hooks/fbsplash"
  rm -rf "$UNPACK_DIR"
  if [ "$files_ok" == "false" ]; then
    echo "... Could not install splash to initramfs-tools directory! (copy error) ..."
    remove_initramfs >/dev/null 2>&1
    EXITCODE=1
    return 1
  fi
  echo "installed splash to initramfs-tools directory."
}

function remove_initramfs() {
  rm -f "/etc/initramfs-tools/scripts/init-top/fbsplash"
  rm -f "/etc/initramfs-tools/hooks/fbsplash"
  rm -f "/etc/initramfs-tools/hooks/splash/fbsplash"
  rm -f "/etc/initramfs-tools/hooks/splash/fbsplash.png"
  rm -rf "/etc/initramfs-tools/hooks/splash"
  echo "removed splash from initramfs-tools directory."
}

function cmd_plymouth_active() {
  create_plymouth_theme
  set_plymouth_theme
  echo "plymouth theme installed and activated!"
}

function cmd_plymouth_inactive() {
  unset_plymouth_theme
  remove_plymouth_theme
  echo "plymouth theme removed and deactivated!"
}

function cmd_initramfs_active() {
  install_initramfs
  update_initramfs
  echo "initramfs splash installed and activated!"
}

function cmd_initramfs_inactive() {
  remove_initramfs
  update_initramfs
  echo "initramfs splash removed and deactivated!"
}

function cmd_cmdline_fastboot_active() {
  set_boot_rw
  sed -i -e 's/ fastboot//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/fastboot //' "$BOOT_DIR/cmdline.txt"
  sed -i 's/$/ fastboot/g' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_cmdline_fastboot_inactive() {
  set_boot_rw
  sed -i -e 's/ fastboot//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/fastboot //' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_cmdline_splash_active() {
  set_boot_rw
  sed -i -e 's/ logo.nologo//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/logo.nologo //' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/ quiet//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/quiet //' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/ splash//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/splash //' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/ loglevel=[a-f0-9-]\+//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/loglevel=[a-f0-9-]\+ //' "$BOOT_DIR/cmdline.txt"
  sed -i 's/$/ logo.nologo quiet splash loglevel=3/g' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_cmdline_splash_inactive() {
  set_boot_rw
  sed -i -e 's/ logo.nologo//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/logo.nologo //' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/ quiet//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/quiet //' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/ splash//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/splash //' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/ loglevel=[a-f0-9-]\+//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/loglevel=[a-f0-9-]\+ //' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_cmdline_termcursor_active() {
  set_boot_rw
  sed -i -e 's/ vt.global_cursor_default=[a-f0-9-]\+//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/vt.global_cursor_default=[a-f0-9-]\+ //' "$BOOT_DIR/cmdline.txt"
  sed -i 's/$/ vt.global_cursor_default=0/g' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_cmdline_termcursor_inactive() {
  set_boot_rw
  sed -i -e 's/ vt.global_cursor_default=[a-f0-9-]\+//' "$BOOT_DIR/cmdline.txt"
  sed -i -e 's/vt.global_cursor_default=[a-f0-9-]\+ //' "$BOOT_DIR/cmdline.txt"
  set_boot_ro
}

function cmd_print_version() {
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
}

function cmd_print_help() {
  echo "Usage: $SCRIPT_NAME [OPTION]"
  echo "$SCRIPT_TITLE v$SCRIPT_VERSION"
  echo " "
  echo "Lightweight initramfs splash/bootsplash installer and manager for Raspberry Pi systems."
  echo "Loads splash screens from (in this hirarchy):"
  echo "-inside initramfs: /etc/splash/splash.config (always shown shortly)"
  echo "-root filesystem:  /usr/lib/rpi-kiosk/kiosk-splash/splash.config"
  echo "-root filesystem:  /IMAGES/system.img/usr/lib/rpi-kiosk/kiosk-splash/splash.config"
  echo "-root filesystem:  /IMAGES/oem.img/usr/lib/rpi-kiosk/kiosk-splash/splash.config"
  echo "-root filesystem:  /etc/splash/splash.config"
  echo "-root filesystem:  /IMAGES/system.img/etc/splash/splash.config"
  echo "-root filesystem:  /IMAGES/oem.img/etc/splash/splash.config"
  echo "-root filesystem:  /CONFIG/initramfs-splash/splash.config"
  echo " "
  echo "-c, --clean                       remove initramfs-splash, plymouth-splash"
  echo "                                  and rebuild image"
  echo "-i, --initramfs_active            install files to initramfs and rebuild image"
  echo "-I, --initramfs_inactive          remove files from initramfs and rebuild image"
  echo "-p, --plymouth_active             set simple plymouth theme as default"
  echo "-P, --plymouth_inactive           set default plymouth theme as default"
  echo "-f, --cmdline_fastboot_active     set fastboot flag in cmdline.txt"
  echo "-F, --cmdline_fastboot_inactive   unset fastboot flag in cmdline.txt"
  echo "-s, --cmdline_splash_active       set showing splash in cmdline.txt"
  echo "-S, --cmdline_splash_inactive     unset showing splash in cmdline.txt"
  echo "-t, --cmdline_termcursor_active   set hide term cursor flag in cmdline.txt"
  echo "-T, --cmdline_termcursor_inactive unset hide term cursor flag in cmdline.txt"
  echo "-v, --version                     print version info and exit"
  echo "-h, --help                        print this help and exit"
  echo " "
  echo "Author: aragon25 <aragon25.01@web.de>"
}

[ "$cmd" != "version" ] && [ "$cmd" != "help" ] && \
[ "$cmd" != "payload_pack" ] && [ "$cmd" != "payload_unpack" ] && do_check_start
[[ "$cmd" == "version" ]] && cmd_print_version
[[ "$cmd" == "help" ]] && cmd_print_help
[[ "$cmd" == "clean" ]] && cmd_clean
[[ "$cmd" == "update" ]] && cmd_update
[[ "$cmd" =~ "initramfs_active" ]] && cmd_initramfs_active
[[ "$cmd" =~ "initramfs_inactive" ]] && cmd_initramfs_inactive
[[ "$cmd" =~ "plymouth_active" ]] && cmd_plymouth_active
[[ "$cmd" =~ "plymouth_inactive" ]] && cmd_plymouth_inactive
[[ "$cmd" =~ "cmdline_fastboot_active" ]] && cmd_cmdline_fastboot_active
[[ "$cmd" =~ "cmdline_fastboot_inactive" ]] && cmd_cmdline_fastboot_inactive
[[ "$cmd" =~ "cmdline_splash_active" ]] && cmd_cmdline_splash_active
[[ "$cmd" =~ "cmdline_splash_inactive" ]] && cmd_cmdline_splash_inactive
[[ "$cmd" =~ "cmdline_termcursor_active" ]] && cmd_cmdline_termcursor_active
[[ "$cmd" =~ "cmdline_termcursor_inactive" ]] && cmd_cmdline_termcursor_inactive
[[ "$cmd" == "payload_pack" ]] && cmd_payload_pack
[[ "$cmd" == "payload_unpack" ]] && cmd_payload_unpack

exit $EXITCODE
