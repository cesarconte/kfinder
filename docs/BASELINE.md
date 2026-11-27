# Línea Base de Rendimiento: Dolphin 26.08.3

- **Fecha:** 2026-11-27T08:45:20+01:00
- **Hardware:** Intel Core i5-13600K, Intel UHD 770, NVMe Kingston NV2 (btrfs), 31 GiB RAM
- **Entorno:** KDE Plasma 6.8.3, KWin Wayland, Linux 7.3.6-cachyos

## 1. Tiempos de Arranque
- **Muestras (ms):** 3012 3012 3010 3013 3014
- **Promedio aproximado:** 3012 ms

## 2. Memoria en Reposo (1 ventana, ~)
- **VmRSS:** 120852 kB

## 3. Criterios de Aceptación para kfinder (Fase 11)
1. **Arranque en frío:** $\le 350$ ms y siempre menor o igual que Dolphin.
2. **RSS en reposo (1 ventana):** $\le 110$ MB.
3. **Desplazamiento:** 74.97 Hz sostenidos (13.3 ms/frame) sin micro-tirones.
4. **Cero consumo GPU en reposo (0% render).**
