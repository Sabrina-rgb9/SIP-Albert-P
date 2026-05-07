# Floor is Lava - Versión comentada

Este proyecto es un juego de consola hecho con Node.js.

El objetivo es moverse por un tablero de 6 filas y 8 columnas desde A0 hasta F7 sin quedarse sin puntos.

## Archivos

- `index.js`: controla la entrada del usuario por terminal.
- `gameLoop.js`: contiene toda la lógica del juego.
- `package.json`: define cómo ejecutar el proyecto con `npm start`.

## Cómo ejecutar

Abre una terminal en la carpeta del proyecto y ejecuta:

```bash
npm start
```

## Comandos

```text
ajuda
caminar amunt
caminar avall
caminar esquerra
caminar dreta
puntuació
activar trampa
desactivar trampa
guardar partida partida.json
carregar partida partida.json
```

## Símbolos del tablero

```text
T = jugador
* = destino
l = lava descubierta
· = casilla normal
```
