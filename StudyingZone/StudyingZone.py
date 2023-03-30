#=======================================================================================================================
# PRACTICA 1 - PROGRAMACIÓN CONCURRENTE
# Mario Ventura & Luis Miguel Vargas
# Curso 2022 - 2023
# UIB - Grado en Ingeniería Informática - GIN3
# ENLACE AL VIDEO: https://youtu.be/qqHiw7C-flw
#=======================================================================================================================

# -----> IMPORTS
import threading
from random import randint
import time


# -----> VARIABLES
numEstdiantesEnSala = 0                 # Numero de estudiantes dentro la sala
numBloqueados = 0                       # Numero de estudiantes bloqueados
rondaActual = 0                         # Ronda actual


# -----> CONSTANTES
NUM_ESTUDIANTES = 10                    # Numero de estudiantes de la simulacion
MAX_ESTUDIANTES = 4                     # Capacidad de la sala en alumnos (SC)
NUM_RONDAS = 3                          # Numero de simulaciones que se harán


# NOMBRES DE LOS ESTUDIANTES (aleatorio)
NOMBRES_ESTUDIANTES = ["Mario", "Luismi", "Aregosti", "Chacha", "Enrike",
                       "Albert", "FalipAntoni", "Dijkstra", "Dekker",
                        "Lamport", "Argawala", "Ricart", "Peterson"]        # 13 en total


# -----> SEMÁFOROS
mutexSALA = threading.Lock()                # PARA CONTROLAR ACCESO CONCURRENTE A SALA
semALUMNOS = threading.Semaphore(1)         # PARA CONTROLAR LOS ESTUDIANTES
semDIRECTOR_IN = threading.Semaphore(1)     # PARA CONTROLAR AL DIRECTOR CUANDO HAY ALUMNOS EN LA SALA
semDIRECTOR_OUT = threading.Semaphore(0)    # PARA CONTROLAR AL DIRECTOR FUERA SI NO HAY FIESTA


# -----> ESTADOS DEL DIRECTOR
FUERA = 0
ESPERANDO = 1
DENTRO = 2
estadoDirector = FUERA  # inicialmente el director está fuera



#=======================================================================================================================
#                                                   CLASE ESTUDIANTE
#=======================================================================================================================
class Estudiante(threading.Thread):

    # ----------< ATRIBUTOS >----------
    id = ""

    # ----------< FUNCIONES >----------
    # -----> CONSTRUCTOR
    def __init__(self, i):
        super().__init__()                  # Llamada a la clase madre
        self.id = NOMBRES_ESTUDIANTES[i]    # El estudiante se inicializa con un nombre aleatorio del array

    # -----> FUNCIÓN QUE PERMITE Y CONTROLA EL ACCESO A LA SALA
    def entrar(self):

        time.sleep(randint(4, 8))       # Se duerme un tiempo aleatorio
        mutexSALA.acquire()             # El estudiante coge el mutex para entrar a la sala
        global numEstdiantesEnSala      # Numero de estudiantes en la sala, se usará posteriormente

        # Comprobar si el director está dentro de la sala. Si es así el estudiante soltará el mutex y esperará a que
        # este salga. Cuando esto suceda, volverá a coger el mutex
        if (estadoDirector == DENTRO):
            mutexSALA.release()
            semALUMNOS.acquire()
            mutexSALA.acquire()

        numEstdiantesEnSala += 1          # El estudiante entra, aumenta el numero de alumnos en la sala
        print(self.id, " entra en la sala, nº de estudiantes: ", numEstdiantesEnSala)

        # Si es el primer estudiante, evitará que el director entre
        if (numEstdiantesEnSala == 1):
            mutexSALA.release()
            semDIRECTOR_IN.acquire()            # Se bloquea
            mutexSALA.acquire()

        # Comprobar si la cantidad de estudiantes en la sala actualmente es la cantidad permitida
        if (numEstdiantesEnSala < MAX_ESTUDIANTES):
            # Aforo permitido
            print(self.id, ": estamos estudiando concurrencia...")              # Si no se supera el maximo no se hace fiesta
        else:
            # Aforo no permitido
            print(self.id, ": ¡¡¡ MENUDO FIESTOTE MI COMPADRE !!!")             # Hay fiesta
            # Comprobar si el director esta fuera de la sala esperando
            if (estadoDirector == ESPERANDO):
                print(self.id, ": ¡¡¡ CUIDADO, QUE HA ENTRADO EL DIRECTOR!!!")  # El último en entrar ha llamado la atención al director
                semDIRECTOR_OUT.release()                                       # El director se da cuenta, entra en la sala y echa a todos
        mutexSALA.release()             # El estudiante que sale deja entrar a otro a la sala

    # -----> FUNCIÓN QUE PERMITE Y CONTROLA LA SALIDA DE LA SALA
    def salir(self):

        mutexSALA.acquire()                         # El alumno coge el mutex de salida
        global numEstdiantesEnSala                  # Numero de estudiantes en la sala, se usará posteriormente
        numEstdiantesEnSala -= 1                    # El estudiante sale, disminuye el numero de estudiantes

        # Mostrar cantidad de alumnos actuales en la sala
        print(self.id, " sale de la sala, quedan ",numEstdiantesEnSala," estudiantes")

        # Comprobar el nº de estudiantes que quedan. Si no queda ninguno y el director está esperando fuera,
        # el director se despierta
        if (numEstdiantesEnSala == 0 and estadoDirector == ESPERANDO):
            print(self.id, ": Disculpe señor Director, no volverá a suceder")
            semDIRECTOR_OUT.release()
            semALUMNOS.release()            # El director puede entrar

        # Comprobar el nº de estudiantes que quedan. Si no queda ninguno y el director está dentro, hará que salgan
        # y luego saldrá él
        if (numEstdiantesEnSala == 0 and estadoDirector == DENTRO):
            print(self.id, ": Disculpe señor Director, no volverá a suceder")
            semDIRECTOR_IN.release()
            semALUMNOS.release()            # Sale cuando todos han salido

        mutexSALA.release()                 # El estudiante que sale deja entrar a otro a la sala

    # ----> FUNCIÓN QUE PERMITE LA ACCIÓN DE LOS ESTUDIANTES
    def run(self):
        self.entrar()                   # El estudiante entra en la sala a estudiar/hacer fiesta
        time.sleep(randint(1,4))        # Sleep de un tiempo aleatorio (pasa un tiempo en la sala)
        self.salir()                    # El estudiante sale de la sala


#=======================================================================================================================
#                                                   CLASE DIRECTOR
#=======================================================================================================================
class Director(threading.Thread):

    # ----------< FUNCIONES >----------
    # -----> CONSTRUCTOR
    def __init__(self):
        super().__init__()              # Llamada a la clase madre

    # -----> FUNCIÓN QUE PERMITE DESBLOQUEAR PROCESOS ALUMNO QUE QUERÍAN ENTRAR A LA SALA QUE YA ESTÁ SIENDO DESALOJADA
    #        POR EL DIRECTOR
    def desbloquea(self):

        mutexSALA.acquire()  # Coge el mutex
        global estadoDirector           # Estado del director

        # Recorre toda la lista de estudiantes y desbloque a aquellos que estaban esperando para entrar en la sala a
        # hacer fiesta antes de que el director interrumpiese la fiesta
        for i in range(numBloqueados - 1):
            semALUMNOS.release()

        semDIRECTOR_IN.release()        # Los estudiantes pueden volver a entrar
        mutexSALA.release()             # Suelta el mutex

    # -----> FUNCIÓN QUE PERMITE LA ACCIÓN DEL PROCESO DIRECTOR
    def run(self):

        # Variables que se usarán posteriormente
        global numEstdiantesEnSala, estadoDirector, rondaActual, NUM_RONDAS, numBloqueados

        # Iteración que permite hacer todas las rondas establecidas en la constante NUM_RONDAS
        for i in range(NUM_RONDAS):
            mutexSALA.acquire()                 # Coge el mutex
            rondaActual += 1                    # Aumenta el contador de rondas

            #Indicar por consola el inicio de la ronda para hacer más visual la simulación
            print("=========================================")
            print("     El director comienza la ronda")
            print("=========================================")

            # Comprobar cuantos alumnos hay en la sala
            if (numEstdiantesEnSala == 0):
                # Todavía no hay nadie
                print(" -----> Todavía no hay nadie en la sala de estudio")
                mutexSALA.release()         # Suelta el mutex
            else:
                # Hay gente en la sala pero no hay fiesta
                if (numEstdiantesEnSala < MAX_ESTUDIANTES):
                    print(" -----> El director no entra porque hay alumnos estudiando")
                    estadoDirector = ESPERANDO
                    mutexSALA.release()             # Suelta el mutex permitiendo la entrada a más estudiantes
                    semDIRECTOR_OUT.acquire()       # Se bloquea al director
                    mutexSALA.acquire()             # Al desbloquearse, coge el mutex

                    # El director se ha dado cuenta de que hay fiesta
                    if (numEstdiantesEnSala != 0 and MAX_ESTUDIANTES <= numEstdiantesEnSala):
                        estadoDirector = DENTRO
                        print(" -----> El director para la fiesta: ¡¡¡ AQUÍ NO SE PUEDEN HACER FIESTAS !!!")
                        numBloqueados = (NUM_ESTUDIANTES - numEstdiantesEnSala)     # Nº de estudiantes bloqueados
                        mutexSALA.release()                 # Los estudiantes deben irse
                        semALUMNOS.acquire()                # No pueden entrar más alumnos a la sala
                        semDIRECTOR_IN.acquire()            # Se bloquea al director
                        self.desbloquea()                   # Se desbloquean el resto de alumnos que estaban esperando

                    elif (numEstdiantesEnSala == 0):
                        print(" -----> No hay nadie en la sala de estudio")
                        mutexSALA.release()                 # Se libera el mutex

                # El director se ha dado cuenta de que hay fiesta
                else:
                    estadoDirector = DENTRO
                    print(" -----> El director para la fiesta: ¡¡¡ AQUÍ NO SE PUEDEN HACER FIESTAS !!!")
                    numBloqueados = (NUM_ESTUDIANTES - numEstdiantesEnSala)  # Nº de estudiantes bloqueados
                    mutexSALA.release()                     # Los estudiantes deben irse
                    semALUMNOS.acquire()                    # No pueden entrar más alumnos a la sala
                    semDIRECTOR_IN.acquire()                # Se bloquea al director
                    self.desbloquea()                       # Se desbloquean el resto de alumnos que estaban esperando

            # Mostrar por consola la finalización de la simulación de la ronda
            print("----> El director termina su ronda de vigilancia", (rondaActual))
            # El director sale fuera de la sala
            estadoDirector = FUERA
            # El director va a darse un paseo tras acabar su ronda
            time.sleep(randint(1,7))


#=======================================================================================================================
# -----> FUNCIÓN MAIN
def main():

    # Lista de estudiantes para la simulación
    estudiantes = []
    #Presentación de la simuñación
    print("SIMULACIÓN SALA DE ESTUDIO")
    print("Número de esudiantes de la simulación -----> ", NUM_ESTUDIANTES)
    print("Máximo de estudiantes en la sala ----------> ", MAX_ESTUDIANTES)
    print("\n\n")
    # Se crea al proceso director
    director = Director()
    # Se crean los estudiantes y se añaden a la lista
    for i in range(NUM_ESTUDIANTES):
        estudiantes.append(Estudiante(i))           # Se añade al estudiante

    # Se inician los procesos
    director.start()
    for e in estudiantes:
        e.start()

    # Se debe esperar a que todos los procesos acaben para finalizar
    director.join()
    for e in estudiantes:
        e.join()


if __name__ == "__main__":
    main()
#=======================================================================================================================