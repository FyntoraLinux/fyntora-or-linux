# System Configuration

This section covers comprehensive system configuration including services, security, networking, performance tuning, and user experience customization for your Linux distribution.

## Table of Contents

1. [System Services Configuration](#system-services-configuration)
2. [Security Configuration](#security-configuration)
3. [Network Configuration](#network-configuration)
4. [Performance Tuning](#performance-tuning)
5. [User Experience Configuration](#user-experience-configuration)
6. [System Monitoring](#system-monitoring)
7. [Boot Configuration](#boot-configuration)
8. [Logging Configuration](#logging-configuration)

## System Services Configuration

### Essential Services

#### Core System Services
```bash
# Enable essential services
systemctl enable systemd-journald
systemctl enable systemd-logind
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

# Configure service startup
systemctl set-default multi-user.target  # For server
# systemctl set-default graphical.target  # For desktop
```

#### Network Services
```bash
# Enable NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager

# Configure hostname resolution
systemctl enable systemd-resolved
systemctl start systemd-resolved

# Update resolv.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

#### Security Services
```bash
# Enable firewall
systemctl enable firewalld
systemctl start firewalld

# Configure SELinux
systemctl enable auditd
systemctl start auditd
```

### Custom Services

#### Distro Management Service
Create `/etc/systemd/system/distro-manager.service`:
```ini
[Unit]
Description=Distro Management Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/distro-manager --startup
ExecStop=/usr/local/bin/distro-manager --shutdown
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

#### System Monitoring Service
Create `/etc/systemd/system/distro-monitor.service`:
```ini
[Unit]
Description=Distro System Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/distro-monitor
Restart=always
RestartSec=10
User=distro-monitor
Group=distro-monitor

[Install]
WantedBy=multi-user.target
```

### Service Configuration

#### Service Limits
Create `/etc/systemd/system/distro-service.d/limits.conf`:
```ini
[Service]
LimitNOFILE=65536
LimitNPROC=32768
MemoryMax=2G
CPUQuota=200%
```

#### Service Dependencies
```bash
# Create service dependencies
systemctl add-wants distro-manager.service network.target
systemctl add-requires distro-manager.service systemd-journald.service
```

## Security Configuration

### SELinux Configuration

#### SELinux Policy
```bash
# Check SELinux status
sestatus

# Set SELinux to enforcing
setenforce 1
sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config

# Install SELinux tools
dnf install -y policycoreutils-python-utils setroubleshoot-server
```

#### Custom SELinux Policy
Create custom policy module:
```bash
# Create policy module
cat > distro.te <<'EOF'
module distro 1.0.0;

require {
    type user_home_t;
    type distro_exec_t;
    class file { read execute open };
}

# Allow distro to read user home files
allow distro_exec_t user_home_t:file { read open };
EOF

# Compile and install policy
checkmodule -M -m -o distro.mod distro.te
semodule_package -o distro.pp -m distro.mod
semodule -i distro.pp
```

### Firewall Configuration

#### Firewall Zones
```bash
# Create custom zone
firewall-cmd --permanent --new-zone=distro-zone
firewall-cmd --permanent --zone=distro-zone --set-description="Distro custom zone"

# Configure zone
firewall-cmd --permanent --zone=distro-zone --add-service=ssh
firewall-cmd --permanent --zone=distro-zone --add-service=http
firewall-cmd --permanent --zone=distro-zone --add-service=https

# Set default zone
firewall-cmd --set-default-zone=distro-zone
```

#### Custom Firewall Rules
```bash
# Add custom rules
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" accept'

# Port forwarding
firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80
```

### Access Control

#### User Account Management
```bash
# Create system users
useradd -r -s /sbin/nologin distro-service
useradd -r -s /sbin/nologin distro-monitor

# Configure user groups
groupadd distro-users
groupadd distro-admins
```

#### Sudo Configuration
Create `/etc/sudoers.d/distro-config`:
```bash
# Distro administrators
%distro-admins ALL=(ALL) ALL

# Distro users - specific commands
%distro-users ALL=/usr/local/bin/distro-tool, /usr/bin/distro-update

# Service accounts
distro-service ALL=(ALL) NOPASSWD: /usr/local/bin/distro-service
```

#### File Permissions
```bash
# Secure configuration files
chmod 600 /etc/distro/secrets.conf
chmod 644 /etc/distro/config.conf
chmod 755 /usr/local/bin/distro-*

# Set ownership
chown root:distro-admins /etc/distro
chown distro-service:distro-service /var/lib/distro
```

## Network Configuration

### NetworkManager Configuration

#### Network Profiles
Create `/etc/NetworkManager/system-connections/distro-ethernet.nmconnection`:
```ini
[connection]
id=distro-ethernet
type=ethernet
interface-name=eth0

[ethernet]
auto-negotiate=yes

[ipv4]
method=auto
dns=8.8.8.8;8.8.4.4;
dns-search=distro.local

[ipv6]
method=auto
```

#### DNS Configuration
```bash
# Configure systemd-resolved
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/distro.conf <<EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1 1.0.0.1
Domains=distro.local
EOF

systemctl restart systemd-resolved
```

### Hostname Configuration

#### System Hostname
```bash
# Set hostname
hostnamectl set-hostname distro-system
hostnamectl set-hostname --pretty "Distro System"
hostnamectl set-hostname --transient distro-system.local
```

#### Hosts File
Update `/etc/hosts`:
```bash
# Local entries
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain

# System hostname
127.0.1.1   distro-system.local distro-system

# Network entries
192.168.1.100  distro-build.local distro-build
192.168.1.101  distro-repo.local distro-repo
```

## Performance Tuning

### System Limits

#### Resource Limits
Create `/etc/security/limits.d/distro-limits.conf`:
```bash
# System-wide limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768

# Specific users
distro-service soft nofile 131072
distro-service hard nofile 131072
```

#### Kernel Parameters
Create `/etc/sysctl.d/99-distro.conf`:
```bash
# Network performance
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Memory management
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# File system
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288

# Security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
```

### CPU and Memory Optimization

#### CPU Governor
```bash
# Set CPU governor to performance
echo 'performance' > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Make persistent
cat > /etc/systemd/system/cpu-governor.service <<EOF
[Unit]
Description=Set CPU Governor

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable cpu-governor.service
```

#### Memory Optimization
```bash
# Configure transparent huge pages
echo 'madvise' > /sys/kernel/mm/transparent_hugepage/enabled

# Configure swap behavior
echo 10 > /proc/sys/vm/swappiness
```

## User Experience Configuration

### Desktop Environment

#### GNOME Configuration
```bash
# Set GNOME defaults
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/distro/default.jpg'

# Configure default applications
gsettings set org.gnome.desktop.default-applications.terminal exec 'gnome-terminal'
gsettings set org.gnome.desktop.default-applications.terminal exec-arg '--'
```

#### KDE Configuration
```bash
# KDE system settings
kwriteconfig5 --file kdeglobals --group KDE --key SingleClick false
kwriteconfig5 --file kdeglobals --group General --key BrowserApplication firefox
```

#### XFCE Configuration
```bash
# XFCE settings
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s /usr/share/backgrounds/distro/default.jpg
xfconf-query -c xsettings -p /Gtk/FontName -s "Sans 10"
```

### Default Applications

#### MIME Type Configuration
Create `/usr/share/applications/distro-defaults.list`:
```ini
[Default Applications]
text/plain=gedit.desktop
application/pdf=evince.desktop
image/jpeg=gnome-photos.desktop
video/mp4=totem.desktop
audio/mpeg=rhythmbox.desktop
```

#### Alternative System
```bash
# Configure alternatives
update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/gnome-terminal 100
update-alternatives --install /usr/bin/www-browser www-browser /usr/bin/firefox 100
```

### User Profile Configuration

#### Default User Profile
Create `/etc/skel/.bashrc`:
```bash
# Distro default bashrc
export DISTRO_NAME="Our Distro"
export DISTRO_VERSION="1.0"

# Custom prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias distro-update='sudo dnf update -y'
alias distro-info='/usr/local/bin/distro-info'

# Custom functions
distro-version() {
    echo "$DISTRO_NAME $DISTRO_VERSION"
}
```

#### Desktop Configuration
Create `/etc/skel/.config/gtk-3.0/settings.ini`:
```ini
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
```

## System Monitoring

### Monitoring Configuration

#### System Metrics
Create `/etc/distro/monitoring.conf`:
```bash
# Monitoring configuration
METRICS_ENABLED=true
METRICS_INTERVAL=60
METRICS_RETENTION=7

# Metrics to collect
CPU_USAGE=true
MEMORY_USAGE=true
DISK_USAGE=true
NETWORK_USAGE=true
SERVICE_STATUS=true
```

#### Log Monitoring
Create `/etc/systemd/system/distro-logmonitor.service`:
```ini
[Unit]
Description=Distro Log Monitor
After=systemd-journald.service

[Service]
Type=simple
ExecStart=/usr/local/bin/distro-logmonitor
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```

### Health Checks

#### System Health Script
Create `/usr/local/bin/distro-healthcheck`:
```bash
#!/bin/bash
# System health check

LOG_FILE="/var/log/distro-health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Starting health check" >> $LOG_FILE

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "[$TIMESTAMP] WARNING: Disk usage at ${DISK_USAGE}%" >> $LOG_FILE
fi

# Check memory usage
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEM_USAGE -gt 90 ]; then
    echo "[$TIMESTAMP] WARNING: Memory usage at ${MEM_USAGE}%" >> $LOG_FILE
fi

# Check critical services
for service in sshd firewalld NetworkManager; do
    if ! systemctl is-active --quiet $service; then
        echo "[$TIMESTAMP] ERROR: Service $service is not running" >> $LOG_FILE
    fi
done

echo "[$TIMESTAMP] Health check completed" >> $LOG_FILE
```

## Boot Configuration

### GRUB Configuration

#### GRUB Settings
Update `/etc/default/grub`:
```bash
# Default boot settings
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Our Distro"
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true

# Boot parameters
GRUB_CMDLINE_LINUX="rhgb quiet selinux=1 enforcing=1"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

# Graphics settings
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
```

#### Custom Boot Entries
Create `/etc/grub.d/40_distro_custom`:
```bash
#!/bin/sh
exec tail -n +3 $0
# Custom boot entries

menuentry 'Our Distro - Recovery Mode' {
    saved_entry
    set saved_entry=$prev_saved_entry
    if [ -z "$boot_once" ]; then
        saved_entry=$chosen
    fi
    linux /boot/vmlinuz-$(uname -r) root=UUID=$(blkid -o value -s UUID /dev/sda1) ro single
    initrd /boot/initramfs-$(uname -r).img
}

menuentry 'Our Distro - Safe Mode' {
    saved_entry
    set saved_entry=$prev_saved_entry
    if [ -z "$boot_once" ]; then
        saved_entry=$chosen
    fi
    linux /boot/vmlinuz-$(uname -r) root=UUID=$(blkid -o value -s UUID /dev/sda1) ro 3
    initrd /boot/initramfs-$(uname -r).img
}
```

#### Update GRUB
```bash
# Update GRUB configuration
grub2-mkconfig -o /boot/grub2/grub.cfg

# For UEFI systems
grub2-mkconfig -o /boot/efi/EFI/ol/grub.cfg
```

### Init System Configuration

#### Systemd Configuration
Create `/etc/systemd/system.conf.d/distro.conf`:
```ini
[Manager]
DefaultTimeoutStartSec=30s
DefaultTimeoutStopSec=30s
DefaultTimeoutAbortSec=10s
DefaultRestartSec=10s
```

#### Journal Configuration
Create `/etc/systemd/journald.conf.d/distro.conf`:
```ini
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=1G
RuntimeMaxUse=100M
```

## Logging Configuration

### System Logging

#### Journald Configuration
```bash
# Configure persistent logging
mkdir -p /var/log/journal
systemctl restart systemd-journald

# Configure log rotation
cat > /etc/logrotate.d/distro-logs <<EOF
/var/log/distro/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
```

#### Custom Logging
Create `/etc/rsyslog.d/distro.conf`:
```bash
# Distro specific logging
:programname, isequal, "distro-service" /var/log/distro/service.log
:programname, isequal, "distro-monitor" /var/log/distro/monitor.log
& stop

# System events
*.info;mail.none;authpriv.none;cron.none /var/log/distro/system.log
```

### Log Analysis

#### Log Monitoring Script
Create `/usr/local/bin/distro-logmonitor`:
```bash
#!/bin/bash
# Log monitoring script

LOG_DIR="/var/log/distro"
ALERT_THRESHOLD=10

# Monitor error logs
tail -F $LOG_DIR/service.log | while read line; do
    if echo "$line" | grep -q "ERROR\|CRITICAL"; then
        echo "$(date): $line" >> $LOG_DIR/alerts.log
        
        # Send alert if threshold exceeded
        error_count=$(grep -c "ERROR\|CRITICAL" $LOG_DIR/alerts.log)
        if [ $error_count -gt $ALERT_THRESHOLD ]; then
            /usr/local/bin/distro-alert "High error rate detected"
        fi
    fi
done
```

## Configuration Management

### Configuration Files Structure

```
/etc/distro/
├── config.conf              # Main configuration
├── security.conf            # Security settings
├── network.conf             # Network configuration
├── monitoring.conf          # Monitoring settings
├── secrets.conf             # Sensitive data (restricted)
├── distro-release           # Release information
└── scripts/                 # Configuration scripts
    ├── setup.sh
    ├── update.sh
    └── cleanup.sh
```

### Configuration Scripts

#### Setup Script
Create `/etc/distro/scripts/setup.sh`:
```bash
#!/bin/bash
# System setup script

echo "Configuring distro system..."

# Apply system configuration
sysctl -p /etc/sysctl.d/99-distro.conf

# Configure services
systemctl daemon-reload
systemctl enable distro-manager.service
systemctl enable distro-monitor.service

# Set up logging
mkdir -p /var/log/distro
chmod 755 /var/log/distro

# Configure firewall
firewall-cmd --reload

echo "System configuration completed"
```

#### Update Script
Create `/etc/distro/scripts/update.sh`:
```bash
#!/bin/bash
# System update script

echo "Updating distro configuration..."

# Update packages
dnf update -y

# Update configuration files
cp /usr/share/distro/config/* /etc/distro/

# Restart services if needed
systemctl restart distro-manager.service

echo "Configuration update completed"
```

## Next Steps

With system configuration complete:

1. Proceed to [Branding and Identity](05-branding-and-identity.md)
2. Create visual identity and branding elements
3. Implement custom themes and artwork

## Troubleshooting

### Common Configuration Issues

#### Service Failures
```bash
# Check service status
systemctl status distro-service

# View service logs
journalctl -u distro-service

# Check configuration
systemd-analyze verify distro-service
```

#### Network Issues
```bash
# Check network configuration
nmcli connection show
ip addr show

# Test DNS resolution
nslookup distro.local
```

#### Performance Issues
```bash
# Check system performance
top
iostat
free -h

# Analyze boot performance
systemd-analyze
systemd-analyze blame
```