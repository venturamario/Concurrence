---------------------------------------------------------------------------
--------- PRÁCTICA 2 - PROGRAMACIÓN CONCURRENTE
--------- Mario Ventura & Luis Miguel Vargas
--------- Curso 2022-2023
--------- UIB - Grado en Ingeniería Informática - GIN3
---------------------------------------------------------------------------
--------- ENLACE AL VÍDEO: https://youtu.be/5C6OrnlUXss

---------------------------------------------------------------------------
with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO;  use Ada.Text_IO.Unbounded_IO;
with maitre;                    use maitre;

    ---------------------------------------------------------------------------
    -- Se llama a todas las funciones declaradas en maitre.ads y desarrolladas en
    -- maitre.adb, se usan para realizar una simulación y mostrarla por consola.
    ---------------------------------------------------------------------------
    
procedure rest_solitaris is

    ---------------------------------------------------------------------------
    -- El archivo rest_solitaris.adb es el que se ejecuta y por tanto el que
    -- actúa como archivo principal. Sin embargo, no tiene una función o
    -- método main. Lo que se hace en este archivo es declarar y desarrollar
    -- la tarea que hace el comensal, y llamar a estas desde un bloque de
    -- código comprendido entre un begin y un end. Lo que se encuentra entre
    -- este begin y end es el código que actuará como "main" del programa.
    -- Será desde ahí desde donde se llame a la tarea del comensal mediante
    -- "Start".
    ---------------------------------------------------------------------------
    
    -----> AUXILIAR
    -- Función auxiliar que permite el paso de String a Unbounded_String
    function "+"(Source : String) return unbounded_string renames 
    Ada.strings.unbounded.to_unbounded_string;

    -----> VARIABLES
    ---------------------------------------------------------------------------
    -- Array de Unbounded_String (nombres) con el que se tratará posteriormente
    type Nombres is array(1..7) of Unbounded_String;

    -----> CONSTANTES
    ---------------------------------------------------------------------------
    ---> Array de nombres de los procesos no fumador (7 procesos, 7 nombres)
    NOMBRES_NO_FUMADORES: constant Nombres := (+"Mario", +"Luismi", +"Aregosti", +"Chacha", +"Enrike", +"Balerto", +"FalipAntoni");
    ---> Array de nombres de los procesos fumador (7 procesos, 7 nombres)
    NOMBRES_FUMADORES: constant Nombres :=  (+"Dijkstra", +"Dekker", +"Lamport" ,+"Ricart", +"Argawala", +"Peterson", +"Mizuno");
    ---> Monitor maitre de tipo protegido
    monitor: maitreMonitor;


    -----> DEFINICIÓN Y ESPECIFICACIÓN DE LA TAREA QUE HACE UN COMENSAL
    task type tareaComensal is
        entry Start(s: in Salas; t: in Integer; id: in Integer; n: in Unbounded_String);
    end tareaComensal;

    -----> DESARROLLO DEL CUERPO/BODY DE LA TAREA
    task body tareaComensal is
    ---> Variables
        tipoC: Integer;                 ---> Tipo de conmensal
        nombreC: Unbounded_String;      ---> Nombre del comensal
        idC: Integer;                   ---> Id del comensal
        salones: Salas;                 ---> Lista de salones
    begin
        accept Start(s: in Salas; t: in Integer; id: in Integer; n: in Unbounded_String) do
            tipoC := t;                 ---> Tipo de conmensal
            nombreC := n;               ---> Nombre del comensal
            idC := id;                  ---> Id del comensal
            salones := s;               ---> Lista de salones
        end Start;
        
        -- Se comrpobará el tipo de comnensal, ya que esto es lo que nos permitirá saber qué función, entry
        -- o procedure llamar. Cuando sepamos el tipo, llamaremos a estas y haremos los prints necesarios
        -- para mostrar los resultados de la simulación

        ---> El salón es de fumadores
        if tipoC = SALON_FUMADORES then
            ---> Prints de la simulación 
            Put_Line("BON DIA som en "& nombreC &" i som fumador");
            ---> El proceso fumador entra en el salón llamando al entry de procesos fumadores
            monitor.entrarSalaFumadores(idC,nombreC);   -- Llamada al entry para el proceso idC
            ---> Prints de la simulación
            Put_Line("En "& nombreC &" diu: Prendre el menu del dia. Som al salo "& monitor.getFumadores(idC)'Img);
            ---> Los comensales tardan un tiempo en comer
            delay(2.5); -- Tiempo que se tarda en comer
            ---> Prints de la simulación
            Put_Line("En "&nombreC &" diu: Ja he dinat, el compte per favor");
            ---> El proceso fumador sale del salón llamando al procedure de procesos fumadores 
            monitor.salirSalonFumadores(idC, nombreC);  -- Llamada el procedure para salir del salón
            ---> Prints de la simulación
            Put_Line("En "& nombreC &" SE'N VA");
        else 
            ---> El salón es de no fumadores
            if tipoC = SALON_NO_FUMADORES then
                ---> Prints de la simulación 
                Put_Line("BON DIA som en "& nombreC &" i som no fumador");
                ---> El proceso no fumador entra en el salón llamando al entry de procesos no fumadores
                monitor.entrarSalaNoFumadores(idC,nombreC);     -- Llamada al entry para el proceso idC
                ---> Prints de la simulación
                Put_Line("En "& nombreC &" diu: Prendre el menu del dia. Som al salo "& monitor.getNoFumadores(idC)'Img);
                ---> Los comensales tardan un tiempo en comer
                delay(2.5); -- Tiempo que se tarda en comer
                ---> Prints de la simulación
                Put_Line("En "& nombreC &" diu: Ja he dinat, el compte per favor");
                ---> El proceso no fumador sale del salón llamando al procedure de procesos no fumadores
                monitor.salirSalonNoFumadores(idC, nombreC);    -- Llamada el procedure para salir del salón
                ---> Prints de la simulación
                Put_Line("En "& nombreC &" SE'N VA");
            end if;
        end if;
        ---> Fin de la tarea y por tanto de las acciones que hacen los comensales
    end tareaComensal;

    ---------------------------------------------------------------------------
    -----> DESARROLLO DEL CÓDIGO DE TIPO 'MAIN'
    ---------------------------------------------------------------------------

    -----> VARIABLES
    type comensalesFumadores is array(1..NUM_FUMADORES) of tareaComensal;       ---> Definimos un tipo de array de comensales fumadores
    type comensalesNoFumadores is array(1..NUM_NO_FUMADORES) of tareaComensal;  ---> Definimos un tipo de array de comensales no fumadores
    comensalesF: comensalesFumadores;           ---> Creamos un array de tipo fumadores definido anteriormente
    comensalesNF: comensalesNoFumadores;        ---> Creamos un array de tipo no fumadores definido anteriormente


-----> BLOQUE DE CÓDIGO QUE ACTÚA COMO FUNCIÓN MAIN
begin
    -- Desde aquí se llama a la tarea comensal mediante Start, que a su vez, llama a los procedures,
    -- entries y funciones declaradas y desarrolladas en maitre.ads y maitre.adb respectivamente.
    -- De esta forma se hará la simulación de los comensales de tipos fumadores y no fumadores entrando
    -- y saliendo de los salones de forma concurrente sin que se produzcan quejas

    ---> Prints de la simulación
    Put_Line("++++++++++ El Maitre esta preparat");
    Put_Line("++++++++++ Hi ha " & NUM_SALONES'Img & " salons amb capacitat de " & NUM_MESAS_POR_SALON'Img & " comensals cada un");

    ---> Inicialización de los salones y los comensales
    -- Primero se inicializa los salones ya que en la inicialización de los comensales se tiene que asignar un
    -- salón ya inicializado
    monitor.initSalones;        ---> Inicialización de salones
    monitor.initComensales;     ---> Inicialización de comensales

    ---> Inicialización de las tareas de los comensales fumadores
    for i in NOMBRES_FUMADORES'Range loop
        ---> Se inicializa a cada comensal del array
        comensalesF(i).Start(monitor.getSalones,SALON_FUMADORES,i,NOMBRES_FUMADORES(i));
    end loop;

    ---> Inicialización de las tareas de los comensales no fumadores
    for i in NOMBRES_NO_FUMADORES'Range loop
        ---> Se inicializa a cada comensal del array
        comensalesNF(i).Start(monitor.getSalones,SALON_NO_FUMADORES,i,NOMBRES_NO_FUMADORES(i));
    end loop;

-----> FIN DEL ARCHIVO REST_SOLITARIS.adb
end rest_solitaris;