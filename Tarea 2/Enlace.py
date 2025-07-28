import psycopg2

# Conectar a la base de datos
conn = psycopg2.connect(
    dbname="postgres",
    user="postgres",
    password="mariannenicte8934",
    host="localhost",
    port="5432"
)

# Crear un cursor para ejecutar consultas
cursor = conn.cursor()

# Insertar datos en la tabla
cursor.execute("INSERT INTO tarea2 (nombre, carnet) VALUES (%s, %s);", ('Marianne', '202000656'))

# Ejecutar una consulta SELECT
cursor.execute("SELECT * FROM tarea2;")
rows = cursor.fetchall()

# Mostrar los resultados
for row in rows:
    print(row)

# Confirmar la transacción
conn.commit()

# Cerrar el cursor y la conexión
cursor.close()
conn.close()