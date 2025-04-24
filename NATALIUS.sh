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
# Paso 0: Preparar entorno de compilación y definir CLI de Asterisk
echo "🔧 Instalando herramientas de compilación..."
yum -q -y install gcc gcc-c++ make cpp autoconf automake \
    libuuid-devel ncurses-devel libxml2-devel sqlite-devel openssl-devel
ASTERISK_CMD="asterisk -rx"
# ---------------------------------------------------------------------
# Paso 1: Instalar dependencias adicionales
echo "🔧 Instalando paquetes necesarios..."
yum -q -y install php-xml php php-mysql php-pear php-mbstring \
    mariadb-devel mariadb-server mariadb \
    lynx bison gmime-devel psmisc tftp-server httpd \
    ncurses-devel libtermcap-devel sendmail sendmail-cf \
    caching-nameserver sox newt-devel libxml2-devel libtiff-devel \
    audiofile-devel gtk2-devel uuid-devel libtool subversion \
    "kernel-devel-$(uname -r)" git epel-release wget vim \
    cronie cronie-anacron php-process crontabs
# ---------------------------------------------------------------------
# Paso 2: Instalar Asterisk desde fuente y generar samples
AST_SRC_DIR="/usr/src/asterisk-1.8.13.0"
if ! command -v asterisk &>/dev/null; then
  echo "⚠️  Asterisk no está instalado. Compilando e instalando..."
  cd /usr/src || exit 1
  wget -q https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
  tar -xzf asterisk-1.8.13.0.tar.gz
  cd asterisk-1.8.13.0 || exit 1
  ./configure --libdir=/usr/lib64
  make -s && make -s install && make -s samples
  echo "  → Asterisk instalado y samples generados"
else
  echo "✅ Asterisk ya instalado, omitiendo compilación"
fi

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
# Paso 11: Crear insert_data.php en /var/www/html/
# ---------------------------------------------------------------------
echo "🔧 Creando /var/www/html/insert_data.php..."
cat > /var/www/html/insert_data.php <<'EOF'
<?php
// insert_data.php
date_default_timezone_set('America/Santo_Domingo');
// argv: [1]=ext, [2]=num, [3]=Gano/Perdio, [4]=premio o NULL, [5]=Si/No
$extension       = $argv[1];
$numero_generado = $argv[2];
$resultado       = $argv[3];
$premio          = $argv[4];
$tuvo_chance     = $argv[5];
$conn = new mysqli("localhost","root","","ivrdb");
if ($conn->connect_error) {
    file_put_contents("/tmp/error_log_php.txt","Conexión fallida: ".$conn->connect_error."\n",FILE_APPEND);
    exit(1);
}
$fecha_hora = date("Y-m-d H:i:s");
$gano       = ($resultado==="Gano") ? 1 : 0;
$premio     = ($premio==="NULL") ? null : $premio;
$chance     = ($tuvo_chance==="Si")   ? 1 : 0;
$stmt = $conn->prepare(
    "INSERT INTO llamadas
     (extension, fecha_hora, numero_generado, gano, premio_ganado, tuvo_chance)
     VALUES (?, ?, ?, ?, ?, ?)"
);
$stmt->bind_param("ssiisi",$extension,$fecha_hora,$numero_generado,$gano,$premio,$chance);
if (!$stmt->execute()) {
    file_put_contents("/tmp/error_log_php.txt","Error al insertar: ".$stmt->error."\n",FILE_APPEND);
}
$stmt->close();
$conn->close();
?>
EOF
chmod 644 /var/www/html/insert_data.php
echo "  → insert_data.php creado y permisos establecidos"

# ---------------------------------------------------------------------
# Paso 12: Iniciar y recargar Asterisk
# ---------------------------------------------------------------------
echo "🔧 Iniciando y recargando Asterisk..."
systemctl start asterisk 2>/dev/null || asterisk start
asterisk -rx "reload" &>/dev/null

# ---------------------------------------------------------------------
# Paso 13: Verificar y cargar chan_sip.so en Asterisk
# ---------------------------------------------------------------------
echo "🔧 Verificando módulo chan_sip..."
# 1) Comprobar en el CLI
OUTPUT=$($ASTERISK_CMD -rx "module show like sip" 2>&1)
if echo "$OUTPUT" | grep -qi "Unable to connect"; then
  echo "❌ No se pudo conectar al CLI de Asterisk."
  echo "   Revisa permisos del socket (/var/run/asterisk/asterisk.ctl)."
  exit 1
fi

# 2) Si ya está cargado, salimos
if echo "$OUTPUT" | grep -qF "chan_sip.so"; then
  echo "✅ chan_sip.so ya está cargado."
else
  # 3) Verificar que el archivo exista
  MODULE_PATH="/usr/lib/asterisk/modules/chan_sip.so"
  if [ ! -f "$MODULE_PATH" ]; then
    echo "⚠️  No existe el módulo en: $MODULE_PATH"
    exit 1
  fi

  # 4) Intentar cargarlo
  echo "🔄 Cargando chan_sip.so..."
  LOAD_OUT=$($ASTERISK_CMD -rx "module load chan_sip.so" 2>&1)
  if echo "$LOAD_OUT" | grep -qi "Loaded"; then
    echo "✅ chan_sip.so cargado correctamente."
  else
    echo "❌ Falló carga chan_sip.so:"
    echo "$LOAD_OUT"
    echo "🔄 Probando sin extensión .so..."
    LOAD2=$($ASTERISK_CMD -rx "module load chan_sip" 2>&1)
    if echo "$LOAD2" | grep -qi "Loaded"; then
      echo "✅ chan_sip cargado (sin .so)."
    else
      echo "❌ Segundo intento falló:"
      echo "$LOAD2"
      exit 1
    fi
  fi
fi


# ---------------------------------------------------------------------
# Paso 14: Instalar SpeechRecognition, MySQL‑Connector y FFmpeg
# ---------------------------------------------------------------------

echo "🔧 Instalando dependencias de Python y multimedia..."
pip3 install --upgrade pip
pip3 install speechrecognition
pip3 install mysql-connector-python==8.0.28
yum install -y epel-release
yum localinstall -y --nogpgcheck \
  https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm \
  https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm
yum clean all && yum makecache
yum install -y ffmpeg ffmpeg-devel
echo "  → SpeechRecognition, conector MySQL y FFmpeg instalados"
# ---------------------------------------------------------------------
# Paso 15: Descargar + reproducir jingle de despedida y borrarlo
# ---------------------------------------------------------------------
echo "🔊 Descargando jingle de despedida..."
TMP_JINGLE="/tmp/adios.m4a"
if wget -q -O "${TMP_JINGLE}" \
    "https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/adios.m4a"; then
  echo "  → ${TMP_JINGLE} descargado"
else
  echo "  ❗ No se pudo descargar el jingle, omitiendo reproducción."
  TMP_JINGLE=""
fi

if [ -n "${TMP_JINGLE}" ]; then
  # Sólo si no existe ffplay instalamos repositorio + paquete
  if ! command -v ffplay &>/dev/null; then
    echo "📦 Habilitando repositorios EPEL + RPM Fusion..."
    yum install -y epel-release
    yum localinstall -y --nogpgcheck \
      https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm \
      https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm
    yum clean all && yum makecache
    echo "📦 Instalando ffmpeg (incluye ffplay)..."
    yum install -y ffmpeg ffmpeg-devel
  fi

  if command -v ffplay &>/dev/null; then
    echo "▶️  Reproduciendo jingle..."
    ffplay -nodisp -autoexit "${TMP_JINGLE}" >/dev/null 2>&1 || \
      echo "  ❗ Falló la reproducción con ffplay"
  else
    echo "⚠️  Aún no se encontró ffplay, omitiendo reproducción"
  fi

  echo "🗑  Borrando jingle..."
  rm -f "${TMP_JINGLE}"
fi

# ---------------------------------------------------------------------
# Fin
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
