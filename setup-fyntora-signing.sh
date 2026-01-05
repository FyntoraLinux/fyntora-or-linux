#!/bin/bash
# Setup GPG signing infrastructure for FyntoraLinux

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