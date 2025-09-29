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

Una empresa de serveis tecnològics vol optimitzar la gestió de les seves tasques de manteniment de sistemes. Per això, vol desenvolupar una aplicació en Java que pugui executar múltiples tasques en paral·lel, utilitzant un pool de fils per evitar sobrecàrregues en el sistema.

**Objectiu**

Implementa una aplicació que utilitzi un ExecutorService amb un pool de 2 fils per gestionar dues tasques en paral·lel. Aquestes tasques representaran operacions independents que es poden executar simultàniament sense compartir dades. La finalitat és garantir que les operacions es processen de manera eficient, aprofitant el paral·lelisme per reduir el temps total d'execució.

**Requisits**

- Crea una classe Java amb un mètode main.

- Defineix dues tasques (Runnable) que simulin operacions de manteniment, com ara registrar esdeveniments de sistema i comprovar l'estat de la xarxa.
- Utilitza un ExecutorService amb un pool de 2 fils (newFixedThreadPool(2)).

- Envia les tasques a l'executor perquè s'executin en paral·lel.

- Assegura't de tancar l'executor al final per alliberar els recursos.

**Important**: Fes servir el format MVN habitual, i no t'oblidis dels arxius 'run.ps1' i 'run.sh'