#!/bin/bash
# ----------------------------------------------------
# HAZ EJECUTADO NATALIUS
# Script de salvación creado por:
#   NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL
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
# Paso 0: Asegurarse de que Asterisk está instalado
# ---------------------------------------------------------------------
if ! command -v asterisk &>/dev/null; then
  echo "⚠️  Asterisk no está instalado. Iniciando instalación..."
  cd /usr/src || exit 1
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -xzf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0 || exit 1
  ./configure --libdir=/usr/lib64
  make -s && make -s install && make -s samples
  echo "  → Asterisk instalado"
else
  echo "✅ Asterisk ya instalado, saltando instalación"
fi

# ---------------------------------------------------------------------
# Paso 1: Descargar y desplegar configs de Asterisk y ODBC
# ---------------------------------------------------------------------
echo "🔧 Desplegando archivos de configuración desde GitHub..."
CONF_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/conf"

# Asterisk core configs
ASTERISK_CONF=(extensions.conf sip.conf voicemail.conf func_odbc.conf res_odbc.conf)
for file in "${ASTERISK_CONF[@]}"; do
  [ -f "/etc/asterisk/$file" ] && cp "/etc/asterisk/$file" "/etc/asterisk/${file}.bak_$(date +%s)"
  if wget -q -O "/etc/asterisk/$file" "$CONF_URL/$file"; then
    echo "  → /etc/asterisk/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# ODBC configs
ODBC_CONF=(odbc.ini odbcinst.ini)
for file in "${ODBC_CONF[@]}"; do
  [ -f "/etc/$file" ] && cp "/etc/$file" "/etc/${file}.bak_$(date +%s)"
  if wget -q -O "/etc/$file" "$CONF_URL/$file"; then
    echo "  → /etc/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# AGI scripts
echo "🔧 Desplegando AGI scripts..."
mkdir -p /var/lib/asterisk/agi-bin
AGI_SCRIPTS=(juego.py voz.py)
for file in "${AGI_SCRIPTS[@]}"; do
  [ -f "/var/lib/asterisk/agi-bin/$file" ] && cp "/var/lib/asterisk/agi-bin/$file" "/var/lib/asterisk/agi-bin/${file}.bak_$(date +%s)"
  if wget -q -O "/var/lib/asterisk/agi-bin/$file" "$CONF_URL/$file"; then
    chmod +x "/var/lib/asterisk/agi-bin/$file"
    echo "  → /var/lib/asterisk/agi-bin/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# ---------------------------------------------------------------------
# Paso 2: Configurar repositorios de CentOS
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS..."
sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# ---------------------------------------------------------------------
# Paso 3: Instalar dependencias mínimas
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
# Paso 4: Instalar jansson si no existe
# ---------------------------------------------------------------------
echo "🔧 Verificando jansson..."
if ldconfig -p | grep -q libjansson.so; then
  echo "  → Jansson ya está instalada"
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
# Paso 5: Desactivar SELinux y firewalld
# ---------------------------------------------------------------------
echo "🔧 Deshabilitando SELinux y firewalld..."
SEL_CFG=/etc/selinux/config
cp "$SEL_CFG" "${SEL_CFG}.bak_$(date +%s)"
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "$SEL_CFG" && echo "  → SELinux disabled (requiere reinicio)"
if systemctl is-active --quiet firewalld; then
  systemctl stop firewalld
  systemctl disable firewalld
  echo "  → firewalld desactivado"
else
  echo "  → firewalld ya está desactivado"
fi

# ---------------------------------------------------------------------
# Paso 6: Recompilar Asterisk con soporte ODBC
# ---------------------------------------------------------------------
echo "🔧 Recompilando Asterisk con res_odbc y func_odbc..."
cd /usr/src/asterisk-1.8.13.0 || exit 1
make clean
make distclean
./configure --libdir=/usr/lib64
menuselect/menuselect --enable res_odbc --enable func_odbc menuselect.makeopts
make -s && make -s install
echo "  → Asterisk recompilado con módulos ODBC"

# ---------------------------------------------------------------------
# Paso 7: (Re)crear ivrdb + tabla premios “limpia”
# ---------------------------------------------------------------------
echo "🔧 (Re)creando ivrdb y tabla premios…"
systemctl start mariadb

mysql -u root <<SQL
DROP DATABASE IF EXISTS ivrdb;
CREATE DATABASE ivrdb;
USE ivrdb;

CREATE TABLE premios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  premio VARCHAR(50) NOT NULL
);

CREATE TABLE llamadas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  extension VARCHAR(10),
  fecha_hora DATETIME,
  numero_generado INT,
  gano BOOLEAN,
  premio_ganado VARCHAR(50),
  tuvo_chance BOOLEAN
);

CREATE TABLE voice (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fechahora DATETIME,
  texto VARCHAR(100)
);

INSERT INTO premios (premio) VALUES
  ('lavadora'),
  ('smart-tv'),
  ('airfryer'),
  ('laptop'),
  ('celular'),
  ('tablet'),
  ('audífonos'),
  ('bocina-bluetooth'),
  ('reloj-inteligente'),
  ('bonificacion');
SQL

echo "  → ivrdb y tabla premios poblada con nombres LOWERCASE–HYPHENATED"


# ---------------------------------------------------------------------
# Paso 8: (Re)Construir sonidos personalizados desde cero
# ---------------------------------------------------------------------
echo "🔄 Limpiando sonidos antiguos..."
DEST="/var/lib/asterisk/sounds"
rm -rf "${DEST}"/*.gsm     # borra TODOS los .gsm viejos
mkdir -p "$DEST"

echo "🔧 Descargando sonidos personalizados..."
GSM_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm"

# Lista completa de archivos a traer siempre fresco
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
  if wget -q -O "${DEST}/${f}" "${GSM_URL}/${f}"; then
    echo "  ✅ ${f} descargado"
  else
    echo "  ❗ ERROR descargando ${f}"
  fi
done


# ---------------------------------------------------------------------
# Paso 9: Instalar conector MySQL para Python
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
# Paso 10: Instalar drivers ODBC y recargar módulo res_odbc
# ---------------------------------------------------------------------
echo "🔧 Instalando unixODBC y driver MySQL‑ODBC..."
yum -q -y install unixODBC unixODBC-devel mysql-connector-odbc

echo "🔧 Probando DSN 'asterisk' con isql (no interactivo)..."
if echo "quit" | isql -v asterisk root "" >/dev/null 2>&1; then
  echo "  → DSN 'asterisk' OK"
else
  echo "  ❗ Prueba ODBC fallida"
fi

echo "🔧 Recargando módulo res_odbc en Asterisk..."
if asterisk -rx "module reload res_odbc.so" &>/dev/null; then
  echo "  → res_odbc recargado"
else
  echo "  ❗ No se pudo recargar res_odbc"
fi


# ---------------------------------------------------------------------
# Paso 11: Iniciar y recargar Asterisk
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
echo "  NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
echo "Pasos a seguir: sudo asterisk -rvvvvvvvv y probar"
echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
echo "--------------------------------------------------"
echo "NATALIUS, script de salvación ha completado correctamente, ¡estás bendecido!"