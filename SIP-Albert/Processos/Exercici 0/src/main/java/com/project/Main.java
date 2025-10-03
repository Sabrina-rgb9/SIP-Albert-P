package com.project;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Main {
    public static void main(String[] args) {
        ExecutorService executor = Executors.newFixedThreadPool(2);

        Runnable registreEsdeveniments = () -> {
            try { Thread.sleep(2000); } catch (InterruptedException ignored) {}
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