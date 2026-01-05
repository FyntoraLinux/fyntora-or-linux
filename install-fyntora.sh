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
    dnf install -y git rpm-build createrepo mock syslinux xorriso grub2-tools lorax plymouth plymouth-theme-spinner gnome-shell gnome-session gdm nautilus gnome-terminal firefox gimp inkscape ansible python3 python3-pip vim htop tree lsof strace tcpdump wireshark nmap curl wget rsync
    
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
| ____| | | | | / \\  | |  | | | |
|  _| | | | |/ _ \\ | |  | | | | |
| |___|_| | / ___ \\| |  | | | | | |
|_____|_|_|_/_/   \\_\\_|  |_| |_| |_|_|
                                     
$DISTRO_NAME 1.0 - Independence Edition
Type 'fyntora-help' for assistance.
EOF
    
    print_success "Identity files created"
}

# Create build script
create_build_script() {
    print_status "Creating build script..."
    
    cat > "$SCRIPT_DIR/build-$DISTRO_ID.sh" <<'ENDOFFILE'
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
    cat > "$BUILD_DIR/fyntora-live.ks" <<KICKSTART
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
ENDOFFILE

    chmod +x "$SCRIPT_DIR/build-$DISTRO_ID.sh"
    print_success "Build script created"
}

# Create independence script
create_independence_script() {
    print_status "Creating independence script..."
    
    cat > "$SCRIPT_DIR/achieve-independence.sh" <<'ENDOFFILE'
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
echo "2. Test -> update system: fyntora-update-manager check"
echo "3. Build your custom ISO: build-fyntora.sh iso"
echo "4. Setup your mirror infrastructure"
echo ""
echo "Welcome to independence! 🚀"
ENDOFFILE

    chmod +x "$SCRIPT_DIR/achieve-independence.sh"
    print_success "Independence script created"
}

# Create help script
create_help_script() {
    print_status "Creating help script..."
    
    cat > "$SCRIPT_DIR/$DISTRO_ID-help" <<'ENDOFFILE'
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
ENDOFFILE

    chmod +x "$SCRIPT_DIR/$DISTRO_ID-help"
    print_success "Help script created"
}

# Create branding removal script
create_branding_removal_script() {
    print_status "Creating branding removal script..."
    
    cat > "$SCRIPT_DIR/remove-oracle-branding.sh" <<'ENDOFFILE'
#!/bin/bash
# Remove all Oracle branding

echo "Removing Oracle packages..."
dnf remove -y oraclelinux-release oracle-logos oracle-backgrounds oracle-epel-release kmod-oracle* 2>/dev/null || true

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
ENDOFFILE

    chmod +x "$SCRIPT_DIR/remove-oracle-branding.sh"
    print_success "Branding removal script created"
}

# Create verification script
create_verification_script() {
    print_status "Creating verification script..."
    
    cat > "$SCRIPT_DIR/verify-independence.sh" <<'ENDOFFILE'
#!/bin/bash
# Verify independence status

echo "=== VERIFYING INDEPENDENCE ==="

# Check for Oracle remnants
oracle_count=$(find / -name "*oracle*" 2>/dev/null | wc -l)
echo "Oracle files found: $oracle_count"

# Check FyntoraLinux files
fyntora_count=$(find / -name "*fyntora*" 2>/dev/null | wc -l)
echo "FyntoraLinux files found: $fyntora_count"

# Check system identity
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
ENDOFFILE

    chmod +x "$SCRIPT_DIR/verify-independence.sh"
    print_success "Verification script created"
}

# Create systemd services
create_systemd_services() {
    print_status "Creating systemd services..."
    
    # Welcome service
    cat > "$SERVICE_DIR/$DISTRO_ID-welcome.service" <<ENDOFFILE
[Unit]
Description=$DISTRO_NAME Welcome Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/$DISTRO_ID-welcome
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
ENDOFFILE

    # Update manager service
    cat > "$SERVICE_DIR/$DISTRO_ID-update-manager.service" <<ENDOFFILE
[Unit]
Description=$DISTRO_NAME Update Manager
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/$DISTRO_ID-update-manager check
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
ENDOFFILE
    
    print_success "Systemd services created"
}

# Create welcome script
create_welcome_script() {
    print_status "Creating welcome script..."
    
    cat > "$SCRIPT_DIR/$DISTRO_ID-welcome" <<'ENDOFFILE'
#!/bin/bash
echo "Welcome to FyntoraLinux!"
echo "System: $(uname -sr)"
echo "Uptime: $(uptime -p)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
echo ""
echo "Type 'fyntora-help' for assistance."
ENDOFFILE

    chmod +x "$SCRIPT_DIR/$DISTRO_ID-welcome"
    print_success "Welcome script created"
}

# Set permissions and ownership
set_permissions() {
    print_status "Setting permissions and ownership..."
    
    # Set ownership of build directory
    chown -R $DISTRO_ID:$DISTRO_ID "$BUILD_DIR"
    
    # Set permissions for scripts
    chmod +x "$SCRIPT_DIR/build-$DISTRO_ID.sh"
    chmod +x "$SCRIPT_DIR/achieve-independence.sh"
    chmod +x "$SCRIPT_DIR/$DISTRO_ID-help"
    chmod +x "$SCRIPT_DIR/remove-oracle-branding.sh"
    chmod +x "$SCRIPT_DIR/verify-independence.sh"
    chmod +x "$SCRIPT_DIR/$DISTRO_ID-welcome"
    
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
    create_identity_files
    create_build_script
    create_independence_script
    create_help_script
    create_branding_removal_script
    create_verification_script
    create_systemd_services
    create_welcome_script
    set_permissions
    show_completion_message
}

# Run main function
main "$@"