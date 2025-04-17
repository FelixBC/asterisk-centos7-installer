#!/bin/bash
# ----------------------------------------------------
# HAZ EJECUTADO NATALIUS
# Script de salvación creado por:
#   NATALY BERROA, FELIX BLANCO, EDWIN ESPINAL
# ----------------------------------------------------
echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FELIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
sleep 2

echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
sleep 2

# ---------------------------------------------------------------------
# Paso 0: Obtener archivos de configuración personalizados
# ---------------------------------------------------------------------
echo "🔧 Descargando archivos de configuración desde GitHub..."
CONF_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf"

# Backup y reemplazo de configs Asterisk
for file in extensions.conf sip.conf voicemail.conf; do
  if [ -f "/etc/asterisk/$file" ]; then
    cp "/etc/asterisk/$file" "/etc/asterisk/${file}.bak_$(date +%s)"
  fi
  wget -q -O "/etc/asterisk/$file" "$CONF_URL/$file" && echo "  → reemplazado /etc/asterisk/$file" || echo "  ! ERROR descargando $file"
done

# Backup y reemplazo de AGI scripts
mkdir -p /var/lib/asterisk/agi-bin
for file in juego.py voz.py; do
  if [ -f "/var/lib/asterisk/agi-bin/$file" ]; then
    cp "/var/lib/asterisk/agi-bin/$file" "/var/lib/asterisk/agi-bin/${file}.bak_$(date +%s)"
  fi
  wget -q -O "/var/lib/asterisk/agi-bin/$file" "$CONF_URL/$file" && chmod +x "/var/lib/asterisk/agi-bin/$file" && echo "  → reemplazado /var/lib/asterisk/agi-bin/$file" || echo "  ! ERROR descargando $file"
done

# ---------------------------------------------------------------------
# Paso 1: Configurar repositorios de CentOS y actualizar sistema
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS..."
for repo in /etc/yum.repos.d/CentOS-*; do
    cp "$repo" "${repo}.bak_$(date +%s)"
done
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

yum update -y

# ---------------------------------------------------------------------
# Paso 2: Instalar paquetes y dependencias necesarias
# ---------------------------------------------------------------------
echo "🔧 Instalando paquetes necesarios..."
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring \
    mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel \
    psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail \
    sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
    audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion \
    kernel-devel-$(uname -r) git epel-release wget vim cronie cronie-anacron php-process crontabs

# ---------------------------------------------------------------------
# Paso 3: Instalar jansson (si no está instalada)
# ---------------------------------------------------------------------
echo "🔧 Verificando e instalando jansson..."
if ldconfig -p | grep -q libjansson.so; then
    echo "🔄 Jansson ya instalada."
else
    cd /usr/src || exit 1
    [ -f jansson-2.7.tar.gz ] || wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
    tar -zxvf jansson-2.7.tar.gz
    cd jansson-2.7 || exit 1
    ./configure --prefix=/usr
    make clean && make && make install
    ldconfig
fi

# ---------------------------------------------------------------------
# Paso 4: Desactivar SELinux (con backup previo)
# ---------------------------------------------------------------------
echo "🔧 Deshabilitando SELinux..."
SEL_CFG=/etc/selinux/config
cp "$SEL_CFG" "${SEL_CFG}.bak_$(date +%s)"
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$SEL_CFG" && echo "SELinux disabled (requiere reinicio)"

# ---------------------------------------------------------------------
# Paso 5: Instalar Asterisk 1.8.13.0
# ---------------------------------------------------------------------
echo "🔧 Instalando Asterisk 1.8.13.0 si es necesario..."
if ! command -v asterisk &>/dev/null; then
  cd /usr/src || exit 1
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -zxvf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0 || exit 1
  ./configure --libdir=/usr/lib64
  make && make install && make samples
else
  echo "🔄 Asterisk ya existe, saltando instalación."
fi

# ---------------------------------------------------------------------
# Paso 6: Configurar base de datos ivrdb y tablas en MariaDB
# ---------------------------------------------------------------------
echo "🔧 Configurando ivrdb en MariaDB..."
systemctl start mariadb
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS ivrdb;
USE ivrdb;
CREATE TABLE IF NOT EXISTS premios (id INT AUTO_INCREMENT PRIMARY KEY, premio VARCHAR(50));
CREATE TABLE IF NOT EXISTS llamadas (id INT AUTO_INCREMENT PRIMARY KEY, extension VARCHAR(10), fecha_hora DATETIME, numero_generado INT, gano BOOLEAN, premio_ganado VARCHAR(50), tuvo_chance BOOLEAN);
CREATE TABLE IF NOT EXISTS voice (id INT AUTO_INCREMENT PRIMARY KEY, fechahora DATETIME, texto VARCHAR(100));
SQL
if mysql -u root -D ivrdb -e "SELECT COUNT(*) FROM premios;" | grep -q "0"; then
  mysql -u root -D ivrdb <<SQL
INSERT INTO premios (premio) VALUES ('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),('Celular'),('Tablet'),('Audífonos'),('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
SQL
fi

# ---------------------------------------------------------------------
# Paso 7: Sonidos oficiales y personalizados
# ---------------------------------------------------------------------
echo "🔧 Sonidos Asterisk español..."
cd /usr/src
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
mkdir -p /var/lib/asterisk/sounds/es
tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz -C /var/lib/asterisk/sounds/es --strip-components=1

echo "🔧 Sonidos custom..."
SONG_URL=https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos
GSM_URL=https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm
DEST=/var/lib/asterisk/sounds
mkdir -p $DEST
for f in bachata.gsm merengue.gsm rock.gsm; do
  [ -f $DEST/$f ] || wget -q -P $DEST $SONG_URL/$f && echo "Descargado $f"
done
for f in bienvenida.gsm menu-principal.gsm musica-opciones.gsm juego-bienvenida.gsm introduzca-numero.gsm nuevo-chance.gsm ganador.gsm lo-sentimos.gsm adios.gsm; do
  [ -f $DEST/$f ] || wget -q -P $DEST $GSM_URL/$f && echo "Descargado $f"
done

# ---------------------------------------------------------------------
# Paso 8: mysql-connector-python
# ---------------------------------------------------------------------
echo "🔧 Instalando conector MySQL Python..."
if ! python3 -c "import mysql.connector" &>/dev/null; then
  yum install -y python3-pip
  pip3 install mysql-connector-python
fi

# ---------------------------------------------------------------------
# Paso 9: Iniciar y recargar Asterisk (sin banner)
# ---------------------------------------------------------------------
echo "🔧 Iniciando y recargando Asterisk..."
systemctl start asterisk 2>/dev/null || asterisk start
asterisk -rx "reload" >/dev/null 2>&1

# ---------------------------------------------------------------------
# Fin
# ---------------------------------------------------------------------
echo "El script de salvación NATALIUS ha sido completado correctamente, ¡estás bendecido!"