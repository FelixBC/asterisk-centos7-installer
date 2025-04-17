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
for file in extensions.conf sip.conf voicemail.conf; do
  [ -f "/etc/asterisk/$file" ] && cp "/etc/asterisk/$file" "/etc/asterisk/${file}.bak_$(date +%s)"
  if wget -q -O "/etc/asterisk/$file" "$CONF_URL/$file"; then
    echo "  → reemplazado /etc/asterisk/$file"
  else
    echo "  ! ERROR descargando $file"
  fi
done

mkdir -p /var/lib/asterisk/agi-bin
for file in juego.py voz.py; do
  [ -f "/var/lib/asterisk/agi-bin/$file" ] && cp "/var/lib/asterisk/agi-bin/$file" "/var/lib/asterisk/agi-bin/${file}.bak_$(date +%s)"
  if wget -q -O "/var/lib/asterisk/agi-bin/$file" "$CONF_URL/$file"; then
    chmod +x "/var/lib/asterisk/agi-bin/$file"
    echo "  → reemplazado /var/lib/asterisk/agi-bin/$file"
  else
    echo "  ! ERROR descargando $file"
  fi
done

# ---------------------------------------------------------------------
# Paso 1: Configurar repositorios de CentOS y actualizar sistema
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS..."
for repo in /etc/yum.repos.d/CentOS-*; do
  cp "$repo" "${repo}.bak_$(date +%s)"
done
sed -i 's/^mirrorlist/#&/' /etc/yum.repos.d/CentOS-*
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

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
    kernel-devel-$(uname -r) git epel-release wget vim cronie cronie-anacron \
    php-process crontabs

# ---------------------------------------------------------------------
# Paso 3: Instalar jansson (si no está instalado)
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
# Paso 4: Desactivar SELinux y firewall (con backup previo)
# ---------------------------------------------------------------------
echo "🔧 Deshabilitando SELinux..."
SEL_CFG=/etc/selinux/config
cp "$SEL_CFG" "${SEL_CFG}.bak_$(date +%s)"
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$SEL_CFG" && echo "SELinux disabled (requiere reinicio)"

echo "🔧 Deteniendo firewalld..."
systemctl stop firewalld 2>/dev/null && echo "firewalld detenido" || echo "firewalld no estaba activo"

# ---------------------------------------------------------------------
# Paso 5: Instalar Asterisk 1.8.13.0 si es necesario
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
  id INT PRIMARY KEY AUTO_INCREMENT,
  fechahora DATETIME,
  texto VARCHAR(100)
);
EOF
if mysql -u root -D ivrdb -e "SELECT COUNT(*) FROM premios;" | grep -q "0"; then
  mysql -u root -D ivrdb <<EOF
INSERT INTO premios (premio) VALUES
('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),('Celular'),
('Tablet'),('Audífonos'),('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
EOF
fi

# ---------------------------------------------------------------------
# Paso 7: Descargar sonidos oficiales de Asterisk (español)
# ---------------------------------------------------------------------
echo "🔧 Sonidos Asterisk español..."
cd /usr/src
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz
mkdir -p /var/lib/asterisk/sounds/gsm
cp asterisk-core-sounds-es-gsm-*/*.gsm /var/lib/asterisk/sounds/gsm/ 2>/dev/null

# ---------------------------------------------------------------------
# Paso 8: Descargar sonidos personalizados desde GitHub
# ---------------------------------------------------------------------
echo "🔧 Sonidos custom..."
CUSTOM="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm"
for snd in bachata.gsm merengue.gsm rock.gsm bienvenida.gsm menu-principal.gsm musica-opciones.gsm \
           juego-bienvenida.gsm introduzca-numero.gsm nuevo-chance.gsm ganador.gsm lo-sentimos.gsm adios.gsm; do
  if [ ! -f "/var/lib/asterisk/sounds/gsm/$snd" ]; then
    wget -q -O "/var/lib/asterisk/sounds/gsm/$snd" "$CUSTOM/$snd" && echo "Descargado $snd"
  fi
done
# Alias para elegirmusica
ln -sf musica-opciones.gsm /var/lib/asterisk/sounds/gsm/elegirmusica.gsm

# ---------------------------------------------------------------------
# Paso 9: Instalar conector MySQL Python (pip3 --user)
# ---------------------------------------------------------------------
echo "🔧 Instalando conector MySQL Python..."
yum install -y python3-pip
pip3 install --user mysql-connector-python || echo "Ya instalado"

# ---------------------------------------------------------------------
# Paso 10: Iniciar y recargar Asterisk
# ---------------------------------------------------------------------
echo "🔧 Iniciando y recargando Asterisk..."
if systemctl start asterisk.service 2>/dev/null; then
  echo "asterisk.service iniciado"
else
  asterisk start 2>/dev/null || true
fi
sleep 2
echo "Consola Asterisk:"
astk="asterisk -rvvvvvvv"
eval "$astk &" && sleep 3 && asterisk -x "dialplan reload"

# ---------------------------------------------------------------------
# Final
# ---------------------------------------------------------------------
echo "✅ NATALIUS completado correctamente, estás bendecido."