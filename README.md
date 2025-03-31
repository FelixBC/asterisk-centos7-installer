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

#☕ ¿Te fue útil?
Bríndame un café vía PayPal si este proyecto te ayudó:
👉 https://www.paypal.me/felixBlancoC

#🧑‍🔧 Autores (El equipo Nautilius)
Félix José Blanco Cabrera
Nathaly Berroa : https://github.com/nmbf02
Edwin Espinal : https://github.com/Edwinesp19

