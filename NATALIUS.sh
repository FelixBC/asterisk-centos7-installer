#!/bin/bash

echo "***********************************************"
echo "  HAZ EJECUTADO NATALIUS"
echo "  Script de salvación creado por los ingenieros:"
echo "  NATALY BERROA, FELIX BLANCO, EDWIN ESPINAL"
echo "***********************************************"
sleep 2

echo "☕ ¿Este script te salvó la vida? Invítanos un café:"
echo "👉 https://www.paypal.me/felixBlancoC"
sleep 2

# Paso 1: Configurar repositorios de CentOS
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

yum check-update
yum makecache
sudo yum update -y

# Paso 2: Instalar paquetes necesarios
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel kernel-devel-$(uname) git subversion saukernel-devel php-process crontabs cronie cronie-anacron wget vim epel-release gmime-devel

# Paso 3: Instalar jansson
cd /usr/src
wget http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
tar -zxvf jansson-2.7.tar.gz
cd jansson-2.7/
./configure --prefix=/usr
make clean
make && make install
ldconfig

# Paso 4: Desactivar SELinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Paso 5: Instalar Asterisk 1.8.13.0
cd /usr/src
wget https://repository.timesys.com/buildsources/a/asterisk/asterisk-1.8.13.0/asterisk-1.8.13.0.tar.gz
tar -zxvf asterisk-1.8.13.0.tar.gz
cd asterisk-1.8.13.0
./configure --libdir=/usr/lib64
make
make install
make samples

# Paso 6: Crear base de datos ivrdb y tablas en MariaDB
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
  id INT AUTO_INCREMENT PRIMARY KEY,
  fechahora DATETIME,
  texto VARCHAR(100)
);
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

# Paso 7: Descargar sonidos en español
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz
mkdir -p /var/lib/asterisk/sounds/es
# Se copian los archivos .gsm (si no se encuentran en la raíz, se ignora el error)
cp asterisk-core-sounds-es-gsm*/.gsm /var/lib/asterisk/sounds/es/ 2>/dev/null || true

# Paso 8: Integrar scripts AGI para el juego y reconocimiento de voz

# Crear juego.py en /var/lib/asterisk/agi-bin
mkdir -p /var/lib/asterisk/agi-bin
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

# Crear voz.py en /var/lib/asterisk/agi-bin
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

# Dar permisos a los scripts AGI
chmod +x /var/lib/asterisk/agi-bin/juego.py
chmod +x /var/lib/asterisk/agi-bin/voz.py

# Paso 9: Modificar extensions.conf para integrar nuevos contextos
cat <<'EOF' >> /etc/asterisk/extensions.conf

[juego]
exten => s,1,AGI(juego.py)
 same => n,Goto(ivr,s,1)

[reconocimiento]
exten => s,1,AGI(voz.py)
 same => n,Goto(ivr,s,1)

; Acceso directo al IVR marcando 700 desde el softphone
exten => 700,1,Goto(ivr,s,1)
EOF

# Paso 10: Mensaje final
echo "✅ El script de salvación NATALIUS ha terminado satisfactoriamente."
