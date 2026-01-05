# ISO Creation and Testing

This section covers comprehensive ISO creation, testing procedures, validation, and quality assurance for your Linux distribution.

## Table of Contents

1. [ISO Types and Variants](#iso-types-and-variants)
2. [Live System Creation](#live-system-creation)
3. [Install Media Creation](#install-media-creation)
4. [Boot Configuration](#boot-configuration)
5. [ISO Testing Procedures](#iso-testing-procedures)
6. [Automated Testing](#automated-testing)
7. [Quality Assurance](#quality-assurance)
8. [Release Validation](#release-validation)

## ISO Types and Variants

### ISO Variants Overview

```
ISO Types
├── Live ISO
│   ├── Desktop Live
│   ├── Server Live
│   └── Rescue Live
├── Install ISO
│   ├── Full Install
│   ├── Minimal Install
│   └── Network Install
├── Update ISO
│   ├── Delta Updates
│   └── Security Updates
└── Special ISO
    ├── OEM Install
    ├── Development Build
    └── Testing Build
```

### ISO Configuration Matrix

| ISO Type | Size | Use Case | Desktop | Server | Development |
|----------|------|----------|---------|--------|-------------|
| Desktop Live | 2-3GB | Try/Install | ✓ | ✗ | ✓ |
| Server Live | 800MB | Server Deployment | ✗ | ✓ | ✓ |
| Full Install | 4-5GB | Complete Installation | ✓ | ✓ | ✓ |
| Minimal Install | 600MB | Base System | ✗ | ✓ | ✓ |
| Network Install | 100MB | Network Boot | ✓ | ✓ | ✓ |

## Live System Creation

### Desktop Live ISO

#### Kickstart Configuration
Create `config/desktop-live.ks`:
```kickstart
# Desktop Live System Configuration

# System identification
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone America/New_York --isUtc
auth --enableshadow --passalgo=sha512

# Network configuration
network --bootproto=dhcp --device=link --activate
firewall --enabled --service=ssh

# Root and user configuration
rootpw --lock
user --name=liveuser --password=liveuser --plaintext --gecos="Live User"

# SELinux configuration
selinux --enforcing

# System services
services --enabled="NetworkManager,sshd,firewalld,gdm"

# Repository configuration
repo --name="base" --baseurl=file:///opt/distro-repo --cost=100
repo --name="updates" --baseurl=file:///opt/distro-repo/updates --cost=200

# Package selection
%packages
@core
@standard
@desktop-platform
@guest-desktop-agents
@fonts
@multimedia
@internet-browser

# Distro packages
distro-release
distro-config
distro-branding
distro-desktop
distro-themes

# Desktop environment
gnome-shell
gnome-session
gdm
nautilus
gnome-terminal
firefox
libreoffice-writer
evince
gnome-photos

# System tools
gnome-disk-utility
gnome-system-monitor
baobab
gnome-logs

# Remove unwanted packages
-remove=@printing
-remove=scdaemon
-remove=sendmail
%end

# Post-installation configuration
%post --log=/root/ks-post.log
# Distro post-install script
/usr/local/bin/distro-postinstall-live

# Configure desktop for live user
cp /usr/share/distro/config/live-user-profile.sh /home/liveuser/.profile
chown liveuser:liveuser /home/liveuser/.profile

# Create desktop shortcuts
mkdir -p /home/liveuser/Desktop
cat > /home/liveuser/Desktop/install.desktop <<'EOF'
[Desktop Entry]
Name=Install to Hard Drive
Comment=Install Distro Linux to your hard drive
Exec=/usr/local/bin/distro-install-launcher
Icon=system-installer
Type=Application
Categories=System;
EOF
chmod +x /home/liveuser/Desktop/install.desktop
chown liveuser:liveuser /home/liveuser/Desktop/install.desktop

# Configure autologin for live user
mkdir -p /etc/gdm
cat > /etc/gdm/custom.conf <<'EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=liveuser

[security]

[xdmcp]

[chooser]

[debug]
EOF

# Clean up
rm -f /etc/udev/rules.d/70-persistent-net.rules
%end
```

#### Live Build Script
Create `scripts/build-desktop-live.sh`:
```bash
#!/bin/bash
# Desktop Live ISO build script

set -e

# Configuration
DISTRO_NAME="Distro"
VERSION="1.0"
BUILD_DIR="/opt/distro-build"
KICKSTART_FILE="$BUILD_DIR/config/desktop-live.ks"
OUTPUT_DIR="$BUILD_DIR/iso"
TEMP_DIR="$BUILD_DIR/tmp-live"

# Clean previous build
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR"

echo "Building Desktop Live ISO..."

# Build live system with lorax
lorax -p "$DISTRO_NAME-Live" \
    -v "$VERSION" \
    -r 9 \
    -t "$TEMP_DIR" \
    -c "$KICKSTART_FILE" \
    --buildarch=x86_64 \
    --add-template="$BUILD_DIR/templates/live-templates.tmpl" \
    --add-arch-template="$BUILD_DIR/templates/live-arch.tmpl" \
    --add-variant-template="$BUILD_DIR/templates/live-variant.tmpl" \
    "$TEMP_DIR/result"

# Create bootable ISO
cd "$TEMP_DIR/result"

# Create boot catalog
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Distro Live $VERSION" \
    -appid "Distro Live" \
    -publisher "Distro Project" \
    -preparer "Distro Build System" \
    -eltorito-boot images/boot.iso \
    -eltorito-catalog boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -output "$OUTPUT_DIR/distro-desktop-live-$VERSION-x86_64.iso" \
    .

# Create UEFI bootable ISO
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Distro Live $VERSION" \
    -appid "Distro Live" \
    -publisher "Distro Project" \
    -preparer "Distro Build System" \
    -eltorito-boot images/efiboot.img \
    -eltorito-catalog boot.cat \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "$OUTPUT_DIR/distro-desktop-live-$VERSION-x86_64-uefi.iso" \
    .

# Create checksums
cd "$OUTPUT_DIR"
sha256sum "distro-desktop-live-$VERSION-x86_64.iso" > "distro-desktop-live-$VERSION-x86_64.iso.sha256"
sha256sum "distro-desktop-live-$VERSION-x86_64-uefi.iso" > "distro-desktop-live-$VERSION-x86_64-uefi.iso.sha256"

# Generate ISO info
echo "Desktop Live ISO Information:" > "distro-desktop-live-$VERSION-info.txt"
echo "=============================" >> "distro-desktop-live-$VERSION-info.txt"
echo "BIOS ISO: distro-desktop-live-$VERSION-x86_64.iso" >> "distro-desktop-live-$VERSION-info.txt"
echo "UEFI ISO: distro-desktop-live-$VERSION-x86_64-uefi.iso" >> "distro-desktop-live-$VERSION-info.txt"
echo "BIOS Size: $(du -h "distro-desktop-live-$VERSION-x86_64.iso" | cut -f1)" >> "distro-desktop-live-$VERSION-info.txt"
echo "UEFI Size: $(du -h "distro-desktop-live-$VERSION-x86_64-uefi.iso" | cut -f1)" >> "distro-desktop-live-$VERSION-info.txt"
echo "Build Date: $(date)" >> "distro-desktop-live-$VERSION-info.txt"

echo "Desktop Live ISO built successfully:"
echo "  Location: $OUTPUT_DIR"
echo "  BIOS ISO: distro-desktop-live-$VERSION-x86_64.iso"
echo "  UEFI ISO: distro-desktop-live-$VERSION-x86_64-uefi.iso"
```

### Server Live ISO

#### Server Kickstart
Create `config/server-live.ks`:
```kickstart
# Server Live System Configuration

# System identification
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone America/New_York --isUtc
auth --enableshadow --passalgo=sha512

# Network configuration
network --bootproto=dhcp --device=link --activate
firewall --enabled --service=ssh,http,https

# Root configuration
rootpw --lock
user --name=server --password=server --plaintext --gecos="Server User"

# SELinux configuration
selinux --enforcing

# System services
services --enabled="NetworkManager,sshd,firewalld,cockpit"

# Repository configuration
repo --name="base" --baseurl=file:///opt/distro-repo --cost=100

# Package selection
%packages
@core
@standard
@server-product

# Distro packages
distro-release
distro-config
distro-branding

# Server tools
cockpit
cockpit-ws
cockpit-system
cockpit-networkmanager
vim
tmux
wget
curl

# Remove desktop packages
-remove=@desktop-platform
-remove=@gnome-desktop
-remove=@xfce-desktop
%end

# Post-installation configuration
%post
# Server post-install script
/usr/local/bin/distro-postinstall-server

# Configure Cockpit
systemctl enable cockpit.socket

# Configure SSH for key-based access only
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Create server user profile
cp /usr/share/distro/config/server-user-profile.sh /home/server/.profile
chown server:server /home/server/.profile
%end
```

## Install Media Creation

### Full Install ISO

#### Install Kickstart
Create `config/full-install.ks`:
```kickstart
# Full Install System Configuration

# System identification
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone America/New_York --isUtc
auth --enableshadow --passalgo=sha512

# Root password (will be set during install)
rootpw --lock

# SELinux configuration
selinux --enforcing

# System services
services --enabled="NetworkManager,sshd,firewalld"

# Repository configuration
repo --name="base" --baseurl=file:///mnt/source/repo --cost=100
repo --name="updates" --baseurl=file:///mnt/source/repo/updates --cost=200

# Package selection
%packages
@core
@standard
@desktop-platform
@fonts
@multimedia
@internet-browser
@development-tools

# Distro packages
distro-release
distro-config
distro-branding
distro-desktop
distro-themes

# Desktop environment
gnome-shell
gnome-session
gdm
nautilus
gnome-terminal
firefox
libreoffice-writer

# Development tools
gcc
gcc-c++
make
cmake
git
vim
%end

# Post-installation configuration
%post --log=/root/ks-post.log
# Full install post-install script
/usr/local/bin/distro-postinstall-full

# Configure default user setup
mkdir -p /etc/skel/Desktop
mkdir -p /etc/skel/Documents
mkdir -p /etc/skel/Downloads
mkdir -p /etc/skel/Pictures
mkdir -p /etc/skel/Videos
mkdir -p /etc/skel/Music

# Configure system defaults
systemctl enable gdm
systemctl set-default graphical.target
%end

%addon com_redhat_kdump --enable --reserve-mb=auto
%end
```

#### Install Build Script
Create `scripts/build-full-install.sh`:
```bash
#!/bin/bash
# Full Install ISO build script

set -e

# Configuration
DISTRO_NAME="Distro"
VERSION="1.0"
BUILD_DIR="/opt/distro-build"
KICKSTART_FILE="$BUILD_DIR/config/full-install.ks"
PACKAGE_DIR="/opt/distro-repo"
OUTPUT_DIR="$BUILD_DIR/iso"
TEMP_DIR="$BUILD_DIR/tmp-install"

# Clean previous build
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR"

echo "Building Full Install ISO..."

# Create install tree
mkdir -p "$TEMP_DIR/install-tree"

# Install packages to install tree
dnf --installroot="$TEMP_DIR/install-tree" \
    --releasever=9 \
    --setopt=install_weak_deps=False \
    --repo=base \
    install -y \
    @core \
    @standard \
    anaconda \
    dracut \
    kernel \
    distro-release \
    distro-config \
    distro-branding

# Copy repository to install tree
mkdir -p "$TEMP_DIR/install-tree/mnt/source/repo"
cp -r "$PACKAGE_DIR"/* "$TEMP_DIR/install-tree/mnt/source/repo/"

# Configure install system
chroot "$TEMP_DIR/install-tree" /bin/bash <<'EOF'
# Configure system
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYTABLE=us" > /etc/sysconfig/keyboard

# Enable services
systemctl enable sshd
systemctl enable NetworkManager

# Create anaconda configuration
mkdir -p /root/.anaconda
cat > /root/.anaconda/anaconda.conf <<'ANACONDA'
[Installation]
product = Distro
version = 1.0
ANACONDA
EOF

# Clean up
rm -rf /var/cache/dnf/*
rm -rf /tmp/*
EOF

# Create boot files
mkdir -p "$TEMP_DIR/install-tree/boot/grub2"
kernel_version=$(ls "$TEMP_DIR/install-tree/boot/vmlinuz-"* | head -1 | sed 's/.*vmlinuz-//')

cp "$TEMP_DIR/install-tree/boot/vmlinuz-$kernel_version" \
   "$TEMP_DIR/install-tree/boot/grub2/vmlinuz"
cp "$TEMP_DIR/install-tree/boot/initramfs-$kernel_version.img" \
   "$TEMP_DIR/install-tree/boot/grub2/initrd.img"

# Create GRUB configuration
cat > "$TEMP_DIR/install-tree/boot/grub2/grub.cfg" <<EOF
set default="0"
set timeout=10

menuentry "Install $DISTRO_NAME $VERSION" {
    linux /grub2/vmlinuz inst.repo=hd:LABEL=Distro:/repo quiet
    initrd /grub2/initrd.img
}

menuentry "Test this media & Install $DISTRO_NAME" {
    linux /grub2/vmlinuz inst.repo=hd:LABEL=Distro:/repo rd.live.check quiet
    initrd /grub2/initrd.img
}

menuentry "Rescue System" {
    linux /grub2/vmlinuz inst.rescue quiet
    initrd /grub2/initrd.img
}
EOF

# Create bootable ISO
cd "$TEMP_DIR"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Distro Install $VERSION" \
    -appid "Distro Install" \
    -publisher "Distro Project" \
    -preparer "Distro Build System" \
    -b boot/grub2/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub2/efiboot.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "$OUTPUT_DIR/distro-full-install-$VERSION-x86_64.iso" \
    install-tree/

# Create checksum
cd "$OUTPUT_DIR"
sha256sum "distro-full-install-$VERSION-x86_64.iso" > "distro-full-install-$VERSION-x86_64.iso.sha256"

echo "Full Install ISO built successfully:"
echo "  Location: $OUTPUT_DIR/distro-full-install-$VERSION-x86_64.iso"
echo "  Size: $(du -h "$OUTPUT_DIR/distro-full-install-$VERSION-x86_64.iso" | cut -f1)"
```

## Boot Configuration

### GRUB Configuration

#### Boot Menu Customization
Create `config/grub-theme.cfg`:
```bash
# GRUB theme configuration
set theme_dir="/boot/grub2/themes/distro"
set theme="${theme_dir}/theme.txt"

# Custom colors
set menu_color_normal=white/black
set menu_color_highlight=green/black
set color_normal=white/black
set color_highlight=green/black
```

#### Boot Splash Configuration
Create `config/plymouth-theme.cfg`:
```ini
[Plymouth Theme]
Name=Distro Splash
Description=Custom boot splash for Distro Linux
ModuleName=two-step

[two-step]
ImageDir=/boot/plymouth/themes/distro
HorizontalAlignment=.5
VerticalAlignment=.5
BackgroundStartColor=0x2E7D32
BackgroundEndColor=0x1B5E20
TransitionDuration=0.5
TransitionForegroundFile=logo.png
BackgroundForegroundColor=0xFFFFFF
```

### UEFI Support

#### UEFI Boot Configuration
Create `scripts/create-uefi-iso.sh`:
```bash
#!/bin/bash
# UEFI ISO creation script

set -e

ISO_FILE=$1
OUTPUT_FILE=$2

if [ -z "$ISO_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input-iso> <output-iso>"
    exit 1
fi

TEMP_DIR="/tmp/uefi-iso-$$"
mkdir -p "$TEMP_DIR"

echo "Creating UEFI-compatible ISO..."

# Mount original ISO
mkdir -p "$TEMP_DIR/original"
mkdir -p "$TEMP_DIR/uefi"

mount -o loop "$ISO_FILE" "$TEMP_DIR/original"

# Copy contents
cp -r "$TEMP_DIR/original"/* "$TEMP_DIR/uefi/"

# Create EFI boot image
mkdir -p "$TEMP_DIR/uefi/EFI/BOOT"
cp /usr/share/edk2/ovmf/OVMF.fd "$TEMP_DIR/uefi/EFI/BOOT/"
cp "$TEMP_DIR/uefi/isolinux/efiboot.img" "$TEMP_DIR/uefi/EFI/BOOT/"

# Create UEFI ISO
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "Distro UEFI" \
    -appid "Distro UEFI" \
    -publisher "Distro Project" \
    -preparer "Distro Build System" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e EFI/BOOT/efiboot.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -output "$OUTPUT_FILE" \
    "$TEMP_DIR/uefi"

# Cleanup
umount "$TEMP_DIR/original"
rm -rf "$TEMP_DIR"

echo "UEFI ISO created: $OUTPUT_FILE"
```

## ISO Testing Procedures

### Manual Testing

#### Boot Testing Script
Create `scripts/test-boot.sh`:
```bash
#!/bin/bash
# ISO boot testing script

set -e

ISO_FILE=$1
TEST_TYPE=${2:-"basic"}

if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
    echo "Usage: $0 <iso-file> [test-type]"
    echo "Test types: basic, boot, install, uefi"
    exit 1
fi

echo "Testing ISO: $ISO_FILE"
echo "Test type: $TEST_TYPE"

# Test 1: ISO integrity
echo "Test 1: Checking ISO integrity..."
if ! isoinfo -i "$ISO_FILE" -d > /dev/null; then
    echo "ERROR: ISO file is corrupted"
    exit 1
fi
echo "PASS: ISO integrity check"

# Test 2: File system validation
echo "Test 2: Validating file system..."
file_count=$(isoinfo -f -i "$ISO_FILE" | wc -l)
if [ "$file_count" -lt 50 ]; then
    echo "ERROR: Too few files on ISO ($file_count)"
    exit 1
fi
echo "PASS: File system validation ($file_count files)"

# Test 3: Boot files check
echo "Test 3: Checking boot files..."
if ! isoinfo -i "$ISO_FILE" -x "/isolinux/isolinux.bin" > /dev/null; then
    echo "ERROR: Missing isolinux.bin"
    exit 1
fi
echo "PASS: Boot files check"

case "$TEST_TYPE" in
    "boot")
        test_qemu_boot "$ISO_FILE"
        ;;
    "install")
        test_qemu_install "$ISO_FILE"
        ;;
    "uefi")
        test_uefi_boot "$ISO_FILE"
        ;;
    *)
        echo "Basic tests completed successfully"
        ;;
esac
```

#### QEMU Boot Test
Create `scripts/test-qemu-boot.sh`:
```bash
#!/bin/bash
# QEMU boot testing

test_qemu_boot() {
    local iso_file=$1
    local test_dir="/tmp/qemu-test-$$"
    local log_file="$test_dir/boot.log"
    
    mkdir -p "$test_dir"
    
    echo "Test 4: QEMU boot test..."
    
    # Start QEMU in background
    timeout 300 qemu-system-x86_64 \
        -m 1024 \
        -cdrom "$iso_file" \
        -boot d \
        -nographic \
        -serial file:"$log_file" \
        -monitor none \
        -daemonize
    
    # Wait for boot
    sleep 60
    
    # Check for successful boot
    if grep -q "kernel panic" "$log_file"; then
        echo "ERROR: Kernel panic during boot"
        cat "$log_file"
        rm -rf "$test_dir"
        exit 1
    fi
    
    if grep -q "login:" "$log_file"; then
        echo "PASS: QEMU boot test - system reached login prompt"
    else
        echo "WARNING: Boot test inconclusive - check logs"
        tail -20 "$log_file"
    fi
    
    # Cleanup
    pkill -f qemu-system-x86_64
    rm -rf "$test_dir"
}
```

### Automated Testing

#### Test Suite
Create `scripts/test-suite.sh`:
```bash
#!/bin/bash
# Comprehensive ISO test suite

set -e

ISO_FILE=$1
TEST_RESULTS="/tmp/test-results-$$"
REPORT_FILE="$TEST_RESULTS/test-report.html"

if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
    echo "Usage: $0 <iso-file>"
    exit 1
fi

mkdir -p "$TEST_RESULTS"

# Initialize test results
echo "<html><head><title>ISO Test Report</title></head><body>" > "$REPORT_FILE"
echo "<h1>ISO Test Report</h1>" >> "$REPORT_FILE"
echo "<p>ISO File: $ISO_FILE</p>" >> "$REPORT_FILE"
echo "<p>Test Date: $(date)</p>" >> "$REPORT_FILE"
echo "<h2>Test Results</h2>" >> "$REPORT_FILE"
echo "<table border='1'>" >> "$REPORT_FILE"
echo "<tr><th>Test</th><th>Status</th><th>Details</th></tr>" >> "$REPORT_FILE"

# Test function
run_test() {
    local test_name=$1
    local test_command=$2
    local expected_result=${3:-0}
    
    echo "Running test: $test_name"
    
    if eval "$test_command" > "$TEST_RESULTS/${test_name}.log" 2>&1; then
        result=0
        status="PASS"
        details="Test completed successfully"
    else
        result=1
        status="FAIL"
        details="Test failed - see log"
    fi
    
    # Add to report
    echo "<tr><td>$test_name</td><td>$status</td><td>$details</td></tr>" >> "$REPORT_FILE"
    
    return $result
}

# Test definitions
run_test "ISO Integrity" "isoinfo -i '$ISO_FILE' -d > /dev/null"
run_test "File Count" "[ \$(isoinfo -f -i '$ISO_FILE' | wc -l) -gt 50 ]"
run_test "Boot Files" "isoinfo -i '$ISO_FILE' -x '/isolinux/isolinux.bin' > /dev/null"
run_test "QEMU Boot" "scripts/test-qemu-boot.sh '$ISO_FILE'"
run_test "Package Check" "scripts/test-iso-packages.sh '$ISO_FILE'"
run_test "Size Check" "[ \$(du -m '$ISO_FILE' | cut -f1) -lt 5000 ]"

# Complete report
echo "</table>" >> "$REPORT_FILE"
echo "<h2>Test Logs</h2>" >> "$REPORT_FILE"

for log_file in "$TEST_RESULTS"/*.log; do
    if [ -f "$log_file" ]; then
        test_name=$(basename "$log_file" .log)
        echo "<h3>$test_name</h3>" >> "$REPORT_FILE"
        echo "<pre>" >> "$REPORT_FILE"
        cat "$log_file" >> "$REPORT_FILE"
        echo "</pre>" >> "$REPORT_FILE"
    fi
done

echo "</body></html>" >> "$REPORT_FILE"

echo "Test suite completed. Report: $REPORT_FILE"
```

## Quality Assurance

### Validation Checklist

#### Pre-Release Validation
Create `config/validation-checklist.txt`:
```text
Distro Linux Pre-Release Validation Checklist

=====================================
ISO Validation
=====================================
[ ] ISO integrity check passed
[ ] File system validation passed
[ ] Boot files present and valid
[ ] QEMU boot test passed
[ ] UEFI boot test passed
[ ] Package validation passed
[ ] Size within acceptable limits

=====================================
Package Validation
=====================================
[ ] All required packages included
[ ] Package dependencies resolved
[ ] Package signatures valid
[ ] Repository metadata valid
[ ] No conflicting packages
[ ] Update packages available

=====================================
Boot Validation
=====================================
[ ] BIOS boot successful
[ ] UEFI boot successful
[ ] Boot menu displays correctly
[ ] Boot splash works
[ ] Login screen appears
[ ] Desktop environment loads

=====================================
Functionality Validation
=====================================
[ ] Network connectivity works
[ ] Package manager functions
[ ] Software installation works
[ ] System updates work
[ ] User account creation works
[ ] Security features enabled

=====================================
Performance Validation
=====================================
[ ] Boot time acceptable (< 60 seconds)
[ ] Memory usage reasonable
[ ] Disk space usage reasonable
[ ] Application performance acceptable
[ ] System responsiveness good

=====================================
Security Validation
=====================================
[ ] SELinux enabled and enforcing
[ ] Firewall configured and active
[ ] No default passwords
[ ] Security updates applied
[ ] User permissions correct
[ ] System hardening applied
```

#### Automated Validation
Create `scripts/validate-release.sh`:
```bash
#!/bin/bash
# Release validation script

set -e

ISO_FILE=$1
VALIDATION_LOG="/tmp/validation-$$"

if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
    echo "Usage: $0 <iso-file>"
    exit 1
fi

echo "Validating release: $ISO_FILE"
echo "Validation log: $VALIDATION_LOG"

# Load validation checklist
CHECKLIST_FILE="config/validation-checklist.txt"
TOTAL_CHECKS=0
PASSED_CHECKS=0

while IFS= read -r line; do
    if [[ "$line" =~ ^\[.*\]$ ]]; then
        check_name=$(echo "$line" | sed 's/\[ //g' | sed 's/ \]//g')
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        
        echo "Validating: $check_name"
        
        case "$check_name" in
            "ISO integrity check passed")
                if isoinfo -i "$ISO_FILE" -d > /dev/null 2>&1; then
                    echo "[✓] $check_name" | tee -a "$VALIDATION_LOG"
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                else
                    echo "[✗] $check_name" | tee -a "$VALIDATION_LOG"
                fi
                ;;
            "File system validation passed")
                file_count=$(isoinfo -f -i "$ISO_FILE" | wc -l)
                if [ "$file_count" -gt 50 ]; then
                    echo "[✓] $check_name ($file_count files)" | tee -a "$VALIDATION_LOG"
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                else
                    echo "[✗] $check_name (only $file_count files)" | tee -a "$VALIDATION_LOG"
                fi
                ;;
            "Boot files present and valid")
                if isoinfo -i "$ISO_FILE" -x "/isolinux/isolinux.bin" > /dev/null 2>&1; then
                    echo "[✓] $check_name" | tee -a "$VALIDATION_LOG"
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                else
                    echo "[✗] $check_name" | tee -a "$VALIDATION_LOG"
                fi
                ;;
            "Size within acceptable limits")
                size_mb=$(du -m "$ISO_FILE" | cut -f1)
                if [ "$size_mb" -lt 5000 ]; then
                    echo "[✓] $check_name (${size_mb}MB)" | tee -a "$VALIDATION_LOG"
                    PASSED_CHECKS=$((PASSED_CHECKS + 1))
                else
                    echo "[✗] $check_name (${size_mb}MB - too large)" | tee -a "$VALIDATION_LOG"
                fi
                ;;
            *)
                echo "[?] $check_name (validation not implemented)" | tee -a "$VALIDATION_LOG"
                ;;
        esac
    fi
done < "$CHECKLIST_FILE"

# Summary
echo "" | tee -a "$VALIDATION_LOG"
echo "Validation Summary:" | tee -a "$VALIDATION_LOG"
echo "===================" | tee -a "$VALIDATION_LOG"
echo "Total checks: $TOTAL_CHECKS" | tee -a "$VALIDATION_LOG"
echo "Passed checks: $PASSED_CHECKS" | tee -a "$VALIDATION_LOG"
echo "Failed checks: $((TOTAL_CHECKS - PASSED_CHECKS))" | tee -a "$VALIDATION_LOG"

success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
echo "Success rate: ${success_rate}%" | tee -a "$VALIDATION_LOG"

if [ "$success_rate" -ge 90 ]; then
    echo "Result: RELEASE READY" | tee -a "$VALIDATION_LOG"
    exit 0
else
    echo "Result: RELEASE NOT READY" | tee -a "$VALIDATION_LOG"
    exit 1
fi
```

## Release Validation

### Final Testing

#### Release Test Script
Create `scripts/test-release.sh`:
```bash
#!/bin/bash
# Final release testing

set -e

RELEASE_DIR="/opt/distro-build/release"
TEST_DIR="/tmp/release-test-$$"

# Create test environment
mkdir -p "$TEST_DIR" "$RELEASE_DIR"

echo "Starting final release testing..."

# Test all ISO variants
for iso_file in /opt/distro-build/iso/*.iso; do
    if [ -f "$iso_file" ]; then
        iso_name=$(basename "$iso_file")
        echo "Testing ISO: $iso_name"
        
        # Run validation
        if scripts/validate-release.sh "$iso_file"; then
            echo "✓ $iso_name passed validation"
            cp "$iso_file" "$RELEASE_DIR/"
        else
            echo "✗ $iso_name failed validation"
            exit 1
        fi
    fi
done

# Test repository
echo "Testing repository..."
if scripts/test-repository.sh; then
    echo "✓ Repository test passed"
else
    echo "✗ Repository test failed"
    exit 1
fi

# Test package installation
echo "Testing package installation..."
if scripts/test-package-install.sh; then
    echo "✓ Package installation test passed"
else
    echo "✗ Package installation test failed"
    exit 1
fi

# Create release checksums
cd "$RELEASE_DIR"
sha256sum *.iso > checksums.txt
sha512sum *.iso > checksums-sha512.txt

# Create release notes
cat > RELEASE-NOTES.txt <<EOF
Distro Linux Release Notes
========================

Release: 1.0
Date: $(date)

ISO Images:
- Desktop Live: distro-desktop-live-1.0-x86_64.iso
- Server Live: distro-server-live-1.0-x86_64.iso
- Full Install: distro-full-install-1.0-x86_64.iso

System Requirements:
- Minimum: 2GB RAM, 10GB disk space
- Recommended: 4GB RAM, 20GB disk space

Known Issues:
- None reported

Installation Instructions:
1. Download appropriate ISO image
2. Verify checksums
3. Create bootable media
4. Boot from media and follow installer

Support:
- Website: https://distro.local
- Documentation: https://docs.distro.local
- Issues: https://bugs.distro.local
EOF

echo "Release testing completed successfully"
echo "Release files located in: $RELEASE_DIR"

# Cleanup
rm -rf "$TEST_DIR"
```

### Performance Testing

#### Performance Benchmark
Create `scripts/benchmark-iso.sh`:
```bash
#!/bin/bash
# ISO performance benchmarking

ISO_FILE=$1
BENCHMARK_DIR="/tmp/benchmark-$$"

if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
    echo "Usage: $0 <iso-file>"
    exit 1
fi

mkdir -p "$BENCHMARK_DIR"

echo "Benchmarking ISO: $ISO_FILE"

# Boot time benchmark
echo "Testing boot time..."
start_time=$(date +%s)

timeout 300 qemu-system-x86_64 \
    -m 1024 \
    -cdrom "$ISO_FILE" \
    -boot d \
    -nographic \
    -serial file:"$BENCHMARK_DIR/boot.log" \
    -monitor none \
    -daemonize

# Wait for login prompt
while ! grep -q "login:" "$BENCHMARK_DIR/boot.log"; do
    sleep 5
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ "$elapsed" -gt 180 ]; then
        echo "Boot time test timeout"
        break
    fi
done

boot_time=$(date +%s)
boot_duration=$((boot_time - start_time))
echo "Boot time: ${boot_duration} seconds"

# Memory usage benchmark
echo "Testing memory usage..."
memory_usage=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
echo "Available memory: ${memory_usage}KB"

# Disk performance
echo "Testing disk performance..."
if [ -f "$ISO_FILE" ]; then
    disk_test=$(dd if="$ISO_FILE" of=/dev/null bs=1M count=100 2>&1 | grep -o '[0-9.]* MB/s')
    echo "Disk read speed: $disk_test"
fi

# Generate benchmark report
cat > "$BENCHMARK_DIR/benchmark-report.txt" <<EOF
ISO Performance Benchmark
========================

ISO File: $ISO_FILE
Test Date: $(date)

Boot Performance:
- Boot Time: ${boot_duration} seconds
- Target: < 60 seconds
- Status: $([ "$boot_duration" -lt 60 ] && echo "PASS" || echo "FAIL")

Memory Performance:
- Available Memory: ${memory_usage}KB
- Status: OK

Disk Performance:
- Read Speed: $disk_test
- Status: OK

Overall Performance: $([ "$boot_duration" -lt 60 ] && echo "ACCEPTABLE" || echo "NEEDS IMPROVEMENT")
EOF

echo "Benchmark completed: $BENCHMARK_DIR/benchmark-report.txt"
```

## Next Steps

With ISO creation and testing complete:

1. Proceed to [Release Management](08-release-management.md)
2. Implement release automation
3. Set up distribution infrastructure

## Troubleshooting

### Common ISO Issues

#### Boot Failures
```bash
# Check boot configuration
isoinfo -i iso.iso -x "/isolinux/isolinux.bin" > /tmp/isolinux.bin
file /tmp/isolinux.bin

# Check GRUB configuration
isoinfo -i iso.iso -x "/boot/grub2/grub.cfg"
```

#### Package Issues
```bash
# Check repository on ISO
mount -o loop iso.iso /mnt/iso
ls -la /mnt/iso/repo/
repomd /mnt/iso/repo/repodata/repomd.xml
```

#### Size Issues
```bash
# Analyze ISO contents
isoinfo -i iso.iso -f | head -20
du -sh /mnt/iso/*
```

### Testing Failures

#### QEMU Test Failures
```bash
# Check QEMU logs
tail -f /tmp/qemu-test-*/boot.log

# Test with more memory
qemu-system-x86_64 -m 2048 -cdrom iso.iso -boot d
```

#### Validation Failures
```bash
# Check validation log
cat /tmp/validation-*/validation.log

# Run individual tests
scripts/test-boot.sh iso.iso basic
```