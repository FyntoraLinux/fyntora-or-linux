# YourDistro Independence Builder - Complete Installation

## 🚀 ONE-CLICK INSTALLATION

This master script automatically configures everything and moves all scripts to their proper locations.

### QUICK START

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/yourdistro/independence/main/install-yourdistro.sh | bash

# Or download and run manually
wget https://raw.githubusercontent.com/yourdistro/independence/main/install-yourdistro.sh
chmod +x install-yourdistro.sh
sudo ./install-yourdistro.sh
```

## 📋 WHAT THE INSTALLER DOES

### ✅ **AUTOMATIC SETUP**
- Creates all directory structure
- Installs required packages
- Sets up build user and permissions
- Configures mock for package building
- Creates all scripts in `/usr/local/bin/`
- Sets up systemd services
- Configures GRUB and Plymouth themes
- Creates desktop themes
- Sets up repository configuration
- Creates GPG signing infrastructure

### ✅ **SCRIPTS INSTALLED**
- `/usr/local/bin/build-yourdistro.sh` - Main build system
- `/usr/local/bin/achieve-independence.sh` - Complete independence
- `/usr/local/bin/yourdistro-update-manager` - Update system
- `/usr/local/bin/yourdistro-help` - Help system
- `/usr/local/bin/remove-oracle-branding.sh` - Branding removal
- `/usr/local/bin/complete-rebrand.sh` - System rebranding
- `/usr/local/bin/verify-independence.sh` - Independence verification
- `/usr/local/bin/setup-yourdistro-signing.sh` - GPG setup

### ✅ **SYSTEM CONFIGURATION**
- Identity files (`/etc/yourdistro-release`, `/etc/os-release`)
- Repository configuration (`/etc/yum.repos.d/yourdistro.repo`)
- Systemd services enabled
- Desktop themes applied
- Boot customization complete
- Documentation installed

## 🎯 POST-INSTALLATION

### **Step 1: Reboot**
```bash
sudo reboot
```

### **Step 2: Achieve Independence**
```bash
achieve-independence.sh
```

### **Step 3: Build Your Distro**
```bash
build-yourdistro.sh all
```

### **Step 4: Test Updates**
```bash
yourdistro-update-manager check
```

## 📁 FILE LOCATIONS

| Purpose | Location |
|---------|----------|
| Main Scripts | `/usr/local/bin/` |
| Configuration | `/etc/yourdistro/` |
| Build Directory | `/opt/yourdistro/` |
| Documentation | `/usr/share/yourdistro/docs/` |
| Logs | `/var/log/yourdistro/` |
| Themes | `/usr/share/themes/yourdistro/` |
| Boot Themes | `/boot/grub2/themes/yourdistro/` |

## 🔧 CUSTOMIZATION

### **Change Distro Name**
Edit `/etc/yourdistro/config.sh`:
```bash
DISTRO_NAME="MyCustomDistro"
DISTRO_ID="mycustomdistro"
```

### **Add Custom Packages**
Place `.spec` files in:
- `/opt/yourdistro/sources/core/`
- `/opt/yourdistro/sources/desktop/`

### **Custom Branding**
Replace files in:
- `/usr/share/yourdistro/branding/`
- `/boot/grub2/themes/yourdistro/`

## 🚨 TROUBLESHOOTING

### **Permission Issues**
```bash
sudo chown -R yourdistro:yourdistro /opt/yourdistro
sudo chmod +x /usr/local/bin/yourdistro-*
```

### **Service Failures**
```bash
systemctl status yourdistro-welcome
journalctl -u yourdistro-welcome
```

### **Build Issues**
```bash
mock -r yourdistro --clean
build-yourdistro.sh packages
```

## 🎉 INDEPENDENCE ACHIEVED

After running `achieve-independence.sh` you will have:

✅ **100% Independent Linux Distribution**  
✅ **No Oracle Dependencies**  
✅ **Custom Branding**  
✅ **Independent Repository**  
✅ **Custom Update System**  
✅ **Professional Build Infrastructure**  

## 📞 SUPPORT

- **Help Command**: `yourdistro-help`
- **Documentation**: `/usr/share/yourdistro/docs/`
- **Logs**: `/var/log/yourdistro/`
- **Verification**: `verify-independence.sh`

---

**Ready to achieve independence? Run the installer and then `achieve-independence.sh`!** 🚀