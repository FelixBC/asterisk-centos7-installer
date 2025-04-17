#!/usr/bin/env python3

import random
import sys
import time
import mysql.connector
from datetime import datetime

def agi_write(command):
    sys.stdout.write(command + '\n')
    sys.stdout.flush()

def agi_read():
    return sys.stdin.readline().strip()

# Obtener extensión
agi_env = {}
while True:
    line = sys.stdin.readline().strip()
    if line == '':
        break
    key, value = line.split(':')
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
        try:
            intento = int(resp.split('=')[1])
            agi_write(f'SAY NUMBER {intento} ""')
            if intento == numero_aleatorio:
                acertado = True
                break
            else:
                intentos += 1
        except ValueError:
            intento = -1
            intentos += 1

if not acertado:
    if random.choice([0, 1]) == 1:
        tuvo_chance = True
        agi_write('STREAM FILE nuevo-chance ""')
        agi_write('GET DATA introduzca-numero 3000 1')
        resp = agi_read()
        if 'result=' in resp:
            try:
                intento = int(resp.split('=')[1])
                agi_write(f'SAY NUMBER {intento} ""')
                if intento == numero_aleatorio:
                    acertado = True
            except ValueError:
                pass

# Resultado
premio = None
conn = mysql.connector.connect(user='root', database='ivrdb')
cur = conn.cursor()

if acertado:
    agi_write('STREAM FILE ganador ""')
    cur.execute("SELECT premio FROM premios ORDER BY RAND() LIMIT 1")
    row = cur.fetchone()
    if row:
        premio = row[0].lower()
        agi_write(f'STREAM FILE {premio} ""')  # asegúrate que exista ese archivo en .gsm
    cur.execute("""
        INSERT INTO llamadas (extension, fecha_hora, numero_generado, gano, premio_ganado, tuvo_chance)
        VALUES (%s, NOW(), %s, 1, %s, %s)
    """, (ext, numero_aleatorio, premio, tuvo_chance))
else:
    agi_write('STREAM FILE lo-sentimos ""')
    cur.execute("""
        INSERT INTO llamadas (extension, fecha_hora, numero_generado, gano, premio_ganado, tuvo_chance)
        VALUES (%s, NOW(), %s, 0, NULL, %s)
    """, (ext, numero_aleatorio, tuvo_chance))

conn.commit()
conn.close()

