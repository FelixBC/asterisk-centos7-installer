#!/usr/bin/env bash

# === HEADER ===
echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
sleep 1

echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
sleep 1

# === REPOS IDÉMPOTENTES ===
if ! grep -q '^#mirrorlist' /etc/yum.repos.d/CentOS-*.repo; then
  echo "🔧 Configurando repositorios..."
  sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*.repo
  sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo
  echo "✔ Repos configurados"
fi

# === PAQUETES NECESARIOS ===
PKGS=(gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring mariadb mariadb-server mariadb-devel sqlite-devel lynx bison gmime-devel psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail sendmail-cf bind-utils sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel git epel-release wget vim cronie cronie-anacron python3-pip)
MISSING=()
for pkg in "${PKGS[@]}"; do
  rpm -q "$pkg" &>/dev/null || MISSING+=("$pkg")
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "🔧 Instalando paquetes: ${MISSING[*]}"
  yum install -y "${MISSING[@]}" &>/dev/null
  echo "✔ Paquetes instalados"
fi

# === JANSSON IDÉMPOTENTE ===
if [ ! -f /usr/include/jansson.h ]; then
  echo "🔧 Instalando jansson..."
  cd /usr/src
  wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
  tar -xzf jansson-2.7.tar.gz
  cd jansson-2.7
  ./configure --prefix=/usr &>/dev/null
  make -s &>/dev/null
  make install -s &>/dev/null
  ldconfig
  echo "✔ jansson instalado"
fi

# === Asterisk ===
if ! command -v asterisk &>/dev/null; then
  echo "🔧 Instalando Asterisk 1.8.13..."
  cd /usr/src
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -xzf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0
  ./configure --libdir=/usr/lib64 &>/dev/null
  make -s && make install -s && make samples -s
  echo "✔ Asterisk instalado"
fi

# === Base de datos ivrdb ===
if ! mysql -uroot -e 'USE ivrdb;' &>/dev/null; then
  echo "🔧 Configurando ivrdb en MariaDB..."
  mysql -uroot <<EOF &>/dev/null
CREATE DATABASE IF NOT EXISTS ivrdb;
USE ivrdb;
CREATE TABLE IF NOT EXISTS premios (id INT AUTO_INCREMENT PRIMARY KEY, premio VARCHAR(50));
CREATE TABLE IF NOT EXISTS llamadas (id INT AUTO_INCREMENT PRIMARY KEY, extension VARCHAR(10), fecha_hora DATETIME, numero_generado INT, gano BOOLEAN, premio_ganado VARCHAR(50), tuvo_chance BOOLEAN);
CREATE TABLE IF NOT EXISTS voice (id INT AUTO_INCREMENT PRIMARY KEY, fechahora DATETIME, texto VARCHAR(100));
EOF
  echo "✔ ivrdb lista"
fi

# === Sonidos en español ===
if [ ! -d /var/lib/asterisk/sounds/es ]; then
  echo "🔧 Descargando sonidos Asterisk (es)..."
  cd /usr/src
  wget -q http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
  tar -xzf asterisk-core-sounds-es-gsm-current.tar.gz
  mkdir -p /var/lib/asterisk/sounds/es
  cp asterisk-core-sounds-es-gsm-*/es/*.gsm /var/lib/asterisk/sounds/es/ &>/dev/null
  echo "✔ Sonidos españoles listos"
fi

# === FOOTER ===
echo "***********************************************"
echo "  HAZ FINALIZADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
# … (script logic in silence) …

echo "NATALIUS, script de salvacion ha completado correctamente, estas bendecido"
