# Oracle Linux Base Setup

This section covers the installation and initial configuration of Oracle Linux as the foundation for your custom distribution.

## Table of Contents

1. [Oracle Linux Installation](#oracle-linux-installation)
2. [Initial System Configuration](#initial-system-configuration)
3. [Repository Setup](#repository-setup)
4. [Kernel Selection](#kernel-selection)
5. [Base System Hardening](#base-system-hardening)
6. [Development Environment Setup](#development-environment-setup)
7. [Network Configuration](#network-configuration)
8. [Storage Configuration](#storage-configuration)

## Oracle Linux Installation

### Download Oracle Linux

1. Visit [Oracle Linux Downloads](https://www.oracle.com/linux/downloads/)
2. Choose the appropriate version (Oracle Linux 8 or 9 recommended)
3. Select the Full ISO image for complete installation
4. Verify the download using provided checksums

### Installation Methods

#### Method 1: Bare Metal Installation
```bash
# Create bootable USB
dd if=OracleLinux-9.x-x86_64-boot.iso of=/dev/sdX bs=4M status=progress

# Boot from USB and follow installation wizard
```

#### Method 2: Virtual Machine Installation
```bash
# Using virt-install
virt-install \
  --name oracle-linux-base \
  --memory 8192 \
  --vcpus 4 \
  --disk size=100 \
  --cdrom OracleLinux-9.x-x86_64-boot.iso \
  --os-variant ol9.0
```

### Installation Configuration

#### Partition Scheme
Recommended partition layout for build system:
```
/boot/efi    512MB    (EFI System Partition)
/boot        1GB      (Boot partition)
/            50GB     (Root filesystem)
/home        20GB     (User data)
/var         20GB     (Package cache and build files)
/swap        8GB      (Swap space)
/build       100GB+   (Build workspace)
```

#### Software Selection
Choose "Minimal Install" as base, then add:
- Development Tools
- System Tools
- Legacy UNIX Compatibility

#### Network Configuration
- Set hostname: `distro-build.local`
- Configure static IP if possible
- Enable network connection

## Initial System Configuration

### System Update
```bash
# Update all packages
sudo dnf update -y

# Install essential packages
sudo dnf install -y \
  vim \
  curl \
  wget \
  git \
  htop \
  tree \
  lsof \
  strace
```

### User Configuration
```bash
# Create build user
sudo useradd -m -s /bin/bash builder
sudo usermod -aG wheel builder

# Configure sudo for build user
echo "builder ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/builder
```

### System Settings
```bash
# Set timezone
sudo timedatectl set-timezone America/New_York

# Configure locale
sudo localectl set-locale LANG=en_US.UTF-8

# Set hostname
sudo hostnamectl set-hostname distro-build.local
```

## Repository Setup

### Enable Required Repositories
```bash
# Enable Oracle Linux repositories
sudo dnf config-manager --enable ol8_appstream
sudo dnf config-manager --enable ol8_baseos
sudo dnf config-manager --enable ol8_codeready_builder

# Enable EPEL repository
sudo dnf install -y epel-release

# Enable optional repositories for development
sudo dnf config-manager --enable ol8_developer
```

### Configure Custom Repository
```bash
# Create local repository directory
sudo mkdir -p /opt/distro-repo

# Initialize repository structure
sudo mkdir -p /opt/distro-repo/{RPMS,SRPMS,repodata}
```

### Repository Configuration Files
Create `/etc/yum.repos.d/distro.repo`:
```ini
[distro-base]
name=Distro Base Repository
baseurl=file:///opt/distro-repo
enabled=1
gpgcheck=0
```

## Kernel Selection

### Available Kernel Options
Oracle Linux provides multiple kernel options:

#### Unbreakable Enterprise Kernel (UEK)
- Default and recommended kernel
- Enhanced performance and features
- Better hardware support
- Latest Linux kernel features

#### Red Hat Compatible Kernel (RHCK)
- Traditional RHEL-compatible kernel
- Maximum compatibility with RHEL
- Conservative feature set

### Kernel Installation
```bash
# List available kernels
dnf list available | grep kernel

# Install UEK (usually default)
sudo dnf install -y kernel-uek

# Install RHCK if desired
sudo dnf install -y kernel

# Install kernel headers for development
sudo dnf install -y kernel-uek-devel
```

### Kernel Configuration
```bash
# Set default kernel
sudo grubby --set-default=/boot/vmlinuz-$(uname -r)

# View kernel boot parameters
sudo grubby --info=DEFAULT

# Add custom kernel parameters
sudo grubby --update-kernel=DEFAULT --args="quiet splash"
```

## Base System Hardening

### Security Configuration
```bash
# Install security tools
sudo dnf install -y \
  firewalld \
  selinux-policy-targeted \
  setroubleshoot-server

# Enable and configure firewall
sudo systemctl enable --now firewalld
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

### SELinux Configuration
```bash
# Verify SELinux status
sestatus

# Set SELinux to enforcing mode
sudo setenforce 1
sudo sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
```

### System Hardening
```bash
# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon

# Secure SSH configuration
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo tee /etc/ssh/sshd_config.d/custom.conf > /dev/null <<EOF
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

sudo systemctl restart sshd
```

## Development Environment Setup

### Build Tools Installation
```bash
# Install development tools group
sudo dnf groupinstall -y "Development Tools"

# Install additional build dependencies
sudo dnf install -y \
  rpm-build \
  createrepo \
  mock \
  spectool \
  rpmlint \
  gcc \
  gcc-c++ \
  make \
  cmake \
  autoconf \
  automake \
  libtool
```

### Mock Configuration
```bash
# Add user to mock group
sudo usermod -a -G mock $USER

# Initialize mock configuration
sudo cp /etc/mock/default.cfg /etc/mock/distro-build.cfg

# Configure mock for custom builds
sudo tee /etc/mock/distro-build.cfg > /dev/null <<EOF
config_opts['root'] = 'distro-build'
config_opts['target_arch'] = 'x86_64'
config_opts['legal_host_arches'] = ('x86_64',)
config_opts['chroot_setup_cmd'] = 'install @buildsys-build'
config_opts['dist'] = 'el9'  # or el8 for Oracle Linux 8
config_opts['releasever'] = '9'
config_opts['package_manager'] = 'dnf'
config_opts['use_bootstrap'] = True
EOF
```

### Version Control Setup
```bash
# Configure Git
git config --global user.name "Distro Builder"
git config --global user.email "builder@distro.local"

# Initialize project repository
mkdir -p ~/distro-project
cd ~/distro-project
git init
```

## Network Configuration

### Static Network Configuration
For build systems, static IP is recommended:
```bash
# Edit network configuration
sudo nmcli connection modify "Wired connection 1" \
  ipv4.addresses 192.168.1.100/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "8.8.8.8,8.8.4.4" \
  ipv4.method manual

# Restart network
sudo nmcli connection down "Wired connection 1" && \
sudo nmcli connection up "Wired connection 1"
```

### Hostname Resolution
```bash
# Edit /etc/hosts
sudo tee -a /etc/hosts > /dev/null <<EOF
192.168.1.100 distro-build.local
EOF
```

## Storage Configuration

### Build Directory Setup
```bash
# Create build directories
sudo mkdir -p /opt/distro-build/{sources,packages,iso,logs}
sudo chown -R builder:builder /opt/distro-build

# Create symlink in user home
ln -s /opt/distro-build ~/distro-build
```

### Package Cache Configuration
```bash
# Configure DNF to keep downloaded packages
sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=False
keepcache=True
EOF
```

## System Optimization

### Performance Tuning
```bash
# Configure system limits
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
builder soft nofile 65536
builder hard nofile 65536
builder soft nproc 32768
builder hard nproc 32768
EOF

# Optimize kernel parameters
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# Build optimization
vm.swappiness=10
fs.file-max=2097152
net.core.somaxconn=65535
EOF

sudo sysctl -p
```

### Service Optimization
```bash
# Disable unnecessary services for build system
sudo systemctl disable cups
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
sudo systemctl disable pcscd
sudo systemctl disable smartd

# Enable essential services
sudo systemctl enable sshd
sudo systemctl enable firewalld
sudo systemctl enable NetworkManager
```

## Verification and Testing

### System Verification
```bash
# Verify system information
uname -a
cat /etc/oracle-release
dnf list installed | wc -l

# Verify network connectivity
ping -c 4 google.com
curl -I https://yum.oracle.com

# Verify build environment
rpm --version
gcc --version
make --version
```

### Test Build Process
```bash
# Create test package
mkdir -p ~/test-build
cd ~/test-build

# Create simple spec file
cat > test.spec <<EOF
Name: test-package
Version: 1.0
Release: 1%{?dist}
Summary: Test package for build verification

License: GPL
BuildArch: noarch

%description
Test package to verify build environment.

%install
mkdir -p %{buildroot}/usr/share/test-package
echo "Test content" > %{buildroot}/usr/share/test-package/test.txt

%files
/usr/share/test-package/test.txt
EOF

# Build test package
rpmbuild -ba test.spec
```

## Next Steps

With Oracle Linux base setup complete:

1. Proceed to [Package Management and Customization](03-package-management.md)
2. Define your package selection strategy
3. Begin customizing the system configuration

## Troubleshooting

### Common Issues

#### Repository Access Problems
```bash
# Check repository connectivity
sudo dnf repolist -v

# Clear DNF cache
sudo dnf clean all
sudo dnf makecache
```

#### Build Environment Issues
```bash
# Verify mock configuration
mock -r distro-build --init

# Check build dependencies
rpm -qa | grep -E "(gcc|make|rpm)"
```

#### Permission Issues
```bash
# Fix directory permissions
sudo chown -R builder:builder /opt/distro-build
sudo chmod -R 755 /opt/distro-build
```

## Documentation References

- [Oracle Linux Installation Guide](https://docs.oracle.com/en/operating-systems/oracle-linux/9/install/)
- [Oracle Linux Administrator's Guide](https://docs.oracle.com/en/operating-systems/oracle-linux/9/admin/)
- [DNF Configuration Guide](https://dnf.readthedocs.io/en/latest/)