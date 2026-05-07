const readline = require('readline');

// Importa la lógica del juego
const GameLoop = require('./gameLoop');

// Crea nueva partida
const game = new GameLoop();

// Permite leer comandos desde terminal
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// Función principal del bucle
function pedirComando() {

    // Muestra tablero
    console.log(game.render());

    // Si modo trampa activo, muestra toda la lava
    if (game.estado.trampaActiva) {

        console.log("--- TABLERO TRAMPA ---");
        console.log(game.render(true));
    }

    // Espera comando del usuario
    rl.question("Escribe un comando: ", (input) => {

        // Divide comando por palabras
        const parts = input.trim().split(" ");

        const cmd = parts[0].toLowerCase();
        const arg = parts[1];
        const archivo = parts[2];

        switch (cmd) {

            // Ayuda
            case 'ayuda':
            case 'help':

                console.log(`
                    [ayuda]
                    [mover arriba]
                    [mover abajo]
                    [mover izquierda]
                    [mover derecha]
                    [puntuacion]
                    [activar trampa]
                    [desactivar trampa]
                    [guardar partida archivo.json]
                    [cargar partida archivo.json]
                                    `);

                break;

            // Movimiento
            case 'mover':

                const resultado = game.mover(arg);

                console.log("\n" + resultado.msg);

                // Si gana o pierde, termina juego
                if (
                    resultado.status === "win" ||
                    resultado.status === "lose"
                ) {

                    process.exit();
                }

                break;

            // Activar modo trampa
            case 'activar':

                if (arg === 'trampa') {

                    game.estado.trampaActiva = true;
                }

                break;

            // Desactivar modo trampa
            case 'desactivar':

                if (arg === 'trampa') {

                    game.estado.trampaActiva = false;
                }

                break;

            // Mostrar puntuación
            case 'puntuacion':

                const dist =
                    Math.abs(game.estado.destino.r - game.estado.posicion.r) +
                    Math.abs(game.estado.destino.c - game.estado.posicion.c);

                console.log(`
                    Puntos restantes: ${game.estado.puntos}
                    Distancia al destino: ${dist}
                    `);

                break;

            // Guardar partida
            case 'guardar':

                if (arg === 'partida') {

                    game.guardar(archivo);

                    console.log("Partida guardada.");
                }

                break;

            // Cargar partida
            case 'cargar':

                if (arg === 'partida') {

                    if (game.cargar(archivo)) {

                        console.log("Partida cargada.");

                    } else {

                        console.log("Error: archivo no encontrado.");
                    }
                }

                break;

            // Comando inválido
            default:

                console.log("Comando desconocido.");
        }

        // Repite bucle
        pedirComando();
    });
}

// Mensaje inicial
console.log("BIENVENIDO A FLOOR IS LAVA");

// Inicia el juego
pedirComando();
