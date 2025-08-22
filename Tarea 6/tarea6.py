import datetime
import psycopg2
from psycopg2 import sql

# Configuración de la conexión a PostgreSQL
conn = psycopg2.connect(
    dbname="postgres",
    user="postgres",
    password="mariannenicte8934",
    host="localhost",
    port="5432"
)

def main():
    while True:
        print("\n--- Menú Principal ---")
        print("1. Calcular y guardar factura")
        print("2. Ver facturas anteriores (solo desde archivo de texto)")
        print("3. Borrar facturas (base de datos y archivo)")
        print("4. Salir")
        
        opcion = input("Seleccione una opción: ")
        
        if opcion == '1':
            calcular_y_guardar_factura()
        elif opcion == '2':
            ver_facturas_anteriores()
        elif opcion == '3':
            borrar_archivo_facturas()
        elif opcion == '4':
            print("Saliendo del programa...")
            break
        else:
            print("Opción no válida. Intente de nuevo.")

def calcular_y_guardar_factura():
    # Solicitar nombre con validación
    while True:
        nombre = input("Nombre del cliente: ")
        if not any(char.isdigit() for char in nombre):
            break
        else:
            print("El nombre no puede contener números. Intente de nuevo.")

    # Solicitar NIT con validación
    while True:
        nit = input("NIT (solo números): ")
        if nit.isdigit():
            break
        else:
            print("El NIT solo puede contener números. Intente de nuevo.")

    placa = input("Número de placa: ")

    # Validar y solicitar hora de entrada
    while True:
        hora_entrada = input("Hora de entrada (HH:MM): ")
        if validar_hora(hora_entrada):
            break
        else:
            print("Formato de hora no válido. Use HH:MM.")

    # Validar y solicitar hora de salida
    while True:
        hora_salida = input("Hora de salida (HH:MM): ")
        if validar_hora(hora_salida):
            break
        else:
            print("Formato de hora no válido. Use HH:MM.")

    # Calcular el monto a pagar
    horas, total = calcular_monto(hora_entrada, hora_salida)

    # Mostrar resumen
    print("\nResumen de la transacción:")
    print(f"Nombre del cliente: {nombre}")
    print(f"NIT: {nit}")
    print(f"Placa del vehículo: {placa}")
    print(f"Hora de entrada: {hora_entrada}")
    print(f"Hora de salida: {hora_salida}")
    print(f"Tiempo en el parqueo: {horas} horas")
    print(f"Monto total a pagar: Q{total:.2f}")

    # Guardar en la base de datos PostgreSQL
    guardar_factura(nombre, nit, placa, hora_entrada, hora_salida, horas, total)

def calcular_monto(hora_entrada, hora_salida):
    formato = "%H:%M"
    entrada = datetime.datetime.strptime(hora_entrada, formato)
    salida = datetime.datetime.strptime(hora_salida, formato)

    diferencia = (salida - entrada).total_seconds() / 3600
    horas = int(diferencia) if diferencia == int(diferencia) else int(diferencia) + 1

    if horas < 1:
        horas = 1

    if horas == 1:
        total = 15.00
    else:
        total = 15.00 + (horas - 1) * 20.00

    return horas, total

def guardar_factura(nombre, nit, placa, hora_entrada, hora_salida, horas, total):
    try:
        # Guardar en la base de datos PostgreSQL
        cursor = conn.cursor()
        query = sql.SQL(""" 
            INSERT INTO factura (nombre, nit, placa, entrada, salida, tiempo, total)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """)
        cursor.execute(query, (nombre, nit, placa, hora_entrada, hora_salida, horas, total))
        conn.commit()
        cursor.close()
        print("\nFactura guardada en la base de datos PostgreSQL.")
    except Exception as e:
        print(f"Error al guardar la factura en la base de datos: {e}")

    try:
        # Guardar en archivo de texto
        with open('facturas.txt', 'a') as file:
            file.write(f"Nombre: {nombre}, NIT: {nit}, Placa: {placa}, Entrada: {hora_entrada}, "
                       f"Salida: {hora_salida}, Tiempo: {horas} horas, Total: Q{total:.2f}\n")
        print("Factura guardada en el archivo de texto.")
    except Exception as e:
        print(f"Error al guardar la factura en el archivo de texto: {e}")

def ver_facturas_anteriores():
    try:
        # Leer facturas desde el archivo de texto
        with open('facturas.txt', 'r') as file:
            facturas = file.readlines()
        
        if facturas:
            print("\n--- Facturas Guardadas (Archivo de Texto) ---")
            for factura in facturas:
                print(factura.strip())
        else:
            print("\nNo hay facturas guardadas en el archivo de texto.")
    except Exception as e:
        print(f"Error al leer las facturas desde el archivo: {e}")

def borrar_archivo_facturas():
    try:
        # Borrar facturas de la base de datos
        cursor = conn.cursor()
        cursor.execute("DELETE FROM factura")
        conn.commit()
        cursor.close()
        print("\nTodas las facturas han sido borradas de la base de datos.")

        # Borrar las facturas del archivo de texto
        with open('facturas.txt', 'w') as file:
            file.truncate(0)  # Vaciar el archivo
        print("Todas las facturas han sido borradas del archivo de texto.")
    except Exception as e:
        print(f"Error al borrar las facturas: {e}")

def validar_hora(hora):
    try:
        datetime.datetime.strptime(hora, "%H:%M")
        return True
    except ValueError:
        return False

if __name__ == "__main__":
    main()
    conn.close()  # Cerrar la conexión al salir del programa