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

Este proyecto es ideal para estudiantes cursando Lab. Telecomunicaciones (GIOBERTY TINEO), tarea proyecto final, desarrolladores y administradores de sistemas que necesiten implantar Asterisk 1.8 rápidamente en CentOS 7. Si no quieres pasar por una instalación manual compleja o buscas un entorno de laboratorio de VoIP listo para usar (con ejemplos de IVR, juego de adivinanza y reconocimiento de voz básicos), NATALIUS.sh es para ti.

# ▶️ Cómo usarlo

Sigue estos pasos para utilizar el script de instalación en tu sistema CentOS 7:
Abrir una terminal: Inicia sesión en tu servidor CentOS 7 y abre una ventana de terminal (línea de comandos).

Descargar el script, darle permisos, y correrlo en un solo comando.

Usa wget para obtener el archivo NATALIUS.sh desde este repositorio de GitHub. Por ejemplo:
```bash
wget https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/NATALIUS.sh -O NATALIUS.sh
chmod +x NATALIUS.sh
sudo ./NATALIUS.sh
```
#OPTIONAL (PUEDES PROBAR ANTES)
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

## SI TIENES ALGUN PROBLEMA CORRE:
```bash
#!/bin/bash
# reload_asterisk.sh
# Instala drivers ODBC y recarga Asterisk por completo

set -euo pipefail

echo "=== 1. Instalando paquetes ODBC necesarios ==="
yum install -y mysql-connector-odbc unixODBC unixODBC-devel

echo
echo "=== 2. Probando DSN 'asterisk' con isql ==="
if echo "quit" | isql -v asterisk root "" >/dev/null 2>&1; then
  echo "✔ DSN 'asterisk' OK"
else
  echo "❗ Falló la prueba ODBC (revisa /etc/odbc.ini y permisos)"
fi

echo
echo "=== 3. Recargando módulos ODBC en Asterisk ==="
asterisk -rx "module reload res_odbc.so" || echo "⚠ No se pudo recargar res_odbc.so"
asterisk -rx "module reload func_odbc.so" || echo "⚠ No se pudo recargar func_odbc.so"

echo
echo "=== 4. Recargando core y dialplan de Asterisk ==="
asterisk -rx "core reload" || echo "⚠ No se pudo recargar core"
asterisk -rx "dialplan reload" || echo "⚠ No se pudo recargar dialplan"

echo
echo "✅ ¡Listo! Asterisk debería tener todo actualizado."

```
## SI TODO TERMINO CONFIGURA EL SOFPHONE.  Y marca  📞 700.
![image](https://github.com/user-attachments/assets/d555373c-cf20-45ec-be38-2083a9aa0f92)

# Una vez dentro de la consola de Asterisk, significa que la instalación fue exitosa y Asterisk está en ejecución.
## 📋 ¿Qué hace el script?

`NATALIUS.sh` automatiza todo el proceso de instalación y configuración de **Asterisk 1.8.13.0** en **CentOS 7** de forma **idempotente** (es decir, puedes ejecutarlo varias veces sin dañar configuraciones previas ni repetir pasos innecesarios).

---

### ✅ Funcionalidades del script:

#### ⚙️ Instalación de dependencias
- Instala compiladores, librerías de desarrollo, MariaDB y más usando `yum`.

#### 🔐 SELinux y repositorios
- Desactiva SELinux (haciendo backup del archivo `config`).
- Actualiza los repositorios para usar los mirrors de `vault.centos.org`.

#### 📦 Instalación de Asterisk 1.8.13.0
- Descarga, compila e instala Asterisk **solo si no está instalado**.

#### 🧩 Librerías adicionales
- Verifica e instala **jansson** (para soporte JSON).
- Verifica e instala **mysql-connector-python** si no existe (usado por los scripts AGI).

#### 🛠️ Base de datos MariaDB
- Crea la base de datos `ivrdb` con las tablas:
  - `premios` 🏆  
  - `llamadas` 📞  
  - `voice` 🗣️
- Inserta automáticamente **10 premios** si la tabla `premios` está vacía.

#### 🔊 Sonidos en español para Asterisk
- Descarga e instala los sonidos en formato `.gsm` (incluye locuciones del sistema en español).

#### 🤖 Integración de scripts AGI
- Copia `juego.py` (juego de adivinar un número).
- Copia `voz.py` (simulación de reconocimiento de voz).
- Ambos se colocan en `/var/lib/asterisk/agi-bin/` con permisos de ejecución.

#### 📞 Actualización del dialplan (`extensions.conf`)
- Agrega los contextos `[juego]` y `[reconocimiento]`.
- Añade la extensión `700` para acceso directo al IVR.
- Verifica duplicados antes de escribir y hace un **backup del archivo original**.



# Proximas actualizaciones:
```
- Usar las voces de eleven labs api para autogenerar voces random.
- El script debe poner la voz de nathaly berroa al final despidiendose.
- Debe tener una opcion que lo autoelimine sin dejar rastro de el mismo.
- Debe tener documentacion mantenible, y puntual para que cualquiera pueda cambiar ciertos aspectos en caso que cambie la asignacion o sus necesidades especificas.
- Deberia hacer un hall of fame agradeciendo a los colaboardores en github. Con su nombre de github en la ejecucion del script.

```

# ☕ ¿Te fue útil?
¡Esperamos que este instalador te haya sido de gran ayuda! Si NATALIUS.sh te ahorró tiempo o te sacó de apuros, invítanos un café ☕ haciendo una donación en PayPal. Cualquier aporte es bienvenido y nos motiva a seguir creando herramientas open source. ¡Gracias por tu apoyo! 👉 https://www.paypal.me/felixBlancoC



### 👥 Autores (El equipo Nautilius)
```
Félix José Blanco Cabrera
Nathaly Berroa : https://github.com/nmbf02
Edwin Espinal : https://github.com/Edwinesp19
```

