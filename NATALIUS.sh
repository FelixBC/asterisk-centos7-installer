#!/usr/bin/env bash
set -euo pipefail

echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"

# 1) Deploy your 5 config files (always overwrites with your latest GitHub versions)
echo "🔧 Descargando archivos de configuración..."
BASE="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf"
for f in extensions.conf sip.conf voicemail.conf juego.py voz.py; do
  target="/etc/asterisk/${f}"
  [[ "$f" == juego.py || "$f" == voz.py ]] && target="/var/lib/asterisk/agi-bin/${f}"
  curl -fsSL "${BASE}/${f}" -o "${target}"
  [[ "$f" == juego.py || "$f" == voz.py ]] && chmod +x "${target}"
done

# 2) Fix CentOS repos (sed is safe to re‑run)
echo "🔧 Configurando repositorios de CentOS..."
find /etc/yum.repos.d -type f -name '*.repo' -exec sed -i \
  -e 's|^mirrorlist=|#mirrorlist=|' \
  -e 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|' {} +

# 3) Disable SELinux & firewall (idempotent)
echo "🔧 Deshabilitando SELinux y firewall..."
if grep -q '^SELINUX=' /etc/selinux/config; then
  sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
  setenforce 0 2>/dev/null || true
fi
systemctl is-enabled firewalld   &>/dev/null && systemctl disable  firewalld
systemctl is-active  firewalld   &>/dev/null && systemctl stop     firewalld

# 4) Install packages (yum is idempotent)
echo "🔧 Instalando paquetes necesarios..."
yum makecache fast
yum install -y \
  gcc gcc-c++ php php-xml php-mysql php-pear php-mbstring \
  mariadb-server mariadb-devel sqlite-devel lynx bison gmime-devel \
  psmisc tftp-server httpd make ncurses-devel sendmail sendmail-cf \
  sox newt-devel libxml2-devel libtiff-devel audiofile-devel \
  gtk2-devel uuid-devel libtool subversion git epel-release \
  python3-pip jansson-devel

# 5) MariaDB + ivrdb + tables + seed (only creates if missing)
echo "🔧 Configurando ivrdb en MariaDB..."
systemctl enable mariadb   2>/dev/null || true
systemctl start  mariadb
mysql -uroot <<SQL
CREATE DATABASE IF NOT EXISTS ivrdb;
USE ivrdb;
CREATE TABLE IF NOT EXISTS premios (
  id INT PRIMARY KEY AUTO_INCREMENT,
  premio VARCHAR(50)
);
INSERT IGNORE INTO premios (id,premio) VALUES
 (1,'Lavadora'),(2,'Smart TV'),(3,'Air Fryer'),(4,'Laptop'),
 (5,'Celular'),(6,'Tablet'),(7,'Audífonos'),(8,'Bocina Bluetooth'),
 (9,'Reloj Inteligente'),(10,'Bonificación');
CREATE TABLE IF NOT EXISTS llamadas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  extension VARCHAR(10),
  fecha_hora DATETIME,
  numero_generado INT,
  gano BOOLEAN,
  premio_ganado VARCHAR(50),
  tuvo_chance BOOLEAN
);
CREATE TABLE IF NOT EXISTS voice (
  id INT PRIMARY KEY AUTO_INCREMENT,
  fechahora DATETIME,
  texto VARCHAR(100)
);
SQL

# 6) Install Asterisk only once
echo "🔧 Instalando Asterisk 1.8.13.0 si es necesario..."
if ! command -v asterisk &>/dev/null; then
  cd /usr/src
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar zxvf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0
  ./configure --libdir=/usr/lib64
  make && make install && make samples
fi

# 7) Pull Spanish core sounds (only re‑downloads if newer)
echo "🔧 Sonidos Asterisk español..."
cd /usr/src
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
rm -rf /tmp/esamp
mkdir -p /tmp/esamp
tar zxvf asterisk-core-sounds-es-gsm-current.tar.gz -C /tmp/esamp
mkdir -p /var/lib/asterisk/sounds/es
cp -u /tmp/esamp/asterisk-core-sounds-es-gsm-*/[a-z]*.gsm /var/lib/asterisk/sounds/es/ || true

# 8) Your custom GSM prompts
echo "🔧 Sonidos custom..."
for p in bachata merengue rock bienvenida menu-principal \
         musica-opciones juego-bienvenida introduzca-numero \
         nuevo-chance ganador lo-sentimos adios; do
  curl -fsSL \
    "https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm/${p}.gsm" \
    -o "/var/lib/asterisk/sounds/${p}.gsm"
done

# 9) Python MySQL connector (pip is idempotent)
echo "🔧 Instalando conector MySQL Python..."
pip3 install --upgrade --no-cache-dir mysql-connector-python

# 10) Start & Reload Asterisk cleanly (never drop you into the CLI)
echo "🔧 Iniciando y recargando Asterisk..."
systemctl enable asterisk 2>/dev/null || true
systemctl start  asterisk 2>/dev/null || asterisk start
asterisk -rvvvvvvvv -x "reload" >/dev/null 2>&1
asterisk -rx        "reload" >/dev/null 2>&1

echo "✅ NATALIUS completado correctamente, estás bendecido."