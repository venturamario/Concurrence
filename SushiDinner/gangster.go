//=======================================================================================================================
// 		PRACTICA 3 - PROGRAMACIÓN CONCURRENTE
// 		Mario Ventura & Luis Miguel Vargas
//		ARCHIVO: gangster.go
// 		Curso 2022 - 2023
// 		UIB - Grado en Ingeniería Informática - GIN3
//=======================================================================================================================

package main

// -----> IMPORTS
import (
	"fmt"

	"github.com/streadway/amqp"
)

// -----> STRUCTS
type Empty struct{} // Mensaje vacío

// -----> FUNCIÓN MAIN
func main() {

	// Creamos el canal done con un mensaje inicialmente vacío
	done := make(chan Empty, 1) // Mensaje empty
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
	permisosClientes, errorPermisos := channel.QueueDeclare("colaPermisosClientes", false, false, false, false, nil)
	errorHandle(errorPermisos) //Control de posibles errores

	//Llamada a la función gangster
	go gangster(channel, permisosClientes, done)
	// Lectura del canal done (Leer y quedar a la espera de que se añada ahí el mensaje de que ya se ha acabado)
	// El envío de este mensaje al canal done se hace en la línea XXX de código, en la función gangster()
	<-done
}

// -----> FUNCIÓN QUE PERMITE LA ACCIÓN DEL PROCESO GANGSTER
func gangster(channel *amqp.Channel, colaPermisosClientes amqp.Queue, done chan Empty) {

	// ----- PRINTS PARA LA SIMULACIÓN DE LOS DIÁLOGOS DEL GANGSTER -----
	fmt.Println("GANGSTER: ¡¡¡ Todos quietos !!!")
	fmt.Println("GANGSTER: ¡¡¡ Estoy hambriento !!!")

	// Debemos esperar a que el chef haya terminado de cocinar para que nos dé permiso para comer, ya que no se puede
	// comer una comida que todavía no se ha preparado. Cuando haya acabado, depositará un mensaje en el canal.
	// Este canal será durable, exclusivo, no hay espera, y sin argumentos adicionales
	// Acabado esto, borraremos los mensajes de la cola de mensajes
	permiso, err := channel.Consume(colaPermisosClientes.Name, "", true, false, false, false, nil)
	errorHandle(err)
	perm := <-permiso

	//----- PRINTS PARA LA SIMULACION -----
	fmt.Printf("-----> El gangster engulle las %s piezas que quedaban\n", string(perm.Body))
	channel.QueuePurge("sushiQueue", false)
	fmt.Println("GANGSTER: ¡¡¡ ESTABA TODO MALÍSIMO !!!")
	fmt.Println("-----> El gangster destroza el plato y se marcha enfadado")
	fmt.Println("GANGSTER: ¡¡¡ ME VOY DE ESTE CUCHITRIL !!!")
	// Se añade el mensaje vacío al canal indicando a la función main que la función gangster() ya ha acabado. Cuando main()
	// lea este mensaje se dará cuenta de esto y continuará su ejecución
	done <- Empty{}
}

// =======================================================================================================================
// -----> FUNCIÓN QUE PERMITE EL CONTROL DE ERRORES
func errorHandle(err error) {
	if err != nil {
		fmt.Println(err) // Control de errores
		panic(err)
	}
}

// =======================================================================================================================
