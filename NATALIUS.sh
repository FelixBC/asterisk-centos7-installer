#!/bin/bash

echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
sleep 1

echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
sleep 1

# ---------------------------------------------------------------------
# 1) Descargar y reemplazar archivos de configuración
echo "🔧 Descargando archivos de configuración desde GitHub..."
curl -sL https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/extensions.conf -o /etc/asterisk/extensions.conf
curl -sL https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/sip.conf        -o /etc/asterisk/sip.conf
curl -sL https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/voicemail.conf  -o /etc/asterisk/voicemail.conf
curl -sL https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/juego.py         -o /var/lib/asterisk/agi-bin/juego.py
curl -sL https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/voz.py           -o /var/lib/asterisk/agi-bin/voz.py
chmod +x /var/lib/asterisk/agi-bin/{juego.py,voz.py}

# ---------------------------------------------------------------------
# 2) Configurar repositorios de CentOS (sin backup)
echo "🔧 Configurando repositorios de CentOS..."
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum makecache -q

# ---------------------------------------------------------------------
# 3) Instalar paquetes necesarios
echo "🔧 Instalando paquetes necesarios..."
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring \
  mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel \
  psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail \
  sendmail-cf bind-utils sox newt-devel libxml2-devel libtiff-devel \
  audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion \
  kernel-devel-$(uname -r) git epel-release wget vim cronie cronie-anacron \
  python3-pip || yum install -y gcc-c++ php-mysql mariadb-server

# ---------------------------------------------------------------------
# 4) Instalar jansson si falta
echo "🔧 Verificando e instalando jansson..."
if ! ldconfig -p | grep -q libjansson; then
  cd /usr/src
  wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
  tar zxvf jansson-2.7.tar.gz
  cd jansson-2.7
  ./configure --prefix=/usr && make && make install
  ldconfig
fi

# ---------------------------------------------------------------------
# 5) Desactivar SELinux y firewall
echo "🔧 Deshabilitando SELinux y firewall..."
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

# ---------------------------------------------------------------------
# 6) Instalar Asterisk 1.8.13.0 si falta
echo "🔧 Instalando Asterisk 1.8.13.0 si es necesario..."
if ! command -v asterisk &>/dev/null; then
  cd /usr/src
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar zxvf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0
  ./configure --libdir=/usr/lib64
  make && make install && make samples
fi

# ---------------------------------------------------------------------
# 7) Configurar base de datos ivrdb
echo "🔧 Configurando ivrdb en MariaDB..."
systemctl start mariadb
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ivrdb;
USE ivrdb;
CREATE TABLE IF NOT EXISTS premios (
  id INT PRIMARY KEY AUTO_INCREMENT,
  premio VARCHAR(50)
);
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
  id INT AUTO_INCREMENT PRIMARY KEY,
  fechahora DATETIME,
  texto VARCHAR(100)
);
EOF

# Inserta premios si tabla vacía
if [[ "$(mysql -u root -D ivrdb -Bse "SELECT COUNT(*) FROM premios")" -eq 0 ]]; then
  mysql -u root -D ivrdb <<EOF
INSERT INTO premios (premio) VALUES
('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),
('Celular'),('Tablet'),('Audífonos'),
('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
EOF
fi

# ---------------------------------------------------------------------
# 8) Sonidos oficiales de Asterisk (español)
echo "🔧 Sonidos Asterisk español..."
cd /usr/src
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
tar -xzf asterisk-core-sounds-es-gsm-current.tar.gz
mkdir -p /var/lib/asterisk/sounds/es
cp -r asterisk-core-sounds-es-gsm-*/*.gsm /var/lib/asterisk/sounds/es/

# ---------------------------------------------------------------------
# 9) Sonidos personalizados desde GitHub
echo "🔧 Sonidos custom..."
mkdir -p /var/lib/asterisk/sounds/
cd /var/lib/asterisk/sounds/
for f in bachata rock merengue bienvenida menu-principal musica-opciones \
         juego-bienvenida introduzca-numero nuevo-chance ganador lo-sentimos adios; do
  curl -sL https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm/${f}.gsm \
    -o ${f}.gsm
done

# ---------------------------------------------------------------------
# 10) Instalar conector MySQL-Python
echo "🔧 Instalando conector MySQL Python..."
pip3 install --no-warn-script-location mysql-connector-python

# ---------------------------------------------------------------------
# 11) Iniciar y recargar Asterisk
echo "🔧 Iniciando y recargando Asterisk..."
systemctl start asterisk 2>/dev/null || asterisk start
asterisk -rvvvvvvvv -x "reload" >/dev/null 2>&1

echo "✅ NATALIUS completado correctamente, estás bendecido."