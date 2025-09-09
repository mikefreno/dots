#!/usr/bin/env bash
b64url() {
  # $1: string (stdin)
  base64 -w0 | tr '+/' '-_' | tr -d '='
}
# --------------------------------------------------
#  Generate an EdDSA (Ed25519) JWT from the command line.
#  Requires: OpenSSL 1.1.1+ or 3.0, jq (optional for decoding).
#
#  Usage:
#      ./jwt.sh
#
#  The private key must be PEM‑encoded (private.pem)
#  The public key (public.pem) is used only for verification.
# --------------------------------------------------

# 1.  Header & payload JSON – no whitespace, but you can use jq to compress them.
header='{"alg":"EdDSA","typ":"JWT"}'
payload='{"sub":"user‑123","role":"admin"}'

# 2.  Base64URL‑encode the JSON strings
h64=$(echo -n "$header" | b64url)
p64=$(echo -n "$payload" | b64url)

# 3.  Form the unsigned part:  header.payload
msg="$h64.$p64"

# 4.  Sign with the Ed25519 private key
#    (OpenSSL will automatically pick Ed25519; no digest option is used)
sig=$(openssl dgst -sign client_private.pem -out /dev/stdout <<<"$msg")

# 5.  Base64URL‑encode the binary signature
s64=$(printf '%s' "$sig" | b64url)

# 6.  Final JWT
jwt="$msg.$s64"
echo "$jwt"
