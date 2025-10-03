package com.project;

import java.util.concurrent.*;

public class Main {
    public static void main(String[] args) throws Exception {
        ConcurrentHashMap<String, Double> compte = new ConcurrentHashMap<>();

        CountDownLatch cdIni = new CountDownLatch(1);
        CountDownLatch cdMod = new CountDownLatch(1);

        // Tasca 1: inicialitzar el compte
        Runnable inicialitzador = () -> {
            compte.put("saldo", 2452.00);
            System.out.println("Recepció operació bancària: saldo inicial " + compte.get("saldo") + "€");
            cdIni.countDown(); // Indica que ja ha acabat
        };

        // Tasca 2: modificar el saldo (espera que l’inicialitzador acabi)
        Runnable modificador = () -> {
            try {
                cdIni.await(); // espera inicialitzador
                compte.put("saldo", compte.get("saldo") + 365);
                System.out.println("Saldo modificat: " + compte.get("saldo") + "€");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                cdMod.countDown(); // Indica que ja ha acabat
            }
        };

        // Tasca 3: llegir saldo final (espera que el modificador acabi)
        Callable<Double> lector = () -> {
            try {
                cdMod.await(); // espera modificador
                return compte.get("saldo");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return null;
            }
        };

        ExecutorService executor = Executors.newFixedThreadPool(3);

        executor.submit(inicialitzador);
        executor.submit(modificador);
        Future<Double> resultat = executor.submit(lector);

        System.out.println("Resultat final presentat al client: " + resultat.get() + "€");

        executor.shutdown();
    }
}
