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

if [[ -z $1 ]]; then
  echo "Select a cdn to add IPs:"
  echo "1) arvancloud"
  echo "2) cloudflare"
  echo "3) iranserver"
  read -r -p "cdn: " option
else
  option=$1
fi

clear

echo "Adding IPs of selected cdn"

# Process user input
case "$option" in
1 | arvancloud)
  CDNNAME="arvancloud"
  echo "Downloading Arvancloud IPs list..."

  IPsLink="https://www.arvancloud.com/fa/ips.txt"
  IPsFile=$(mktemp /tmp/arvancloud-ips.XXXXXX)
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

  clear
  ;;
2 | cloudflare)
  CDNNAME="cloudflare"
  echo "Downloading cloudflare IPs list..."

  IPsLink="https://www.cloudflare.com/ips-v4"
  IPsFile=$(mktemp /tmp/cloudflare-ips.XXXXXX)
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

  clear
  ;;
3 | iranserver)
  CDNNAME="iranserver"
  echo "Downloading iranserver IPs list..."

  IPsLink="https://ips.f95.com/ip.txt"
  IPsFile=$(mktemp /tmp/iranserver-ips.XXXXXX)
  # Delete the temp file if the script stopped for any reason
  trap 'rm -f ${IPsFile}' 0 2 3 15

  if [[ -x "$(command -v curl)" ]]; then
    downloadStatus=$(curl "${IPsLink}" -o "${IPsFile}" -L -s -w "%{http_code}\n" | grep  -oP "(\d+\.+\d+\.+\d+\.+\d+)")

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

  clear
  ;;
*)
  abort "The selected cdn is not valid."
  ;;
esac

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
