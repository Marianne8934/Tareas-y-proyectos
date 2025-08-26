pkg load database

% ================= RUTA COMPARTIDA DEL ARCHIVO =================
% ⚠️ Cambia esta ruta si guardas el archivo en otro lugar
FACTURAS_PATH = 'C:/Users/50241/Desktop/PROYECTOS/facturas.txt';

% =================== CONFIG DB (AJUSTABLE) =====================
DB_NAME = 'postgres';
DB_HOST = 'localhost';
DB_PORT = '5432';
DB_USER = 'postgres';
DB_PASS = 'mariannenicte8934';

% ================== CONEXIÓN (con ping y cache) =================
function conn = get_conn()
  persistent _conn;
  global DB_NAME DB_HOST DB_PORT DB_USER DB_PASS;

  if isempty(_conn)
    try
      opts = setdbopts('dbname', DB_NAME, ...
                       'host',   DB_HOST, ...
                       'port',   DB_PORT, ...
                       'user',   DB_USER, ...
                       'password', DB_PASS, ...
                       'sslmode', 'prefer');
      _conn = pq_connect(opts);

      % Ping
      pq_exec_params(_conn, 'SELECT 1;', {});
      printf("✅ Conectado a PostgreSQL (%s@%s:%s / DB=%s)\n", DB_USER, DB_HOST, DB_PORT, DB_NAME);

      % Asegurar tabla con VARCHAR(50) (según tu esquema)
      ensure_schema_varchar(_conn);

    catch err
      fprintf(2, "❌ Error conectando a PostgreSQL: %s\n", err.message);
      _conn = [];
    end
  end

  conn = _conn;
end

% ====== CREA LA TABLA public.ventas CON VARCHAR(50) SI NO EXISTE ======
function ensure_schema_varchar(conn)
  if isempty(conn), return; end
  try
    pq_exec_params(conn, "CREATE SCHEMA IF NOT EXISTS public;", {});
    pq_exec_params(conn, "SET search_path TO public;", {});

    % Crea la tabla exactamente con VARCHAR(50) en todas las columnas (como tu ALTER)
    sql_create = [
      "CREATE TABLE IF NOT EXISTS public.ventas ("
      "  id SERIAL PRIMARY KEY,"
      "  nombre_cliente   VARCHAR(50),"
      "  placa_vehiculo   VARCHAR(50),"
      "  tipo_combustible VARCHAR(50),"
      "  litros           VARCHAR(50),"
      "  precio_litro     VARCHAR(50),"
      "  monto_total      VARCHAR(50),"
      "  fecha            VARCHAR(50)"
      ");"
    ];
    pq_exec_params(conn, sql_create, {});

    % Si tu tabla existía sin alguna columna, las agregamos como VARCHAR(50)
    cols = { ...
      'nombre_cliente','placa_vehiculo','tipo_combustible','litros',...
      'precio_litro','monto_total','fecha' ...
    };
    for k = 1:numel(cols)
      pq_exec_params(conn, ...
        sprintf("ALTER TABLE public.ventas ADD COLUMN IF NOT EXISTS %s VARCHAR(50);", cols{k}), {});
    end

    % Confirmación
    chk = pq_exec_params(conn, "SELECT to_regclass('public.ventas');", {});
    if !(isfield(chk,'data') && !isempty(chk.data) && !isempty(chk.data{1}))
      error("La tabla 'public.ventas' no se registró correctamente.");
    end
    printf("🛠️  Tabla 'public.ventas' lista para usar (VARCHAR(50)).\n");
  catch err
    fprintf(2, "❌ Error en ensure_schema_varchar: %s\n", err.message);
  end
end

% ====================== UTILIDADES ======================
function s = ahora_texto()
  s = datestr(now, "yyyy-mm-dd HH:MM:SS");
end

function ok = es_num_pos(v)
  ok = ~(isempty(v)) && isnumeric(v) && isfinite(v) && v > 0;
end

% ===================== MENÚ PRINCIPAL ====================
1; % para permitir funciones en el mismo archivo

function main()
  conn = get_conn();  % puede ser []

  % Precios configurables
  precios = struct('Regular', 6.75, 'Premium', 7.60, 'Diesel', 6.29);

  while true
    disp("\n--- Menú Principal ---");
    disp("1. Ingresar venta");
    disp("2. Ver historial");
    disp("3. Borrar datos");
    disp("4. Salir");
    opcion = input("Seleccione una opción: ", "s");

    switch opcion
      case '1'
        ingresar_venta(precios, conn);
      case '2'
        ver_historial(conn);
      case '3'
        borrar_datos(conn);
      case '4'
        try, if ~isempty(conn), pq_close(conn); end, catch, end
        disp("👋 Saliendo...");
        break;
      otherwise
        disp("Opción inválida. Intente nuevamente.");
    end
  end
end

% ===================== INGRESAR VENTA =====================
function ingresar_venta(precios, conn)
  global FACTURAS_PATH;

  nombre = strtrim(input("Nombre del cliente: ", "s"));
  placa  = strtrim(input("Placa del vehículo: ", "s"));

  disp("\nTipos de combustible:");
  disp("1. Gasolina Regular");
  disp("2. Gasolina Premium");
  disp("3. Diesel");
  tipo = input("Seleccione el tipo (1-3): ", "s");
  while ~ismember(tipo, {'1','2','3'})
    tipo = input("Opción inválida. Seleccione nuevamente (1-3): ", "s");
  end

  litros = [];
  while ~es_num_pos(litros)
    try
      litros_input = input("Litros a despachar: ", "s");
      litros = str2double(litros_input);
      if isnan(litros) || litros <= 0, error("Valor inválido"); end
    catch
      disp("Ingrese un número positivo.");
      litros = [];
    end
  end

  switch tipo
    case '1', combustible = 'Gasolina Regular'; precio = precios.Regular;
    case '2', combustible = 'Gasolina Premium'; precio = precios.Premium;
    case '3', combustible = 'Diesel';           precio = precios.Diesel;
  end

  total = litros * precio;

  % ====== Guardar en archivo TXT (una sola línea por venta) ======
  try
    fid = fopen(FACTURAS_PATH, "a");
    if fid < 0, error("No se pudo abrir facturas.txt"); end
    fprintf(fid, "[VENTA] Fecha: %s | Cliente: %s | Placa: %s | Combustible: %s | Litros: %.2f | Precio/L: Q%.2f | Total: Q%.2f\n", ...
      ahora_texto(), nombre, placa, combustible, litros, precio, total);
    fclose(fid);
    disp(["📝 Venta guardada en archivo: " FACTURAS_PATH]);
  catch err
    fprintf(2, "❌ Error escribiendo en facturas.txt: %s\n", err.message);
  end

  % ====== Insertar en DB (como VARCHAR(50), según tu esquema) ======
  if isempty(conn)
    conn = get_conn(); % reintento
  end

  if ~isempty(conn)
    try
      sql = ["INSERT INTO public.ventas "
             "(nombre_cliente, placa_vehiculo, tipo_combustible, litros, precio_litro, monto_total, fecha) "
             "VALUES ($1,$2,$3,$4,$5,$6,$7);"];
      params = { ...
        nombre, ...
        placa, ...
        combustible, ...
        sprintf('%.2f', litros), ...
        sprintf('%.2f', precio), ...
        sprintf('%.2f', total), ...
        ahora_texto() ...
      };
      pq_exec_params(conn, sql, params);
      disp("💾 Venta guardada en DB (public.ventas).");
    catch err
      fprintf(2, "❌ Error insertando en DB: %s\n", err.message);
    end
  else
    disp("⚠️ Sin conexión a DB, la venta quedó solo en el archivo.");
  end

  printf("\nTotal a pagar: Q%.2f\n✅ Venta registrada.\n", total);
end

% ====================== VER HISTORIAL ======================
function ver_historial(conn)
  global FACTURAS_PATH;

  disp("\n===== HISTORIAL EN facturas.txt =====");
  try
    fid = fopen(FACTURAS_PATH, "r");
    if fid < 0
      disp("(No hay facturas en archivo)");
    else
      datos = fscanf(fid, "%c", Inf);
      if isempty(datos), disp("(Archivo vacío)"); else, disp(datos); end
      fclose(fid);
    end
  catch err
    fprintf(2, "❌ Error leyendo facturas.txt: %s\n", err.message);
  end

  % Reintento de conexión si está vacía
  if isempty(conn), conn = get_conn(); end

  if ~isempty(conn)
    disp("===== HISTORIAL EN BASE DE DATOS (public.ventas) =====");
    try
      res = pq_exec_params(conn, ...
        "SELECT id, nombre_cliente, placa_vehiculo, tipo_combustible, litros, precio_litro, monto_total, fecha FROM public.ventas ORDER BY id;", {});
      if isfield(res, "data") && !isempty(res.data)
        cab = {"id","cliente","placa","combustible","litros","precio_L","total","fecha"};
        ancho = [6,20,12,20,10,12,12,20];
        for k=1:numel(cab), printf("%-*s", ancho(k), cab{k}); end
        printf("\n");
        for i=1:size(res.data,1)
          row = res.data(i,:);
          printf("%-*s%-*s%-*s%-*s%-*s%-*s%-*s%-*s\n", ...
            ancho(1), num2str(row{1}), ...
            ancho(2), char(row{2}), ...
            ancho(3), char(row{3}), ...
            ancho(4), char(row{4}), ...
            ancho(5), char(row{5}), ...
            ancho(6), char(row{6}), ...
            ancho(7), char(row{7}), ...
            ancho(8), char(row{8}));
        end
      else
        disp("(No hay ventas en la DB)");
      end
    catch err
      fprintf(2, "❌ Error consultando DB: %s\n", err.message);
    end
  else
    disp("(* Sin conexión a DB, solo se muestra archivo *)");
  end
end

% ======================= BORRAR DATOS =======================
function borrar_datos(conn)
  global FACTURAS_PATH;
  confirmacion = input("¿Está seguro? (s/n): ", "s");
  if lower(confirmacion) == 's'
    % Limpiar archivo
    try
      fid = fopen(FACTURAS_PATH, "w");
      if fid >= 0, fclose(fid); end
      disp("🧹 Archivo facturas.txt borrado/limpiado.");
    catch err
      fprintf(2, "❌ Error limpiando archivo: %s\n", err.message);
    end

    % Reintento de conexión por si estaba caída
    if isempty(conn), conn = get_conn(); end

    % Truncate DB
    if ~isempty(conn)
      try
        pq_exec_params(conn, "TRUNCATE TABLE public.ventas RESTART IDENTITY;", {});
        disp("🧹 Tabla 'public.ventas' truncada en DB.");
      catch err
        fprintf(2, "❌ Error truncando tabla en DB: %s\n", err.message);
      end
    else
      disp("(* Sin conexión a DB; no se pudo truncar tabla *)");
    end
  else
    disp("Operación cancelada.");
  end
end

% ====================== EJECUTAR PROGRAMA ===================
main();


