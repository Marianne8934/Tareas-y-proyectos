# Definición de categorías
bajoPeso = "Bajo peso";
pesoNormal = "Peso normal";
sobrePeso = "Sobrepeso";

# Bucle principal
while true
    # Mostrar opciones
    disp("1. Calcular IMC");
    disp("2. Leer información del archivo");
    disp("3. Borrar información del archivo");
    disp("4. Salir");

    # Leer la opción del usuario
    opcion = input("Ingrese la opción deseada: ");

    # Validar la opción
    if ~(1 <= opcion && opcion <= 4)
        disp("Opción no válida. Intente de nuevo.");
        continue;
    end

    # Ejecutar la acción según la opción
    switch opcion
        case 1
            # Leer datos del usuario
            nombre = input("Ingrese su nombre: ", 's');
            peso = input("Ingrese su peso en kg: ");
            altura = input("Ingrese su altura en metros: ");

            if peso <= 0 || altura <= 0
                disp("Error: El peso y la altura deben ser valores positivos.");
                continue;
            end

            # Calcular IMC
            imc = peso / (altura^2);

            # Determinar la categoría
            if imc < 18.5
                categoria = bajoPeso;
            elseif imc >= 18.5 && imc < 25
                categoria = pesoNormal;
            else
                categoria = sobrePeso;
            end

            # Mostrar resultados
            fprintf('Nombre: %s\n', nombre);
            fprintf('IMC: %.2f\n', imc);
            fprintf('Categoría: %s\n', categoria);

            # Guardar en archivo de texto
            opcion_guardar = input('¿Desea guardar la información en el archivo de texto? (s/n): ', 's');
            if lower(opcion_guardar) == 's'
                fid = fopen('imc.txt', 'a');
                if fid ~= -1
                    fprintf(fid, 'Nombre: %s, Peso: %.2f kg, Altura: %.2f m, IMC: %.2f, Categoría: %s\n', ...
                        nombre, peso, altura, imc, categoria);
                    fclose(fid);
                    disp('Información guardada en imc.txt');
                else
                    disp('No se pudo abrir el archivo para escribir.');
                end
            end

        case 2
            # Leer información del archivo
            fid = fopen('imc.txt', 'r');
            if fid ~= -1
                disp('--- Información almacenada ---');
                while ~feof(fid)
                    linea = fgetl(fid);
                    disp(linea);
                end
                fclose(fid);
                disp('-----------------------------');
            else
                disp('No se pudo abrir el archivo o no existe.');
            end

        case 3
            # Borrar información del archivo
            opcion_borrar = input('¿Está seguro de que desea borrar la información? (s/n): ', 's');
            if lower(opcion_borrar) == 's'
                if exist('imc.txt', 'file')
                    delete('imc.txt');
                    disp('Archivo imc.txt borrado.');
                else
                    disp('El archivo imc.txt no existe.');
                end
            end

        case 4
            # Salir del programa
            break;
    end
end

# Mensaje de despedida
disp("¡Gracias por usar el programa!");

