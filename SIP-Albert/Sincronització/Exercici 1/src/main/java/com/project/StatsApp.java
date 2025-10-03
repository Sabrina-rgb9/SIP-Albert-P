package com.project;

import java.util.*;
import java.util.concurrent.*;

public class StatsApp {

    // Resultats compartits
    private static double sum = 0.0;
    private static double mean = 0.0;
    private static double stddev = 0.0;

    public static void main(String[] args) {

        // Conjunt de dades
        List<Double> data = Arrays.asList(10.0, 20.0, 30.0, 40.0, 50.0);

        // Barrier per 3 tasques + acció de combinació
        CyclicBarrier barrier = new CyclicBarrier(3, () -> {
            System.out.println("\n--- Resultats Finals ---");
            System.out.println("Suma: " + sum);
            System.out.println("Mitjana: " + mean);
            System.out.println("Desviació estàndard: " + stddev);
        });

        ExecutorService executor = Executors.newFixedThreadPool(3);

        // Tasca 1: càlcul suma
        Runnable sumTask = () -> {
            try {
                sum = data.stream().mapToDouble(Double::doubleValue).sum();
                System.out.println("Suma calculada.");
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        // Tasca 2: càlcul mitjana
        Runnable meanTask = () -> {
            try {
                mean = data.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
                System.out.println("Mitjana calculada.");
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        // Tasca 3: càlcul desviació estàndard
        Runnable stddevTask = () -> {
            try {
                double m = data.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
                double variance = data.stream()
                                      .mapToDouble(x -> Math.pow(x - m, 2))
                                      .average()
                                      .orElse(0.0);
                stddev = Math.sqrt(variance);
                System.out.println("Desviació estàndard calculada.");
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        // Llançar tasques
        executor.submit(sumTask);
        executor.submit(meanTask);
        executor.submit(stddevTask);

        executor.shutdown();
    }
}
