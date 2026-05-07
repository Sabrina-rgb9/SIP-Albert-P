const fs = require('fs');

// Clase principal del juego.
// Aquí se guarda toda la lógica:
// - posición del jugador
// - lava
// - puntos
// - movimiento
// - guardado/carga
class GameLoop {

    constructor() {

        // Número de filas del tablero
        this.FILAS = 6;

        // Número de columnas
        this.COLUMNAS = 8;

        // Número total de casillas de lava
        this.LAVA_COUNT = 16;

        // Etiquetas para mostrar filas A-F
        this.FILAS_LABELS = ['A', 'B', 'C', 'D', 'E', 'F'];

        // Inicializa el juego
        this.reset();
    }

    // Reinicia el estado del juego
    reset() {

        this.estado = {

            // Posición inicial del jugador
            posicion: { r: 0, c: 0 },

            // Posición final (tesoro)
            destino: { r: 5, c: 7 },

            // Puntos iniciales
            puntos: 32,

            // Array donde se guardará la lava
            lava: [],

            // Modo trampa desactivado por defecto
            trampaActiva: false
        };

        // Generar lava aleatoria
        this.generarLava();
    }

    // Genera las casillas de lava
    generarLava() {

        while (this.estado.lava.length < this.LAVA_COUNT) {

            // Genera fila aleatoria
            let r = Math.floor(Math.random() * this.FILAS);

            // Genera columna aleatoria
            let c = Math.floor(Math.random() * this.COLUMNAS);

            // Comprueba si es la casilla inicial
            const esInicio = (r === 0 && c === 0);

            // Comprueba si es la casilla final
            const esDestino = (r === 5 && c === 7);

            // Comprueba si ya existe lava ahí
            const yaExiste = this.estado.lava.some(
                l => l.r === r && l.c === c
            );

            // Solo añade lava si no rompe las reglas
            if (!esInicio && !esDestino && !yaExiste) {

                this.estado.lava.push({
                    r,
                    c,
                    pisada: false
                });
            }
        }
    }

    // Calcula la distancia mínima a la lava más cercana
    getDistanciaLava() {

        let distancias = this.estado.lava.map(l =>

            Math.abs(l.r - this.estado.posicion.r) +
            Math.abs(l.c - this.estado.posicion.c)
        );

        return Math.min(...distancias);
    }

    // Movimiento del jugador
    mover(direccion) {

        // Copia posición actual
        let nuevaPos = { ...this.estado.posicion };

        // Modifica posición según dirección
        if (direccion === 'arriba') nuevaPos.r--;
        else if (direccion === 'abajo') nuevaPos.r++;
        else if (direccion === 'izquierda') nuevaPos.c--;
        else if (direccion === 'derecha') nuevaPos.c++;
        else {
            return {
                msg: "Dirección no válida.",
                status: "error"
            };
        }

        // Comprueba si sale del tablero
        if (
            nuevaPos.r < 0 ||
            nuevaPos.r >= this.FILAS ||
            nuevaPos.c < 0 ||
            nuevaPos.c >= this.COLUMNAS
        ) {

            return {
                msg: "Has perdido, has caído por un precipicio.",
                status: "lose"
            };
        }

        // Actualiza posición
        this.estado.posicion = nuevaPos;

        // Busca si hay lava en la casilla
        const lavaAqui = this.estado.lava.find(
            l => l.r === nuevaPos.r && l.c === nuevaPos.c
        );

        // Si pisa lava
        if (lavaAqui) {

            lavaAqui.pisada = true;

            this.estado.puntos--;

            // Sin puntos = derrota
            if (this.estado.puntos <= 0) {

                return {
                    msg: "Has perdido, ya no te quedan puntos.",
                    status: "lose"
                };
            }

            return {
                msg: "Has pisado lava, pierdes un punto.",
                status: "lava"
            };
        }

        // Comprueba victoria
        if (
            nuevaPos.r === this.estado.destino.r &&
            nuevaPos.c === this.estado.destino.c
        ) {

            return {
                msg: `Has ganado, llegaste al final con ${this.estado.puntos} puntos.`,
                status: "win"
            };
        }

        // Mensaje normal
        return {
            msg: `Vas por buen camino, tienes lava a ${this.getDistanciaLava()} casillas.`,
            status: "ok"
        };
    }

    // Dibuja tablero en texto
    render(revelar = false) {

        let output = "\n  01234567\n";

        for (let r = 0; r < this.FILAS; r++) {

            let fila = this.FILAS_LABELS[r];

            for (let c = 0; c < this.COLUMNAS; c++) {

                const esJugador =
                    this.estado.posicion.r === r &&
                    this.estado.posicion.c === c;

                const esDestino =
                    this.estado.destino.r === r &&
                    this.estado.destino.c === c;

                const lava = this.estado.lava.find(
                    l => l.r === r && l.c === c
                );

                if (esJugador) fila += "T";
                else if (esDestino) fila += "*";
                else if (lava && (revelar || lava.pisada)) fila += "L";
                else fila += "·";
            }

            output += fila + "\n";
        }

        return output;
    }
    // Guarda partida en JSON
    guardar(nombre) {

        fs.writeFileSync(
            nombre,
            JSON.stringify(this.estado)
        );
    }

    // Carga partida desde JSON
    cargar(nombre) {

        if (fs.existsSync(nombre)) {

            this.estado = JSON.parse(
                fs.readFileSync(nombre)
            );

            return true;
        }

        return false;
    }
}

module.exports = GameLoop;
