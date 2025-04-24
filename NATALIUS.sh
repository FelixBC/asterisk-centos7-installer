#!/bin/bash
# ----------------------------------------------------
# HAZ EJECUTADO NATALIUS
# Script de salvación creado por:
#   NATALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL
# ----------------------------------------------------

echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATHALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
sleep 2

echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
sleep 2

# ---------------------------------------------------------------------
# Paso 1: Configurar repositorios (CentOS Vault, EPEL, RPM Fusion)
# ---------------------------------------------------------------------
echo "🔧 Configurando repositorios de CentOS y terceros..."
# Usar CentOS Vault para repos antiguos de CentOS 7
sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

# Instalar EPEL y RPM Fusion (free y non-free) si aún no están instalados
if ! rpm -q epel-release &>/dev/null; then
  /usr/bin/yum -q -y install epel-release
fi
RPMFUSION_FREE_RPM="https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm"
RPMFUSION_NONFREE_RPM="https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm"
if ! rpm -q rpmfusion-free-release &>/dev/null; then
  /usr/bin/yum -q -y localinstall --nogpgcheck "${RPMFUSION_FREE_RPM}" "${RPMFUSION_NONFREE_RPM}"
fi
/usr/bin/yum -q -y clean all && /usr/bin/yum -q -y makecache
echo "  → Repositorios configurados correctamente"

# ---------------------------------------------------------------------
# Paso 2: Instalar herramientas de compilación y dependencias del sistema
# ---------------------------------------------------------------------
echo "🔧 Instalando paquetes necesarios..."
/usr/bin/yum -q -y install gcc gcc-c++ make kernel-devel-$(uname -r) \
    php php-xml php-mysql php-pear php-mbstring php-process \
    mariadb mariadb-server mariadb-devel sqlite-devel lynx bison \
    gmime-devel psmisc tftp-server httpd ncurses-devel libtermcap-devel \
    sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel \
    libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel \
    subversion git wget vim cronie cronie-anacron crontabs \
    ffmpeg ffmpeg-devel python3 python3-pip
echo "  → Paquetes del sistema instalados"

# ---------------------------------------------------------------------
# Paso 3: Instalar Jansson (si no existe)
# ---------------------------------------------------------------------
echo "🔧 Verificando biblioteca Jansson..."
if ldconfig -p | grep -q libjansson.so; then
  echo "  → Jansson ya está instalada"
else
  cd /usr/src || exit 1
  JANSSON_TARBALL="jansson-2.7.tar.gz"
  JANSSON_URL="http://www.digip.org/jansson/releases/${JANSSON_TARBALL}"
  if [ ! -f "${JANSSON_TARBALL}" ]; then
    echo "🔽 Descargando ${JANSSON_TARBALL}..."
    if ! /usr/bin/wget -q "${JANSSON_URL}"; then
      echo "❌ Error descargando ${JANSSON_TARBALL}"
      exit 1
    fi
  fi
  tar -xzf "${JANSSON_TARBALL}" && cd jansson-2.7 || { echo "❌ Error preparando Jansson"; exit 1; }
  ./configure --prefix=/usr
  make -s clean && make -s && make -s install
  /sbin/ldconfig
  echo "  → Jansson instalada"
fi

# ---------------------------------------------------------------------
# Paso 4: Instalar Asterisk (compilar desde código fuente con soporte ODBC)
# ---------------------------------------------------------------------
AST_VERSION="1.8.13.0"
AST_TARBALL="asterisk-${AST_VERSION}.tar.gz"
AST_SRC_DIR="/usr/src/asterisk-${AST_VERSION}"
AST_URL="https://repository.timesys.com/buildsources/a/asterisk/asterisk-${AST_VERSION}/${AST_TARBALL}"

echo "🔧 Verificando instalación de Asterisk..."
if ! command -v asterisk &>/dev/null; then
  echo "⚠️  Asterisk no está instalado. Iniciando compilación e instalación..."
  cd /usr/src || exit 1
  if ! /usr/bin/wget -q "${AST_URL}"; then
    echo "❌ No se pudo descargar ${AST_TARBALL}"
    exit 1
  fi
  tar -xzf "${AST_TARBALL}" && cd "asterisk-${AST_VERSION}" || { echo "❌ Error extrayendo Asterisk"; exit 1; }
  ./configure --libdir=/usr/lib64
  menuselect/menuselect --enable res_odbc --enable func_odbc menuselect.makeopts
  make -s && make -s install && make -s samples
  echo "  → Asterisk ${AST_VERSION} instalado y samples generados"
else
  echo "✅ Asterisk ya está instalado, comprobando configuración..."
  # Regenerar samples si faltan archivos base
  if [ ! -f /etc/asterisk/asterisk.conf ]; then
    if [ -d "${AST_SRC_DIR}" ]; then
      echo "🛠  Archivos de muestra faltantes: regenerando samples..."
      cd "${AST_SRC_DIR}" || exit 1
      make -s samples
      echo "  → Samples regenerados"
    else
      echo "⚠️  Fuente de Asterisk no encontrada; no se pueden regenerar samples"
    fi
  fi
  # Recompilar Asterisk con módulos ODBC habilitados
  echo "🔧 Recompilando Asterisk con soporte ODBC..."
  if [ ! -d "${AST_SRC_DIR}" ]; then
    # Descargar fuente si no existe para recompilar módulos
    cd /usr/src || exit 1
    echo "🔽 Descargando fuente de Asterisk ${AST_VERSION}..."
    if ! /usr/bin/wget -q "${AST_URL}"; then
      echo "❌ No se pudo descargar ${AST_TARBALL}"
      exit 1
    fi
    tar -xzf "${AST_TARBALL}" || { echo "❌ Error extrayendo Asterisk"; exit 1; }
  fi
  cd "${AST_SRC_DIR}" || exit 1
  make -s clean && make -s distclean
  ./configure --libdir=/usr/lib64
  menuselect/menuselect --enable res_odbc --enable func_odbc menuselect.makeopts
  make -s && make -s install
  echo "  → Asterisk recompilado con módulos ODBC"
fi

# ---------------------------------------------------------------------
# Paso 5: Desplegar archivos de configuración de Asterisk y ODBC
# ---------------------------------------------------------------------
echo "🔧 Desplegando archivos de configuración desde GitHub..."
CONF_BASE_URL="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main"
CONF_URL="${CONF_BASE_URL}/conf"

# Archivos principales de configuración de Asterisk
ASTERISK_CONF=(extensions.conf sip.conf voicemail.conf func_odbc.conf res_odbc.conf)
for file in "${ASTERISK_CONF[@]}"; do
  [ -f "/etc/asterisk/$file" ] && cp "/etc/asterisk/$file" "/etc/asterisk/${file}.bak_$(date +%s)"
  if /usr/bin/wget -q -O "/etc/asterisk/$file" "${CONF_URL}/$file"; then
    echo "  → /etc/asterisk/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# Archivos de configuración ODBC (unixODBC)
ODBC_CONF=(odbc.ini odbcinst.ini)
for file in "${ODBC_CONF[@]}"; do
  [ -f "/etc/$file" ] && cp "/etc/$file" "/etc/${file}.bak_$(date +%s)"
  if /usr/bin/wget -q -O "/etc/$file" "${CONF_URL}/$file"; then
    echo "  → /etc/$file reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# ---------------------------------------------------------------------
# Paso 6: Desplegar scripts AGI personalizados
# ---------------------------------------------------------------------
echo "🔧 Desplegando AGI scripts..."
AGI_DIR="/var/lib/asterisk/agi-bin"
mkdir -p "${AGI_DIR}"
AGI_SCRIPTS=(juego.py voz.py)
for file in "${AGI_SCRIPTS[@]}"; do
  [ -f "${AGI_DIR}/${file}" ] && cp "${AGI_DIR}/${file}" "${AGI_DIR}/${file}.bak_$(date +%s)"
  if /usr/bin/wget -q -O "${AGI_DIR}/${file}" "${CONF_URL}/${file}"; then
    chmod +x "${AGI_DIR}/${file}"
    echo "  → ${AGI_DIR}/${file} reemplazado"
  else
    echo "  ❗ ERROR descargando $file"
  fi
done

# ---------------------------------------------------------------------
# Paso 7: Desactivar SELinux y firewalld
# ---------------------------------------------------------------------
echo "🔧 Deshabilitando SELinux y firewalld..."
SEL_CFG="/etc/selinux/config"
cp "${SEL_CFG}" "${SEL_CFG}.bak_$(date +%s)"
if sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' "${SEL_CFG}"; then
  echo "  → SELinux deshabilitado (requiere reinicio para aplicar)"
else
  echo "  ❗ No se pudo modificar SELinux (verifica permisos)"
fi
if /usr/bin/systemctl is-active --quiet firewalld; then
  /usr/bin/systemctl stop firewalld
  /usr/bin/systemctl disable firewalld
  echo "  → firewalld detenido y deshabilitado"
else
  echo "  → firewalld ya está desactivado"
fi

# ---------------------------------------------------------------------
# Paso 8: (Re)crear base de datos ivrdb y tabla premios limpia
# ---------------------------------------------------------------------
echo "🔧 (Re)creando base de datos 'ivrdb' y tabla 'premios'…"
# Iniciar servicio MariaDB si está disponible
if /usr/bin/systemctl list-unit-files | grep -q '^mariadb.service'; then
  /usr/bin/systemctl enable mariadb --now &>/dev/null || /usr/bin/systemctl start mariadb
else
  echo "❌ Servicio MariaDB no encontrado. Por favor instala MariaDB e intenta de nuevo."
  exit 1
fi

# Crear base de datos y tablas requeridas
/usr/bin/mysql -u root <<SQL
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
# Paso 9: (Re)Construir sonidos personalizados desde cero
# ---------------------------------------------------------------------
echo "🔄 Reconstruyendo directorio de sonidos personalizados..."
SOUND_DIR="/var/lib/asterisk/sounds"
rm -rf "${SOUND_DIR}"/*.gsm 2>/dev/null   # borrar TODOS los .gsm viejos
mkdir -p "${SOUND_DIR}"

echo "🔧 Descargando sonidos personalizados (formatos .gsm)..."
GSM_URL="${CONF_BASE_URL}/sonidos/gsm"
# Lista completa de archivos de audio a descargar
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
  if /usr/bin/wget -q -O "${SOUND_DIR}/${f}" "${GSM_URL}/${f}"; then
    echo "  ✅ ${f} descargado"
  else
    echo "  ❗ ERROR descargando ${f}"
  fi
done

# ---------------------------------------------------------------------
# Paso 10: Instalar dependencias Python (MySQL Connector y SpeechRecognition)
# ---------------------------------------------------------------------
echo "🔧 Verificando e instalando dependencias de Python..."
# Asegurarse de tener pip3 actualizado
if ! command -v pip3 &>/dev/null; then
  /usr/bin/yum -q -y install python3-pip
fi
/usr/bin/pip3 install --quiet --upgrade pip
echo "  → pip actualizado"

# MySQL Connector (Python)
echo "🔧 Verificando mysql-connector-python..."
if ! python3 -c "import mysql.connector" &>/dev/null; then
  /usr/bin/pip3 install --quiet mysql-connector-python==8.0.28
  echo "  → Conector MySQL-Python instalado"
else
  echo "  → Conector MySQL-Python ya existente"
fi

# SpeechRecognition (Python)
echo "🔧 Verificando SpeechRecognition..."
if ! python3 -c "import speech_recognition" &>/dev/null; then
  /usr/bin/pip3 install --quiet SpeechRecognition
  echo "  → SpeechRecognition instalado"
else
  echo "  → SpeechRecognition ya existente"
fi

# ---------------------------------------------------------------------
# Paso 11: Instalar drivers ODBC de UnixODBC y MySQL, luego probar DSN
# ---------------------------------------------------------------------
echo "🔧 Instalando drivers ODBC (unixODBC y MySQL ODBC)..."
/usr/bin/yum -q -y install unixODBC unixODBC-devel mysql-connector-odbc
echo "🔧 Probando DSN 'asterisk' con isql..."
if echo "quit" | /usr/bin/isql -v asterisk root "" &>/dev/null; then
  echo "  → DSN 'asterisk' OK"
else
  echo "  ❗ Prueba de conexión ODBC fallida (DSN 'asterisk')"
fi

# ---------------------------------------------------------------------
# Paso 12: Iniciar Asterisk y recargar configuración (incluyendo ODBC)
# ---------------------------------------------------------------------
echo "🔧 Iniciando servicio de Asterisk..."
ASTERISK_CMD="$(command -v asterisk || echo "/usr/sbin/asterisk")"
if /usr/bin/systemctl list-unit-files | grep -q '^asterisk.service'; then
  /usr/bin/systemctl start asterisk 2>/dev/null || echo "❗ No se pudo iniciar Asterisk con systemd."
else
  # Si no hay servicio systemd, intentar iniciar Asterisk directamente
  if ! $ASTERISK_CMD &>/dev/null; then
    echo "❗ No se pudo iniciar Asterisk. Inícialo manualmente para continuar."
  fi
fi

# Recargar configuración de Asterisk
$ASTERISK_CMD -rx "reload" &>/dev/null

# ---------------------------------------------------------------------
# Paso 13: Verificar y cargar módulo chan_sip en Asterisk
# ---------------------------------------------------------------------
echo "🔧 Verificando módulo chan_sip..."
# 1) Comprobar conexión al CLI de Asterisk
OUTPUT=$($ASTERISK_CMD -rx "module show like sip" 2>&1)
if echo "$OUTPUT" | grep -qi "Unable to connect"; then
  echo "❌ No se pudo conectar al CLI de Asterisk."
  echo "   Revisa permisos del socket (/var/run/asterisk/asterisk.ctl)."
  exit 1
fi

# 2) Si chan_sip ya está cargado, finalizar
if echo "$OUTPUT" | grep -qF "chan_sip.so"; then
  echo "✅ chan_sip.so ya está cargado."
else
  # 3) Verificar que el archivo de módulo exista (en /usr/lib64 o /usr/lib)
  MODULE_PATH=""
  if [ -f "/usr/lib64/asterisk/modules/chan_sip.so" ]; then
    MODULE_PATH="/usr/lib64/asterisk/modules/chan_sip.so"
  elif [ -f "/usr/lib/asterisk/modules/chan_sip.so" ]; then
    MODULE_PATH="/usr/lib/asterisk/modules/chan_sip.so"
  fi
  if [ -z "$MODULE_PATH" ]; then
    echo "⚠️  No existe el módulo chan_sip.so en las rutas estándar."
    exit 1
  fi

  # 4) Intentar cargar el módulo chan_sip
  echo "🔄 Cargando chan_sip.so..."
  LOAD_OUT=$($ASTERISK_CMD -rx "module load chan_sip.so" 2>&1)
  if echo "$LOAD_OUT" | grep -qi "Loaded"; then
    echo "✅ chan_sip.so cargado correctamente."
  else
    echo "❌ Falló carga chan_sip.so:"
    echo "$LOAD_OUT"
    echo "🔄 Probando cargar sin extensión .so..."
    LOAD_OUT2=$($ASTERISK_CMD -rx "module load chan_sip" 2>&1)
    if echo "$LOAD_OUT2" | grep -qi "Loaded"; then
      echo "✅ chan_sip cargado correctamente (sin .so)."
    else
      echo "❌ Segundo intento falló:"
      echo "$LOAD_OUT2"
      exit 1
    fi
  fi
fi

# ---------------------------------------------------------------------
# Paso 14: Descargar y reproducir jingle de despedida, luego limpiarlo
# ---------------------------------------------------------------------
echo "🔊 Descargando jingle de despedida..."
TMP_JINGLE="/tmp/adios.m4a"
if /usr/bin/wget -q -O "${TMP_JINGLE}" "${CONF_BASE_URL}/sonidos/adios.m4a"; then
  echo "  → ${TMP_JINGLE} descargado"
else
  echo "  ❗ No se pudo descargar el jingle, se omitirá la reproducción."
  TMP_JINGLE=""
fi

if [ -n "${TMP_JINGLE}" ]; then
  if command -v ffplay &>/dev/null; then
    echo "▶️  Reproduciendo jingle..."
    ffplay -nodisp -autoexit "${TMP_JINGLE}" &>/dev/null || echo "  ❗ Falló la reproducción con ffplay"
  else
    echo "⚠️  ffplay no encontrado, omitiendo reproducción"
  fi
  echo "🗑  Borrando jingle..."
  rm -f "${TMP_JINGLE}"
fi

# ---------------------------------------------------------------------
# Fin del script
# ---------------------------------------------------------------------
echo "***********************************************"
echo "  HA FINALIZADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATHALY BERROA, FÉLIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
echo "Pasos a seguir: sudo asterisk -rvvvvvvvv y probar"
echo "☕ ¿Este script te salvó la vida? ¡Invítanos un café!"
echo "👉 https://www.paypal.me/felixBlancoC"
echo "--------------------------------------------------"
echo "NATALIUS, script de salvación ha completado correctamente, ¡estás bendecido!"
