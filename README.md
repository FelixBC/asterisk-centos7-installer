# 🛰️ PARA PROYECTO FINAL PARTICULARMENTE:

# Tabla de Contenidos

- [🛰️ PARA PROYECTO FINAL PARTICULARMENTE](#para-proyecto-final-particularmente)
- [▶️ Cómo usarlo](#cómo-usarlo)
- [Nota: El proceso tomará varios minutos…](#nota-el-proceso-tomará-varios-minutos-mientras-se-instalan-paquetes-y-se-compila-asterisk)
  - [Verificar Asterisk](#verificar-asterisk)
  - [Entrada al CLI de Asterisk](#esto-debería-llevarte-a-la-consola-interactiva-de-asterisk-prompt-cli)
- [SI TIENES ALGÚN PROBLEMA](#si-tienes-algún-problema)
- [SI TODO TERMINÓ, CONFIGURA EL SOFTPHONE](#si-todo-terminó-configura-el-softphone--y-marca-📞-700)
- [📋 ¿Qué hace el script?](#qué-hace-el-script)
- [✅ Funcionalidades del script](#funcionalidades-del-script)
  - [⚙️ Instalación de dependencias](#instalación-de-dependencias)
  - [🔐 SELinux, repositorios y desactivar firewall](#selinux-repositorios-y-desactivar-firewall)
  - [📦 Instalación de Asterisk 1.8.13.0](#instalación-de-asterisk-18130)
    - [🧩 Librerías adicionales](#librerías-adicionales)
    - [🛠️ Base de datos MariaDB](#base-de-datos-mariadb)
    - [🔊 Sonidos en español para Asterisk](#sonidos-en-español-para-asterisk)
    - [🤖 Integración de scripts AGI](#integración-de-scripts-agi)
    - [📞 Actualización del dialplan (`extensions.conf`)](#actualización-del-dialplan-extensionsconf)
- [Próximas actualizaciones](#próximas-actualizaciones)
- [☕ ¿Te fue útil?](#te-fue-útil)
- [👥 Autores (El equipo Nautilius)](#autores-el-equipo-nautilius)




Este proyecto es ideal para estudiantes cursando Lab. Telecomunicaciones (GIOBERTY TINEO), tarea proyecto final. Si no quieres pasar por una instalación manual compleja o buscas un entorno de laboratorio de VoIP listo para usar (con ejemplos de IVR, juego de adivinanza y reconocimiento de voz básicos), NATALIUS.sh hara todo esto por ti.

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
# Nota: El proceso tomará varios minutos mientras se instalan paquetes y se compila Asterisk. ¡Ve por un café mientras tanto! ☕

#### Verificar Asterisk: abre de nuevo la terminal y comprueba que Asterisk esté funcionando:
```bash  
asterisk start
asterisk -rvvvvvvvvv
```
#### Esto debería llevarte a la consola interactiva de Asterisk (prompt *CLI>).

# Una vez dentro de la consola de Asterisk, significa que la instalación fue exitosa y Asterisk está en ejecución.
## SI TIENES ALGUN PROBLEMA:   
#### Es probable que asterisk no este recargando los modulos correctamente o la ODBC no este cargando bien, esto puede solucionarse recargando los paquetes o reiniciando la PC.  
  Corre estos comandos y reinicia, luego prueba:
```bash
yum install -y mysql-connector-odbc unixODBC unixODBC-devel
isql -v asterisk root ""
asterisk -rx "module reload res_odbc.so"
asterisk -rx "module reload func_odbc.so"
asterisk -rx "core reload"
asterisk -rx "dialplan reload"
```
## SI TODO TERMINO CONFIGURA EL SOFPHONE.  Y marca  📞 700.
![image](https://github.com/user-attachments/assets/d555373c-cf20-45ec-be38-2083a9aa0f92)


# 📋 ¿Qué hace el script?

`NATALIUS.sh` es un instalador y configurador completo de Asterisk 1.8.13.0 sobre CentOS 7, diseñado para que, con un solo comando, tengas un sistema PBX operativo y listo para probar. Al ejecutarlo, primero desactiva SELinux/Firewalls y actualiza los repositorios para usar los mirrors de vault.centos.org; a continuación instala todas las dependencias necesarias, desde compiladores y librerías de desarrollo hasta MariaDB y los módulos JSON (jansson) y ODBC para MySQL.

Luego descarga, compila e instala Asterisk junto con sus módulos básicos y AGIs personalizados (los scripts de juego y voz), configura la base de datos ivrdb con las tablas de premios y llamadas, y despliega el dialplan en extensions.conf. A continuación limpia y vuelve a generar todos los archivos de audio en formato GSM para el IVR, ajusta permisos, recarga los módulos en caliente y arranca Asterisk. Al finalizar, muestra un mensaje de éxito y un enlace para “invitar un café” a los creadores.

---

## ✅ Funcionalidades del script:

## ⚙️ Instalación de dependencias
- Instala compiladores, librerías de desarrollo, MariaDB y más usando `yum`.

## 🔐 SELinux, repositorios y desactivar firewall
- Desactiva SELinux (haciendo backup del archivo `config`).  
- Desactiva firewall (puede causar problemas).
- Actualiza los repositorios para usar los mirrors de `vault.centos.org`.

## 📦 Instalación de Asterisk 1.8.13.0
- Descarga, compila e instala Asterisk **solo si no está instalado**.

### 🧩 Librerías adicionales
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

