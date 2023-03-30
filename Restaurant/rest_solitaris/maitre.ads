---------------------------------------------------------------------------
--------- PRÁCTICA 2 - PROGRAMACIÓN CONCURRENTE
--------- Mario Ventura & Luis Miguel Vargas
--------- Curso 2022-2023
--------- UIB - Grado en Ingeniería Informática - GIN3
---------------------------------------------------------------------------
--------- ENLACE AL VÍDEO: https://youtu.be/5C6OrnlUXss

---------------------------------------------------------------------------
with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;

    -- Archivo .ads para establecer las especificaciones necesarias del programa en Ada
    -- correspondiente. maitre.ads corresponde al programa maitre.adb.
    -- Aquí se establecen las variables, constantes, monitores, etc... que se usarán en
    -- el desarrollo del programa general

package maitre is
    
    -- Programar la simulació descrita per a 7 processos fumador i 7 processos no fumador
    -- suposant que el restaurant té 3 salons on hi caben 3 taules / comensals a cada un

    ----->  DECLARACIÓN DE CONSTANTES
    NUM_MESAS_POR_SALON: constant integer := 3; ---> Número de mesas por cada salón
    NUM_SALONES: constant integer := 3;         ---> Número de salones
    NUM_NO_FUMADORES: constant integer := 7;    ---> Número de procesos no fumadores
    NUM_FUMADORES : constant integer := 7;      ---> Número de procesos fumadores
    
    -- Una vez que un proceso entra en uno de los salones, ese salón se convierte en un salón
    -- que podrá contener solo a ese tipo de procesos (salon de fumadores o no fumadores (o vacío)).
    -- Tendremos que establecer constantes que permitan diferenciar entre cada tipo de salón

    -----> TIPOS DE SALÓN
    SALON_VACIO : constant integer := 0;        ---> Salón vacío. Puede entrar cualquier tipo de proceso
    SALON_FUMADORES: constant integer := 1;     ---> Salón de procesos fumadores
    SALON_NO_FUMADORES: constant integer := 2;  ---> Salón de procesos no fumadores

    -----> STRUCT / TIPO QUE REPRESENTA UN SALÓN CON UN TIPO UN NÚMERO DE MESAS
    type Salon is record
        tipoSalon: Integer;                     ---> Tipo de salón (según el proceso que entre)
        mesasOcupadas: Integer;                 ---> Número de mesas ocupadas
    end record;

    -----> ARRAY DE SALONES, CON UN NÚMERO DE SALONES IGUAL A NUM_SALONES
    type Salas is array(1..NUM_SALONES) of Salon;

    -----> ARRAY DE COMENSALES QUE INDICA EN QUÉ SALA SE ENCUENTRA
    type Comensales is array(1..7) of Integer;  ---> n = Salón n

    -----> CREACIÓN DE UN MONITOR PROTEGIDO PARA EL MAITRE
    protected type maitreMonitor is
        -- En el monitor se declaran todas las funciones, procedures y entries
        -- de las que este consta. El cuerpo/código de estas se desarrollará en el
        -- archivo maitre.adb, y las llamadas se harán desde rest_solitaris.adb

        ---> Funciones del monitor
        function getNoFumadores return Comensales;                  ---> Getter de los comensales no fumadores
        function getFumadores return Comensales;                    ---> Getter de los comensales fumadores
        function getSalones return Salas;                           ---> Getter de los salones
        function notFull(tipo: Integer) return Boolean;             ---> Dice si queda espacio en el salón
        function salonDisponible(tipo: Integer) return Integer;     ---> Dice si el salón está disponible

        ---> Procedures del monitor
        procedure initComensales;           ---> Inicialización de los comensales
        procedure initSalones;              ---> Inicialización de los salones
        procedure salirSalonFumadores(id: Integer; nombre: Unbounded_String);   ---> Salir del salón de fumadores
        procedure salirSalonNoFumadores(id: Integer; nombre: Unbounded_String); ---> Salir del salón de no fumadores

        ---> Entries del monitor
        entry entrarSalaFumadores(id: Integer; nombre: Unbounded_String);    ---> Entry para fumadores 
        entry entrarSalaNoFumadores(id: Integer; nombre: Unbounded_String);  ---> Entry para no fumadores

        ---> Variables protegidas & privadas
        private
            comensalesFumadores: Comensales;        ---> Cada monitor tiene un array de comensales fumadores
            comensalesNoFumadores: Comensales;      ---> Cada monitor tiene un array de comensales no fumadores
            salones: Salas;                         ---> Cada monitor tiene una cantidad de salas (NUM_SALONES)
    end maitreMonitor;

-----> FIN DEL ARCHIVO DE ESPECIFICACIONES
end maitre;