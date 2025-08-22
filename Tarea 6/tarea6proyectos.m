clear;

% ===== Ruta compartida del archivo facturas.txt (AJUSTA si la tuya es distinta) =====
FACTURAS_PATH = 'C:/Users/50241/Desktop/PROYECTOS/facturas.txt';  % usa / o escapa \\

% Cargar el paquete de base de datos
pkg load database

% Variables globales para la conexión
global conn;

% ======== Conectar a la base de datos ========
try
    conn = pq_connect(setdbopts('dbname','postgres', ...
                                'host','localhost', ...
                                'port','5432', ...
                                'user','postgres', ...
                                'password','mariannenicte8934'));
    disp('Conexión a la base de datos establecida.');
    pq_exec_params(conn, "ALTER TABLE public.factura ADD COLUMN IF NOT EXISTS origen varchar(10)", {});
catch ME
    error('No se pudo conectar a la base de datos: %s', ME.message);
end

% ======== Funciones Auxiliares =========

function valido = validar_nombre(nombre)
    valido = ~isempty(regexp(nombre, '^[A-Za-záéíóúÁÉÍÓÚñÑ ]+$', 'once'));
end

function valido = validar_nit(nit)
    valido = ~isempty(regexp(nit, '^[0-9]+$', 'once'));
end

function valido = validar_hora(hora)
    valido = ~isempty(regexp(hora, '^([01]?[0-9]|2[0-3]):[0-5][0-9]$', 'once'));
end

function [horas, total] = calcular_monto(hora_entrada, hora_salida)
    entrada = datenum(hora_entrada, "HH:MM");
    salida  = datenum(hora_salida,  "HH:MM");
    diferencia = (salida - entrada) * 24; % horas
    horas = ceil(diferencia);
    if horas < 1, horas = 1; end
    if horas == 1
        total = 15.00;
    else
        total = 15.00 + (horas - 1) * 20.00;
    end
end

function guardar_factura(nombre, nit, placa, hora_entrada, hora_salida, horas, total, FACTURAS_PATH)
    global conn;

    % === Insertar en DB con origen='OCTAVE' (monto como texto por ser varchar) ===
    monto_str = sprintf('%.2f', total);
    sql = ["INSERT INTO public.factura (nombre, nit, placa, hora_de_entrada, hora_de_salida, monto, origen) " ...
           "VALUES ($1, $2, $3, $4, $5, $6, 'OCTAVE')"];
    params = {nombre, nit, placa, hora_entrada, hora_salida, monto_str};

    try
        pq_exec_params(conn, sql, params);
        disp("Factura guardada en PostgreSQL (tabla 'factura', origen=OCTAVE).");
    catch ME
        fprintf(2, 'Error al guardar la factura en la base de datos: %s\n', ME.message);
    end

    % === Guardar en archivo de texto en la RUTA COMPARTIDA ===
    try
        fid = fopen(FACTURAS_PATH, 'a');  % modo append
        if fid == -1, error('No se pudo abrir el archivo de facturas.'); end
        fprintf(fid, '[OCTAVE] Nombre: %s, NIT: %s, Placa: %s, Entrada: %s, Salida: %s, Tiempo: %d horas, Total: Q%.2f\n', ...
                nombre, nit, placa, hora_entrada, hora_salida, horas, total);
        fclose(fid);
        disp(["Factura guardada en el archivo de texto: ", FACTURAS_PATH]);
    catch ME
        fprintf(2, 'Error al guardar la factura en el archivo de texto: %s\n', ME.message);
    end
end

function ver_facturas_anteriores(FACTURAS_PATH)
    % Archivo
    try
        fid = fopen(FACTURAS_PATH, 'r');
        if fid == -1
            disp("No hay facturas guardadas en el archivo.");
        else
            disp("\n--- Facturas Anteriores (Archivo de texto) ---");
            while ~feof(fid)
                tline = fgetl(fid);
                if ischar(tline), disp(tline); end
            end
            fclose(fid);
        end
    catch ME
        fprintf(2, 'Error al leer las facturas del archivo: %s\n', ME.message);
    end

    % DB (mostrar origen)
    global conn;
    try
        res = pq_exec_params(conn, ...
          "SELECT nombre, nit, placa, hora_de_entrada, hora_de_salida, monto, COALESCE(origen,'') FROM public.factura ORDER BY origen, nombre", {});
        if ~isstruct(res) || ~isfield(res,'data') || isempty(res.data)
            disp("\n(Sin registros en la base de datos).");
        else
            disp("\n--- Facturas en DB (public.factura) ---");
            for i = 1:rows(res.data)
                fila = res.data(i,:);
                printf("[%s] Nombre: %s | NIT: %s | Placa: %s | Entrada: %s | Salida: %s | Monto: Q%s\n", ...
                       fila{7}, fila{1}, fila{2}, fila{3}, fila{4}, fila{5}, fila{6});
            end
        end
    catch ME
        fprintf(2, 'Error al consultar DB: %s\n', ME.message);
    end
end

function borrar_facturas_octave()
    global conn;
    try
        pq_exec_params(conn, "DELETE FROM public.factura WHERE origen = 'OCTAVE'", {});
        disp("✔ Borradas de la DB las facturas con origen=OCTAVE.");
    catch ME
        fprintf(2, 'Error al borrar facturas en la DB: %s\n', ME.message);
    end
end

function calcular_y_guardar_factura(FACTURAS_PATH)
    nombre = "";
    while true
        nombre = input("Nombre del cliente (solo letras): ", "s");
        if validar_nombre(nombre), break; else, printf("El nombre solo debe contener letras y espacios.\n"); end
    end

    nit = "";
    while true
        nit = input("NIT (solo números): ", "s");
        if validar_nit(nit), break; else, printf("El NIT solo debe contener números.\n"); end
    end

    placa = input("Número de placa: ", "s");

    while true
        hora_entrada = input("Hora de entrada (HH:MM): ", "s");
        if validar_hora(hora_entrada), break; else, printf("Formato de hora no válido. Use HH:MM.\n"); end
    end

    while true
        hora_salida = input("Hora de salida (HH:MM): ", "s");
        if validar_hora(hora_salida), break; else, printf("Formato de hora no válido. Use HH:MM.\n"); end
    end

    [horas, total] = calcular_monto(hora_entrada, hora_salida);

    printf("\nResumen de la transacción:\n");
    printf("Nombre: %s\nNIT: %s\nPlaca: %s\nEntrada: %s\nSalida: %s\nTiempo: %d horas\nMonto: Q%.2f\n", ...
           nombre, nit, placa, hora_entrada, hora_salida, horas, total);

    guardar_factura(nombre, nit, placa, hora_entrada, hora_salida, horas, total, FACTURAS_PATH);
end

% ======== Menú Principal =========
while true
    disp("\n--- Menú Principal (OCTAVE) ---");
    disp("1. Calcular y guardar factura");
    disp("2. Ver facturas anteriores (archivo + DB)");
    disp("3. Borrar SOLO facturas creadas por Octave en la DB");
    disp("4. Salir");

    opcion = input("Seleccione una opción: ");

    switch opcion
        case 1
            calcular_y_guardar_factura(FACTURAS_PATH);
        case 2
            ver_facturas_anteriores(FACTURAS_PATH);
        case 3
            borrar_facturas_octave();
        case 4
            disp("Saliendo del programa...");
            pq_close(conn);
            break;
        otherwise
            disp("Opción no válida. Intente de nuevo.");
    end
end




