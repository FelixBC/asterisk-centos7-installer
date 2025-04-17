#!/bin/bash
set -euo pipefail

echo "***********************************************"
echo "***********************************************"
echo "***********************************************"

echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"

echo "***********************************************"
echo "***********************************************"
echo "***********************************************"
sleep 2

echo "***********************************************"
echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"

echo "***********************************************"
sleep 2

# ---------------------------------------------------------------------
# Paso 0: Descargar y reemplazar configs desde GitHub
echo "🔧 Descargando archivos de configuración desde GitHub..."
for file in extensions.conf sip.conf voicemail.conf; do
  wget -q https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/$file -O /etc/asterisk/$file
done
mkdir -p /var/lib/asterisk/agi-bin
for file in juego.py voz.py; do
  wget -q https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf/$file -O /var/lib/asterisk/agi-bin/$file
  chmod +x /var/lib/asterisk/agi-bin/$file
done

# ---------------------------------------------------------------------
# Paso 1: Configurar repositorios de CentOS (haciendo backup)
echo "🔧 Configurando repositorios de CentOS..."
for repo in /etc/yum.repos.d/CentOS-*; do
  cp "$repo" "${repo}.bak_$(date +%s)"
  sed -i 's|^mirrorlist=|#mirrorlist=|g' "$repo"
  sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' "$repo"
done
yum makecache

# ---------------------------------------------------------------------
# Paso 2: Instalar paquetes necesarios
echo "🔧 Instalando paquetes necesarios..."
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring \
 mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel \
 psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail \
 sendmail-cf bind sox newt-devel libxml2-devel libtiff-devel audiofile-devel \
 gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel git \
 epel-release cronie cronie-anacron wget vim python3-pip firewalld

# ---------------------------------------------------------------------
# Paso 3: Verificar e instalar jansson
echo "🔧 Verificando e instalando jansson..."
if ldconfig -p | grep -q libjansson.so; then
  echo "🔄 Jansson ya instalada."
else
  cd /usr/src
  wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
  tar -zxvf jansson-2.7.tar.gz
  cd jansson-2.7
  ./configure --prefix=/usr
  make clean && make && make install
  ldconfig
fi

# ---------------------------------------------------------------------
# Paso 4: Desactivar SELinux (backup previo)
echo "🔧 Deshabilitando SELinux..."
SELINUX_CONFIG="/etc/selinux/config"
cp "$SELINUX_CONFIG" "${SELINUX_CONFIG}.bak_$(date +%s)"
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$SELINUX_CONFIG" || true
echo "SELinux disabled (requiere reinicio)"

# ---------------------------------------------------------------------
# Paso 5: Detener firewall
echo "🔧 Deteniendo firewalld..."
systemctl stop firewalld

# ---------------------------------------------------------------------
# Paso 6: Instalar Asterisk 1.8.13.0 si no existe
echo "🔧 Instalando Asterisk 1.8.13.0 si es necesario..."
if ! command -v asterisk &>/dev/null; then
  cd /usr/src
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -zxvf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0
  ./configure --libdir=/usr/lib64
  make && make install && make samples
else
  echo "🔄 Asterisk ya existe, saltando instalación."
fi

# ---------------------------------------------------------------------
# Paso 7: Configurar base de datos ivrdb en MariaDB
echo "🔧 Configurando ivrdb en MariaDB..."
systemctl start mariadb
mysql -u root <<'EOF'
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
# Insertar premios si no existen
if ! mysql -u root -D ivrdb -e "SELECT COUNT(*) FROM premios;" | grep -q 0; then
  mysql -u root -D ivrdb <<'EOF'
INSERT INTO premios (premio) VALUES
('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),
('Celular'),('Tablet'),('Audífonos'),
('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
EOF
else
  echo "🗃️ Premios ya insertados."
fi

# ---------------------------------------------------------------------
# Paso 8: Sonidos oficiales en español
echo "🔧 Sonidos Asterisk español..."
cd /usr/src
if [ ! -f asterisk-core-sounds-es-gsm-current.tar.gz ]; then
  wget -q http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
fi
if [ ! -d asterisk-core-sounds-es-gsm* ]; then
  tar -zxvf asterisk-core-sounds-es-gsm-current.tar.gz
fi
mkdir -p /var/lib/asterisk/sounds/es
for d in asterisk-core-sounds-es-gsm*; do
  cp "$d"/*.gsm /var/lib/asterisk/sounds/es/ 2>/dev/null || true
done

# ---------------------------------------------------------------------
# Paso 9: Sonidos personalizados
echo "🔧 Sonidos custom..."
cd /usr/src
mkdir -p /usr/src/sg && cd /usr/src/sg
# ritmos
for s in bachata.gsm merengue.gsm rock.gsm; do
  if [ ! -f "$s" ]; then
    wget -q "https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/$s"
  fi
  cp "$s" /var/lib/asterisk/sounds/es/
done
# menús y demás
mkdir -p gsm && cd gsm
for s in bienvenida.gsm menu-principal.gsm musica-opciones.gsm \
       juego-bienvenida.gsm introduzca-numero.gsm nuevo-chance.gsm \
       ganador.gsm lo-sentimos.gsm adios.gsm; do
  if [ ! -f "$s" ]; then
    wget -q "https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm/$s"
  fi
  cp "$s" /var/lib/asterisk/sounds/es/
done

# ---------------------------------------------------------------------
# Paso 10: Instalar conector MySQL para Python
echo "🔧 Instalando conector MySQL Python..."
pip3 install --user mysql-connector-python

# ---------------------------------------------------------------------
# Paso 11: Iniciar y recargar Asterisk
echo "🔧 Iniciando y recargando Asterisk..."
systemctl start asterisk 2>/dev/null || asterisk start
asterisk -rvvvvvvvv -x "reload"

echo "✅ NATALIUS completado correctamente, ¡estás bendecido!"