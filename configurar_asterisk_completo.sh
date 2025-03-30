#!/bin/bash

echo "🔧 Iniciando configuración de Asterisk (extensiones, IVR, buzón)..."

# Crear backups
cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.bak
cp /etc/asterisk/voicemail.conf /etc/asterisk/voicemail.conf.bak
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.bak

# Agregar a sip.conf
cat <<'EOF' >> /etc/asterisk/sip.conf

[general]
context=ivr
allowoverlap=no
bindport=5060
bindaddr=0.0.0.0
disallow=all
allow=ulaw
allow=alaw
allow=gsm
canreinvite=no

[201]
type=friend
secret=0000
host=dynamic
context=ivr
mailbox=201@default

[301]
type=friend
secret=5555
host=dynamic
context=ivr
mailbox=301@default
EOF

# Agregar a voicemail.conf
cat <<'EOF' >> /etc/asterisk/voicemail.conf

[general]
format=wav49|gsm|wav
serveremail=asterisk
attach=yes
skipms=3000
maxmessage=180
minmessage=3
maxsilence=10
emailsubject=Correo de Voz Nuevo ${VM_NAME}
emailbody=Tiene un nuevo correo de voz de ${VM_CALLERID} a la extensión ${VM_DURACION}
locale=es

[default]
201 => 0000,Pepe Goico,pepe@correo.local
301 => 5555,Mami Jordan,mami@correo.local
EOF

# Agregar a extensions.conf
cat <<'EOF' >> /etc/asterisk/extensions.conf

[ivr]
exten => s,1,Answer()
 same => n,Set(CHANNEL(language)=es)
 same => n,Set(TIMEOUT(digit)=5)
 same => n,Set(TIMEOUT(response)=10)
 same => n,Playback(bienvenida)
 same => n,Background(menu-principal)
 same => n,WaitExten()

exten => 1,1,Goto(musica,s,1)
exten => 2,1,Set(CHANNEL(language)=es)
 same => n,VoiceMailMain()
exten => 3,1,Goto(juego,s,1)
exten => 4,1,Goto(reconocimiento,s,1)
exten => 5,1,Goto(ivr,s,1)
exten => 6,1,Hangup()

[musica]
exten => s,1,Playback(musica-opciones)
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

# Crear carpeta y descargar sonidos en español si no existen
mkdir -p /var/lib/asterisk/sounds/es
cd /usr/src
if [ ! -f asterisk-core-sounds-es-gsm-current.tar.gz ]; then
  wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-es-gsm-current.tar.gz
fi

tar -xvzf asterisk-core-sounds-es-gsm-current.tar.gz
cd asterisk-core-sounds-es-gsm*
cp *.gsm /var/lib/asterisk/sounds/es/

# Establecer idioma por defecto
if ! grep -q "defaultlanguage" /etc/asterisk/asterisk.conf; then
  echo -e "\n[options]\nlanguageprefix = yes\ndefaultlanguage = es" >> /etc/asterisk/asterisk.conf
fi

echo "✅ Configuración aplicada con éxito. Reinicia Asterisk o la máquina para aplicar los cambios."
