//=======================================================================================================================
// 		PRACTICA 3 - PROGRAMACIÓN CONCURRENTE
// 		Mario Ventura & Luis Miguel Vargas
//		ARCHIVO: chef.go
// 		Curso 2022 - 2023
// 		UIB - Grado en Ingeniería Informática - GIN3
//		ENLACE AL VÍDEO ----> https://youtu.be/T002g3itw2I
//=======================================================================================================================

package main

// -----> IMPORTS
import (
	"fmt"
	"math/rand"
	"time"

	"github.com/streadway/amqp"
)

// -----> STRUCTS
type rolloSushi struct {
	tipoRollo     string
	cantidadRollo int
}
type Empty struct{}

// -----> VARIABLES
// Plato: Array que contendrá objetos del tipo rolloSushi
var plato = []rolloSushi{}

// Tipos de sushi definidos para la simulación
var tipoRollo = []string{"Nigiri de salmón", "Sashimi de atún", "Maki de cangrejo"}

// =======================================================================================================================
//
//	FUNCIONES
//
// =======================================================================================================================
// -----> FUNCIÓN MAIN QUE USA TODAS LAS FUNCIONES Y VARIABLES DEFINIDAS A LO LARGO DEL ARCHIVO
func main() {

	// Creamos el canal done donde el chef indicará posteriormente con un mensaje que ya ha acabado de cocinar
	done := make(chan Empty, 1) // Inicialmente está vacío
	// Creamos un enlace a RabbitMQ
	conexion, error := amqp.Dial("amqp://guest:guest@localhost:5672/")
	// Control de posibles errores
	errorHandle(error)
	// Cerrar conexión
	defer conexion.Close()
	// Creamos un canal
	channel, error := conexion.Channel()
	// Control de posibles errores
	errorHandle(error)
	// Cerrar conexión
	defer channel.Close()

	// Creamos una cola de mensajes/permisos con la función "QueueDeclare". Esta cola tendrá el nombre sushiQueue, y será durable,
	// con autoDelete, exclusiva, no hay espera, y sin argumentos adicionales
	sushiQueue, error := channel.QueueDeclare("sushiQueue", false, false, false, false, nil)
	errorHandle(error) //Control de posibles errores
	// Creamos una cola de mensajes/permisos con la función "QueueDeclare". Esta cola tendrá el nombre colaPermisosClientes,
	// y será durable, con autoDelete, exclusiva, no hay espera, y sin argumentos adicionales
	colaPermisosClientes, permisoError := channel.QueueDeclare("colaPermisosClientes", false, false, false, false, nil)
	errorHandle(permisoError) // Control de posibles errores

	// Llamada a la función preprararSushi
	go prepararSushi(channel, sushiQueue, colaPermisosClientes, done)
	// Lectura del canal done (Leer y quedar a la espera de que se añada ahí el mensaje de que ya se ha acabado)
	// El envío de este mensaje al canal done se hace en la línea 120 de código, en la función prepararSushi
	<-done
}

// -----> FUNCIÓN PREPARARSHUSHI QUE PERMITE QUE EL CHEF PREPARE LAS CANTIDADES DE CADA TIPO DE SUSHI
func prepararSushi(channel *amqp.Channel, queue amqp.Queue, colaPermisosClientes amqp.Queue, done chan Empty) {

	// Número aleatorio
	rand.Seed(time.Now().UnixNano()) // Asegura aleatoriedad en cada simulación

	// El cocinero llega, saluda y decide cuantas piezas de sushi pondrá en el plato
	fmt.Println("-----> EL MAESTRO SUSHI HA LLEGADO") // El maestro saluda
	fmt.Println("En el menú de hoy tenemos:")         // Anuncia lo que va a preparar

	// Se calcula los rollos de sushi que se harán de cada tipo
	numSashimi := rand.Intn(10)            // Numero de piezas de Sashimi
	numMaki := rand.Intn(10 - numSashimi)  // Numero de piezas de Maki
	numNigiri := 10 - numSashimi - numMaki // Numero de piezas de Nigiri

	// Mostrar por consola el nº de piezas de la simulación
	fmt.Printf("Un total de %d piezas de %s, %d piezas de %s y %d de %s\n", numNigiri, tipoRollo[0], numSashimi, tipoRollo[1], numMaki, tipoRollo[2])
	plato = append(plato, rolloSushi{tipoRollo[0], numNigiri})  // Añadir al array plato
	plato = append(plato, rolloSushi{tipoRollo[1], numSashimi}) // Añadir al array plato
	plato = append(plato, rolloSushi{tipoRollo[2], numMaki})    // Añadir al array plato

	// Se hacen las piezas correspondientes
	for _, piezaSushi := range plato {
		// Se hacen el numero de piezas pactado de cada tipo
		for i := 0; i < piezaSushi.cantidadRollo; i++ {
			body := piezaSushi.tipoRollo
			// Mensaje en el canal dado por parametro
			error := channel.Publish("", queue.Name, false, false, amqp.Publishing{ContentType: "text/plain", Body: []byte(body)})
			// Gestión de los posibles errores
			errorHandle(error)
			// Sleep de un tiempo "ciertamente" aleatorio
			time.Sleep(1 * time.Second)
			// Impresión por consola
			fmt.Printf("%s ---> EL CHEF HA PREPARADO LA PIEZA %s Y LA AÑADE AL PLATO ¡(o)¡\n", time.Now().Format("2006/01/02 15:04:05"), piezaSushi.tipoRollo)
		}
	}

	// Al acabar de llenar el plato el cocinero avisa a  los clientes y estos ya pueden comer, después de que el cocinero acabe
	// Esto es en realidad, la publicación de un mensaje en el canal de permisos 'qPermit', que es el que permite a los clientes
	// comer los rollos de sushi que ha preparado el chef
	errPermit := channel.Publish("", colaPermisosClientes.Name, false, false, amqp.Publishing{ContentType: "text/plain", Body: []byte("10")})
	// Gestionar con la función errHandle los posibles errores que puedan haberse dado en la instrucción anterior
	errorHandle(errPermit)
	// El maestro del sushi avisa a los clientes de que ya pueden empezar a comer (simulacion)
	fmt.Println("\n -----> YA PUEDEN USTEDES EMPEZAR A COMER - exclamó el chef")
	// Se mete en el canal done un mensaje vacío para informar de que se ha acabado (es como activar una señal)
	done <- Empty{}
}

// =======================================================================================================================
// -----> FUNCIÓN QUE PERMITE LA GESTIÓN E IMPRESIÓN DE ERRORES QUE PUEDAN DARSE
func errorHandle(ERROR error) {
	if ERROR != nil {
		fmt.Println(ERROR) //Imprimiremos el error para saber qué ha sucedido
		panic(ERROR)
	}
}

// =======================================================================================================================
