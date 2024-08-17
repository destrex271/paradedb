#!/bin/bash

ARCH=$(uname -m)
LATEST_RELEASE_VERSION=$(curl -s "https://api.github.com/repos/paradedb/paradedb/releases/latest" | jq -r .tag_name)
LATEST_RELEASE_VERSION="${LATEST_RELEASE_VERSION#v}"

set -Eeuo pipefail
set -e

installDocker() {
  # Set default values
  pguser="myuser"
  pgpass="mypassword"
  dbname="paradedb"

  echo "Installing docker..."


  OPTIONS=("Debian Base" "RHEL Based" "Arch Based")


  select opt in "${OPTIONS[@]}"
  do
    case $opt in
      "Debian Base")
        sudo apt-get install docker -y || false
        break ;;
      "RHEL Based")
        sudo dnf install docker || false
        break ;;
      "Arch Based")
        sudo pacman -Syyu docker || false
        break ;;
      *)
        break ;;
    esac
  done

  echo "Successfully Installed Docker✅"


  # Prompt for user input
  read -r -p "Username for Database (default: myuser): " tmp_pguser
  if [[ -n "$tmp_pguser" ]]; then
    pguser="$tmp_pguser"
  fi

  read -r -p "Password for Database (default: mypassword): " tmp_pgpass
  if [[ -n "$tmp_pgpass" ]]; then
    pgpass="$tmp_pgpass"
  fi

  read -r -p "Name for your database (default: paradedb): " tmp_dbname
  if [[ -n "$tmp_dbname" ]]; then
    dbname="$tmp_dbname"
  fi


  # Pull Docker image
  echo "Pulling Docker Image for Parade DB: docker pull paradedb/paradedb"
  docker pull paradedb/paradedb || { echo "Failed to pull Docker image"; exit 1; }
  echo "Pulled Successfully ✅"

  # Create Docker container
  echo "Processing..."
  docker run \
    --name paradedb \
    -e POSTGRES_USER="$pguser" \
    -e POSTGRES_PASSWORD="$pgpass" \
    -e POSTGRES_DB="$dbname" \
    -v paradedb_data:/var/lib/postgresql/data/ \
    -p 5432:5432 \
    -d \
    paradedb/paradedb:latest || { echo "Failed to start Docker container. Please check if an existing container is active or not."; exit 1; }
  echo "Docker Container started ✅"

  # Provide usage information
  echo "To use paradedb execute the command: docker exec -it paradedb psql $dbname -U $pguser"
}

# Please update the debian file with the lastest version here
installDeb(){
  echo "Select your distribution"

  echo "Installing dependencies...."
  # echo "Installing cURL"
  #
  # sudo apt-get update || false
  # sudo apt-get install curl || false
  #
  # echo "Successfully Installed cURL✅"

  distros=("bookworm" "jammy" "noble")
  distro=
  select op in "${distros[@]}"
  do
    case $op in
      "bookworm")
        distro="bookworm"
        break ;;
      "jammy")
        distro="jammy"
        break ;;
      "noble")
        distro="noble"
        break ;;
    esac
  done

  if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
  fi

  filename="postgresql-$1-pg-search_${LATEST_RELEASE_VERSION}-1PARADEDB-${distro}_${ARCH}.deb"
  url="https://github.com/paradedb/paradedb/releases/latest/download/${filename}"

  echo "Downloading ${url}"

  curl -L "$url" > "$filename" || false

  sudo apt install ./"$filename" || false
}

# Please update the RPM file with the latest version here
installRPM(){
  filename="pg_search_$1-$LATEST_RELEASE_VERSION-1PARADEDB.el9.${ARCH}.rpm"
  url="https://github.com/paradedb/paradedb/releases/latest/download/${filename}"
  echo -e "Insatlling cURL"
  sudo dnf install curl || false
  echo "Successfully Installed cURL✅"

  echo "Downloading ${url}"
  curl -l "$url" > "$filename" || false

  sudo rpm -i "$filename" || false
  echo "ParadeDB installed successfully!"
}

installStable(){

  # Select postgres version
  pg_version=
  echo "Select postgres version"
  versions=("14" "15" "16")

  select vers in "${versions[@]}"
  do
    case $vers in
      "14")
        pg_version="14"
        break ;;
      "15")
        pg_version="15"
        break ;;
      "16")
        pg_version="16"
        break ;;
    esac
  done

  # Select Base type
  echo "Select supported file type: "
  opts=(".deb" ".rpm")

  select opt in "${opts[@]}"
  do
    case $opt in
      ".deb")
        installDeb $pg_version
        break ;;
      ".rpm")
        installRPM $pg_version
        break ;;
    esac
  done
}


echo -e "=========================================================\n"

echo -e "Hi there!

Welcome to ParadeDB, an open-source alternative to Elasticsearch built on Postgres.\nThis script will guide you through installing ParadeDB.

ParadeDB is available as a Kubernetes Helm chart, a Docker image, and as prebuilt binaries for Debian-based and Red Hat-based Linux distributions.\nHow would you like to install ParadeDB?"


echo -e "=========================================================\n"



OPTIONS=("🐳Latest Docker Image" "⬇️ Stable Binary")


select opt in "${OPTIONS[@]}"
do
  case $opt in
    "🐳Latest Docker Image")
      installDocker
      echo -e "Installation Successfull!\n"
      break ;;
    "⬇️ Stable Binary")
      echo "Stable"
      installStable
      echo -e "Installation Successfull!\n"
      break ;;
    *)
      echo -e "No option selected, exiting setup.\n"
      break ;;
  esac
done


echo -e "If you'd like to stay upto date with everything about ParadeDB\nJoin our slack channel: https://join.slack.com/t/paradedbcommunity/shared_invite/zt-217mordsh-ielS6BiZf7VW3rqKBFgAlQ \nGitHub: https://github.com/paradedb/paradedb"
