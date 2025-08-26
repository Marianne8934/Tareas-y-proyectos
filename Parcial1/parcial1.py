import psycopg2
from datetime import datetime

# Configuración de PostgreSQL
conn = psycopg2.connect(
    dbname='Proyectos',
    user='postgres',
    password='sosa2811',
 
)
cursor = conn.cursor()

# Crear tabla si no existe
cursor.execute('''
    CREATE TABLE IF NOT EXISTS ventas (
        id SERIAL PRIMARY KEY,
        nombre_cliente VARCHAR(100),
        placa_vehiculo VARCHAR(20),
        tipo_combustible VARCHAR(50),
        litros FLOAT,
        precio_litro FLOAT,
        monto_total FLOAT,
        fecha TIMESTAMP
    )
''')
conn.commit()

# Precios de combustibles
PRECIOS = {
    '1': {'tipo': 'Gasolina Regular', 'precio': 6.75},
    '2': {'tipo': 'Gasolina Premium', 'precio': 7.60},
    '3': {'tipo': 'Diesel', 'precio': 6.29}
}

def ingresar_venta():
    nombre = input("Nombre del cliente: ")
    placa = input("Placa del vehículo: ")
    
    print("\nTipos de combustible:")
    for key, value in PRECIOS.items():
        print(f"{key}. {value['tipo']} - ${value['precio']}/L")
    
    tipo = input("Seleccione el tipo (1-3): ")
    while tipo not in PRECIOS:
        tipo = input("Opción inválida. Seleccione nuevamente (1-3): ")
    
    litros = float(input("Litros a despachar: "))
    while litros <= 0:
        litros = float(input("Ingrese un valor positivo: "))
    
    precio = PRECIOS[tipo]['precio']
    total = litros * precio
    
    # Guardar en archivo
    with open("facturas.txt", "a") as f:
        f.write(
            f"Fecha: {datetime.now()}\n"
            f"Cliente: {nombre}\nPlaca: {placa}\n"
            f"Combustible: {PRECIOS[tipo]['tipo']}\n"
            f"Litros: {litros}\nPrecio/L: ${precio}\nTotal: ${total}\n\n"
        )
    
    # Guardar en PostgreSQL
    cursor.execute('''
        INSERT INTO ventas (nombre_cliente, placa_vehiculo, tipo_combustible, litros, precio_litro, monto_total, fecha)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    ''', (nombre, placa, PRECIOS[tipo]['tipo'], litros, precio, total, datetime.now()))
    conn.commit()
    
    print(f"\nTotal a pagar: ${total:.2f}\nFactura generada correctamente.")

def ver_historial():
    try:
        with open("facturas.txt", "r") as f:
            print(f.read())
    except FileNotFoundError:
        print("No hay historial registrado.")

def borrar_datos():
    confirmacion = input("¿Está seguro? (s/n): ")
    if confirmacion.lower() == 's':
        open("facturas.txt", "w").close()
        cursor.execute("DELETE FROM ventas")
        conn.commit()
        print("Datos borrados.")

def main():
    while True:
        print("\n--- Menú Principal ---")
        print("1. Ingresar venta")
        print("2. Ver historial")
        print("3. Borrar datos")
        print("4. Salir")
        opcion = input("Seleccione una opción: ")
        
        if opcion == '1':
            ingresar_venta()
        elif opcion == '2':
            ver_historial()
        elif opcion == '3':
            borrar_datos()
        elif opcion == '4':
            break
        else:
            print("Opción inválida.")

if __name__ == "__main__":
    main()
    cursor.close()
    conn.close()