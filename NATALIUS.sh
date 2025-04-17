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

#############################
# Paso 1: Configurar repositorios de CentOS y actualizar sistema
#############################
echo "🔧 Configurando repositorios de CentOS..."
for file in /etc/yum.repos.d/CentOS-*; do
    cp "$file" "${file}.bak_$(date +%s)"
done
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum check-update
yum makecache
sudo yum update -y

#############################
# Paso 2: Instalar paquetes y dependencias necesarias
#############################
echo "🔧 Instalando paquetes necesarios..."
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel kernel-devel-$(uname) git subversion saukernel-devel php-process crontabs cronie cronie-anacron wget vim epel-release

#############################
# Paso 3: Instalar jansson (si no está instalada)
#############################
echo "🔧 Verificando e instalando jansson..."
if ldconfig -p | grep -q libjansson.so; then
    echo "🔄 La librería jansson ya está instalada."
else
    cd /usr/src || { echo "Error al acceder a /usr/src"; exit 1; }
    if [ ! -f jansson-2.7.tar.gz ]; then
        wget http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
    fi
    tar -zxvf jansson-2.7.tar.gz
    cd jansson-2.7/ || { echo "Error al acceder a jansson-2.7"; exit 1; }
    ./configure --prefix=/usr
    make clean
    make && make install
    ldconfig
fi

#############################
# Paso 4: Desactivar SELinux (con respaldo previo)
#############################
echo "🔧 Deshabilitando SELinux..."
SELINUX_CONFIG="/etc/selinux/config"
cp "$SELINUX_CONFIG" "${SELINUX_CONFIG}.bak_$(date +%s)"
if grep -q "SELINUX=enforcing" "$SELINUX_CONFIG"; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' "$SELINUX_CONFIG"
    echo "SELinux configurado a disabled. ¡Reinicia para aplicar los cambios!"
else
    echo "SELinux ya está configurado a disabled u otro estado."
fi

#############################
# Paso 5: Instalar Asterisk 1.8.13.0
#############################
if command -v asterisk &> /dev/null; then
    echo "🔄 Asterisk ya está instalado. Saltando instalación."
else
    echo "🔧 Instalando Asterisk 1.8.13.0..."
    cd /usr/src || exit 1
    wget https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
    tar -zxvf asterisk-1.8.13.0.tar.gz
    cd asterisk-1.8.13.0 || exit 1
    ./configure --libdir=/usr/lib64
    make
    make install
    make samples
fi

#############################
# Paso 6: Configurar base de datos ivrdb y tablas necesarias en MariaDB
#############################
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
('Lavadora'),
('Smart TV'),
('Air Fryer'),
('Laptop'),
('Celular'),
('Tablet'),
('Audífonos'),
('Bocina Bluetooth'),
('Reloj Inteligente'),
('Bonificación');
EOF
else
    echo "🗃️ La tabla premios ya contiene datos. Saltando inserción."
fi

#############################
# Paso 7: Descargar sonidos oficiales de Asterisk y audios personalizados desde GitHub
#############################

# 7.1 Descargar sonidos oficiales en español (Asterisk core sounds)
echo "🔧 Descargando sonidos oficiales de Asterisk (español)..."
cd /usr/src || exit 1
wget -N http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz
mkdir -p /var/lib/asterisk/sounds/es
for d in asterisk-core-sounds-es*; do
    if [ -d "$d" ]; then
        cp "$d"/*.gsm /var/lib/asterisk/sounds/es/ 2>/dev/null
    fi
done

# 7.2 Descargar audios personalizados desde el repositorio GitHub
echo "🔧 Descargando audios personalizados desde GitHub..."
# Directorio de destino para los audios personalizados
DEST="/var/lib/asterisk/sounds"
mkdir -p "$DEST"

# Función para descargar un archivo usando wget solo si no existe
download_file() {
    local url="$1"
    local dest="$2"
    if [ ! -f "$dest" ]; then
        wget -q -O "$dest" "$url" && echo "Descargado $(basename "$dest")" || echo "Error al descargar $(basename "$dest")"
    else
        echo "$(basename "$dest") ya existe. Saltando descarga."
    fi
}

# Descarga de la carpeta 'sonidos' (para clips musicales: bachata, merengue, rock, etc.)
BASE_URL_SONIDOS="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos"
# Lista de archivos en 'sonidos' (suponiendo que son nombres descriptivos)
for file in bachata.gsm merengue.gsm rock.gsm; do
    download_file "$BASE_URL_SONIDOS/$file" "$DEST/$file"
done

# Descarga de la carpeta 'sonidos/gsm' (para audios informativos: bienvenida, menu-principal, etc.)
BASE_URL_GSM="https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/sonidos/gsm"
# Lista de archivos en 'sonidos/gsm' (agregar los nombres exactos según repositorio)
for file in bienvenida.gsm menu-principal.gsm musica-opciones.gsm juego-bienvenida.gsm introduzca-numero.gsm nuevo-chance.gsm ganador.gsm lo-sentimos.gsm adios.gsm; do
    download_file "$BASE_URL_GSM/$file" "$DEST/$file"
done

#############################
# Paso 7.3: Verificar e instalar pip3 (para los scripts AGI)
#############################
if ! command -v pip3 &> /dev/null; then
    echo "🔧 Instalando pip3..."
    yum install -y python3-pip
fi

#############################
# Paso 7.4: Instalar mysql-connector-python (para los scripts AGI)
#############################
if ! python3 -c "import mysql.connector" &>/dev/null; then
    echo "🔧 Instalando mysql-connector-python..."
    pip3 install mysql-connector-python
else
    echo "🔄 mysql-connector-python ya está instalado. Saltando instalación."
fi

#############################
# Paso 8: Integrar scripts AGI (juego.py y voz.py)
#############################
echo "🔧 Integrando scripts AGI..."
mkdir -p /var/lib/asterisk/agi-bin

# juego.py
if [ -f /var/lib/asterisk/agi-bin/juego.py ]; then
    cp /var/lib/asterisk/agi-bin/juego.py /var/lib/asterisk/agi-bin/juego.py.bak_$(date +%s)
fi
cat <<'EOF' > /var/lib/asterisk/agi-bin/juego.py
#!/usr/bin/env python3
import random
import sys
import mysql.connector
from datetime import datetime

def agi_write(command):
    sys.stdout.write(command + '\n')
    sys.stdout.flush()

def agi_read():
    return sys.stdin.readline().strip()

agi_env = {}
while True:
    line = sys.stdin.readline().strip()
    if line == '':
        break
    key, value = line.split(':', 1)
    agi_env[key.strip()] = value.strip()

ext = agi_env.get('agi_callerid', 'desconocido')
numero_aleatorio = random.randint(1, 9)
intentos = 0
acertado = False
tuvo_chance = False

agi_write('STREAM FILE juego-bienvenida ""')

while intentos < 3:
    agi_write('GET DATA introduzca-numero 3000 1')
    resp = agi_read()
    if 'result=' in resp:
        intento = int(resp.split('=')[1])
        agi_write(f'SAY NUMBER {intento} ""')
        if intento == numero_aleatorio:
            acertado = True
            break
        else:
            intentos += 1

if not acertado:
    if random.choice([0,1]) == 1:
        tuvo_chance = True
        agi_write('STREAM FILE nuevo-chance ""')
        agi_write('GET DATA introduzca-numero 3000 1')
        resp = agi_read()
        intento = int(resp.split('=')[1])
        agi_write(f'SAY NUMBER {intento} ""')
        if intento == numero_aleatorio:
            acertado = True

premio = None
if acertado:
    agi_write('STREAM FILE ganador ""')
    conn = mysql.connector.connect(user='root', database='ivrdb')
    cur = conn.cursor()
    cur.execute("SELECT premio FROM premios ORDER BY RAND() LIMIT 1")
    premio = cur.fetchone()[0]
    agi_write(f'STREAM FILE {premio.lower()} ""')
    cur.execute("INSERT INTO llamadas (extension, fecha_hora, numero_generado, gano, premio_ganado, tuvo_chance) VALUES (%s, NOW(), %s, 1, %s, %s)",
                (ext, numero_aleatorio, premio, tuvo_chance))
    conn.commit()
    conn.close()
else:
    agi_write('STREAM FILE lo-sentimos ""')
    conn = mysql.connector.connect(user='root', database='ivrdb')
    cur = conn.cursor()
    cur.execute("INSERT INTO llamadas (extension, fecha_hora, numero_generado, gano, premio_ganado, tuvo_chance) VALUES (%s, NOW(), %s, 0, NULL, %s)",
                (ext, numero_aleatorio, tuvo_chance))
    conn.commit()
    conn.close()
EOF
chmod +x /var/lib/asterisk/agi-bin/juego.py

# voz.py
if [ -f /var/lib/asterisk/agi-bin/voz.py ]; then
    cp /var/lib/asterisk/agi-bin/voz.py /var/lib/asterisk/agi-bin/voz.py.bak_$(date +%s)
fi
cat <<'EOF' > /var/lib/asterisk/agi-bin/voz.py
#!/usr/bin/env python3
import sys
import mysql.connector
from datetime import datetime

def agi_write(cmd):
    sys.stdout.write(cmd + '\n')
    sys.stdout.flush()

def agi_read():
    return sys.stdin.readline().strip()

agi_env = {}
while True:
    line = sys.stdin.readline().strip()
    if line == '':
        break
    key, value = line.split(':', 1)
    agi_env[key.strip()] = value.strip()

agi_write('STREAM FILE diga-palabra ""')
agi_write('GET DATA introduzca-numero 3000 1')
resp = agi_read()

texto_simulado = {
    '1': 'Hola',
    '2': 'Adiós',
    '3': 'Gracias',
    '4': 'Ayuda',
    '5': 'Soporte',
    '6': 'Reclamo',
    '7': 'Felicidad',
    '8': 'Premio',
    '9': 'Cliente'
}

if 'result=' in resp:
    valor = resp.split('=')[1]
    texto = texto_simulado.get(valor, 'Desconocido')
    conn = mysql.connector.connect(user='root', database='ivrdb')
    cur = conn.cursor()
    cur.execute("INSERT INTO voice (fechahora, texto) VALUES (NOW(), %s)", (texto,))
    conn.commit()
    conn.close()
    agi_write(f'SAY PHRASE "Usted dijo {texto}" ""')
else:
    agi_write('STREAM FILE lo-sentimos ""')
EOF
chmod +x /var/lib/asterisk/agi-bin/voz.py

#############################
# Paso 9: Actualizar configuraciones en extensions.conf
#############################
EXT_CONF="/etc/asterisk/extensions.conf"
cp "$EXT_CONF" "${EXT_CONF}.bak_$(date +%s)"

if ! grep -q "^\[ivr\]" "$EXT_CONF"; then
cat <<'EOF' >> "$EXT_CONF"

[ivr]
exten => s,1,Answer()
 same => n,Set(TIMEOUT(digit)=5)
 same => n,Set(TIMEOUT(response)=10)
 same => n,Playback(bienvenida)         ; archivo bienvenida.gsm
 same => n,Background(menu-principal)   ; archivo menu-principal.gsm
 same => n,WaitExten()

; Opción 1 - Ir al submenú de música
exten => 1,1,Goto(musica,s,1)
; Opción 2 - Buzón de voz en español
exten => 2,1,Set(CHANNEL(language)=es)
 same => n,VoiceMailMain()
; Opción 3 - Juego de adivinar el número
exten => 3,1,Goto(juego,s,1)
; Opción 4 - Reconocimiento de voz
exten => 4,1,Goto(reconocimiento,s,1)
; Opción 5 - Repetir menú
exten => 5,1,Goto(ivr,s,1)
; Opción 6 - Salir
exten => 6,1,Playback(adios)            ; archivo adios.gsm
 same => n,Hangup()

; Acceso directo al IVR (700)
exten => 700,1,Goto(ivr,s,1)
EOF
else
  echo "🔁 Contexto [ivr] ya existe en extensions.conf. Saltando configuración manual."
fi

if ! grep -q "^\[musica\]" "$EXT_CONF"; then
cat <<'EOF' >> "$EXT_CONF"

[musica]
exten => s,1,Playback(musica-opciones)   ; "Para escuchar rock presione 1, bachata 2, merengue 3, volver 4"
 same => n,WaitExten()

exten => 1,1,Playback(rock)
 same => n,Goto(musica,s,1)

exten => 2,1,Playback(bachata)
 same => n,Goto(musica,s,1)

exten => 3,1,Playback(merengue)
 same => n,Goto(musica,s,1)

exten => 4,1,Goto(ivr,s,1)

exten => t,1,Goto(musica,s,1)
exten => i,1,Playback(por-favor-intente-nuevamente)
 same => n,Goto(musica,s,1)
EOF
else
  echo "🔁 Contexto [musica] ya existe en extensions.conf. Saltando."
fi

if ! grep -q "^\[juego\]" "$EXT_CONF"; then
cat <<'EOF' >> "$EXT_CONF"

[juego]
exten => s,1,AGI(juego.py)
 same => n,Goto(ivr,s,1)
EOF
fi

if ! grep -q "^\[reconocimiento\]" "$EXT_CONF"; then
cat <<'EOF' >> "$EXT_CONF"

[reconocimiento]
exten => s,1,AGI(voz.py)
 same => n,Goto(ivr,s,1)
EOF
fi

#############################
# Paso 10: Mensaje final
#############################
echo "✅ El script de salvación NATALIUS ha terminado satisfactoriamente."