# Package Management and Customization

This section covers package selection, custom package creation, repository management, and software customization for your Linux distribution.

## Table of Contents

1. [Package Selection Strategy](#package-selection-strategy)
2. [Repository Management](#repository-management)
3. [Custom Package Creation](#custom-package-creation)
4. [Package Modification](#package-modification)
5. [Dependency Management](#dependency-management)
6. [Package Configuration](#package-configuration)
7. [Update Management](#update-management)
8. [Quality Assurance](#quality-assurance)

## Package Selection Strategy

### Base Package Set

#### Essential System Packages
```bash
# Core system packages
dnf install -y \
  systemd \
  kernel \
  glibc \
  bash \
  coreutils \
  util-linux \
  rpm \
  dnf \
  selinux-policy-targeted \
  firewalld
```

#### Network and Connectivity
```bash
# Network management
dnf install -y \
  NetworkManager \
  network-scripts \
  wireless-tools \
  wpa_supplicant \
  openssh-clients \
  curl \
  wget \
  iproute \
  iputils
```

#### Filesystem and Storage
```bash
# Filesystem support
dnf install -y \
  e2fsprogs \
  xfsprogs \
  btrfs-progs \
  lvm2 \
  mdadm \
  cryptsetup \
  dosfstools \
  ntfs-3g
```

### Desktop Environment Packages

#### GNOME Desktop
```bash
# GNOME desktop environment
dnf groupinstall -y "GNOME Desktop"
dnf install -y \
  gnome-shell \
  gnome-session \
  gdm \
  nautilus \
  gnome-terminal \
  gnome-control-center
```

#### KDE Plasma
```bash
# KDE desktop environment
dnf groupinstall -y "KDE Plasma Workspaces"
dnf install -y \
  plasma-workspace \
  kde-applications \
  sddm
```

#### XFCE Desktop
```bash
# Lightweight XFCE desktop
dnf groupinstall -y "XFCE Desktop"
dnf install -y \
  xfce4-session \
  xfce4-panel \
  xfce4-terminal \
  lightdm
```

### Development Tools

#### Programming Languages
```bash
# Development languages
dnf install -y \
  gcc \
  gcc-c++ \
  python3 \
  python3-pip \
  nodejs \
  npm \
  java-11-openjdk \
  java-11-openjdk-devel \
  golang \
  rust
```

#### Build Tools
```bash
# Build and compilation tools
dnf install -y \
  make \
  cmake \
  autoconf \
  automake \
  libtool \
  pkgconfig \
  git \
  mercurial \
  subversion
```

### Multimedia Support

#### Audio and Video
```bash
# Multimedia packages
dnf install -y \
  gstreamer1 \
  gstreamer1-plugins-base \
  gstreamer1-plugins-good \
  gstreamer1-plugins-bad-free \
  gstreamer1-plugins-ugly \
  vlc \
  ffmpeg \
  libavcodec \
  pulseaudio \
  alsa-utils
```

#### Graphics and Image Processing
```bash
# Graphics packages
dnf install -y \
  gimp \
  inkscape \
  imagemagick \
  libraw \
  libexif \
  poppler-utils
```

## Repository Management

### Local Repository Setup

#### Create Repository Structure
```bash
# Create repository directories
mkdir -p /opt/distro-repo/{RPMS,SRPMS,repodata,logs}
cd /opt/distro-repo

# Initialize repository
createrepo --verbose .
```

#### Repository Configuration
Create `/etc/yum.repos.d/distro-local.repo`:
```ini
[distro-local]
name=Distro Local Repository
baseurl=file:///opt/distro-repo
enabled=1
gpgcheck=0
metadata_expire=0
cost=500
```

### Remote Repository Setup

#### Web Server Configuration
```bash
# Install Apache for repository hosting
dnf install -y httpd

# Configure repository directory
mkdir -p /var/www/html/repo
ln -s /opt/distro-repo /var/www/html/repo/distro

# Configure Apache
cat > /etc/httpd/conf.d/repo.conf <<EOF
<VirtualHost *:80>
    ServerName repo.distro.local
    DocumentRoot /var/www/html/repo
    <Directory /var/www/html/repo>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
EOF

systemctl enable --now httpd
```

#### Repository Metadata
```bash
# Update repository metadata
createrepo --update --verbose /opt/distro-repo

# Create repository checksums
cd /opt/distro-repo
find . -type f -name "*.rpm" -exec sha256sum {} \; > checksums.txt
```

### Repository Synchronization

#### Mirror Configuration
```bash
# Create mirror script
cat > /usr/local/bin/sync-repo.sh <<'EOF'
#!/bin/bash
REPO_DIR="/opt/distro-repo"
SOURCE_URL="https://yum.oracle.com/repo/OracleLinux/ol9/baseos/latest/x86_64/"

# Sync packages
rsync -avz --delete \
  --exclude="*.drpm" \
  --exclude="*.srpm" \
  $SOURCE_URL $REPO_DIR/

# Update metadata
createrepo --update $REPO_DIR
EOF

chmod +x /usr/local/bin/sync-repo.sh
```

## Custom Package Creation

### RPM Package Basics

#### Spec File Structure
```spec
Name:           distro-custom-tool
Version:        1.0.0
Release:        1%{?dist}
Summary:        Custom tool for our distribution

License:        GPL-3.0-or-later
URL:            https://github.com/our-distro/custom-tool
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

BuildRequires:  python3-devel
Requires:       python3 >= 3.6

%description
This is a custom tool specifically designed for our Linux distribution.
It provides essential functionality for system management and configuration.

%prep
%autosetup -n %{name}-%{version}

%build
%py3_build

%install
%py3_install

%files
%license LICENSE
%doc README.md
%{python3_sitelib}/distro_custom_tool/
%{_bindir}/distro-tool

%changelog
* Mon Jan 05 2026 Distro Builder <builder@distro.local> - 1.0.0-1
- Initial package creation
EOF
```

#### Building Custom Packages
```bash
# Create build directory structure
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cd ~/rpmbuild

# Download source
wget https://github.com/our-distro/custom-tool/archive/v1.0.0.tar.gz
mv v1.0.0.tar.gz SOURCES/distro-custom-tool-1.0.0.tar.gz

# Build package
rpmbuild -ba SPECS/distro-custom-tool.spec
```

### Package Templates

#### System Service Package
```spec
Name:           distro-service
Version:        1.0.0
Release:        1%{?dist}
Summary:        Custom system service

License:        MIT
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  systemd
Requires:       systemd

%description
Custom system service for our distribution.

%prep
%autosetup

%install
install -D -m 644 distro.service %{buildroot}%{_unitdir}/distro.service
install -D -m 755 distro-daemon %{buildroot}%{_sbindir}/distro-daemon

%files
%{_unitdir}/distro.service
%{_sbindir}/distro-daemon

%post
%systemd_post distro.service

%preun
%systemd_preun distro.service

%postun
%systemd_postun_with_restart distro.service
```

#### Configuration Package
```spec
Name:           distro-config
Version:        1.0.0
Release:        1%{?dist}
Summary:        System configuration files

License:        GPL-2.0-or-later
BuildArch:      noarch

%description
System configuration files for our distribution.

%install
mkdir -p %{buildroot}%{_sysconfdir}/distro
install -D -m 644 config/*.conf %{buildroot}%{_sysconfdir}/distro/

%files
%config %{_sysconfdir}/distro/
```

## Package Modification

### Rebuilding Existing Packages

#### Download Source RPM
```bash
# Download source RPM
dnf download --source package-name

# Install build dependencies
sudo dnf builddep package-name.src.rpm

# Extract source
rpm2cpio package-name.src.rpm | cpio -idmv
```

#### Modify Spec File
```bash
# Extract and patch source
tar -xf package-version.tar.gz
cd package-version

# Apply custom patches
patch -p1 < ../custom-feature.patch

# Update spec file
# Add Patch and %patch directives
# Modify %build, %install, or %files sections as needed
```

#### Rebuild Package
```bash
# Build modified package
rpmbuild -ba package-name.spec

# Test package
rpm -qp --scripts RPMS/arch/package-name-version-release.arch.rpm
```

### Patch Management

#### Create Patch Files
```bash
# Create patch from modified source
diff -Naur original-source/ modified-source/ > custom-feature.patch

# Add patch to spec file
Patch0: custom-feature.patch

# Apply patch in %prep section
%patch0 -p1
```

#### Patch Automation
```bash
# Create patch management script
cat > manage-patches.sh <<'EOF'
#!/bin/bash
PATCH_DIR="patches"
SOURCE_DIR="sources"

# Create patch directory
mkdir -p $PATCH_DIR

# Generate patches for all modified files
for file in $(git diff --name-only); do
    patch_file="$PATCH_DIR/$(basename $file).patch"
    git diff "HEAD~1" -- "$file" > "$patch_file"
    echo "Created patch: $patch_file"
done
EOF

chmod +x manage-patches.sh
```

## Dependency Management

### Dependency Resolution

#### Automatic Dependencies
```bash
# Generate requires automatically
rpm -qp --requires package.rpm

# Generate provides
rpm -qp --provides package.rpm

# Generate conflicts
rpm -qp --conflicts package.rpm
```

#### Manual Dependencies
```spec
# Explicit requires
Requires:       glibc >= 2.17
Requires:       python3 >= 3.6
Requires:       systemd

# Conditional requires
%if 0%{?fedora} || 0%{?rhel} >= 8
Requires:       python3-setuptools
%endif

# Weak dependencies
Recommends:     vim-enhanced
Suggests:       git
```

### Virtual Provides

#### Custom Provides
```spec
# Add virtual provides
Provides:       distro-toolkit = %{version}-%{release}
Provides:       web-server
Provides:       database-client
```

#### Dependency Scripts
```bash
# Check dependencies script
cat > check-deps.sh <<'EOF'
#!/bin/bash
PACKAGE=$1

# Check if package is installed
if ! rpm -q $PACKAGE > /dev/null 2>&1; then
    echo "Error: $PACKAGE is not installed"
    exit 1
fi

# Check dependencies
echo "Dependencies for $PACKAGE:"
rpm -qR $PACKAGE | sort
EOF

chmod +x check-deps.sh
```

## Package Configuration

### Default Configuration

#### Configuration Files
```bash
# Create default configuration
mkdir -p /etc/distro
cat > /etc/distro/distro.conf <<EOF
# Distribution configuration
DISTRO_NAME="Our Distro"
DISTRO_VERSION="1.0"
DISTRO_ID="ourdistro"

# System settings
DEFAULT_DESKTOP="gnome"
ENABLE_FIREWALL=true
ENABLE_SELINUX=true
EOF
```

#### Configuration Packages
```spec
Name:           distro-defaults
Version:        1.0.0
Release:        1%{?dist}
Summary:        Default configuration files

BuildArch:      noarch

%description
Default configuration files for our distribution.

%install
mkdir -p %{buildroot}%{_sysconfdir}/distro
mkdir -p %{buildroot}%{_sysconfdir}/skel/.config

# Install system configuration
install -D -m 644 config/distro.conf %{buildroot}%{_sysconfdir}/distro/
install -D -m 644 config/user-profile %{buildroot}%{_sysconfdir}/skel/

%files
%config(noreplace) %{_sysconfdir}/distro/
%config(noreplace) %{_sysconfdir}/skel/.config/
```

### Package Configuration Scripts

#### Pre-Installation Script
```spec
%pre
# Create system user
getent group distro >/dev/null || groupadd -r distro
getent passwd distro >/dev/null || useradd -r -g distro -s /sbin/nologin distro

# Create directories
mkdir -p /var/lib/distro
mkdir -p /var/log/distro
```

#### Post-Installation Script
```spec
%post
# Update configuration
if [ $1 -eq 1 ]; then
    # Fresh installation
    systemctl enable distro-service
    systemctl start distro-service
else
    # Upgrade
    systemctl restart distro-service
fi

# Update alternatives
update-alternatives --install /usr/bin/default-editor default-editor /usr/bin/vim 100
```

## Update Management

### Update Strategy

#### Update Channels
```bash
# Stable channel
[distro-stable]
name=Distro Stable Repository
baseurl=https://repo.distro.local/stable/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-distro

# Testing channel
[distro-testing]
name=Distro Testing Repository
baseurl=https://repo.distro.local/testing/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-distro
```

#### Update Automation
```bash
# Create update script
cat > /usr/local/bin/distro-update.sh <<'EOF'
#!/bin/bash
LOG_FILE="/var/log/distro-update.log"

echo "Starting system update: $(date)" >> $LOG_FILE

# Clean cache
dnf clean all >> $LOG_FILE 2>&1

# Update packages
dnf update -y >> $LOG_FILE 2>&1

# Update metadata
createrepo --update /opt/distro-repo >> $LOG_FILE 2>&1

echo "System update completed: $(date)" >> $LOG_FILE
EOF

chmod +x /usr/local/bin/distro-update.sh
```

### Security Updates

#### Security Patch Management
```bash
# Check for security updates
dnf updateinfo list security

# Apply only security updates
dnf update --security

# Create security update script
cat > security-update.sh <<'EOF'
#!/bin/bash
# Apply security updates only
dnf update --security -y

# Log security updates
echo "Security updates applied: $(date)" >> /var/log/security-updates.log
EOF
```

## Quality Assurance

### Package Testing

#### Installation Testing
```bash
# Test package installation
dnf install -y test-package.rpm

# Verify installation
rpm -q test-package
rpm -ql test-package

# Test removal
dnf remove -y test-package
```

#### Dependency Testing
```bash
# Check dependencies
dnf deplist test-package

# Test broken dependencies
dnf install --test test-package.rpm
```

### Package Validation

#### RPM Validation
```bash
# Check package signature
rpm --checksig --verbose package.rpm

# Validate package integrity
rpm -K --verbose package.rpm

# Check package contents
rpm -qpl package.rpm
```

#### Linting
```bash
# Use rpmlint for package validation
rpmlint package.rpm

# Fix common issues
# - Update summary and description
# - Fix file permissions
# - Add required documentation
```

### Repository Testing

#### Repository Validation
```bash
# Test repository metadata
dnf repolist -v

# Test package installation from repository
dnf install --test distro-custom-tool

# Validate repository structure
repoquery --list distro-custom-tool
```

## Automation Scripts

### Package Build Automation

#### Build Script
```bash
#!/bin/bash
# build-packages.sh

BUILD_DIR="/opt/distro-build"
PACKAGE_LIST="packages.txt"

while read package; do
    echo "Building $package..."
    cd $BUILD_DIR/$package
    rpmbuild -ba $package.spec
    
    if [ $? -eq 0 ]; then
        echo "Successfully built $package"
        mv ~/rpmbuild/RPMS/*/*.rpm /opt/distro-repo/RPMS/
    else
        echo "Failed to build $package"
    fi
done < $PACKAGE_LIST

# Update repository metadata
createrepo --update /opt/distro-repo
```

### Repository Management

#### Repository Update Script
```bash
#!/bin/bash
# update-repository.sh

REPO_DIR="/opt/distro-repo"
LOG_FILE="/var/log/repo-update.log"

echo "Starting repository update: $(date)" > $LOG_FILE

# Clean old metadata
rm -rf $REPO_DIR/repodata/*

# Generate new metadata
createrepo --verbose --update $REPO_DIR >> $LOG_FILE 2>&1

# Update checksums
cd $REPO_DIR
find . -name "*.rpm" -exec sha256sum {} \; > checksums.txt

echo "Repository update completed: $(date)" >> $LOG_FILE
```

## Next Steps

With package management and customization complete:

1. Proceed to [System Configuration](04-system-configuration.md)
2. Configure system services and settings
3. Implement security and performance optimizations

## Troubleshooting

### Common Package Issues

#### Dependency Conflicts
```bash
# Check for conflicts
dnf check

# Resolve conflicts
dnf install --allowerasing package-name
```

#### Build Failures
```bash
# Check build logs
cat ~/rpmbuild/BUILDROOT/*.log

# Install missing dependencies
sudo dnf builddep package-name.src.rpm
```

#### Repository Issues
```bash
# Clean repository cache
dnf clean all
dnf makecache

# Verify repository configuration
dnf repolist -v
```