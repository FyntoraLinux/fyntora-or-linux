#!/bin/bash
# FyntoraLinux Independence Builder - Master Installation Script
# This script automatically configures and installs all components for building an independent Linux distribution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DISTRO_NAME="FyntoraLinux"
DISTRO_ID="fyntora"
BUILD_DIR="/opt/$DISTRO_ID"
SCRIPT_DIR="/usr/local/bin"
CONFIG_DIR="/etc/$DISTRO_ID"
SERVICE_DIR="/etc/systemd/system"

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    mkdir -p "$BUILD_DIR"/{sources,packages,iso,config,branding,logs,tmp}
    mkdir -p "$CONFIG_DIR"/{gpg,branding,scripts}
    mkdir -p "/var/www/html/$DISTRO_ID-repo"
    mkdir -p "/var/log/$DISTRO_ID"
    mkdir -p "/usr/share/$DISTRO_ID"/{themes,backgrounds,icons,docs}
    mkdir -p "/boot/grub2/themes/$DISTRO_ID"
    mkdir -p "/boot/plymouth/themes/$DISTRO_ID"
    mkdir -p "/usr/share/gnome-shell/theme/$DISTRO_ID"
    mkdir -p "/usr/share/themes/$DISTRO_ID/gtk-3.0"
    
    # Set permissions
    chown -R root:root "$BUILD_DIR"
    chmod 755 "$BUILD_DIR"
    
    print_success "Directory structure created"
}

# Install required packages
install_packages() {
    print_status "Installing required packages..."
    
    dnf update -y
    dnf groupinstall -y "Development Tools"
    dnf install -y \
        git \
        rpm-build \
        createrepo \
        mock \
        syslinux \
        xorriso \
        grub2-tools \
        lorax \
        plymouth \
        plymouth-theme-spinner \
        gnome-shell \
        gnome-session \
        gdm \
        nautilus \
        gnome-terminal \
        firefox \
        gimp \
        inkscape \
        ansible \
        python3 \
        python3-pip \
        vim \
        htop \
        tree \
        lsof \
        strace \
        tcpdump \
        wireshark \
        nmap \
        curl \
        wget \
        rsync
    
    print_success "Required packages installed"
}

# Create build user
create_build_user() {
    print_status "Creating build user..."
    
    if ! id "$DISTRO_ID" &>/dev/null; then
        useradd -m -s /bin/bash "$DISTRO_ID"
        usermod -aG mock,wheel "$DISTRO_ID"
        
        # Create rpmbuild directory for build user
        mkdir -p "/home/$DISTRO_ID/rpmbuild"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
        chown -R "$DISTRO_ID:$DISTRO_ID" "/home/$DISTRO_ID/rpmbuild"
        
        print_success "Build user '$DISTRO_ID' created"
    else
        print_warning "Build user '$DISTRO_ID' already exists"
    fi
}

# Create mock configuration
create_mock_config() {
    print_status "Creating mock configuration..."
    
    cat > "/etc/mock/$DISTRO_ID.cfg" <<EOF
config_opts['root'] = '$DISTRO_ID'
config_opts['target_arch'] = 'x86_64'
config_opts['legal_host_arches'] = ('x86_64',)
config_opts['chroot_setup_cmd'] = 'install @buildsys-build'
config_opts['dist'] = '$DISTRO_ID'
config_opts['releasever'] = '1'
config_opts['package_manager'] = 'dnf'
config_opts['use_bootstrap'] = True

config_opts['yum.conf'] = """
[main]
keepcache=1
gpgcheck=0
debuglevel=2
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=

[oracle-baseos]
name=Oracle Linux BaseOS
baseurl=https://yum.oracle.com/repo/OracleLinux/ol9/baseos/latest/x86_64/
enabled=1
gpgcheck=0

[oracle-appstream]
name=Oracle Linux AppStream
baseurl=https://yum.oracle.com/repo/OracleLinux/ol9/appstream/latest/x86_64/
enabled=1
gpgcheck=0

[$DISTRO_ID-local]
name=$DISTRO_ID Local Repository
baseurl=file://$BUILD_DIR/packages
enabled=1
gpgcheck=0
"""
EOF
    
    print_success "Mock configuration created"
}

# Create identity files
create_identity_files() {
    print_status "Creating identity files..."
    
    # Main release file
    cat > "/etc/$DISTRO_ID-release" <<EOF
$DISTRO_NAME 1.0
EOF
    
    # os-release
    cat > "/etc/os-release" <<EOF
NAME="$DISTRO_NAME"
VERSION="1.0"
ID="$DISTRO_ID"
ID_LIKE="rhel fedora"
VERSION_ID="1.0"
PRETTY_NAME="$DISTRO_NAME 1.0"
HOME_URL="https://$DISTRO_ID.org"
SUPPORT_URL="https://support.$DISTRO_ID.org"
BUG_REPORT_URL="https://bugs.$DISTRO_ID.org"
EOF
    
    # lsb-release
    cat > "/etc/lsb-release" <<EOF
DISTRIB_ID=$DISTRO_NAME
DISTRIB_DESCRIPTION="$DISTRO_NAME 1.0"
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=independence
EOF
    
    # Custom motd
    cat > "/etc/motd" <<EOF
 _____ _ _ _   _    _    _   _ 
| ____| | | | | / \  | |  | | | |
|  _| | | | |/ _ \ | |  | | | | |
| |___|_| | / ___ \| |  | | | | | |
|_____|_|_|_/_/   \_\_|  |_| |_| |_|_|
                                     
$DISTRO_NAME 1.0 - Independence Edition
Type 'fyntora-help' for assistance.
EOF
    
    print_success "Identity files created"
}

# Create main scripts
create_main_scripts() {
    print_status "Creating main scripts..."
    
    # Main build script
    cat > "$SCRIPT_DIR/build-$DISTRO_ID.sh" <<'EOF'
#!/bin/bash
# Main build script for FyntoraLinux

set -e

DISTRO_NAME="FyntoraLinux"
DISTRO_ID="fyntora"
BUILD_DIR="/opt/fyntora"
SOURCE_DIR="$BUILD_DIR/sources"
PACKAGE_DIR="$BUILD_DIR/packages"
ISO_DIR="$BUILD_DIR/iso"
LOG_DIR="$BUILD_DIR/logs"

# Create build environment
mkdir -p "$BUILD_DIR" "$SOURCE_DIR" "$PACKAGE_DIR" "$ISO_DIR" "$LOG_DIR"

# Build all packages
build_packages() {
    echo "Building $DISTRO_NAME packages..."
    
    # Core packages
    for spec in "$SOURCE_DIR"/core/*.spec; do
        if [ -f "$spec" ]; then
            package=$(basename "$spec" .spec)
            echo "Building $package..."
            mock -r fyntora --build "$spec" --resultdir="$PACKAGE_DIR/RPMS/"
        fi
    done
    
    # Desktop packages
    for spec in "$SOURCE_DIR"/desktop/*.spec; do
        if [ -f "$spec" ]; then
            package=$(basename "$spec" .spec)
            echo "Building $package..."
            mock -r fyntora --build "$spec" --resultdir="$PACKAGE_DIR/RPMS/"
        fi
    done
    
    # Update repository
    createrepo --update "$PACKAGE_DIR"
}

# Build ISO
build_iso() {
    echo "Building $DISTRO_NAME ISO..."
    
    # Create kickstart file
    cat > "$BUILD_DIR/fyntora-live.ks" <<'KICKSTART'
# FyntoraLinux Live System
lang en_US.UTF-8
keyboard --vckeymap=us
timezone America/New_York
auth --enableshadow --passalgo=sha512
rootpw --lock
user --name=fyntora --password=fyntora --plaintext

services --enabled="NetworkManager,sshd,firewalld,gdm"

%packages
@core
@standard
@desktop-platform
@guest-desktop-agents
fyntora-release
fyntora-config
fyntora-branding
gnome-shell
gnome-session
gdm
nautilus
gnome-terminal
firefox
%end

%post
# FyntoraLinux post-install
/usr/local/bin/fyntora-postinstall
%end
KICKSTART
    
    # Build live ISO
    lorax -p "FyntoraLinux-Live" \
        -v "1.0" \
        -r 9 \
        -t "$BUILD_DIR/tmp" \
        -c "$BUILD_DIR/fyntora-live.ks" \
        --buildarch=x86_64 \
        "$BUILD_DIR/live-result"
    
    # Create bootable ISO
    cd "$BUILD_DIR/live-result"
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "FyntoraLinux Live 1.0" \
        -appid "FyntoraLinux Live" \
        -publisher "FyntoraLinux Project" \
        -eltorito-boot images/boot.iso \
        -eltorito-catalog boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -output "$ISO_DIR/fyntora-live-1.0-x86_64.iso" \
        .
}

# Main execution
case "$1" in
    "packages")
        build_packages
        ;;
    "iso")
        build_iso
        ;;
    "all")
        build_packages
        build_iso
        ;;
    *)
        echo "Usage: $0 {packages|iso|all}"
        exit 1
        ;;
esac
EOF

    # Independence achievement script
    cat > "$SCRIPT_DIR/achieve-independence.sh" <<'EOF'
#!/bin/bash
# Complete independence achievement script

set -e

echo "=== ACHIEVING COMPLETE INDEPENDENCE ==="

# Step 1: Remove all Oracle branding
echo "Step 1: Removing Oracle branding..."
/usr/local/bin/remove-oracle-branding.sh

# Step 2: Complete system rebranding
echo "Step 2: Complete system rebranding..."
/usr/local/bin/complete-rebrand.sh

# Step 3: Setup independent infrastructure
echo "Step 3: Setting up independent infrastructure..."
/usr/local/bin/setup-fyntora-signing.sh

# Step 4: Build independent packages
echo "Step 4: Building independent packages..."
/usr/local/bin/build-fyntora.sh packages

# Step 5: Sign packages
echo "Step 5: Signing packages..."
/usr/local/bin/sign-fyntora-packages.sh

# Step 6: Create independent ISO
echo "Step 6: Creating independent ISO..."
/usr/local/bin/build-fyntora.sh iso

# Step 7: Setup update system
echo "Step 7: Setting up update system..."
systemctl enable fyntora-update-manager

# Step 8: Final cleanup
echo "Step 8: Final cleanup..."
dnf autoremove -y
dnf clean all

# Step 9: Generate independence report
cat > /etc/fyntora-independence.txt <<REPORT
FyntoraLinux Independence Report
=====================================

Achieved: $(date)
Base System: Independent from Oracle Linux
Package Repository: https://repo.fyntora.org
Update System: fyntora-update-manager
Build System: /usr/local/bin/build-fyntora.sh
Signing Key: $(gpg --list-keys --with-colons | grep '^pub:' | cut -d: -f5)

Independence Level: 100%
Oracle Dependencies: None
FyntoraLinux Packages: $(find /opt/fyntora/packages -name "*.rpm" | wc -l)
Custom Services: $(systemctl list-units | grep fyntora | wc -l)

This system is now completely independent.
REPORT

echo ""
echo "🎉 INDEPENDENCE ACHIEVED! 🎉"
echo "FyntoraLinux is now completely independent from Oracle Linux."
echo "Check /etc/fyntora-independence.txt for details."
echo ""
echo "Next steps:"
echo "1. Reboot to see all changes"
echo "2. Test the update system: fyntora-update-manager check"
echo "3. Build your custom ISO: build-fyntora.sh iso"
echo "4. Setup your mirror infrastructure"
echo ""
echo "Welcome to independence! 🚀"
EOF

    # Update manager script
    cat > "$SCRIPT_DIR/$DISTRO_ID-update-manager" <<'EOF'
#!/bin/bash
# Custom update manager for FyntoraLinux

REPO_BASE="https://repo.fyntora.org"
GPG_KEY="/etc/pki/rpm-gpg/RPM-GPG-KEY-fyntora"
LOG_FILE="/var/log/fyntora-update.log"

check_updates() {
    echo "Checking for FyntoraLinux updates..."
    dnf check-update --repo=fyntora-*
}

apply_updates() {
    echo "Applying FyntoraLinux updates..."
    dnf update -y --repo=fyntora-* >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "Updates applied successfully"
        # Rebuild initramfs if kernel updated
        if rpm -qa kernel | grep -q "$(uname -r)"; then
            dracut -f
        fi
    else
        echo "Update failed. Check $LOG_FILE"
    fi
}

security_update() {
    echo "Applying security updates..."
    dnf update --security -y --repo=fyntora-updates >> "$LOG_FILE" 2>&1
}

list_available() {
    echo "Available updates:"
    dnf list updates --repo=fyntora-*
}

case "$1" in
    "check")
        check_updates
        ;;
    "update")
        apply_updates
        ;;
    "security")
        security_update
        ;;
    "list")
        list_available
        ;;
    *)
        echo "Usage: $0 {check|update|security|list}"
        exit 1
        ;;
esac
EOF

    # Help script
    cat > "$SCRIPT_DIR/$DISTRO_ID-help" <<'EOF'
#!/bin/bash
# Help system for FyntoraLinux

echo "FyntoraLinux Help System"
echo "============================"
echo ""
echo "Available Commands:"
echo "  build-fyntora.sh      - Build packages and ISO"
echo "  achieve-independence.sh  - Complete independence process"
echo "  fyntora-update-manager - Update system"
echo "  verify-independence.sh    - Verify independence status"
echo ""
echo "Configuration Files:"
echo "  /etc/fyntora/          - Main configuration"
echo "  /opt/fyntora/          - Build directory"
echo "  /var/log/fyntora/      - Log files"
echo ""
echo "Getting Started:"
echo "1. Run 'achieve-independence.sh' for complete setup"
echo "2. Use 'build-fyntora.sh all' to build everything"
echo "3. Test with 'fyntora-update-manager check'"
echo ""
echo "Documentation: /usr/share/fyntora/docs/"
echo "Support: https://support.fyntora.org"
EOF

    # Make scripts executable
    chmod +x "$SCRIPT_DIR/build-$DISTRO_ID.sh"
    chmod +x "$SCRIPT_DIR/achieve-independence.sh"
    chmod +x "$SCRIPT_DIR/$DISTRO_ID-update-manager"
    chmod +x "$SCRIPT_DIR/$DISTRO_ID-help"
    
    print_success "Main scripts created"
}

# Create branding removal scripts
create_branding_scripts() {
    print_status "Creating branding removal scripts..."
    
    # Oracle branding removal
    cat > "$SCRIPT_DIR/remove-oracle-branding.sh" <<'EOF'
#!/bin/bash
# Remove all Oracle branding

echo "Removing Oracle packages..."
dnf remove -y oraclelinux-release \
    oracle-logos \
    oracle-backgrounds \
    oracle-epel-release \
    kmod-oracle* 2>/dev/null || true

# Remove Oracle files
rm -f /etc/oracle-release
rm -f /etc/issue
rm -f /etc/issue.net

# Remove Oracle repositories
rm -f /etc/yum.repos.d/oracle-*.repo

# Clean Oracle directories
rm -rf /usr/share/oracle
rm -rf /etc/oracle

# Update all configuration files
find /etc -type f -exec sed -i 's/Oracle Linux/FyntoraLinux/g' {} \; 2>/dev/null || true
find /etc -type f -exec sed -i 's/oracle/fyntora/g' {} \; 2>/dev/null || true

# Rebuild initramfs without Oracle modules
dracut -f --regenerate-all

echo "Oracle branding removal completed"
EOF

    # Complete rebranding script
    cat > "$SCRIPT_DIR/complete-rebrand.sh" <<'EOF'
#!/bin/bash
# Complete system rebranding

echo "Starting complete system rebranding..."

# Update all system files
find /etc -type f -exec grep -l "Oracle" {} \; 2>/dev/null | while read file; do
    sed -i 's/Oracle/FyntoraLinux/g' "$file" 2>/dev/null || true
    sed -i 's/oracle/fyntora/g' "$file" 2>/dev/null || true
done

# Update GRUB
sed -i 's/Oracle Linux/FyntoraLinux/g' /etc/default/grub 2>/dev/null || true
grub2-mkconfig -o /boot/grub2/grub.cfg

# Update Plymouth
plymouth-set-default-theme fyntora 2>/dev/null || true
dracut -f

# Update desktop backgrounds
rm -f /usr/share/backgrounds/*oracle* 2>/dev/null || true
mkdir -p /usr/share/backgrounds/fyntora

# Update system logos
rm -f /usr/share/pixmaps/*oracle* 2>/dev/null || true

# Rebuild font cache
fc-cache -fv

# Update GTK icon cache
gtk-update-icon-cache -f -i /usr/share/icons/ 2>/dev/null || true

echo "Complete rebranding finished. Reboot to see changes."
EOF

    # Verification script
    cat > "$SCRIPT_DIR/verify-independence.sh" <<'EOF'
#!/bin/bash
# Verify independence status

echo "=== VERIFYING INDEPENDENCE ==="

# Check for Oracle remnants
oracle_count=$(find / -name "*oracle*" 2>/dev/null | wc -l)
echo "Oracle files found: $oracle_count"

# Check FyntoraLinux files
fyntora_count=$(find / -name "*fyntora*" 2>/dev/null | wc -l)
echo "FyntoraLinux files found: $fyntora_count"

# Check repositories
echo "Repository configuration:"
cat /etc/yum.repos.d/*.repo 2>/dev/null | grep -E "name|baseurl" | grep -v "#" || echo "No custom repos found"

# Check installed packages
echo "FyntoraLinux packages installed:"
rpm -qa | grep fyntora || echo "No FyntoraLinux packages installed"

# Check services
echo "FyntoraLinux services:"
systemctl list-units | grep fyntora || echo "No FyntoraLinux services found"

# Check branding
echo "System identity:"
cat /etc/os-release
cat /etc/fyntora-release

# Independence score
total_files=$(find / -type f 2>/dev/null | wc -l)
if [ "$total_files" -gt 0 ]; then
    independence_score=$(( (fyntora_count * 100) / total_files ))
else
    independence_score=0
fi

echo ""
echo "INDEPENDENCE SCORE: $independence_score%"
if [ "$independence_score" -gt 80 ]; then
    echo "✅ HIGH INDEPENDENCE ACHIEVED"
elif [ "$independence_score" -gt 50 ]; then
    echo "⚠️  MODERATE INDEPENDENCE"
else
    echo "❌ LOW INDEPENDENCE - MORE WORK NEEDED"
fi
EOF

    # Make scripts executable
    chmod +x "$SCRIPT_DIR/remove-oracle-branding.sh"
    chmod +x "$SCRIPT_DIR/complete-rebrand.sh"
    chmod +x "$SCRIPT_DIR/verify-independence.sh"
    
    print_success "Branding scripts created"
}

# Create GPG setup script
create_gpg_script() {
    print_status "Creating GPG setup script..."
    
    cat > "$SCRIPT_DIR/setup-$DISTRO_ID-signing.sh" <<'EOF'
#!/bin/bash
# Setup GPG signing infrastructure

GPG_DIR="/etc/fyntora/gpg"
mkdir -p "$GPG_DIR"
chmod 700 "$GPG_DIR"

echo "Generating GPG signing key..."
gpg --batch --homedir "$GPG_DIR" --gen-key <<KEY
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: FyntoraLinux Signing Key
Name-Email: signing@fyntora.org
Name-Comment: Official signing key for FyntoraLinux
Expire-Date: 5y
%commit
%echo done
KEY

# Get key ID
KEY_ID=$(gpg --homedir "$GPG_DIR" --list-secret-keys --with-colons | grep '^sec:' | cut -d: -f5)

# Export keys
gpg --homedir "$GPG_DIR" --armor --export "$KEY_ID" > "$GPG_DIR/public.key"
gpg --homedir "$GPG_DIR" --armor --export-secret-keys "$KEY_ID" > "$GPG_DIR/private.key"

# Create signing script
cat > /usr/local/bin/sign-fyntora-packages.sh <<SIGN
#!/bin/bash
GPG_DIR="$GPG_DIR"
KEY_ID="$KEY_ID"
PACKAGE_DIR="/opt/fyntora/packages"

# Sign all RPM packages
find "\$PACKAGE_DIR" -name "*.rpm" -type f | while read rpm_file; do
    echo "Signing: \$(basename "\$rpm_file")"
    rpmsign --addsign --key-id="\$KEY_ID" --homedir="\$GPG_DIR" "\$rpm_file"
done

# Sign repository metadata
cd "\$PACKAGE_DIR"
if [ -f "repodata/repomd.xml" ]; then
    gpg --homedir="\$GPG_DIR" --detach-sign --armor repodata/repomd.xml
fi

# Create GPG key file for repository
gpg --homedir="\$GPG_DIR" --armor --export "\$KEY_ID" > RPM-GPG-KEY-fyntora
SIGN

chmod +x /usr/local/bin/sign-fyntora-packages.sh

echo "GPG signing infrastructure setup completed"
echo "Key ID: $KEY_ID"
EOF

    chmod +x "$SCRIPT_DIR/setup-$DISTRO_ID-signing.sh"
    
    print_success "GPG setup script created"
}

# Create repository configuration
create_repository_config() {
    print_status "Creating repository configuration..."
    
    cat > "/etc/yum.repos.d/$DISTRO_ID.repo" <<EOF
[$DISTRO_ID-base]
name=$DISTRO_NAME Base Repository
baseurl=https://repo.$DISTRO_ID.org/base/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-$DISTRO_ID

[$DISTRO_ID-updates]
name=$DISTRO_NAME Updates Repository
baseurl=https://repo.$DISTRO_ID.org/updates/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-$DISTRO_ID

[$DISTRO_ID-testing]
name=$DISTRO_NAME Testing Repository
baseurl=https://repo.$DISTRO_ID.org/testing/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-$DISTRO_ID
EOF
    
    print_success "Repository configuration created"
}

# Create systemd services
create_systemd_services() {
    print_status "Creating systemd services..."
    
    # Welcome service
    cat > "$SERVICE_DIR/$DISTRO_ID-welcome.service" <<EOF
[Unit]
Description=$DISTRO_NAME Welcome Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/$DISTRO_ID-welcome
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Update manager service
    cat > "$SERVICE_DIR/$DISTRO_ID-update-manager.service" <<EOF
[Unit]
Description=$DISTRO_NAME Update Manager
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/$DISTRO_ID-update-manager check
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Build service
    cat > "$SERVICE_DIR/$DISTRO_ID-build.service" <<EOF
[Unit]
Description=$DISTRO_NAME Build Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/build-$DISTRO_ID.sh all
WorkingDirectory=$BUILD_DIR
User=$DISTRO_ID
Group=$DISTRO_ID

[Install]
WantedBy=multi-user.target
EOF
    
    print_success "Systemd services created"
}

# Create desktop customization
create_desktop_customization() {
    print_status "Creating desktop customization..."
    
    # GTK theme
    cat > "/usr/share/themes/$DISTRO_ID/gtk-3.0/gtk.css" <<'EOF'
/* FyntoraLinux GTK Theme */
@define-color primary #2E7D32;
@define-color secondary #4CAF50;
@define-color accent #1976D2;

* {
    font-family: "Inter", sans-serif;
}

.window {
    background-color: #FAFAFA;
    border: 1px solid #E0E0E0;
}

.button {
    background-color: @primary;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 8px 16px;
}

.button:hover {
    background-color: @secondary;
}

.entry {
    background-color: white;
    border: 2px solid #E0E0E0;
    border-radius: 4px;
    padding: 6px;
}

.entry:focus {
    border-color: @accent;
}
EOF

    # Theme index
    cat > "/usr/share/themes/$DISTRO_ID/index.theme" <<EOF
[Icon Theme]
Name=$DISTRO_NAME
Comment=$DISTRO_NAME Theme
Inherits=Adwaita

[Desktop Entry]
Name=$DISTRO_NAME
Comment=$DISTRO_NAME Theme
X-GNDE-Metatheme=$DISTRO_NAME
EOF

    # GNOME Shell theme
    mkdir -p "/usr/share/gnome-shell/theme/$DISTRO_ID"
    cat > "/usr/share/gnome-shell/theme/$DISTRO_ID/gnome-shell.css" <<'EOF
/* FyntoraLinux GNOME Shell Theme */
#lockDialogGroup {
    background-color: #2E7D32;
    background-image: url("resource:///org/gnome/shell/theme/background.jpg");
    background-size: cover;
}

.login-dialog {
    background-color: rgba(255, 255, 255, 0.95);
    border-radius: 12px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.login-dialog-button {
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 6px;
    font-weight: bold;
}

.login-dialog-button:hover {
    background-color: #2E7D32;
}
EOF

    print_success "Desktop customization created"
}

# Create boot customization
create_boot_customization() {
    print_status "Creating boot customization..."
    
    # GRUB configuration
    cat > "/etc/default/grub" <<EOF
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$DISTRO_NAME"
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_CMDLINE_LINUX="rhgb quiet splash"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
EOF

    # GRUB theme
    cat > "/boot/grub2/themes/$DISTRO_ID/theme.txt" <<EOF
# FyntoraLinux GRUB Theme
global_menu_font = "Inter 16"
global_color_normal = "white/black"
global_color_highlight = "#4CAF50/black"
menu_color_normal = "white/black"
menu_color_highlight = "#4CAF50/black"
desktop-color = "#2E7D32"
terminal-font = "Inter 14"
terminal-left = "0%"
terminal-top = "100%"
terminal-width = "100%"
terminal-height = "25%"
terminal-border = "0"
EOF

    # Plymouth theme
    cat > "/boot/plymouth/themes/$DISTRO_ID/$DISTRO_ID.plymouth" <<EOF
[Plymouth Theme]
Name=$DISTRO_NAME Splash
Description=Custom boot splash for $DISTRO_NAME
ModuleName=two-step

[two-step]
ImageDir=/boot/plymouth/themes/$DISTRO_ID
HorizontalAlignment=.5
VerticalAlignment=.5
BackgroundStartColor=0x2E7D32
BackgroundEndColor=0x4CAF50
TransitionDuration=0.5
TransitionForegroundFile=logo.png
BackgroundForegroundColor=0xFFFFFF
EOF

    # Update GRUB and Plymouth
    grub2-mkconfig -o /boot/grub2/grub.cfg
    plymouth-set-default-theme -R $DISTRO_ID
    
    print_success "Boot customization created"
}

# Create welcome script
create_welcome_script() {
    print_status "Creating welcome script..."
    
    cat > "$SCRIPT_DIR/$DISTRO_ID-welcome" <<'EOF'
#!/bin/bash
echo "Welcome to FyntoraLinux!"
echo "System: $(uname -sr)"
echo "Uptime: $(uptime -p)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
echo ""
echo "Type 'fyntora-help' for assistance."
EOF

    chmod +x "$SCRIPT_DIR/$DISTRO_ID-welcome"
    
    print_success "Welcome script created"
}

# Create post-install script
create_postinstall_script() {
    print_status "Creating post-install script..."
    
    cat > "$SCRIPT_DIR/$DISTRO_ID-postinstall" <<'EOF'
#!/bin/bash
# Post-installation script for FyntoraLinux

echo "Running FyntoraLinux post-installation..."

# Enable services
systemctl enable fyntora-welcome.service
systemctl enable fyntora-update-manager.service

# Set default theme
gsettings set org.gnome.desktop.interface gtk-theme 'FyntoraLinux'
gsettings set org.gnome.shell.extensions.user-theme name 'FyntoraLinux'

# Configure default applications
gsettings set org.gnome.desktop.default-applications.terminal exec 'gnome-terminal'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/fyntora/default.jpg'

echo "Post-installation completed"
EOF

    chmod +x "$SCRIPT_DIR/$DISTRO_ID-postinstall"
    
    print_success "Post-install script created"
}

# Enable systemd services
enable_services() {
    print_status "Enabling systemd services..."
    
    systemctl daemon-reload
    systemctl enable $DISTRO_ID-welcome.service
    systemctl enable $DISTRO_ID-update-manager.service
    
    print_success "Systemd services enabled"
}

# Create documentation
create_documentation() {
    print_status "Creating documentation..."
    
    mkdir -p "/usr/share/$DISTRO_ID/docs"
    
    cat > "/usr/share/$DISTRO_ID/docs/README.md" <<EOF
# $DISTRO_NAME

Welcome to $DISTRO_NAME - Your independent Linux distribution.

## Quick Start

1. **Complete Setup**: Run \`achieve-independence.sh\`
2. **Build System**: Use \`build-$DISTRO_ID.sh\`
3. **Updates**: Use \`$DISTRO_ID-update-manager\`
4. **Help**: Use \`$DISTRO_ID-help\`

## Configuration Files

- Main config: \`/etc/$DISTRO_ID/\`
- Build directory: \`/opt/$DISTRO_ID/\`
- Logs: \`/var/log/$DISTRO_ID/\`

## Getting Help

Type \`$DISTRO_ID-help\` for assistance.

## Support

- Website: https://$DISTRO_ID.org
- Documentation: /usr/share/$DISTRO_ID/docs/
- Issues: https://bugs.$DISTRO_ID.org
EOF

    print_success "Documentation created"
}

# Set permissions and ownership
set_permissions() {
    print_status "Setting permissions and ownership..."
    
    # Set ownership of build directory
    chown -R $DISTRO_ID:$DISTRO_ID "$BUILD_DIR"
    
    # Set permissions for scripts
    chmod +x $SCRIPT_DIR/build-$DISTRO_ID.sh
    chmod +x $SCRIPT_DIR/achieve-independence.sh
    chmod +x $SCRIPT_DIR/$DISTRO_ID-update-manager
    chmod +x $SCRIPT_DIR/$DISTRO_ID-help
    chmod +x $SCRIPT_DIR/remove-oracle-branding.sh
    chmod +x $SCRIPT_DIR/complete-rebrand.sh
    chmod +x $SCRIPT_DIR/verify-independence.sh
    chmod +x $SCRIPT_DIR/setup-$DISTRO_ID-signing.sh
    chmod +x $SCRIPT_DIR/$DISTRO_ID-welcome
    chmod +x $SCRIPT_DIR/$DISTRO_ID-postinstall
    
    # Set permissions for configuration
    chmod 755 "$CONFIG_DIR"
    chmod -R 644 "$CONFIG_DIR"/*
    chmod 700 "$CONFIG_DIR/gpg"
    
    print_success "Permissions and ownership set"
}

# Display completion message
show_completion_message() {
    print_success "Installation completed successfully!"
    echo ""
    echo -e "${GREEN}🎉 FyntoraLinux Builder is now installed! 🎉${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Reboot your system to see changes"
    echo "2. Run 'achieve-independence.sh' for complete setup"
    echo "3. Use 'build-fyntora.sh all' to build packages and ISO"
    echo "4. Test with 'fyntora-update-manager check'"
    echo "5. Get help with 'fyntora-help'"
    echo ""
    echo "Important Files:"
    echo "- Main scripts: /usr/local/bin/"
    echo "- Configuration: /etc/fyntora/"
    echo "- Build directory: /opt/fyntora/"
    echo "- Documentation: /usr/share/fyntora/docs/"
    echo ""
    echo "Achieve complete independence by running:"
    echo -e "${BLUE}achieve-independence.sh${NC}"
    echo ""
    echo "Welcome to independence! 🚀"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  FyntoraLinux Independence Builder     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    check_root
    create_directories
    install_packages
    create_build_user
    create_mock_config
    create_identity_files
    create_main_scripts
    create_branding_scripts
    create_gpg_script
    create_repository_config
    create_systemd_services
    create_desktop_customization
    create_boot_customization
    create_welcome_script
    create_postinstall_script
    enable_services
    create_documentation
    set_permissions
    show_completion_message
}

# Run main function
main "$@"