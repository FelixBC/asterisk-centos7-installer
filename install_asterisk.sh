#!/bin/bash

# Paso 1: Configurar repositorios antiguos de CentOS
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Paso 2: Actualizar paquetes
yum check-update
yum makecache
yum update -y

# Paso 3: Instalar herramientas de desarrollo y dependencias
yum install -y gcc gcc-c++ php-xml php php-mysql php-pear php-mbstring mariadb-devel mariadb-server mariadb sqlite-devel lynx bison gmime-devel psmisc tftp-server httpd make ncurses-devel libtermcap-devel sendmail sendmail-cf caching-nameserver sox newt-devel libxml2-devel libtiff-devel audiofile-devel gtk2-devel uuid-devel libtool libuuid-devel subversion kernel-devel kernel-devel-$(uname -r) git php-process crontabs cronie cronie-anacron wget vim

# Paso 4: Instalar EPEL y gmime-devel adicional
yum install -y epel-release
yum install -y gmime-devel

# Paso 5: Descargar e instalar jansson 2.7
cd /usr/src
wget http://www.digip.org/jansson/releases/jansson-2.7.tar.gz
tar -zxvf jansson-2.7.tar.gz
cd jansson-2.7/
./configure --prefix=/usr
make clean
make && make install
ldconfig

# Paso 6: Desactivar SELinux
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Recordatorio: no reiniciar aquí, que el usuario lo haga manualmente
echo "👉 SELinux deshabilitado. Recuerda reiniciar con: sudo shutdown -r now"

# Paso 7: Descargar e instalar Asterisk 1.8.13.0
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-1.8.13.0.tar.gz
tar -zxvf asterisk-1.8.13.0.tar.gz
cd asterisk-1.8.13.0
./configure --libdir=/usr/lib64
make
make install
make samples

# Paso 8: Instrucciones para iniciar Asterisk después del reinicio
echo "✅ Instalación completa. Luego de reiniciar, ejecuta:"
echo "cd /etc/asterisk"
echo "asterisk -r"
echo "👉 Si da error de socket, ejecuta: asterisk start && asterisk -r"

# Mensaje de donación
echo ""
echo "💡 Si este script te ayudó y deseas apoyar el proyecto, puedes donar vía PayPal:"
echo "👉 https://www.paypal.me/felixBlancoC"
echo "¡Gracias por tu apoyo! 🙏"
