#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import speech_recognition as sr
import mysql.connector
from datetime import datetime
import subprocess
import os

if len(sys.argv) < 2:
    print("Uso: voz.py archivo_audio.wav")
    sys.exit(1)

audio_path = sys.argv[1]
audio_convertido = "/tmp/audio_convertido.wav"

# Convertir a formato compatible con speech_recognition (16kHz, 1 canal)
try:
    subprocess.run([
        "ffmpeg", "-y", "-i", audio_path, "-ar", "16000", "-ac", "1", audio_convertido
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except Exception as e:
    print("Error al convertir el audio:", str(e))
    sys.exit(1)

# Inicializar el reconocedor
r = sr.Recognizer()

try:
    with sr.AudioFile(audio_convertido) as source:
        audio = r.record(source)

    texto = r.recognize_google(audio, language="es-ES")
    print("Texto reconocido:", texto)
except sr.UnknownValueError:
    texto = "No reconocido"
except sr.RequestError:
    texto = "Error de conexion"
except Exception as e:
    texto = "Error inesperado: " + str(e)

# Insertar en base de datos
try:
    fecha = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    conn = mysql.connector.connect(user='root', database='ivrdb')
    cur = conn.cursor()
    cur.execute("INSERT INTO voice (fechahora, texto) VALUES (%s, %s)", (fecha, texto))
    conn.commit()
    conn.close()
except Exception as e:
    print("Error insertando en BD:", str(e))

# Eliminar archivo temporal convertido
if os.path.exists(audio_convertido):
    os.remove(audio_convertido)
