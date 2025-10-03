<div style="display: flex; width: 100%;">
    <div style="flex: 1; padding: 0px;">
        <p>© Albert Palacios Jiménez, 2024</p>
    </div>
    <div style="flex: 1; padding: 0px; text-align: right;">
        <img src="./assets/ieti.png" height="32" alt="Logo de IETI" style="max-height: 32px;">
    </div>
</div>
<br/>

# Exercici 0

Una empresa està desenvolupant una aplicació basada en microserveis, on cada microservei processa una part específica de les dades. La tasca de cada microservei ha de ser sincronitzada amb les altres per garantir que les dades processades estiguin correctament agregades abans d'enviar una resposta al client.

**Objectiu**

Implementa un sistema en Java que simuli l'execució de tres microserveis diferents que processen dades de manera concurrent. Utilitza una **CyclicBarrier** per sincronitzar aquestes tasques i garantir que totes han acabat el seu treball abans de combinar els resultats finals. Aquesta sincronització és crucial per assegurar que la resposta enviada al client inclou tots els resultats processats correctament.

**Requisits**

- Crea una classe Java amb un mètode main.

- Defineix tres tasques (Runnable) que simulin el processament de dades en tres microserveis diferents. Cadascuna d'elles ha de retornar un resultat parcial.

- Utilitza una CyclicBarrier per sincronitzar les tres tasques, de manera que només es procedeixi a la següent fase quan totes hagin acabat.

- Quan totes les tasques hagin completat el seu treball, combina els resultats parcials en un resultat final i mostra'l a la consola.

- Utilitza un ExecutorService amb un pool de fils per executar les tasques en paral·lel.

- Assegura't de tancar l'executor al final.

**Important**: Fes servir el format MVN habitual, i no t'oblidis dels arxius 'run.ps1' i 'run.sh'