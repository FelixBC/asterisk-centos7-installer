<a name="for-final-project"></a>
# 🛰️ PARA PROYECTO FINAL PARTICULARMENTE:

# Tabla de Contenidos
- [Para proyecto final particularmente](#for-final-project)
- [Cómo usarlo](#how-to-use)
  - [Verificar Asterisk](#verify-asterisk)
  - [Esto debería llevarte a la consola interactiva de Asterisk prompt CLI](#asterisk-cli-prompt)
- [Si tienes un problema](#if-you-have-a-problem)
- [Si todo terminó configura el softphone y marca 700](#if-setup-complete-configure-softphone-and-dial-700)
- [Para autenticidad](#for-authenticity)
- [Convertidor de youtube a MP3](#youtube-mp3)
- [Convertidor MP3 GSM](#mp3-gsm)
- [Texto a voces, para el menu gsm](#new-voice-elevenlabs)
- [Qué hace el script](#what-does-the-script-do)
- [Funcionalidades del script](#script-functionality)
  - [Instalación de dependencias](#dependency-installation)
  - [SELinux, repositorios y desactivar firewall](#selinux-repos-and-firewall-disable)
  - [Instalación de Asterisk 1.8.13.0](#asterisk-18130-installation)
  - [Librerías adicionales](#additional-libraries)
  - [Base de datos MariaDB](#mariadb-database-setup)
  - [Sonidos en español para Asterisk](#spanish-sounds-for-asterisk)
  - [Integración de scripts AGI](#agi-script-integration)
  - [Actualización del dialplan (extensions.conf)](#dialplan-update-extensionsconf)
- [Próximas actualizaciones](#upcoming-updates)
- [¿Te fue útil?](#was-it-useful)
- [Autores - equipo Nautilius](#authors-nautilius-team)





Este proyecto es ideal para estudiantes cursando Lab. Telecomunicaciones (GIOBERTY TINEO), tarea proyecto final. Si no quieres pasar por una instalación manual compleja o buscas un entorno de laboratorio de VoIP listo para usar (con ejemplos de IVR, juego de adivinanza y reconocimiento de voz básicos), NATALIUS.sh hara todo esto por ti.
<a name="how-to-use"></a>


# ▶️ Cómo usarlo


Sigue estos pasos para utilizar el script de instalación en tu sistema CentOS 7:
Abrir una terminal: Inicia sesión en tu servidor CentOS 7 y abre una ventana de terminal (línea de comandos).
Entra en modo root: 

```bash
su -
```
escribe tu password, y luego veras algo como: "root[LocalHost]:"

Descargar el script, darle permisos, y correrlo en un solo comando.

Usa wget para obtener el archivo NATALIUS.sh desde este repositorio de GitHub. Por ejemplo:
```bash
wget https://raw.githubusercontent.com/FelixBC/asterisk-centos7-installer/main/NATALIUS.sh -O NATALIUS.sh
chmod +x NATALIUS.sh
sudo ./NATALIUS.sh
```
<a name="verify-asterisk"></a>
# Nota: El proceso tomará varios minutos mientras se instalan paquetes y se compila Asterisk. ¡Ve por un café mientras tanto! ☕

#### Verificar Asterisk: abre de nuevo la terminal y comprueba que Asterisk esté funcionando:

```bash  
asterisk start
asterisk -rvvvvvvvvv
```
<a name="asterisk-cli-prompt"></a>


#### Esto debería llevarte a la consola interactiva de Asterisk (prompt *CLI>).
# Una vez dentro de la consola de Asterisk, significa que la instalación fue exitosa y Asterisk está en ejecución.
<a name="if-you-have-a-problem"></a>


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
<a name="if-setup-complete-configure-softphone-and-dial-700"></a>


## SI TODO TERMINO CONFIGURA EL SOFPHONE.  Y marca  📞 700.
![image](https://github.com/user-attachments/assets/d555373c-cf20-45ec-be38-2083a9aa0f92)

<a name="for-authenticity"></a>

## Para autenticidad, cambia los sonidos .gsm del menu, y canciones. OJOO!!:: DEBEN TENER EL MISMO NOMBRE QUE TENIAN, si te da algun error vuelve a chequear los nombres!
  adios.gsm bonificacion.gsm ganaste.gsm lavadora.gsm perdiste.gsm
  airfryer.gsm celular.gsm gracias-2.gsm lo-sentimos.gsm reloj-inteligente.gsm
  audifonos.gsm diga-palabra.gsm gracias.gsm menu-principal.gsm smart-tv.gsm
  bienvenida.gsm elegir-musica.gsm introduzca-numero.gsm no-disp.gsm tablet.gsm
  bienvenida-juego.gsm elige-numero.gsm juego-bienvenida.gsm chance-extra.gsm timeout-es.gsm
  bocina-bluetooth.gsm ganador.gsm laptop.gsm numero-marcado.gsm tuvoz.gsm
  
``` bash
cd /var/lib/asterisk/sounds
```

<a name="youtube-mp3"></a>

bachata.gsm merengue.gsm rock.gsm 
#Convertidor de Youtube a MP3, con corte permitido. (Preferiblemente 10 segundos para las canciones) 
```
https://soundly.cc/es
```
![image](https://github.com/user-attachments/assets/af0c31e6-8c5d-4b52-b451-343dfb842f4a)

<a name="mp3-gsm"></a>


# MP3 a .gsm

```
https://convertio.co/es/mp3-gsm/
```
<a name="new-voice-elevenlabs"></a>

#Para las nuevas voces .gsm utiliza esta herramienta, escribe texto y te da la voz para descargar es gratuita solo quizas debas loggearte:

https://elevenlabs.io/app/speech-synthesis/text-to-speech

<a name="what-does-the-script-do"></a>

# 📋 ¿Qué hace el script?

`NATALIUS.sh` es un instalador y configurador completo de Asterisk 1.8.13.0 sobre CentOS 7, diseñado para que, con un solo comando, tengas un sistema PBX operativo y listo para probar. Al ejecutarlo, primero desactiva SELinux/Firewalls y actualiza los repositorios para usar los mirrors de vault.centos.org; a continuación instala todas las dependencias necesarias, desde compiladores y librerías de desarrollo hasta MariaDB y los módulos JSON (jansson) y ODBC para MySQL.

Luego descarga, compila e instala Asterisk junto con sus módulos básicos y AGIs personalizados (los scripts de juego y voz), configura la base de datos ivrdb con las tablas de premios y llamadas, y despliega el dialplan en extensions.conf. A continuación limpia y vuelve a generar todos los archivos de audio en formato GSM para el IVR, ajusta permisos, recarga los módulos en caliente y arranca Asterisk. Al finalizar, muestra un mensaje de éxito y un enlace para “invitar un café” a los creadores.

---
<a name="script-functionality"></a>


## ✅ Funcionalidades del script:
<a name="dependency-installation"></a>


## ⚙️ Instalación de dependencias
- Instala compiladores, librerías de desarrollo, MariaDB y más usando `yum`.
<a name="selinux-repos-and-firewall-disable"></a>


## 🔐 SELinux, repositorios y desactivar firewall
- Desactiva SELinux (haciendo backup del archivo `config`).  
- Desactiva firewall (puede causar problemas).
- Actualiza los repositorios para usar los mirrors de `vault.centos.org`.
- <a name="asterisk-18130-installation"></a>


## 📦 Instalación de Asterisk 1.8.13.0
- Descarga, compila e instala Asterisk **solo si no está instalado**.
<a name="additional-libraries"></a>


### 🧩 Librerías adicionales
- Verifica e instala **jansson** (para soporte JSON).
- Verifica e instala **mysql-connector-python** si no existe (usado por los scripts AGI).
<a name="mariadb-database-setup"></a>


#### 🛠️ Base de datos MariaDB
- Crea la base de datos `ivrdb` con las tablas:
  - `premios` 🏆  
  - `llamadas` 📞  
  - `voice` 🗣️
- Inserta automáticamente **10 premios** si la tabla `premios` está vacía.
<a name="spanish-sounds-for-asterisk"></a>


#### 🔊 Sonidos en español para Asterisk
- Descarga e instala los sonidos en formato `.gsm` (incluye locuciones del sistema en español).
<a name="agi-script-integration"></a>


#### 🤖 Integración de scripts AGI
- Copia `juego.py` (juego de adivinar un número).
- Copia `voz.py` (simulación de reconocimiento de voz).
- Ambos se colocan en `/var/lib/asterisk/agi-bin/` con permisos de ejecución.
- <a name="dialplan-update-extensionsconf"></a>


#### 📞 Actualización del dialplan (`extensions.conf`)
- Agrega los contextos `[juego]` y `[reconocimiento]`.
- Añade la extensión `700` para acceso directo al IVR.
- Verifica duplicados antes de escribir y hace un **backup del archivo original**.
- <a name="upcoming-updates"></a>


# Proximas actualizaciones:
```
- Usar las voces de eleven labs api para autogenerar voces random.
- El script debe poner la voz de nathaly berroa al final despidiendose.
- Debe tener una opcion que lo autoelimine sin dejar rastro de el mismo.
- Debe tener documentacion mantenible, y puntual para que cualquiera pueda cambiar ciertos aspectos en caso que cambie la asignacion o sus necesidades especificas.
- Deberia hacer un hall of fame agradeciendo a los colaboardores en github. Con su nombre de github en la ejecucion del script.

```
<a name="was-it-useful"></a>



# ☕ ¿Te fue útil?
¡Esperamos que este instalador te haya sido de gran ayuda! Si NATALIUS.sh te ahorró tiempo o te sacó de apuros, invítanos un café ☕ haciendo una donación en PayPal. Cualquier aporte es bienvenido y nos motiva a seguir creando herramientas open source. ¡Gracias por tu apoyo! 👉 https://www.paypal.me/felixBlancoC
<a name="authors-nautilius-team"></a>



### 👥 Autores (El equipo Nautilius)
```
Félix José Blanco Cabrera
Nathaly Berroa : https://github.com/nmbf02
Edwin Espinal : https://github.com/Edwinesp19
```

