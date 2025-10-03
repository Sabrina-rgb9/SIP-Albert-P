package com.project;

import java.util.concurrent.CompletableFuture;

public class Main {
    public static void main(String[] args) {
        CompletableFuture<Void> process = CompletableFuture
            // 1. Validació de les dades (simulada)
            .supplyAsync(() -> {
                System.out.println("Validant dades de la sol·licitud...");
                int importeAlbert = 638;
                // Simulem una validació i retornem un valor inicial
                return "Usuari: Albert, import: " + importeAlbert;
            })
            // 2. Processament de les dades
            .thenApply(dades -> {
                System.out.println("Processant dades...");
                // Simulem un càlcul (ex: afegim una comissió)
                int importInicial = Integer.parseInt(dades.split(": ")[2]);
                int comissio = 176;
                int resultat = importInicial - comissio;
                return "Usuari: Albert, Import final: " + resultat;
            })
            // 3. Mostrar la resposta final
            .thenAccept(resultat -> {
                System.out.println("Resposta final a l'usuari:");
                System.out.println(resultat);
            });

        // Esperem que totes les operacions asíncrones acabin
        process.join();
    }
}