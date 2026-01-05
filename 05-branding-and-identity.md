# Branding and Identity

This section covers creating a unique visual identity, branding elements, and user experience customization for your Linux distribution.

## Table of Contents

1. [Brand Identity Development](#brand-identity-development)
2. [Visual Design Elements](#visual-design-elements)
3. [Desktop Themes](#desktop-themes)
4. [Boot Splash and Login](#boot-splash-and-login)
5. [System Branding](#system-branding)
6. [Documentation Branding](#documentation-branding)
7. [Marketing Materials](#marketing-materials)
8. [Brand Guidelines](#brand-guidelines)

## Brand Identity Development

### Naming Your Distribution

#### Naming Considerations
- **Uniqueness**: Ensure the name isn't already in use
- **Memorability**: Easy to remember and pronounce
- **Relevance**: Reflects the distribution's purpose
- **Legal**: Check trademark availability
- **Technical**: Compatible with file naming conventions

#### Name Examples
```bash
# Examples of good distro names
- "NexusOS" - Suggests connectivity and integration
- "VertexLinux" - Implies peak performance
- "CatalystOS" - Indicates transformation and change
- "FoundationLinux" - Emphasizes stability and reliability
```

#### Brand Name Registration
```bash
# Create brand configuration
cat > /etc/distro/brand.conf <<EOF
DISTRO_NAME="NexusOS"
DISTRO_ID="nexusos"
DISTRO_VERSION="1.0"
DISTRO_CODENAME="fusion"
DISTRO_TAGLINE="Connecting Innovation"
DISTRO_WEBSITE="https://nexusos.org"
DISTRO_SUPPORT="https://support.nexusos.org"
EOF
```

### Logo Design

#### Logo Requirements
- **Scalability**: Must work at all sizes (16px to 1024px)
- **Formats**: SVG (vector), PNG (raster), ICO (Windows)
- **Variants**: Full color, monochrome, inverted
- **Aspect Ratio**: Square or horizontal variants

#### Logo Creation Process
```bash
# Create logo directory structure
mkdir -p /usr/share/distro/branding/{logo,icons,wallpapers}

# SVG logo (master file)
# Create scalable vector logo using Inkscape or similar tool
# Save as /usr/share/distro/branding/logo/nexusos-logo.svg
```

#### Logo Variants
```bash
# Required logo formats and sizes
/usr/share/distro/branding/logo/
├── nexusos-logo.svg              # Master vector logo
├── nexusos-logo-256.png          # Large PNG
├── nexusos-logo-128.png          # Medium PNG
├── nexusos-logo-64.png           # Small PNG
├── nexusos-logo-32.png           # Icon size
├── nexusos-logo-16.png           # Tiny size
├── nexusos-logo-mono.svg         # Monochrome version
└── nexusos-logo-inverted.svg     # Dark background version
```

### Color Palette

#### Primary Colors
```bash
# Define color scheme
cat > /etc/distro/colors.conf <<EOF
# Primary Colors
PRIMARY_MAIN="#2E7D32"          # Deep Green
PRIMARY_LIGHT="#4CAF50"         # Light Green
PRIMARY_DARK="#1B5E20"          # Dark Green

# Secondary Colors
SECONDARY_MAIN="#1976D2"        # Deep Blue
SECONDARY_LIGHT="#42A5F5"       # Light Blue
SECONDARY_DARK="#0D47A1"        # Dark Blue

# Accent Colors
ACCENT_ORANGE="#FF6F00"         # Orange Accent
ACCENT_PURPLE="#7B1FA2"         # Purple Accent

# Neutral Colors
TEXT_PRIMARY="#212121"          # Main Text
TEXT_SECONDARY="#757575"        # Secondary Text
BACKGROUND="#FAFAFA"            # Light Background
SURFACE="#FFFFFF"               # White Surface
EOF
```

#### Color Implementation
```bash
# Create CSS color variables
cat > /usr/share/distro/branding/colors.css <<EOF
:root {
    /* Primary Colors */
    --primary-main: #2E7D32;
    --primary-light: #4CAF50;
    --primary-dark: #1B5E20;
    
    /* Secondary Colors */
    --secondary-main: #1976D2;
    --secondary-light: #42A5F5;
    --secondary-dark: #0D47A1;
    
    /* Accent Colors */
    --accent-orange: #FF6F00;
    --accent-purple: #7B1FA2;
    
    /* Neutral Colors */
    --text-primary: #212121;
    --text-secondary: #757575;
    --background: #FAFAFA;
    --surface: #FFFFFF;
}
EOF
```

## Visual Design Elements

### Typography

#### Font Selection
```bash
# Install custom fonts
mkdir -p /usr/share/fonts/distro

# Primary font (sans-serif)
# Download and install custom sans-serif font
fc-cache -fv

# Font configuration
cat > /etc/distro/fonts.conf <<EOF
# Font Configuration
PRIMARY_FONT="Inter"
MONOSPACE_FONT="JetBrains Mono"
TITLE_FONT="Montserrat"
EOF
```

#### Font Implementation
```bash
# Create font configuration
cat > /etc/fonts/conf.d/99-distro-fonts.conf <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <alias>
        <family>sans-serif</family>
        <prefer><family>Inter</family></prefer>
    </alias>
    <alias>
        <family>monospace</family>
        <prefer><family>JetBrains Mono</family></prefer>
    </alias>
    <alias>
        <family>serif</family>
        <prefer><family>Montserrat</family></prefer>
    </alias>
</fontconfig>
EOF
```

### Icon Theme

#### Custom Icon Set
```bash
# Create icon theme directory
mkdir -p /usr/share/icons/distro/{16x16,22x22,24x24,32x32,48x48,64x64,128x128,256x256,scalable}

# Icon theme definition
cat > /usr/share/icons/distro/index.theme <<EOF
[Icon Theme]
Name=Distro Icons
Comment=Custom icon theme for NexusOS
Inherits=Adwaita

Directories=16x16,22x22,24x24,32x32,48x48,64x64,128x128,256x256,scalable

[16x16]
Size=16
Context=Applications
Type=Fixed

[256x256]
Size=256
Context=Applications
Type=Fixed

[scalable]
Size=48
Context=Applications
Type=Scalable
MinSize=8
MaxSize=256
EOF
```

#### Application Icons
```bash
# Create custom application icons
# Replace standard application icons with branded versions
cp /usr/share/distro/branding/logo/nexusos-logo-64.png /usr/share/icons/distro/64x64/apps/distro-launcher.png
cp /usr/share/distro/branding/logo/nexusos-logo.svg /usr/share/icons/distro/scalable/apps/distro-launcher.svg
```

### Cursor Theme

#### Custom Cursor Design
```bash
# Create cursor theme
mkdir -p /usr/share/icons/distro-cursors/{cursors,scalable}

# Cursor theme definition
cat > /usr/share/icons/distro-cursors/index.theme <<EOF
[Icon Theme]
Name=Distro Cursors
Comment=Custom cursor theme for NexusOS

Inherits=Adwaita
EOF
```

## Desktop Themes

### GTK Theme

#### Theme Structure
```bash
# Create GTK theme directory
mkdir -p /usr/share/themes/Distro/{gtk-3.0,gtk-4.0}
```

#### GTK 3 Theme
Create `/usr/share/themes/Distro/gtk-3.0/gtk.css`:
```css
/* Distro GTK Theme */
@import url("colors.css");

* {
    -GtkArrow-arrow-scaling: 0.5;
    -GtkButton-child-displacement-x: 0;
    -GtkButton-child-displacement-y: 0;
    -GtkCheckButton-indicator-size: 16;
    -GtkEntry-inner-border: 2;
    -GtkEntry-progress-border: 2;
    -GtkExpander-expander-size: 16;
    -GtkHTML-link-color: @link_color;
    -GtkIMModule-hilight-thickness: 2;
    -GtkMenu-horizontal-padding: 0;
    -GtkMenu-vertical-padding: 0;
    -GtkPaned-handle-size: 6;
    -GtkProgressBar-min-horizontal-bar-height: 10;
    -GtkProgressBar-min-vertical-bar-height: 10;
    -GtkRange-trough-border: 2;
    -GtkRange-slider-width: 14;
    -GtkRange-stepper-size: 14;
    -GtkRange-trough-under-steppers: 1;
    -GtkScrollbar-has-backward-stepper: 0;
    -GtkScrollbar-has-forward-stepper: 0;
    -GtkScrollbar-min-slider-length: 30;
    -GtkScrolledWindow-scrollbar-spacing: 0;
    -GtkScrolledWindow-scrollbars-within-bevel: 1;
    -GtkSeparatorMenuItem-horizontal-padding: 0;
    -GtkStatusbar-shadow-type: none;
    -GtkTextView-error-underline-color: @error_color;
    -GtkToolButton-icon-spacing: 0;
    -GtkToolItemGroup-expander-size: 11;
    -GtkTreeView-expander-size: 11;
    -GtkTreeView-vertical-separator: 0;
    -GtkWidget-focus-line-width: 1;
    -GtkWidget-focus-padding: 4;
    -GtkWidget-link-color: @link_color;
    -GtkWidget-visited-link-color: @visited_link_color;

    background-color: @theme_bg_color;
    color: @theme_fg_color;
}

/* Application-specific styling */
.window {
    background-color: @theme_bg_color;
    border: 1px solid @borders;
}

.button {
    background-image: linear-gradient(to bottom, 
                                      shade(@theme_bg_color, 1.1),
                                      shade(@theme_bg_color, 0.9));
    border: 1px solid @borders;
    border-radius: 3px;
    color: @theme_fg_color;
}

.button:hover {
    background-image: linear-gradient(to bottom, 
                                      shade(@theme_selected_bg_color, 1.1),
                                      shade(@theme_selected_bg_color, 0.9));
    color: @theme_selected_fg_color;
}

.entry {
    background-color: @base_color;
    border: 1px solid @borders;
    border-radius: 3px;
    color: @text_color;
    padding: 4px;
}
```

#### GTK 4 Theme
Create `/usr/share/themes/Distro/gtk-4.0/gtk.css`:
```css
/* Distro GTK 4 Theme */
@define-color theme_bg_color #FAFAFA;
@define-color theme_fg_color #212121;
@define-color theme_selected_bg_color #2E7D32;
@define-color theme_selected_fg_color #FFFFFF;
@define-color base_color #FFFFFF;
@define-color text_color #212121;
@define-color borders #CCCCCC;

window {
    background-color: @theme_bg_color;
}

button {
    background-color: shade(@theme_bg_color, 0.9);
    border: 1px solid @borders;
    border-radius: 6px;
    color: @theme_fg_color;
    padding: 8px 16px;
    transition: all 200ms ease;
}

button:hover {
    background-color: @theme_selected_bg_color;
    color: @theme_selected_fg_color;
}

entry {
    background-color: @base_color;
    border: 2px solid @borders;
    border-radius: 4px;
    color: @text_color;
    padding: 8px;
}

entry:focus {
    border-color: @theme_selected_bg_color;
}
```

### Qt Theme

#### KDE/Qt Theme Configuration
```bash
# Create Qt theme configuration
mkdir -p /usr/share/kde4/apps/kstyle/themes
mkdir -p /usr/share/Qt5/gtk3
```

#### Qt Theme CSS
Create `/usr/share/Qt5/gtk3/distro-qt.css`:
```css
/* Distro Qt Theme */
QMainWindow {
    background-color: #FAFAFA;
    color: #212121;
}

QPushButton {
    background-color: #4CAF50;
    border: none;
    border-radius: 4px;
    color: white;
    padding: 8px 16px;
    font-weight: bold;
}

QPushButton:hover {
    background-color: #2E7D32;
}

QLineEdit {
    background-color: white;
    border: 2px solid #CCCCCC;
    border-radius: 4px;
    padding: 6px;
    color: #212121;
}

QLineEdit:focus {
    border-color: #2E7D32;
}
```

## Boot Splash and Login

### Plymouth Boot Splash

#### Plymouth Theme
```bash
# Create Plymouth theme directory
mkdir -p /usr/share/plymouth/themes/distro
```

#### Plymouth Theme Configuration
Create `/usr/share/plymouth/themes/distro/distro.plymouth`:
```ini
[Plymouth Theme]
Name=Distro Splash
Description=Custom boot splash for NexusOS
ModuleName=two-step

[two-step]
ImageDir=/usr/share/plymouth/themes/distro
HorizontalAlignment=.5
VerticalAlignment=.5
BackgroundStartColor=0x2E7D32
BackgroundEndColor=0x1B5E20
TransitionDuration=0.5
TransitionForegroundFile=logo.png
BackgroundForegroundColor=0xFFFFFF
```

#### Plymouth Script
Create `/usr/share/plymouth/themes/distro/distro.script`:
```bash
# Plymouth boot script
logo_image = Image("logo.png");
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

logo_sprite = Sprite(logo_image);
logo_sprite.SetX(screen_width / 2 - logo_image.GetWidth() / 2);
logo_sprite.SetY(screen_height / 2 - logo_image.GetHeight() / 2);

fun dialog_callback() {
    status = "normal";
}

fun display_callback(dialog) {
    status = "dialog";
}

# Set up callbacks
Plymouth.SetBootProgressFunction(dialog_callback);
Plymouth.SetMessageFunction(display_callback);
```

### Login Screen Branding

#### GDM Theme
```bash
# Create GDM theme directory
mkdir -p /usr/share/gnome-shell/theme/distro
```

#### GDM CSS Theme
Create `/usr/share/gnome-shell/theme/distro/gnome-shell.css`:
```css
/* Distro GDM Theme */
#lockDialogGroup {
    background-color: #2E7D32;
    background-image: url("background.jpg");
    background-size: cover;
    background-position: center;
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

.login-dialog-user-list-view {
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 8px;
}
```

#### SDDM Theme (KDE)
```bash
# Create SDDM theme directory
mkdir -p /usr/share/sddm/themes/distro
```

#### SDDM Theme Configuration
Create `/usr/share/sddm/themes/distro/theme.conf`:
```ini
[General]
# Theme name
Name=Distro Theme
Description=Custom SDDM theme for NexusOS
# Theme author
Author=Distro Team
# Theme version
Version=1.0.0
# Theme license
License=CC-BY-SA

[Settings]
# Whether to show the hostname
ShowHostname=true
# Whether to show the password field
ShowPassword=true
# Background color
BackgroundColor=#2E7D32
# Background image
BackgroundImage=background.jpg

[Auth]
# Login button text
LoginText=LOG IN
# Password prompt
PasswordPrompt=Password:
# Failed login message
FailedLoginMessage=Login failed
```

## System Branding

### Release Information

#### OS Release File
Create `/etc/distro-release`:
```bash
NexusOS 1.0 (Fusion)
```

Create `/etc/os-release`:
```bash
NAME="NexusOS"
VERSION="1.0 (Fusion)"
ID="nexusos"
ID_LIKE="ol"
PRETTY_NAME="NexusOS 1.0 (Fusion)"
VERSION_ID="1.0"
HOME_URL="https://nexusos.org"
SUPPORT_URL="https://support.nexusos.org"
BUG_REPORT_URL="https://bugs.nexusos.org"
```

#### LSB Release
Create `/etc/lsb-release`:
```bash
DISTRIB_ID=NexusOS
DISTRIB_DESCRIPTION="NexusOS 1.0 (Fusion)"
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=fusion
```

### System Information

#### Distro Info Tool
Create `/usr/local/bin/distro-info`:
```bash
#!/bin/bash
# Distro information tool

source /etc/distro/brand.conf

echo "Distribution: $DISTRO_NAME"
echo "Version: $DISTRO_VERSION"
echo "Codename: $DISTRO_CODENAME"
echo "Tagline: $DISTRO_TAGLINE"
echo "Website: $DISTRO_WEBSITE"
echo "Support: $DISTRO_SUPPORT"

# System information
echo ""
echo "System Information:"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime: $(uptime -p)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
```

### Welcome Screen

#### First Run Experience
Create `/usr/local/bin/distro-welcome`:
```bash
#!/bin/bash
# Welcome screen for first-time users

source /etc/distro/brand.conf

# Create welcome dialog
yad --title="Welcome to $DISTRO_NAME" \
    --text="Welcome to $DISTRO_NAME $DISTRO_VERSION!\n\n$DISTRO_TAGLINE\n\nThis appears to be your first time running $DISTRO_NAME. Let's help you get started." \
    --button="Getting Started:0" \
    --button="System Tour:1" \
    --button="Skip:2"

case $? in
    0)
        # Launch getting started guide
        distro-getting-started &
        ;;
    1)
        # Launch system tour
        distro-system-tour &
        ;;
    2)
        # Skip welcome
        touch ~/.distro-welcome-seen
        ;;
esac
```

## Documentation Branding

### Manual Theme

#### Documentation CSS
Create `/usr/share/distro/docs/theme.css`:
```css
/* Distro Documentation Theme */
:root {
    --primary-color: #2E7D32;
    --secondary-color: #1976D2;
    --text-color: #212121;
    --background-color: #FAFAFA;
    --code-background: #263238;
    --code-color: #EEFFFF;
}

body {
    font-family: 'Inter', sans-serif;
    color: var(--text-color);
    background-color: var(--background-color);
    line-height: 1.6;
}

.header {
    background-color: var(--primary-color);
    color: white;
    padding: 1rem 2rem;
    border-bottom: 4px solid var(--secondary-color);
}

.logo {
    height: 40px;
    vertical-align: middle;
}

.navbar {
    background-color: var(--secondary-color);
    color: white;
    padding: 0.5rem 2rem;
}

.content {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
}

code {
    background-color: var(--code-background);
    color: var(--code-color);
    padding: 0.2rem 0.4rem;
    border-radius: 3px;
    font-family: 'JetBrains Mono', monospace;
}

pre {
    background-color: var(--code-background);
    color: var(--code-color);
    padding: 1rem;
    border-radius: 6px;
    overflow-x: auto;
    font-family: 'JetBrains Mono', monospace;
}

h1, h2, h3, h4, h5, h6 {
    color: var(--primary-color);
    margin-top: 2rem;
    margin-bottom: 1rem;
}

a {
    color: var(--secondary-color);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}
```

### Help System

#### Help Browser
Create `/usr/local/bin/distro-help`:
```bash
#!/bin/bash
# Help browser for distro documentation

source /etc/distro/brand.conf

HELP_DIR="/usr/share/distro/docs"
INDEX_FILE="$HELP_DIR/index.html"

if [ -f "$INDEX_FILE" ]; then
    xdg-open "$INDEX_FILE"
else
    yad --error --text="Help documentation not found in $HELP_DIR"
fi
```

## Marketing Materials

### Wallpapers

#### Wallpaper Collection
```bash
# Create wallpaper directory
mkdir -p /usr/share/backgrounds/distro/{default,abstract,nature,technology}

# Default wallpaper
# Create high-resolution branded wallpaper
# Save as /usr/share/backgrounds/distro/default/nexusos-default.jpg
```

#### Wallpaper Configuration
Create `/usr/share/backgrounds/distro/distro.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<wallpapers>
    <wallpaper>
        <name>NexusOS Default</name>
        <filename>/usr/share/backgrounds/distro/default/nexusos-default.jpg</filename>
        <options>zoom</options>
        <pcolor>#2E7D32</pcolor>
        <scolor>#1976D2</scolor>
    </wallpaper>
    <wallpaper>
        <name>NexusOS Abstract</name>
        <filename>/usr/share/backgrounds/distro/abstract/nexusos-abstract.jpg</filename>
        <options>stretched</options>
        <pcolor>#4CAF50</pcolor>
        <scolor>#42A5F5</scolor>
    </wallpaper>
</wallpapers>
```

### Screenshots and Demos

#### Screenshot Guide
```bash
# Create screenshot script
cat > /usr/local/bin/distro-screenshot <<'EOF'
#!/bin/bash
# Screenshot tool for distro marketing

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SCREENSHOT_DIR="$HOME/Pictures/Distro-Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Take screenshot with branding
gnome-screenshot -a -f "$SCREENSHOT_DIR/distro-$TIMESTAMP.png"

# Add watermark if desired
# convert "$SCREENSHOT_DIR/distro-$TIMESTAMP.png" \
#   -pointsize 20 -fill white -gravity southeast \
#   -annotate +10+10 "NexusOS $TIMESTAMP" \
#   "$SCREENSHOT_DIR/distro-$TIMESTAMP-branded.png"

echo "Screenshot saved to $SCREENSHOT_DIR/distro-$TIMESTAMP.png"
EOF

chmod +x /usr/local/bin/distro-screenshot
```

## Brand Guidelines

### Visual Identity Guide

#### Logo Usage Rules
```bash
# Create brand guidelines document
cat > /usr/share/distro/docs/brand-guidelines.md <<'EOF'
# NexusOS Brand Guidelines

## Logo Usage

### Minimum Size
- Print: 0.5 inches (12.7mm) width
- Digital: 40 pixels width

### Clear Space
- Maintain clear space equal to logo height on all sides

### Color Usage
- Use official colors only
- Monochrome for single-color applications
- Inverted version for dark backgrounds

### Incorrect Usage
- Do not stretch or distort logo
- Do not change colors
- Do not add drop shadows or effects
- Do not rotate or skew logo

## Colors

### Primary Palette
- Main Green: #2E7D32
- Light Green: #4CAF50
- Dark Green: #1B5E20

### Secondary Palette
- Main Blue: #1976D2
- Light Blue: #42A5F5
- Dark Blue: #0D47A1

## Typography

### Primary Font
- Inter for UI elements
- Weights: 400, 500, 600, 700

### Secondary Font
- JetBrains Mono for code
- Montserrat for titles

## Voice and Tone

### Brand Voice
- Innovative and forward-thinking
- Approachable and user-friendly
- Professional and reliable

### Writing Style
- Clear and concise
- Active voice preferred
- Technical but accessible
EOF
```

### Asset Management

#### Asset Directory Structure
```bash
/usr/share/distro/branding/
├── logo/
│   ├── nexusos-logo.svg
│   ├── nexusos-logo-256.png
│   └── nexusos-logo-mono.svg
├── icons/
│   ├── apps/
│   ├── devices/
│   └── status/
├── wallpapers/
│   ├── default/
│   ├── abstract/
│   └── nature/
├── themes/
│   ├── gtk/
│   ├── qt/
│   └── icons/
├── marketing/
│   ├── screenshots/
│   ├── banners/
│   └── posters/
└── docs/
    ├── brand-guidelines.md
    └── style-guide.css
```

## Next Steps

With branding and identity complete:

1. Proceed to [Build System](06-build-system.md)
2. Create automated build infrastructure
3. Implement reproducible build processes

## Troubleshooting

### Common Branding Issues

#### Theme Not Applied
```bash
# Check theme installation
ls /usr/share/themes/Distro/

# Verify GTK theme
gsettings get org.gnome.desktop.interface gtk-theme

# Apply theme manually
gsettings set org.gnome.desktop.interface gtk-theme Distro
```

#### Icons Not Displaying
```bash
# Update icon cache
gtk-update-icon-cache -f -i /usr/share/icons/distro/

# Verify icon theme
gsettings get org.gnome.desktop.interface icon-theme
```

#### Boot Splash Issues
```bash
# Check Plymouth installation
plymouth-set-default-theme -l

# Set theme
plymouth-set-default-theme distro

# Update initramfs
dracut -f
```