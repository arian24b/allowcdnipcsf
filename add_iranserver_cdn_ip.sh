#!/usr/bin/env bash

# Show an error and exit
abort() {
  echo "$1"
  exit 1
}

CDNNAME="cdn_iranserver"
IPsLink="https://ips.f95.com/ip.txt"

IPsFile=$(mktemp /tmp/$CDNNAME-ips.XXXXXX)

if [[ -x "$(command -v curl)" ]]; then
  downloadStatus=$(curl "${IPsLink}" -o "${IPsFile}" -L -s -w "%{http_code}\n")
elif [[ -x "$(command -v wget)" ]]; then
  downloadStatus=$(wget "${IPsLink}" -O "${IPsFile}" --server-response 2>&1 | awk '/^  HTTP/{print $2}' | tail -n1)
else
  abort "curl or wget is required to run this script."
fi

if [[ "$downloadStatus" -ne 200 ]]; then
  abort "Downloading the IP list wasn't successful. status code: ${downloadStatus}"
else
  IPs=$(cat "$IPsFile")
fi

echo "Adding $CDNNAME IPs to the CSF whitelist..."

if [[ ! -x "$(command -v csf)" ]]; then
  abort "csf is not installed."
fi


echo "127.0.0.1" > /etc/csf/csf.ignore

for IP in ${IPs}; do
  sudo csf -dr "$IP"
  sudo csf -tr "$IP"
  sudo csf -a "$IP" "$CDNNAME"
  echo "$IP" "$CDNNAME" >> /etc/csf/csf.ignore
done

sudo csf -r

echo  "DONE"
