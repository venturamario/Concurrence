//=======================================================================================================================
// 		PRACTICA 3 - PROGRAMACIÓN CONCURRENTE
// 		Mario Ventura & Luis Miguel Vargas
//		ARCHIVO: cliente.go
// 		Curso 2022 - 2023
// 		UIB - Grado en Ingeniería Informática - GIN3
//=======================================================================================================================

package main

// -----> IMPORTS
import (
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/streadway/amqp"
)

// -----> STRUCTS
type Empty struct{}

// =======================================================================================================================
//
//	FUNCIONES
//
// =======================================================================================================================

// -----> FUNCIÓN MAIN QUE USA TODAS LAS FUNCIONES Y VARIABLES DEFINIDAS A LO LARGO DEL ARCHIVO
func main() {

	// Creamos el canal done con un mensaje inicialmente vacío
	done := make(chan Empty, 1)
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
	error = channel.Qos(1, 0, false)

	// Llamada a la función cliente
	go cliente(channel, sushiQueue, colaPermisosClientes, done)
	// Lectura del canal done (Leer y quedar a la espera de que se añada ahí el mensaje de que ya se ha acabado)
	// El envío de este mensaje al canal done se hace en la línea 124 de código, en la función cliente
	<-done
}

// -----> FUNCIÓN CLIENTE QUE PERMITE QUE UN CLIENTE COMA UN NUMERO ALEATORIO DE ROLLOS DE SUSHI
func cliente(channel *amqp.Channel, queue amqp.Queue, colaPermisosClientes amqp.Queue, done chan Empty) {

	// El numero de rollos de sushi que come el cliente es aleatorio para dar mas realismo a la simulacion
	rand.Seed(time.Now().UnixNano())
	numRollosSushi := rand.Intn(10)

	// ----- PRINTS PARA LA SIMULACIÓN -----
	fmt.Println("CLIENTE: A ver qué me como hoy... ")
	fmt.Printf("CLIENTE: Venga hoy me comeré %d piezas de sushi\n", numRollosSushi)

	// Debemos esperar a que el chef haya terminado de cocinar para que nos dé permiso para comer, ya que no se puede
	// comer una comida que todavía no se ha preparado. Cuando haya acabado, depositará un mensaje en el canal.
	// Este canal será durable, con autoDelete, exclusiva, no hay espera, y sin argumentos adicionales
	permisoChef, err := channel.Consume(queue.Name, "", false, false, false, false, nil)
	errorHandle(err) // Posibles errores
	// Este canal será durable, con autoDelete, exclusiva, no hay espera, y sin argumentos adicionales
	permisos, err := channel.Consume(colaPermisosClientes.Name, "", false, false, false, false, nil)
	errorHandle(err) // Posibles errores

	// Contador de permisos
	var numPermisos int

	// Se recorre los n rollos de sushi que el cliente comerá. Cada iteración es un rollo de sushi que se come
	for i := 0; i < numRollosSushi; i++ {

		//PERMISOS
		for permiso := range permisos {
			numPermisos, _ = strconv.Atoi(string(permiso.Body))
			permiso.Ack(false)
			break
		}

		// Cada vez que se come un rollo, hay un rollo de sushi menos, y por tanto, un permiso menos
		numPermisos = numPermisos - 1

		// MENSAJES: se imprime por pantalla cada vez que se coge un rollo de sushi
		for mensaje := range permisoChef {
			// Impresión por pantalla
			fmt.Printf("%s Ha cogido el rollo de: %s\n", time.Now().Format("2006/01/02 15:04:05"), string(mensaje.Body))
			// Sleep un tiempo "ciertamente" aleatorio
			time.Sleep(1 * time.Second)
			// Acuse de recibo manual
			mensaje.Ack(false)
			// Se sale de la iteración
			break
		}
		// ----- PRINTS PARA LA SIMULACIÓN -----
		fmt.Printf("-----> Quedan %d rollos de sushi en el plato\n", numPermisos)
		// Gestión de los posibles errores que puedan darse
		permisoError := channel.Publish("", colaPermisosClientes.Name, false, false, amqp.Publishing{ContentType: "text/plain", Body: []byte(strconv.Itoa(numPermisos))})
		errorHandle(permisoError)
	}

	// Notificar al canal done el fin de la ejecución
	fmt.Println("CLIENTE: ¡¡¡ Que rico estaba !!!")
	fmt.Println("CLIENTE: Creo que de momento tengo bastante...")
	// Se añade el mensaje vacío al canal indicando a la función main que la función cliente ya ha acabado. Cuando main() lea este
	// mensaje se dará cuenta de esto y continuará su ejecución
	done <- Empty{}
}

// =======================================================================================================================
// -----> FUNCIÓN QUE PERMITE CONTROLAR LOS POSIBLES ERRORES QUE PUEDAN SUCEDER
func errorHandle(err error) {
	if err != nil {
		fmt.Println(err) // Imprimir el error por pantalla
		panic(err)
	}
}

// =======================================================================================================================
