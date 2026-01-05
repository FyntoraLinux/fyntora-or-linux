# Troubleshooting and FAQ

This section covers comprehensive troubleshooting guides, frequently asked questions, and solutions for common issues encountered when creating and maintaining your Linux distribution.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Boot Problems](#boot-problems)
3. [Package Management Issues](#package-management-issues)
4. [Build System Problems](#build-system-problems)
5. [Network Configuration Issues](#network-configuration-issues)
6. [Performance Problems](#performance-problems)
7. [Security Issues](#security-issues)
8. [Hardware Compatibility](#hardware-compatibility)
9. [Frequently Asked Questions](#frequently-asked-questions)
10. [Debugging Tools](#debugging-tools)

## Installation Issues

### Installation Fails to Start

#### Problem: Installer doesn't boot
```bash
# Symptoms:
- System hangs after "Booting from CD/DVD"
- No boot menu appears
- Error: "No bootable device found"

# Solutions:
1. Check ISO integrity
   sha256sum distro-*.iso
   # Compare with provided checksums

2. Verify boot media creation
   # For USB drives:
   dd if=distro.iso of=/dev/sdX bs=4M status=progress
   sync

3. Check BIOS/UEFI settings
   - Ensure boot order includes USB/CD
   - Try both BIOS and UEFI modes
   - Disable secure boot temporarily

4. Try different USB port or drive
   # Some ports may not support booting
```

#### Problem: Installer crashes during startup
```bash
# Symptoms:
- Kernel panic during boot
- Installer freezes at "Starting installer"
- Error: "Failed to start graphical.target"

# Solutions:
1. Boot with different kernel parameters
   # Edit boot options (press 'e' at boot menu)
   # Add these parameters:
   quiet splash nomodeset
   # Or for debugging:
   systemd.debug=1 systemd.log_level=debug

2. Try text mode installation
   # Add to boot parameters:
   inst.text
   # Or use VNC:
   inst.vnc inst.vncpassword=password

3. Check hardware compatibility
   # Boot with live media and run:
   lspci -nn
   lsusb
   dmesg | grep -i error

4. Use different installation media
   # Try DVD instead of USB
   # Or network install:
   inst.repo=https://repo.distro.local/
```

### Installation Process Issues

#### Problem: Partition creation fails
```bash
# Symptoms:
- "Failed to create partition" error
- Disk not visible in installer
- LVM configuration errors

# Solutions:
1. Check disk status
   # In installer terminal:
   fdisk -l
   lsblk
   wipefs -a /dev/sda

2. Manually create partitions
   # Using fdisk:
   fdisk /dev/sda
   # Create partitions:
   # /dev/sda1: 512MB (EFI)
   # /dev/sda2: 2GB (swap)
   # /dev/sda3: remaining (root)

3. Clear existing partitions
   # In installer terminal:
   wipefs -a /dev/sda
   sgdisk --zap-all /dev/sda

4. Try different partitioning scheme
   # Use MBR instead of GPT for older systems
   # Or use automatic partitioning
```

#### Problem: Package installation fails
```bash
# Symptoms:
- "Failed to install package" errors
- Installation hangs at package installation
- Dependency resolution errors

# Solutions:
1. Check repository configuration
   # In installer terminal:
   cat /etc/yum.repos.d/*.repo
   ping repo.distro.local

2. Use different installation source
   # Network install:
   inst.repo=https://mirror.distro.local/
   # Or local repository:
   inst.repo=hd:LABEL=Distro:/repo

3. Skip problematic packages
   # Add to boot parameters:
   inst.nosave=all
   # Or use minimal install:
   inst.addrepo=base,https://repo.distro.local/base

4. Check disk space
   df -h
   # Ensure at least 10GB free space
```

## Boot Problems

### System Won't Boot

#### Problem: GRUB not found
```bash
# Symptoms:
- "GRUB rescue>" prompt
- "No bootable device found"
- Error: "File not found"

# Solutions:
1. Boot from live media and repair GRUB
   # Mount system:
   mount /dev/sda3 /mnt
   mount /dev/sda1 /mnt/boot/efi  # if UEFI
   
   # Reinstall GRUB:
   grub2-install /dev/sda
   # For UEFI:
   grub2-install --target=x86_64-efi --efi-directory=/mnt/boot/efi

2. Rebuild GRUB configuration
   chroot /mnt
   grub2-mkconfig -o /boot/grub2/grub.cfg
   # For UEFI:
   grub2-mkconfig -o /boot/efi/EFI/ol/grub.cfg

3. Check boot partition
   fdisk -l /dev/sda
   # Ensure boot flag is set
```

#### Problem: Kernel panic
```bash
# Symptoms:
- "Kernel panic - not syncing" error
- System hangs during boot
- Error: "Unable to mount root fs"

# Solutions:
1. Boot with previous kernel
   # At GRUB menu, select "Advanced options"
   # Choose previous kernel version

2. Check initramfs
   # Boot from live media:
   mount /dev/sda3 /mnt
   chroot /mnt
   dracut -f

3. Verify root filesystem
   # In GRUB, edit kernel parameters:
   # Add: root=UUID=$(blkid -s UUID -o value /dev/sda3)

4. Check for hardware issues
   # Add to kernel parameters:
   acpi=off noapic
   # Or:
   pci=nomsi
```

### Boot Performance Issues

#### Problem: Slow boot time
```bash
# Symptoms:
- Boot takes > 2 minutes
- Long delays at services
- System hangs at "Reached target"

# Solutions:
1. Analyze boot performance
   systemd-analyze
   systemd-analyze blame
   systemd-analyze critical-chain

2. Disable unnecessary services
   systemctl disable bluetooth
   systemctl disable cups
   systemctl disable avahi-daemon

3. Optimize filesystem checks
   tune2fs -c 0 /dev/sda3
   tune2fs -i 0 /dev/sda3

4. Update initramfs
   dracut -f --regenerate-all
```

## Package Management Issues

### Repository Problems

#### Problem: Repository not accessible
```bash
# Symptoms:
- "Cannot download metadata" error
- "Failed to synchronize cache"
- Network timeout errors

# Solutions:
1. Check network connectivity
   ping repo.distro.local
   curl -I https://repo.distro.local/

2. Verify repository configuration
   cat /etc/yum.repos.d/distro.repo
   # Check baseurl and enabled status

3. Clear DNF cache
   dnf clean all
   rm -rf /var/cache/dnf/*

4. Use alternative mirror
   # Edit repo file:
   baseurl=https://mirror1.distro.local/
```

#### Problem: Package conflicts
```bash
# Symptoms:
- "package conflicts with" error
- "file conflicts with" error
- Dependency resolution failures

# Solutions:
1. Identify conflicting packages
   dnf check
   dnf repoquery --conflicts package-name

2. Remove conflicting packages
   dnf remove conflicting-package
   # Or use:
   dnf install --allowerasing package-name

3. Clean package database
   rpm --rebuilddb
   dnf makecache

4. Force installation (if necessary)
   dnf install --nodeps package-name
   # Use with caution
```

### Package Installation Issues

#### Problem: Package installation fails
```bash
# Symptoms:
- "Failed to install package" error
- Scriptlet failures
- Permission denied errors

# Solutions:
1. Check package integrity
   rpm -K package-name.rpm
   # Should return "package is not signed" or "digest signatures OK"

2. Verify dependencies
   dnf deplist package-name
   dnf install --downloadonly package-name

3. Check disk space
   df -h
   # Ensure sufficient space in /var and /

4. Install manually
   rpm -ivh --nodeps package-name.rpm
   # Then resolve dependencies
```

## Build System Problems

### Build Failures

#### Problem: Mock build fails
```bash
# Symptoms:
- "Build failed" in mock
- "No package named" errors
- Permission denied errors

# Solutions:
1. Check mock configuration
   mock -r distro-build --list-configs
   mock -r distro-build --dump-configs

2. Clean mock chroot
   mock -r distro-build --clean
   mock -r distro-build --init

3. Install build dependencies
   dnf builddep package-name.src.rpm
   mock -r distro-build --installdeps package-name.src.rpm

4. Check build logs
   # Logs in:
   /var/lib/mock/distro-build/result/
   # Look for build.log and root.log
```

#### Problem: Source compilation fails
```bash
# Symptoms:
- "make: *** [Error]" messages
- "configure: error:" messages
- Missing header files

# Solutions:
1. Check build requirements
   cat package-name.spec | grep BuildRequires
   # Install missing dependencies

2. Clean source directory
   make clean
   make distclean
   # Or:
   git clean -fdx

3. Configure with different options
   ./configure --prefix=/usr --sysconfdir=/etc
   # Check configure --help for options

4. Update build tools
   dnf update gcc make autoconf
```

### ISO Creation Issues

#### Problem: ISO creation fails
```bash
# Symptoms:
- "xorriso failed" error
- "Not enough space" error
- Missing boot files

# Solutions:
1. Check available space
   df -h /opt/distro-build
   # Ensure at least 10GB free

2. Verify kickstart file
   ksvalidator distro-live.ks
   # Fix any syntax errors

3. Check boot configuration
   # Ensure isolinux files exist:
   ls -la /usr/share/syslinux/
   # Copy missing files to build directory

4. Use different ISO creation method
   # Try genisoimage instead of xorriso
   genisoimage -o output.iso -b isolinux.bin -c boot.cat .
```

## Network Configuration Issues

### Network Not Working

#### Problem: No network connection
```bash
# Symptoms:
- "Network is unreachable"
- "Name or service not known"
- No IP address assigned

# Solutions:
1. Check network interface status
   ip addr show
   ip link show
   # Enable interface if down:
   ip link set eth0 up

2. Restart NetworkManager
   systemctl restart NetworkManager
   nmcli connection show

3. Check DHCP
   # Request IP:
   dhclient eth0
   # Or:
   nmcli dev connect eth0

4. Manual configuration
   ip addr add 192.168.1.100/24 dev eth0
   ip route add default via 192.168.1.1
   echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### Problem: Wireless not working
```bash
# Symptoms:
- Wi-Fi not detected
- "No network interfaces available"
- Connection fails

# Solutions:
1. Check wireless adapter
   lspci | grep -i wireless
   lsusb | grep -i wireless
   # Note driver name

2. Install firmware
   dnf install linux-firmware
   # Or specific firmware:
   dnf install iwl1000-firmware

3. Load driver module
   modprobe driver_name
   # Add to /etc/modules-load.d/

4. Configure with NetworkManager
   nmcli dev wifi list
   nmcli dev wifi connect SSID password password
```

### DNS Resolution Issues

#### Problem: Cannot resolve hostnames
```bash
# Symptoms:
- "Temporary failure in name resolution"
- Can ping IP but not hostname
- nslookup fails

# Solutions:
1. Check DNS configuration
   cat /etc/resolv.conf
   # Should contain nameserver entries

2. Test DNS servers
   nslookup google.com 8.8.8.8
   nslookup google.com 1.1.1.1

3. Restart systemd-resolved
   systemctl restart systemd-resolved
   # Or use traditional DNS:
   systemctl disable systemd-resolved
   echo "nameserver 8.8.8.8" > /etc/resolv.conf

4. Check firewall
   firewall-cmd --list-all
   # Ensure DNS port 53 is open
```

## Performance Problems

### System Slow

#### Problem: High CPU usage
```bash
# Symptoms:
- System sluggish
- High load average
- Processes unresponsive

# Solutions:
1. Identify CPU-consuming processes
   top
   htop
   # Sort by CPU usage

2. Check for runaway processes
   ps aux --sort=-%cpu | head -10
   # Kill if necessary:
   kill -9 PID

3. Check system load
   uptime
   w
   # Load average should be < number of CPUs

4. Optimize system services
   systemctl disable unnecessary-service
   # Reduce background processes
```

#### Problem: High memory usage
```bash
# Symptoms:
- System swapping
- Out of memory errors
- Applications closing

# Solutions:
1. Check memory usage
   free -h
   # Look at used/available memory

2. Identify memory-consuming processes
   ps aux --sort=-%mem | head -10
   # Check for memory leaks

3. Clear caches
   sync
   echo 3 > /proc/sys/vm/drop_caches

4. Add swap space
   fallocate -l 2G /swapfile
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
```

### Disk Performance Issues

#### Problem: Slow disk I/O
```bash
# Symptoms:
- Applications take long to start
- File operations slow
- High iowait

# Solutions:
1. Check disk performance
   iostat -x 1
   # Look at %util and await

2. Check for disk errors
   dmesg | grep -i error
   smartctl -a /dev/sda

3. Optimize filesystem
   tune2fs -o journal_data_writeback /dev/sda3
   # Or use noatime:
   mount -o remount,noatime /

4. Check for disk fragmentation
   # For ext4:
   e4defrag /dev/sda3
```

## Security Issues

### SELinux Problems

#### Problem: SELinux denials
```bash
# Symptoms:
- "Permission denied" errors
- Services not starting
- AVC denials in logs

# Solutions:
1. Check SELinux status
   sestatus
   # Should be "enforcing"

2. Review denials
   ausearch -m avc -ts recent
   sealert -a /var/log/audit/audit.log

3. Fix context issues
   restorecon -R -v /path/to/file
   # Check context:
   ls -Z /path/to/file

4. Create local policy
   audit2allow -M local_policy -a
   semodule -i local_policy.pp
```

#### Problem: Cannot disable SELinux
```bash
# Symptoms:
- SELinux won't disable
- "setenforce: command not found"
- Policy errors

# Solutions:
1. Install SELinux tools
   dnf install policycoreutils-python-utils

2. Temporarily disable
   setenforce 0
   # Permanently:
   sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

3. Check policy
   semodule -l
   # Reload if necessary:
   semodule -R
```

### Firewall Issues

#### Problem: Services not accessible
```bash
# Symptoms:
- Cannot connect to services
- "Connection refused" errors
- Services work locally but not remotely

# Solutions:
1. Check firewall status
   firewall-cmd --state
   firewall-cmd --list-all

2. Open required ports
   firewall-cmd --add-service=http --permanent
   firewall-cmd --add-port=8080/tcp --permanent
   firewall-cmd --reload

3. Check specific rules
   firewall-cmd --list-all
   # Verify service is enabled

4. Test connectivity
   telnet server_ip port
   # Or:
   nc -zv server_ip port
```

## Hardware Compatibility

### Graphics Issues

#### Problem: No display or wrong resolution
```bash
# Symptoms:
- Black screen after boot
- Low resolution (640x480)
- No 3D acceleration

# Solutions:
1. Identify graphics card
   lspci | grep -i vga
   lspci | grep -i nvidia
   lspci | grep -i amd

2. Install appropriate drivers
   # For NVIDIA:
   dnf install akmod-nvidia
   # For AMD:
   dnf install xorg-x11-drv-amdgpu

3. Configure X11
   # Create /etc/X11/xorg.conf.d/20-gpu.conf
   # Add driver configuration

4. Test with different drivers
   # Try modesetting driver:
   # Add to kernel parameters:
   nomodeset
```

### Audio Issues

#### Problem: No sound
```bash
# Symptoms:
- No audio output
- "Dummy output" in sound settings
- Audio device not detected

# Solutions:
1. Check audio hardware
   lspci | grep -i audio
   aplay -l
   # List audio devices

2. Check ALSA
   alsamixer
   # Ensure channels are unmuted (press 'M')

3. Install audio drivers
   dnf install alsa-firmware
   # For specific hardware:
   dnf install kmod-intel-sound

4. Test audio
   speaker-test -c 2
   # Or:
   aplay /usr/share/sounds/alsa/Front_Center.wav
```

## Frequently Asked Questions

### General Questions

#### Q: How much disk space is needed for the build system?
A: Minimum 100GB, recommended 500GB+ for full development including:
- 50GB for base system
- 100GB for package sources
- 200GB for build artifacts
- 150GB for ISO images and testing

#### Q: Can I build on a virtual machine?
A: Yes, but ensure:
- At least 8GB RAM (16GB recommended)
- 50GB+ disk space
- Enable virtualization extensions (VT-x/AMD-V)
- Use bridged networking for repository access

#### Q: How long does a complete build take?
A: Depends on hardware:
- 8-core, 16GB RAM: ~4-6 hours
- 16-core, 32GB RAM: ~2-3 hours
- 32-core, 64GB RAM: ~1-2 hours

### Installation Questions

#### Q: Can I upgrade from Oracle Linux to my distro?
A: Direct upgrade is not recommended. Perform fresh installation:
- Backup data from Oracle Linux
- Install your distro
- Restore data and applications

#### Q: How do I dual boot with Windows?
A: Follow these steps:
1. Install Windows first
2. Create free space for Linux
3. Install your distro to free space
4. GRUB will automatically detect Windows

#### Q: Can I install on UEFI systems?
A: Yes, ensure:
- Create EFI System Partition (512MB, FAT32)
- Use UEFI bootable ISO
- Enable UEFI mode in BIOS
- Disable secure boot or enroll keys

### Package Questions

#### Q: How do I add Oracle Linux repositories?
A: Add to `/etc/yum.repos.d/ol.repo`:
```ini
[ol9_baseos]
name=Oracle Linux BaseOS
baseurl=https://yum.oracle.com/repo/OracleLinux/ol9/baseos/latest/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
```

#### Q: Can I use RPMs from other distributions?
A: Generally not recommended due to:
- Different dependency versions
- Library compatibility issues
- Configuration file conflicts
- Use source packages and rebuild instead

#### Q: How do I create my own packages?
A: Follow these steps:
1. Create spec file
2. Prepare source tarball
3. Use mock or rpmbuild to build
4. Test package installation
5. Add to your repository

### Build Questions

#### Q: Why do my builds keep failing?
A: Common causes:
- Missing build dependencies
- Incorrect spec file syntax
- Insufficient disk space
- Permission issues
- Network connectivity problems

#### Q: How do I debug build failures?
A: Use these methods:
1. Check build logs in mock result directory
2. Use `mock --shell` to inspect chroot
3. Build manually outside mock first
4. Use `rpmbuild --verbose` for detailed output

#### Q: Can I build multiple architectures?
A: Yes, but you need:
- Cross-compilation toolchain
- Target-specific mock configurations
- Sufficient build resources
- Separate build directories

### Security Questions

#### Q: Is my distribution secure?
A: Security depends on:
- Regular security updates
- Proper configuration
- SELinux enforcement
- Firewall configuration
- Security best practices

#### Q: How do I handle security updates?
A: Implement these practices:
1. Subscribe to security advisories
2. Test updates in staging environment
3. Apply updates regularly
4. Monitor security logs
5. Use automated update tools

#### Q: Should I use SELinux?
A: Yes, SELinux provides:
- Mandatory access control
- Process isolation
- File system protection
- Network security
- Zero-day exploit mitigation

## Debugging Tools

### System Diagnostics

#### System Information Script
Create `scripts/system-diagnostic.sh`:
```bash
#!/bin/bash
# System diagnostic tool

echo "=== System Diagnostic Report ==="
echo "Generated: $(date)"
echo ""

# System information
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Memory information
echo "=== Memory Information ==="
free -h
echo ""

# Disk information
echo "=== Disk Information ==="
df -h
echo ""

# Network information
echo "=== Network Information ==="
ip addr show
echo ""
ip route show
echo ""

# Service status
echo "=== Service Status ==="
systemctl list-units --failed
echo ""

# Recent errors
echo "=== Recent Errors ==="
journalctl -p err --since "1 hour ago" | tail -20
echo ""

# Hardware information
echo "=== Hardware Information ==="
lspci | head -10
echo ""
lsusb | head -5
echo ""
```

#### Boot Analysis Script
Create `scripts/boot-analysis.sh`:
```bash
#!/bin/bash
# Boot performance analysis

echo "=== Boot Analysis ==="

# Overall boot time
echo "Boot time: $(systemd-analyze)"
echo ""

# Service timing
echo "=== Service Timing ==="
systemd-analyze blame | head -20
echo ""

# Critical chain
echo "=== Critical Chain ==="
systemd-analyze critical-chain
echo ""

# Boot chart
echo "Generating boot chart..."
systemd-analyze plot > /tmp/boot-chart.svg
echo "Boot chart saved to /tmp/boot-chart.svg"
```

### Package Diagnostics

#### Repository Check Script
Create `scripts/repo-check.sh`:
```bash
#!/bin/bash
# Repository diagnostic tool

REPO_DIR="/opt/distro-repo"

echo "=== Repository Diagnostic Report ==="
echo "Repository: $REPO_DIR"
echo "Generated: $(date)"
echo ""

# Repository size
echo "=== Repository Size ==="
du -sh "$REPO_DIR"
echo ""

# Package count
echo "=== Package Count ==="
echo "Total packages: $(find "$REPO_DIR" -name "*.rpm" | wc -l)"
echo "Source packages: $(find "$REPO_DIR" -name "*.src.rpm" | wc -l)"
echo "Binary packages: $(find "$REPO_DIR" -name "*.x86_64.rpm" | wc -l)"
echo ""

# Repository metadata
echo "=== Repository Metadata ==="
if [ -f "$REPO_DIR/repodata/repomd.xml" ]; then
    echo "Metadata exists: YES"
    echo "Metadata size: $(du -sh "$REPO_DIR/repodata" | cut -f1)"
    echo "Last updated: $(stat -c %y "$REPO_DIR/repodata/repomd.xml")"
else
    echo "Metadata exists: NO"
fi
echo ""

# Check for broken packages
echo "=== Package Integrity ==="
broken_count=0
for rpm_file in "$REPO_DIR"/RPMS/*/*.rpm; do
    if [ -f "$rpm_file" ]; then
        if ! rpm -K "$rpm_file" >/dev/null 2>&1; then
            echo "Broken package: $(basename "$rpm_file")"
            broken_count=$((broken_count + 1))
        fi
    fi
done

if [ "$broken_count" -eq 0 ]; then
    echo "All packages appear to be intact"
else
    echo "Found $broken_count broken packages"
fi
```

## Next Steps

With troubleshooting documentation complete:

1. Review all documentation sections
2. Test procedures in your environment
3. Create support infrastructure
4. Prepare for community support

## Getting Help

### Support Channels

- **Documentation**: Review relevant sections
- **Community Forums**: https://community.distro.local
- **Bug Reports**: https://bugs.distro.local
- **Security Issues**: security@distro.local
- **Mailing Lists**: distro-users@distro.local

### Reporting Issues

When reporting issues, include:
1. System information (use diagnostic scripts)
2. Error messages and logs
3. Steps to reproduce
4. Expected vs actual behavior
5. Hardware specifications

### Contributing Fixes

If you find and fix issues:
1. Document the solution
2. Test thoroughly
3. Submit patches
4. Update documentation
5. Share with community