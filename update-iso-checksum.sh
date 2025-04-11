#!/bin/bash
# this will update the debian.pkr.hcl file with the current netboot image checksum.
# see https://www.debian.org/CD/verify
# see https://cdimage.debian.org/debian-cd/12.10.0/amd64/iso-cd/
set -eux
iso_url="$(perl -ne '/default\s*=\s*\"(https:.+\.debian\.org.+)\"/ && print $1' <debian.pkr.hcl)"
iso_checksum_url="$(dirname $iso_url)/SHA256SUMS"
curl -O --silent --show-error $iso_checksum_url
curl -O --silent --show-error $iso_checksum_url.sign
gpg --keyserver hkp://keyring.debian.org/ --recv-keys 0x64E6EA7D 0x6294BE9B 0x09EA8AC3
gpg --verify SHA256SUMS.sign SHA256SUMS
iso_checksum=$(grep $(basename $iso_url) SHA256SUMS | awk '{print $1}')
for f in debian*.pkr.hcl; do
    sed -i -E "s,(default\s*=\s*\")(sha256:[a-z0-9]+)(\"),\\1sha256:$iso_checksum\\3,g" $f
done
rm SHA256SUMS*
echo 'iso_checksum updated successfully'
