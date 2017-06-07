#!/bin/bash
set -e


if [[ ${USER} == "root" ]]; then
	echo "Please run this script without root privilege."
	exit 1
fi

if [ -e ../configure.sh ]; then
        source ../configure.sh
elif [ -e ./configure.sh ]; then
        source ./configure.sh
else
        echo "Error: Could not find 'configure.sh'!"
        exit 1
fi

## postgresql setup
sudo pacman -S --needed --noconfirm postgresql
echo "Setting the password for system user 'postgres'..."
sudo passwd postgres
sudo -u postgres initdb --locale $LANG -E UTF-8 -D '/var/lib/postgres/data'
sudo systemctl enable postgresql.service
sudo systemctl start postgresql.service
sudo -u postgres createuser firmadyne -s
sudo -u postgres createdb -O firmadyne -U firmadyne firmware
sudo -u postgres psql -d firmware < ${DB_DIR}/schema

## install dependencies
sudo pacman -S --needed --noconfirm bc fakeroot curl git openbsd-netcat nmap net-snmp util-linux fuse binwalk python-crypto python-capstone squashfs-tools python-magic python-psycopg2 qemu qemu-arch-extra mtd-utils tar unrar xz gzip bzip2 p7zip arj lhasa cabextract arj cpio python-opengl sleuthkit busybox
yaourt -S --needed --noconfirm firmware-mod-kit flawfinder jefferson-git multipath-tools sasquatch ubi_reader uml_utilities

## Metasploit Framework
sudo pacman -S --needed --noconfirm metasploit
export PATH="$PATH:$(ruby -e 'print Gem.user_dir')/bin"
sudo chown -R ${USER} /opt/metasploit
cd /opt/metasploit
sudo gem update --system
gem install bundler
bundler install
cd -
sudo -u postgres createuser metasploit -s
sudo -u postgres createdb -O metasploit -U metasploit msf
[[ ! -d ${HOME}/.msf4 ]] && mkdir -p ${HOME}/.msf4
echo "production:
 adapter: postgresql
 database: msf
 username: metasploit
 password:
 host: localhost
 port: 5432
 pool: 5
 timeout: 5" > ${HOME}/.msf4/database.yml
msfconsole -qx "db_rebuild_cache; exit"

## AFL
sudo pacman -U --needed --noconfirm pkgs/afl/afl-2.39b-1-x86_64.pkg.tar.xz

echo "Finish setup!"
