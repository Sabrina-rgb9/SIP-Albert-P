package com.example;

import java.util.concurrent.Semaphore;

public class ParkingLot {
    private final Semaphore semaphore;

    public ParkingLot(int capacity) {
        this.semaphore = new Semaphore(capacity, true); // just fairness
    }

    public void enter(String carName) {
        try {
            System.out.println(carName + " intenta entrar a l'aparcament...");
            semaphore.acquire(); // espera si no hi ha espai
            System.out.println(carName + " ha entrat a l'aparcament.");
            // Simulem que el cotxe està aparcat durant una estona
            Thread.sleep((long) (Math.random() * 3000 + 1000));
            leave(carName);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void leave(String carName) {
        System.out.println(carName + " surt de l'aparcament.");
        semaphore.release();
    }
}
