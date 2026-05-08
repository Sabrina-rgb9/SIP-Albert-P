package com.project;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) {
        
        // ExecutiveService la seva funció es gestionar un grup de fils. Els fils són unitats d'execució que permeten realitzar tasques de manera concurrent.
        ExecutorService executor = Executors.newFixedThreadPool(2); // .newFixedThreadPool(2) crea un grup de fils amb una mida fixa de 2 fils.
        
        // runnable és una interfície funcional que representa una tasca que es pot executar en un fil.
        Runnable registreEsdeveniments = () -> {
            try { Thread.sleep(2000); } catch (InterruptedException ignored) {} // Simula una tasca que triga 2 segons a completar-se.
            System.out.println("Registre d'esdeveniments completat.");
        };

        
        Runnable comprovacioXarxa = () -> {
            try { Thread.sleep(3000); } catch (InterruptedException ignored) {}
            System.out.println("Comprovació de xarxa completada.");
        };

        executor.execute(registreEsdeveniments);
        executor.execute(comprovacioXarxa);

        executor.shutdown();
    }
}