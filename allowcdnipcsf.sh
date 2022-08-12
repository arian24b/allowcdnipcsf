#!/usr/bin/env bash

# Show an error and exit
abort() {
  echo "$1"
  exit 1
}

# root access needed
if [[ $EUID -ne 0 ]]; then
  abort "This script needs to be run with superuser privileges."
fi

# get the name of the CDN
if [[ -z $1 ]]; then
  echo "Select a cdn to add IPs:"
  echo "1- cloudflare"
  echo "2- iranserver"
  echo "3- arvancloud"
  read -r -p "CDN number: " option
else
  option=$1
fi

# Process user input
case "$option" in
1 | cloudflare)
  CDNNAME="cloudflare"
  IPsLink="https://www.cloudflare.com/ips-v4"
  ;;
2 | iranserver)
  CDNNAME="iranserver"
  IPsLink="https://ips.f95.com/ip.txt"
  ;;
3 | arvancloud)
  CDNNAME="arvancloud"
  IPsLink="https://www.arvancloud.com/fa/ips.txt"
  ;;
*)
  abort "The selected CDN is not valid."
  ;;
esac

echo "Selected CDN: $CDNNAME"
echo "Downloading $CDNNAME IPs list..."

IPsFile=$(mktemp /tmp/$CDNNAME-ips.XXXXXX)
# Delete the temp file if the script stopped for any reason
trap 'rm -f ${IPsFile}' 0 2 3 15

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

for IP in ${IPs}; do
  sudo csf -a "$IP" "$CDNNAME"
done

csf -df
csf -tf
sudo csf -r

echo  "DONE"