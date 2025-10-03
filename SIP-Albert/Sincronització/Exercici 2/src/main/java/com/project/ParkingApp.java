package com.example;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ParkingApp {

    public static void main(String[] args) {
        final int capacity = 3; // capacitat de l'aparcament
        final int totalCars = 10; // quants cotxes volem simular

        ParkingLot parkingLot = new ParkingLot(capacity);

        ExecutorService executor = Executors.newFixedThreadPool(5);

        for (int i = 1; i <= totalCars; i++) {
            final String carName = "Cotxe " + i;
            executor.submit(() -> parkingLot.enter(carName));
        }

        executor.shutdown();
    }
}
