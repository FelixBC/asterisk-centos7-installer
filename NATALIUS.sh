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
# Paso 0: Descargar y desplegar configs de Asterisk
# ---------------------------------------------------------------------
echo "🔧 Descargando configs desde GitHub..."
CONF_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf"

for file in extensions.conf sip.conf voicemail.conf; do
  if [ -f "/etc/asterisk/$file" ]; then
    cp "/etc/asterisk/$file" "/etc/asterisk/${file}.bak_$(date +%s)"
  fi
  if wget -q -O "/etc/asterisk/$file" "$CONF_URL/$file"; then
    echo "  → /etc/asterisk/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

mkdir -p /var/lib/asterisk/agi-bin
for file in juego.py voz.py; do
  if [ -f "/var/lib/asterisk/agi-bin/$file" ]; then
    cp "/var/lib/asterisk/agi-bin/$file" "/var/lib/asterisk/agi-bin/${file}.bak_$(date +%s)"
  fi
  if wget -q -O "/var/lib/asterisk/agi-bin/$file" "$CONF_URL/$file"; then
    chmod +x "/var/lib/asterisk/agi-bin/$file"
    echo "  → /var/lib/asterisk/agi-bin/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# ---------------------------------------------------------------------
# Paso 1: Configurar repositorios de CentOS
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS..."
sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# ---------------------------------------------------------------------
# Paso 2: Instalar paquetes mínimos
# ---------------------------------------------------------------------
echo "🔧 Instalando paquetes necesarios..."
yum -q -y install gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring \
    mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel \
    psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail \
    sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
    audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion \
    "kernel-devel-$(uname -r)" git epel-release wget vim cronie cronie-anacron \
    php-process crontabs

# ---------------------------------------------------------------------
# Paso 3: Instalar jansson si no existe
# ---------------------------------------------------------------------
echo "🔧 Verificando jansson..."
if ldconfig -p | grep -q libjansson.so; then
  echo "  → Jansson ya instalada"
else
  cd /usr/src || exit 1
  [ -f jansson-2.7.tar.gz ] || wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
  tar -xzf jansson-2.7.tar.gz
  cd jansson-2.7 || exit 1
  ./configure --prefix=/usr
  make -s clean && make -s && make -s install
  ldconfig
  echo "  → Jansson instalada"
fi

# ---------------------------------------------------------------------
# Paso 4: Desactivar SELinux y firewall
# ---------------------------------------------------------------------
echo "🔧 Deshabilitando SELinux y firewall..."
SEL_CFG=/etc/selinux/config
cp "$SEL_CFG" "${SEL_CFG}.bak_$(date +%s)"
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$SEL_CFG" && echo "  → SELinux disabled (requiere reinicio)"
if systemctl is-active --quiet firewalld; then
  systemctl stop firewalld
  systemctl disable firewalld
  echo "  → Firewall desactivado"
else
  echo "  → Firewall ya está desactivado"
fi

# ---------------------------------------------------------------------
# Paso 5: Instalar Asterisk 1.8.13.0
# ---------------------------------------------------------------------
echo "🔧 Instalando Asterisk 1.8.13.0..."
if ! command -v asterisk &>/dev/null; then
  cd /usr/src || exit 1
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -xzf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0 || exit 1
  ./configure --libdir=/usr/lib64
  make -s && make -s install && make -s samples
  echo "  → Asterisk instalado"
else
  echo "  → Asterisk ya existe, saltando"
fi

# ---------------------------------------------------------------------
# Paso 6: Configurar base de datos ivrdb
# ---------------------------------------------------------------------
echo "🔧 Configurando ivrdb en MariaDB..."
systemctl start mariadb
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS ivrdb;
USE ivrdb;
CREATE TABLE IF NOT EXISTS premios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  premio VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS llamadas (
  id INT AUTO_INCREMENT PRIMARY KEY,
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
SQL
if [ "$(mysql -u root -D ivrdb -N -e "SELECT COUNT(*) FROM premios;")" -eq 0 ]; then
  mysql -u root -D ivrdb <<SQL
INSERT INTO premios (premio) VALUES
('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),('Celular'),
('Tablet'),('Audífonos'),('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
SQL
  echo "  → Tabla premios poblada"
fi

# ---------------------------------------------------------------------
# Paso 7: Sonidos custom actualizados
# ---------------------------------------------------------------------
echo "🔧 Descargando sonidos personalizados..."
GSM_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm"
DEST="/var/lib/asterisk/sounds"
mkdir -p "$DEST"

GSM_FILES=(
  adios.gsm bonificacion.gsm ganaste.gsm lavadora.gsm perdiste.gsm
  airfryer.gsm celular.gsm gracias-2.gsm lo-sentimos.gsm reloj-inteligente.gsm
  audifonos.gsm diga-palabra.gsm gracias.gsm menu-principal.gsm smart-tv.gsm
  bienvenida.gsm elegir-musica.gsm introduzca-numero.gsm no-disp.gsm tablet.gsm
  bienvenida-juego.gsm elige-numero.gsm juego-bienvenida.gsm chance-extra.gsm timeout-es.gsm
  bocina-bluetooth.gsm ganador.gsm laptop.gsm numero-marcado.gsm tuvoz.gsm
  bachata.gsm merengue.gsm rock.gsm
)

for f in "${GSM_FILES[@]}"; do
  if wget -q -O "$DEST/$f" "$GSM_URL/$f"; then
    echo "  ✅ Descargado $f"
  else
    echo "  ❗ ERROR descargando $f"
  fi
done

# ---------------------------------------------------------------------
# Paso 8: Instalar conector MySQL para Python
# ---------------------------------------------------------------------
echo "🔧 Verificando mysql-connector-python..."
if ! python3 -c "import mysql.connector" &>/dev/null; then
  yum -q -y install python3-pip
  pip3 install --quiet mysql-connector-python
  echo "  → Conector instalado"
else
  echo "  → Conector ya existente"
fi

# ---------------------------------------------------------------------
# Paso 9: Iniciar y recargar Asterisk
# ---------------------------------------------------------------------
echo "🔧 Iniciando y recargando Asterisk..."
systemctl start asterisk 2>/dev/null || asterisk start
asterisk -rx "reload" &>/dev/null

# ---------------------------------------------------------------------
# Fin
# ---------------------------------------------------------------------
echo "***********************************************"
echo "  HA FINALIZADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FELIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
echo " Pasos a seguir: correr asterisk, con sudo asterisk -rvvvvvvvv y probar"
echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
echo "--------------------------------------------------"
echo "NATALIUS, script de salvacion ha completado correctamente, estas bendecido"