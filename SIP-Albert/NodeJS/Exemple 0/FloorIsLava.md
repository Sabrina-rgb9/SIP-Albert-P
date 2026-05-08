# Floor is lava

Es genera un tauler bidimensional (matriu) de 8x6.

```text
 01234567
A········
B········
C········
D········
E········
F········
Escriu una comanda: 
```

S'amaguen 16 caselles de lava en diverses coordenades aleatòries del tauler. Excepte la *A0* on hi ha l'usuari "T" i la *F7* on hi ha el destí "*".

L'usuari té les següents comandes textuals:

- **ajuda**: paraules *help* o *ajuda*, mostren la llista de comandes
* **carregar partida "nom_arxiu.json"**: carrega una partida guardada
* **guardar partida "nom_guardar.json"**: guarda la partida actual
* **activar/desactivar trampa**: a la dreta del tauler, mostra o amaga un segon tauler amb les caselles destapades
* **caminar "direcció"**: on *"direcció"* pot ser "amunt", "avall", "dreta", "esquerra". 

  - Si s'intenta sortir del tauler, es veu el missatge: "Has perdut, has caigut per un penyasegat"
  - Si es cau en una casella de lava "l", es destapa i es veu el missatge: "Has trepitjat lava, perds un punt"
  - Si es va a una casella lliure, es veu el missatge: "Vas per bon camí, tens lava a x caselles de distància"

* **puntuació**: mostra la puntuació actual que correspòn a la distància des de la sortida i les passes actuals. Originalment l'usuari té 32 passes, que es gasten cada vegada que trepitja lava. 

La partida s'acaba quan:

- L'usuari **acaba els punts**, que surt el missatge: "Has perdut, ja no tens més passes"
- L'usuari **arriba a la casella F7**, que surt el missatge: "Has guanyat, has trobat el tresor"