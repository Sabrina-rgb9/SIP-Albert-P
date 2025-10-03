package com.project;

import java.util.concurrent.*;
import java.util.*;

public class MicroserviceApp {

    public static void main(String[] args) {
        // Llista per guardar els resultats parcials
        List<String> partialResults = Collections.synchronizedList(new ArrayList<>());

        // Creem un CyclicBarrier per 3 microserveis + tasca de combinació
        CyclicBarrier barrier = new CyclicBarrier(3, () -> {
            System.out.println("\n--- Tots els microserveis han acabat. ---");
            String finalResult = String.join(" | ", partialResults);
            System.out.println("Resultat final: " + finalResult);
        });

        ExecutorService executor = Executors.newFixedThreadPool(3);

        Runnable microservice1 = () -> {
            try {
                System.out.println("Microservei 1 processant dades...");
                Thread.sleep(1000);
                partialResults.add("Resultat 1");
                System.out.println("Microservei 1 completat.");
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        Runnable microservice2 = () -> {
            try {
                System.out.println("Microservei 2 processant dades...");
                Thread.sleep(1500);
                partialResults.add("Resultat 2");
                System.out.println("Microservei 2 completat.");
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        Runnable microservice3 = () -> {
            try {
                System.out.println("Microservei 3 processant dades...");
                Thread.sleep(2000);
                partialResults.add("Resultat 3");
                System.out.println("Microservei 3 completat.");
                barrier.await();
            } catch (Exception e) {
                e.printStackTrace();
            }
        };

        // Llançar tasques
        executor.submit(microservice1);
        executor.submit(microservice2);
        executor.submit(microservice3);

        executor.shutdown();
    }
}
