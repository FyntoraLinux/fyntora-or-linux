#!/bin/bash
# Complete system rebranding for FyntoraLinux

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