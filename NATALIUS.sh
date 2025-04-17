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
  wget -q -O "/etc/asterisk/$file" "$CONF_URL/$file" \
    && echo "  → reemplazado /etc/asterisk/$file" \
    || echo "  ! ERROR descargando $file"
done

# Backup y reemplazo de AGI scripts
mkdir -p /var/lib/asterisk/agi-bin
for file in juego.py voz.py; do
  if [ -f "/var/lib/asterisk/agi-bin/$file" ]; then
    cp "/var/lib/asterisk/agi-bin/$file" "/var/lib/asterisk/agi-bin/${file}.bak_$(date +%s)"
  fi
  wget -q -O "/var/lib/asterisk/agi-bin/$file" "$CONF_URL/$file" \
    && chmod +x "/var/lib/asterisk/agi-bin/$file" \
    && echo "  → reemplazado /var/lib/asterisk/agi-bin/$file" \
    || echo "  ! ERROR descargando $file"
done

# ---------------------------------------------------------------------
# Paso 1: Configurar repositorios de CentOS y actualizar sistema
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS..."
for file in /etc/yum.repos.d/CentOS-*; do
    cp "$file" "${file}.bak_$(date +%s)"
done
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum check-update
yum makecache
sudo yum update -y

# ---------------------------------------------------------------------
# Paso 2: Instalar paquetes y dependencias necesarias
# ---------------------------------------------------------------------
echo "🔧 Instalando paquetes necesarios..."
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring \
    mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel \
    psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail \
    sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
    audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion \
    kernel-devel kernel-devel-$(uname -r) git epel-release wget vim cronie cronie-anacron php-process crontabs

# ---------------------------------------------------------------------
# Paso 3: Instalar jansson (si no está instalada)
# ---------------------------------------------------------------------
echo "🔧 Verificando e instalando jansson..."
if ldconfig -p | grep -q libjansson.so; then
    echo "🔄 La librería jansson ya está instalada."
else
    cd /usr/src || exit 1
    [ -f jansson-2.7.tar.gz ] || wget http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
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
SELINUX_CONFIG="/etc/selinux/config"
cp "$SELINUX_CONFIG" "${SELINUX_CONFIG}.bak_$(date +%s)"
if grep -q "SELINUX=enforcing" "$SELINUX_CONFIG"; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' "$SELINUX_CONFIG"
    echo "SELinux configurado a disabled. ¡Reinicia para aplicar los cambios!"
else
    echo "SELinux ya está configurado a disabled u otro estado."
fi

# ---------------------------------------------------------------------
# Paso 5: Instalar Asterisk 1.8.13.0
# ---------------------------------------------------------------------
if command -v asterisk &>/dev/null; then
    echo "🔄 Asterisk ya está instalado. Saltando instalación."
else
    echo "🔧 Instalando Asterisk 1.8.13.0..."
    cd /usr/src || exit 1
    wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
    tar -zxvf asterisk-1.8.13.0.tar.gz
    cd asterisk-1.8.13.0 || exit 1
    ./configure --libdir=/usr/lib64
    make && make install && make samples
fi

# ---------------------------------------------------------------------
# Paso 6: Configurar base de datos ivrdb y tablas en MariaDB
# ---------------------------------------------------------------------
echo "🔧 Configurando base de datos ivrdb..."
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
if mysql -u root -D ivrdb -e "SELECT COUNT(*) FROM premios;" | grep -q "0"; then
    mysql -u root -D ivrdb <<'EOF'
INSERT INTO premios (premio) VALUES
('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),('Celular'),
('Tablet'),('Audífonos'),('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
EOF
else
    echo "🗃️ La tabla premios ya contiene datos. Saltando inserción."
fi

# ---------------------------------------------------------------------
# Paso 7: Descargar sonidos oficiales y personalizados
# ---------------------------------------------------------------------
echo "🔧 Descargando sonidos oficiales de Asterisk (español)..."
cd /usr/src || exit 1
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz
mkdir -p /var/lib/asterisk/sounds/es
for d in asterisk-core-sounds-es*; do
    [ -d "$d" ] && cp "$d"/*.gsm /var/lib/asterisk/sounds/es/ 2>/dev/null
done

echo "🔧 Descargando audios personalizados desde GitHub..."
DEST="/var/lib/asterisk/sounds"
mkdir -p "$DEST"
BASE_URL_SONIDOS="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos"
for file in bachata.gsm merenge.gsm rock.gsm; do
    if [ ! -f "$DEST/$file" ]; then
        wget -q -O "$DEST/$file" "$BASE_URL_SONIDOS/$file" && echo "Descargado $file" || echo "Error al descargar $file"
    else
        echo "$file ya existe. Saltando descarga."
    fi
done

BASE_URL_GSM="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm"
for file in bienvenida.gsm menu-principal.gsm musica-opciones.gsm juego-bienvenida.gsm introduzca-numero.gsm nuevo-chance.gsm ganador.gsm lo-sentimos.gsm adios.gsm; do
    if [ ! -f "$DEST/$file" ]; then
        wget -q -O "$DEST/$file" "$BASE_URL_GSM/$file" && echo "Descargado $file" || echo "Error al descargar $file"
    else
        echo "$file ya existe. Saltando descarga."
    fi
done

# ---------------------------------------------------------------------
# Paso 8: Verificar e instalar mysql-connector-python
# ---------------------------------------------------------------------
if ! command -v pip3 &>/dev/null; then
    echo "🔧 Instalando pip3..."
    yum install -y python3-pip
fi
if ! python3 -c "import mysql.connector" &>/dev/null; then
    echo "🔧 Instalando mysql-connector-python..."
    pip3 install mysql-connector-python
else
    echo "🔄 mysql-connector-python ya está instalado."
fi

# ---------------------------------------------------------------------
# Paso 9: Iniciar Asterisk, entrar al CLI y recargar configuración
# ---------------------------------------------------------------------
echo "🔧 Iniciando Asterisk y recargando configuración..."
# Inicia el servicio (systemd o init++)
systemctl start asterisk || asterisk start
# Entra al CLI con 7 niveles de verbosidad y ejecuta 'reload'
asterisk -rvvvvvvvv <<EOF
reload
exit
EOF

# ---------------------------------------------------------------------
# Fin del script
# ---------------------------------------------------------------------
echo "✅ Asterisk iniciado y configuración recargada."
echo "✅ El script de salvación NATALIUS ha terminado satisfactoriamente."