#!/bin/bash
# ----------------------------------------------------
# NATALIUS: Instalador Automático de Asterisk 1.8.13.0 en CentOS 7
# Creado por: NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL
# ----------------------------------------------------

echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
sleep 2

echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
sleep 2

# ---------------------------------------------------------------------
# Paso 0: Descarga de configuraciones personalizadas
# ---------------------------------------------------------------------
echo "🔧 Descargando archivos de configuración desde GitHub..."
CONF_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf"
for cfg in extensions.conf sip.conf voicemail.conf; do
  [[ -f /etc/asterisk/$cfg ]] && cp /etc/asterisk/$cfg /etc/asterisk/${cfg}.bak_$(date +%s)
  if wget -q -O /etc/asterisk/$cfg "$CONF_URL/$cfg"; then
    echo "  → reemplazado /etc/asterisk/$cfg"
  else
    echo "  ! ERROR descargando $cfg"
  fi
done

mkdir -p /var/lib/asterisk/agi-bin
auto_conf=(juego.py voz.py)
for script in "${auto_conf[@]}"; do
  [[ -f /var/lib/asterisk/agi-bin/$script ]] && cp /var/lib/asterisk/agi-bin/$script /var/lib/asterisk/agi-bin/${script}.bak_$(date +%s)
  if wget -q -O /var/lib/asterisk/agi-bin/$script "$CONF_URL/$script"; then
    chmod +x /var/lib/asterisk/agi-bin/$script
    echo "  → reemplazado /var/lib/asterisk/agi-bin/$script"
  else
    echo "  ! ERROR descargando $script"
  fi
done

# ---------------------------------------------------------------------
# Paso 1: Repositorios y actualización del sistema
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS..."
for repo in /etc/yum.repos.d/CentOS-*; do
  cp "$repo" "${repo}.bak_$(date +%s)"
done
sed -i 's|^mirrorlist|#&|' /etc/yum.repos.d/CentOS-*
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

yum update -y

# ---------------------------------------------------------------------
# Paso 2: Instalación de dependencias
# ---------------------------------------------------------------------
echo "🔧 Instalando paquetes necesarios..."
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring \
    mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel \
    psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail \
    sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
    audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion \
    kernel-devel-$(uname -r) git epel-release wget vim cronie cronie-anacron \
    php-process crontabs python3-pip

# ---------------------------------------------------------------------
# Paso 3: Jansson
# ---------------------------------------------------------------------
echo "🔧 Verificando e instalando jansson..."
if ldconfig -p | grep -q libjansson.so; then
  echo "🔄 Jansson ya instalada."
else
  cd /usr/src || exit 1
  wget -q http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
  tar -zxvf jansson-2.7.tar.gz
  cd jansson-2.7 || exit 1
  ./configure --prefix=/usr && make clean && make && make install
  ldconfig
fi

# ---------------------------------------------------------------------
# Paso 4: SELinux y firewall
# ---------------------------------------------------------------------
echo "🔧 Deshabilitando SELinux..."
SEL_CFG=/etc/selinux/config
cp "$SEL_CFG" "${SEL_CFG}.bak_$(date +%s)"
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$SEL_CFG" && echo "SELinux disabled (requiere reinicio)"

echo "🔧 Deteniendo firewalld..."
systemctl stop firewalld 2>/dev/null && echo "firewalld detenido" || echo "firewalld no estaba activo"

# ---------------------------------------------------------------------
# Paso 5: Asterisk 1.8.13.0
# ---------------------------------------------------------------------
echo "🔧 Instalando Asterisk 1.8.13.0 si es necesario..."
if ! command -v asterisk &>/dev/null; then
  cd /usr/src || exit 1
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -zxvf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0 || exit 1
  ./configure --libdir=/usr/lib64 && make && make install && make samples
else
  echo "🔄 Asterisk ya existe, saltando instalación."
fi

# ---------------------------------------------------------------------
# Paso 6: Base de datos ivrdb
# ---------------------------------------------------------------------
echo "🔧 Configurando ivrdb en MariaDB..."
systemctl start mariadb
echo "CREATE DATABASE IF NOT EXISTS ivrdb; USE ivrdb;" | mysql -u root
echo "Configurar tablas..."
mysql -u root ivrdb <<EOF
CREATE TABLE IF NOT EXISTS premios ( id INT PRIMARY KEY AUTO_INCREMENT, premio VARCHAR(50) );
CREATE TABLE IF NOT EXISTS llamadas ( id INT PRIMARY KEY AUTO_INCREMENT, extension VARCHAR(10), fecha_hora DATETIME, numero_generado INT, gano BOOLEAN, premio_ganado VARCHAR(50), tuvo_chance BOOLEAN );
CREATE TABLE IF NOT EXISTS voice ( id INT PRIMARY KEY AUTO_INCREMENT, fechahora DATETIME, texto VARCHAR(100) );
EOF
if [[ $(mysql -u root -D ivrdb -se "SELECT COUNT(*) FROM premios;") -eq 0 ]]; then
  mysql -u root -D ivrdb <<EOF
INSERT INTO premios (premio) VALUES ('Lavadora'),('Smart TV'),('Air Fryer'),('Laptop'),('Celular'),('Tablet'),('Audífonos'),('Bocina Bluetooth'),('Reloj Inteligente'),('Bonificación');
EOF
fi

# ---------------------------------------------------------------------
# Paso 7: Sonidos Asterisk español
# ---------------------------------------------------------------------
echo "🔧 Sonidos Asterisk español..."
cd /usr/src
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz\mkdir -p /var/lib/asterisk/sounds/gsm
cp asterisk-core-sounds-es-gsm-*/*.gsm /var/lib/asterisk/sounds/gsm/ 2>/dev/null

# ---------------------------------------------------------------------
# Paso 8: Sonidos custom
# ---------------------------------------------------------------------
echo "🔧 Sonidos custom..."
CUSTOM_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm"
files=(bachata.gsm merengue.gsm rock.gsm bienvenida.gsm menu-principal.gsm musica-opciones.gsm juego-bienvenida.gsm introduzca-numero.gsm nuevo-chance.gsm ganador.gsm lo-sentimos.gsm adios.gsm)
for snd in "${files[@]}"; do
  [[ -f /var/lib/asterisk/sounds/gsm/$snd ]] || wget -q -O /var/lib/asterisk/sounds/gsm/$snd "$CUSTOM_URL/$snd" && echo "Descargado $snd"
done
ln -sf musica-opciones.gsm /var/lib/asterisk/sounds/gsm/elegirmusica.gsm

# ---------------------------------------------------------------------
# Paso 9: Conector Python MySQL
# ---------------------------------------------------------------------
echo "🔧 Instalando conector MySQL Python..."
yum install -y python3-pip
pip3 install --user mysql-connector-python || echo "Ya instalado"

# ---------------------------------------------------------------------
# Paso 10: Iniciar y recargar Asterisk sin -r
# ---------------------------------------------------------------------
echo "🔧 Iniciando y recargando Asterisk..."
systemctl start asterisk 2>/dev/null || asterisk start
asterisk -x "reload"
sleep 1
asterisk -x "reload" >/dev/null 2>&1

# ---------------------------------------------------------------------
# Fin
# ---------------------------------------------------------------------
echo "✅ NATALIUS completado correctamente, estás bendecido."