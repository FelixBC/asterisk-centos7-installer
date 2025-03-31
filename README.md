# 🛰️ Instalador de Asterisk 1.8.13.0 para CentOS 7
## AUTOMATIZADO

Este script instala Asterisk 1.8.13.0 en **CentOS 7** de forma automatizada, incluyendo todas las dependencias, librerías, configuración de repositorios y desactivación de SELinux.

---

## 🧑‍💻 ¿Para quién es esto?

Para estudiantes, técnicos o entusiastas que necesiten instalar Asterisk en una máquina virtual o entorno de pruebas usando CentOS 7. Ideal para ciclos de redes, telecomunicaciones o laboratorios.

---

## ⚙️ Cómo usarlo

### 1. Abre la terminal en CentOS 7

Haz clic derecho en el escritorio → “Open Terminal”.

### 2. Descarga el script con `wget`

```bash
wget https://raw.githubusercontent.com/felixBlanco/asterisk-centos7-installer/main/install_asterisk.sh -O install_asterisk.sh
```
3. Dale permisos de ejecución
4. 
```bash
chmod +x install_asterisk.sh
```
4. Ejecuta el script
```bash
./install_asterisk.sh
```
5. Cuando finalice, reinicia tu máquina
```bash
sudo shutdown -r now
```
6. Después del reinicio, accede a Asterisk
```bash

cd /etc/asterisk
asterisk -r
```

Si da error de socket, usa:

```bash

asterisk start && asterisk -r
```

## SI SOLO DESEAS INSTALLAR ASTERISK SOLO HASTA AHI:


## PARA PROYECTO FINAL PARTICULAMENTE:

## 🚀 NATALIUS.sh - Instalador Automático de Asterisk 1.8.13.0 en CentOS 7
NATALIUS.sh es un script de Bash para instalar y configurar Asterisk 1.8.13.0 en CentOS 7 de forma automática. Su propósito es ahorrarte tiempo y esfuerzo, desplegando un servidor Asterisk funcional con todas sus dependencias y configuraciones (¡incluyendo audio en español, base de datos y más!) en unos pocos minutos.

# Tabla de Contenidos
🎯 ¿Para quién es esto?
▶️ Cómo usarlo
📋 ¿Qué hace el script?
👥 Autores
☕ ¿Te fue útil?
🎯 ¿Para quién es esto?

Este proyecto es ideal para estudiantes, desarrolladores y administradores de sistemas que necesiten implantar Asterisk 1.8 rápidamente en CentOS 7. Si no quieres pasar por una instalación manual compleja o buscas un entorno de laboratorio de VoIP listo para usar (con ejemplos de IVR, juego de adivinanza y reconocimiento de voz básicos), NATALIUS.sh es para ti.

# ▶️ Cómo usarlo

Sigue estos pasos para utilizar el script de instalación en tu sistema CentOS 7:
Abrir una terminal: Inicia sesión en tu servidor CentOS 7 y abre una ventana de terminal (línea de comandos).
Descargar el script: Usa wget para obtener el archivo NATALIUS.sh desde este repositorio de GitHub. Por ejemplo:
```bash
wget https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/NATALIUS.sh -O NATALIUS.sh
```
Dar permisos de ejecución: Asigna permisos ejecutables al script descargado:
```bash
chmod +x NATALIUS.sh
```
Ejecutar el script como superusuario: Ejecuta el instalador con privilegios de root (puedes anteponer sudo si estás con un usuario regular):
```bash
sudo ./NATALIUS.sh
```

Nota: El proceso tomará varios minutos mientras se instalan paquetes y se compila Asterisk. ¡Ve por un café mientras tanto! ☕
Reiniciar si es necesario: Al finalizar, el script te indicará si debes reiniciar el sistema (esto es necesario especialmente cuando se deshabilita SELinux). Si es así, reinicia con:
```bash
sudo shutdown -r now
```
Verificar Asterisk: Después del reinicio, abre de nuevo la terminal y comprueba que Asterisk esté funcionando:
```bash
cd /etc/asterisk
asterisk -r
```
Esto debería llevarte a la consola interactiva de Asterisk (prompt *CLI>). Si ves un error del tipo "does /var/run/asterisk/asterisk.ctl exist?", inicia el servicio manualmente con:
```bash
asterisk start
asterisk -r
```
# Una vez dentro de la consola de Asterisk, significa que la instalación fue exitosa y Asterisk está en ejecución.
📋 ¿Qué hace el script?

NATALIUS.sh realiza automáticamente las siguientes acciones (de manera idempotente, es decir, sin repetir pasos que ya se hayan ejecutado):
Instalación de dependencias: Instala todos los paquetes y herramientas necesarios (compiladores, librerías, MariaDB, etc.) usando yum, asegurando que estén presentes antes de compilar Asterisk.
Configuración de SELinux y repositorios: Deshabilita SELinux (previa copia de respaldo del archivo de configuración) para evitar conflictos con Asterisk, y actualiza los repositorios YUM de CentOS 7 para usar los mirrors de Vault (necesario porque CentOS 7 usa ahora vault.centos.org).

Instalación de Asterisk 1.8.13.0: Descarga el código fuente de Asterisk 1.8.13.0, lo compila e instala solo si no está ya instalado en el sistema.
Librerías adicionales: Verifica la presencia de la librería Jansson (necesaria para funcionalidades JSON en Asterisk) y del conector de base de datos MySQL (paquete mysql-connector-python); si no se encuentran, los instala automáticamente.
Base de datos MySQL (MariaDB): Inicia el servicio de MariaDB y configura la base de datos ivrdb con las tablas requeridas (premios, llamadas y voice) solo si no existen. Además, inserta datos de ejemplo en la tabla premios (10 premios distintos) la primera vez, para soportar el juego de adivinanza.

Sonidos en español: Descarga el paquete oficial de sonidos en español para Asterisk (formato GSM) y los instala en el directorio de sonidos de Asterisk, de modo que las locuciones del sistema (correo de voz, menús) estén en español.
Scripts AGI integrados: Copia/crea los scripts AGI juego.py (juego de adivinar números) y voz.py (simulación de reconocimiento de voz) en el directorio de Asterisk (/var/lib/asterisk/agi-bin/), asignándoles permisos de ejecución. Estos scripts permiten la funcionalidad extra del IVR interactivo.

Actualización del dialplan: Agrega de forma segura los contextos y extensiones necesarios al archivo extensions.conf de Asterisk. En concreto, añade los contextos [juego] y [reconocimiento] (cada uno invocando su respectivo script AGI) y crea una extensión de marcación directa (700) para acceder al IVR principal. Todo esto se hace comprobando antes que no existan dichas entradas y realizando un backup del archivo original, garantizando no sobrescribir configuraciones existentes.


# ☕ ¿Te fue útil?
¡Esperamos que este instalador te haya sido de gran ayuda! Si NATALIUS.sh te ahorró tiempo o te sacó de apuros, invítanos un café ☕ haciendo una donación en PayPal. Cualquier aporte es bienvenido y nos motiva a seguir creando herramientas open source. ¡Gracias por tu apoyo! 👉 https://www.paypal.me/felixBlancoC



### 👥 Autores (El equipo Nautilius)
```
Félix José Blanco Cabrera
Nathaly Berroa : https://github.com/nmbf02
Edwin Espinal : https://github.com/Edwinesp19
```

