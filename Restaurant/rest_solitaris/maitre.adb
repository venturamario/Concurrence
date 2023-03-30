---------------------------------------------------------------------------
--------- PRÁCTICA 2 - PROGRAMACIÓN CONCURRENTE
--------- Mario Ventura & Luis Miguel Vargas
--------- Curso 2022-2023
--------- UIB - Grado en Ingeniería Informática - GIN3
---------------------------------------------------------------------------
--------- ENLACE AL VÍDEO: https://youtu.be/5C6OrnlUXss

---------------------------------------------------------------------------
with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Text_IO.Unbounded_IO;  use Ada.Text_IO.Unbounded_IO;

    -- Se establece el cuerpo de las funciones, procedures y entries declaradas en el archivo
    -- maitre.ads. Todas estas serán llamadas desde el archivo rest_solitaris.adb, que es el
    -- programa principal y, por tanto, el que tiene la función del tipo 'main'

package body maitre is
    
    -----> DESARROLLO DEL BODY/CUERPO DE LAS FUNCIONALIDADES DEL MONITOR
    protected body maitreMonitor is
        -----------------------------------------------------------------------------------------
        --------> FUNCIONES
        -----------------------------------------------------------------------------------------

        -----> GETTERS
        ---> Getter del array de procesos fumadores
        function getFumadores return Comensales is
        begin 
            ---> Se retorna el array de comensales fumadores establecido en el monitor
            return comensalesFumadores;
        end getFumadores;

        ---> Getter del array de procesos no fumadores
        function getNoFumadores return Comensales is
        begin 
            ---> Se retorna el array de comensales no fumadores establecido en el monitor
            return comensalesNoFumadores;
        end getNoFumadores;

        ---> Getter del array de salones
        function getSalones return Salas is
        begin
            ---> Se retorna el array de salones establecido en el monitor
            return salones;
        end getSalones;

        -----> FUNCIÓN QUE DEVUELVE UN BOOLEANO QUE REPRESENTA SI UN SALÓN NO ESTÁ LLENO
        function notFull(tipo: Integer) return Boolean is
            ---> Variables: Booleano que se devolverá
            ---> (True = Salón con espacio // False = Salón lleno)
            notFull: Boolean := False;      ---> Inicialmente, por precaución, asumimos que el salón está lleno
        begin
            for i in 1..NUM_SALONES loop
                ---> Para que un salón no esté lleno, tiene que tener 0 mesas ocupadas o tener menos de 3 mesas ocupadas para
                ---> un tipo de proceso en concreto (fumadores o no fumadores)
                if(salones(i).mesasOcupadas = 0 or (salones(i).mesasOcupadas /= 3 and salones(i).tipoSalon = tipo)) then
                    ---> El salón no está lleno
                    notFull := True;
                end if;
            end loop;
            ---> Se devuelve el resultado encontrado en la iteración y almacenado en el booleano
            return notFull;
            ---> Fin de la función
        end notFull;

        -----> FUNCIÓN QUE DEVUELVE EL PRIMER SALÓN DISPONIBLE DEL ARRAY DE SALONES
        function salonDisponible(tipo: Integer) return Integer is
            ---> Variables: Índice que se devolverá
            indiceSala: Integer := 0;   ---> Representa el indice del primer salon dispoible en el array de salones
        begin
            ---> Se recorre el array de salones en busca del primero disponible
            for i in 1..NUM_SALONES loop
                ---> Para que el salón esté disponible de estar vacío, o tener un número de mesas ocupadas menor que 3
                ---> para un tipo determinado de proceso (fumador o no fumador)
                if (salones(i).mesasOcupadas = 0 or (salones(i).mesasOcupadas /= 3 and salones(i).tipoSalon = tipo)) then
                    ---> Para asegurar que se devuelve la primera sala vacía
                    if indiceSala = 0 then
                        ---> Si se cumple, la sala de la iteración actual es la primera libre que encontramos
                        indiceSala := i;
                    end if;
                end if;
            end loop;
            ---> Se devuelve el índice de la sala encontrada
            return indiceSala;
            ---> Fin de la función
        end salonDisponible;

        -----------------------------------------------------------------------------------------
        --------> PROCEDURES
        -----------------------------------------------------------------------------------------
        -- Procedure para tratar la salida de un fumador de una sala

        -----> PROCEDURE QUE GESTIONA LA SALIDA DE PROCESOS NO FUMADORES DEL SALÓN
        procedure salirSalonNoFumadores(id: Integer; nombre: Unbounded_String) is
            -- El procedure hace lo siguiente: deja salir al proceso no fumador actualizando las correspondientes
            -- variables del monitor. Cuando un comensal no fumador sale del salón, las mesas ocupadas disminuyen en 1
            -- y las mesas libres aumentan en 1. Acto seguido, será necesario comprobar la disponibilidad del salón
            -- ya que, en caso de que el comensal que haya salido sea el último, el salón quedará vacío y será
            -- necesario actualizar también el tipo de salon, dándole el valor de SALON_VACIO 

            ---> Variables
            salonLibre: Integer := comensalesNoFumadores(id);   ---> Obtener si el salón está disponible
            mesasLibres: Integer := NUM_MESAS_POR_SALON;        ---> Inicialmente se asume que hay 3 mesas libres
        begin
            ---> Cuando un comensal sale, el número de mesas ocupadas en el salón disminuye, ya que estas tienen capacidad 1
            salones(salonLibre).mesasOcupadas := salones(salonLibre).mesasOcupadas - 1; -- Una mesa ocupada menos
            ---> Si un comensal sale, el número de mesas libres también cambia (aumenta).
            mesasLibres := mesasLibres - salones(salonLibre).mesasOcupadas; -- Actualizar mesas libres
            ---> Se establece que el comensal dado está en el salón obtenido
            comensalesNoFumadores(id) := 0; -- 0 significa que no está en ningún salón

            ---> Si se detecta que ahora el salón tiene 0 comensales, es decir, si se detecta que está vacío, podrán entrar
            ---> a partir de ahora comensales de cualquier tipo, para lo cual se especifica el tipo de salón en SALON_VACIO
            if(salones(salonLibre).mesasOcupadas > 0) then
                ---> Todavía hay comensales, no está vacío el salón
                ---> Prints de simulación
                Put_Line("********** En "& nombre &" allibera una taula del salo "& salonLibre'Img &". Disponibilitat: "& mesasLibres'Img &". Tipus: NO FUMADORES");
            else
                ---> El salón queda vacío, se actualiza el tipo
                salones(salonLibre).tipoSalon := SALON_VACIO;
                ---> Prints de simulación
                Put_Line("********** En "& nombre &" allibera una taula del salo "& salonLibre'Img &". Disponibilitat: "& mesasLibres'Img &". Tipus: SALON_VACIO");
            end if;
            ---> Fin del procedure
        end salirSalonNoFumadores;

        -----> PROCEDURE QUE GESTIONA LA SALIDA DE PROCESOS FUMADORES DEL SALÓN
        procedure salirSalonFumadores(id: Integer; nombre: Unbounded_String) is
        -- El proceso es el mismo que el seguido en el procedure anterior, pero para procesos fumadores
        -- Lo único que cambia es el tipo de proceso

            ---> Variables
            salonDisponible: Integer := comensalesFumadores(id);    ---> Obtener si el salón está disponible
            mesasLibres: Integer := NUM_MESAS_POR_SALON;             ---> Inicialmente se asume que hay 3 mesas libres
        begin
            ---> Cuando un comensal sale, el número de mesas ocupadas en el salón disminuye, ya que estas tienen capacidad 1
            salones(salonDisponible).mesasOcupadas := salones(salonDisponible).mesasOcupadas - 1;   -- Una mesa ocupada menos
            ---> Si un comensal sale, el número de mesas libres también cambia (aumenta).
            mesasLibres := mesasLibres - salones(salonDisponible).mesasOcupadas;
            ---> Se establece que el comensal dado está en el salón obtenido
            comensalesFumadores(id) := 0;   -- 0 significa que no está en ningún salón

            ---> Si se detecta que ahora el salón tiene 0 comensales, es decir, si se detecta que está vacío, podrán entrar
            ---> a partir de ahora comensales de cualquier tipo, para lo cual se especifica el tipo de salón en SALON_VACIO
            if(salones(salonDisponible).mesasOcupadas > 0) then
                ---> Todavía hay comensales, no está vacío el salón
                ---> Prints de simulación
                Put_Line("---------- En "& nombre &" allibera una taula del salo "& salonDisponible'Img &". Disponibilitat: "& mesasLibres'Img &". Tipus: FUMADORES");
            else
                ---> El salón queda vacío, se actualiza el tipo
                salones(salonDisponible).tipoSalon := SALON_VACIO;
                ---> Prints de simulación
                Put_Line("---------- En "& nombre &" allibera una taula del salo "& salonDisponible'Img &". Disponibilitat: "& mesasLibres'Img &". Tipus: SALON_VACIO");
            end if;
            ---> Fin del procedure
        end salirSalonFumadores;

        -----> PROCEDURE QUE SE ENCARGA DE LA INICIALIZACIÓN DE TODOS LOS COMENSALES DEL ARRAY DE COMENSALES
        procedure initComensales is
        -- El procedimiento es el siguiente: Dado que es un array, se recorrerá este, inicializando
        -- los comensales uno a uno. Para hacer eso, simplemente se dará valor a todas las variables del
        -- record/struct/objeto
        begin
            ---> Se recorre el array
            for i in Comensales'Range loop
                comensalesFumadores(i) := 0;    ---> Inicialmente está en el salón 0 (no están en ningún salón)
                comensalesNoFumadores(i) := 0;  ---> Inicialmente está en el salón 0 (no están en ningún salón)
            end loop;
            ---> Fin del procedure
        end initComensales;

        -----> PROCEDURE QUE SE ENCARGA DE LA INCIALIZACIÓN DE TODOS LOS SALONES DEL ARRAY DE SALONES
        procedure initSalones is
        -- El procedimiento es el siguiente: Dado que es un array, se recorrerá este, inicializando
        -- los salones uno a uno. Para hacer eso, simplemente se dará valor a todas las variables del
        -- record/struct/objeto
        begin
            ---> Se recorre el array
            for i in 1..NUM_SALONES loop
                salones(i).tipoSalon := SALON_VACIO;    ---> Inicialmente el salón está vacío
                salones(i).mesasOcupadas := 0;          ---> Inicialmente todas las mesas están libres
            end loop;
            ---> Fin del procedure
        end initSalones;  

        -----------------------------------------------------------------------------------------
        --------> ENTRIES
        -----------------------------------------------------------------------------------------

        -----> ENTRY QUE GESTIONA LOS ACCESOS A UNA SALA DE PROCESOS FUMADORES
        entry entrarSalaFumadores(id: Integer; nombre: Unbounded_String) when notFull(SALON_FUMADORES) is
        -- Para controlar los accesos a un salón sin que haya problemas, es decir, sin que fumadores
        -- y no fumadores se mezclen, evitando así las quejas, lo que se hará será comprobar si hay algún
        -- salón vacío o algún salón no lleno donde pueda entrar un proceso del tipo dado (fumador)
        -- existe también una condición de entrada: notFull(SALON_FUMADORES) = True, es decir, el salón
        -- no debe estar lleno

            ---> Variables:
            salonLibre: Integer := salonDisponible(SALON_FUMADORES);    ---> Obtener si el salón está disponible
            mesasLibres: Integer := NUM_MESAS_POR_SALON;    ---> Inicialmente se asume que hay 3 mesas libres
        begin
            ---> Si existe alguna mesa libre en el salón, el comensal puede entrar
            if(salonLibre > 0) then
                ---> Si ha entrado un proceso fumador, el salón pasa a ser para ese tipo de proceso
                salones(salonLibre).tipoSalon := SALON_FUMADORES; -- Salón destinado a fumadores
                ---> Cuando entra el comensal y se sienta, aumenta el número de mesas ocupadas
                salones(salonLibre).mesasOcupadas := salones(salonLibre).mesasOcupadas + 1;
                ---> Ahora las mesas libres disminuyen. Serán NUM_MESAS - MESAS_OCUPADAS
                mesasLibres := mesasLibres - salones(salonLibre).mesasOcupadas;
                ---> Se establece que el comensal dado está en el salón obtenido
                comensalesFumadores(id) := salonLibre;
                ---> Print para la simulación
                -- (no se pondrán acentos porque vsc los imprime mal al ser caracteres no asci)
                Put_Line("---------- En "& nombre &" te la taula al salo de fumadors "& salonLibre'Img &". Disponibilitat: "& mesasLibres'Img);
            end if;
            ---> Fin del entry para fumadores
        end entrarSalaFumadores;

        -----> ENTRY QUE GESTIONA LOS ACCESOS A UNA SALA DE PROCESOS NO FUMADORES
        entry entrarSalaNoFumadores(id: Integer; nombre: Unbounded_String) when notFull(SALON_NO_FUMADORES)is
        -- El proceso que se seguirá es el mismo que para la entry anterior, pero obviamente, haciendo las comprobaciones
        -- para procesos de tipo no fumadores. En esencia, el código es el mismo

            ---> Variables
            salonLibre: Integer := salonDisponible(SALON_NO_FUMADORES); ---> Obtener si el salón está disponible
            mesasLibres: Integer := NUM_MESAS_POR_SALON;    ---> Inicialmente se asume que hay 3 mesas libres
        begin
            ---> Si existe alguna mesa libre en el salón, el comensal puede entrar
            if(salonLibre > 0) then
                ---> Si ha entrado un proceso no fumador, el salón pasa a ser para ese tipo de proceso
                salones(salonLibre).tipoSalon := SALON_NO_FUMADORES;    -- Salón destinado a no fumadores
                ---> Cuando entra el comensal y se sienta, aumenta el número de mesas ocupadas
                salones(salonLibre).mesasOcupadas := salones(salonLibre).mesasOcupadas + 1;
                ---> Ahora las mesas libres disminuyen. Serán NUM_MESAS - MESAS_OCUPADAS
                mesasLibres := mesasLibres - salones(salonLibre).mesasOcupadas;
                ---> Se establece que el comensal dado está en el salón obtenido
                comensalesNoFumadores(id) := salonLibre;
                ---> Print para la simulación
                -- (no se pondrán acentos porque vsc los imprime mal al ser caracteres no asci)
                Put_Line("********** En "& nombre &" te la taula al salo de fumadors "& salonLibre'Img &". Disponibilitat: "& mesasLibres'Img);
            end if;
            ---> Fin del entry para no fumadores
        end entrarSalaNoFumadores;      

    -----> FIN DEL DESARROLLO DEL CUERPO DE LAS FUNCIONALIDADES DEL MONITOR MAITRE
    end maitreMonitor;
end maitre;