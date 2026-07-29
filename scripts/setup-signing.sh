#!/bin/bash
# Creates a self-signed "Bronze Signing" code-signing certificate and trusts it.
# A stable signing identity keeps the TCC Accessibility grant across rebuilds;
# ad-hoc signing invalidates it on every build.
set -euo pipefail

IDENTITY="Bronze Signing"

if security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
  echo "Identity '$IDENTITY' already exists. Nothing to do."
  exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/cert.conf" <<EOF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $IDENTITY
[ext]
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
basicConstraints = critical,CA:false
EOF

openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -config "$TMP/cert.conf"

# OpenSSL 3 exports PKCS12 with algorithms `security import` rejects
# ("MAC verification failed"), so key and cert are imported as PEM instead.
security import "$TMP/key.pem" -k "$HOME/Library/Keychains/login.keychain-db" \
  -T /usr/bin/codesign
security import "$TMP/cert.pem" -k "$HOME/Library/Keychains/login.keychain-db"

echo "Trusting certificate for code signing (requires sudo)..."
sudo security add-trusted-cert -d -r trustRoot -p codeSign \
  -k /Library/Keychains/System.keychain "$TMP/cert.pem"

echo
echo "Done. Identity '$IDENTITY' is ready."
echo "Note: the first build will show a keychain prompt asking codesign to use"
echo "the key. Choose 'Always Allow'."
