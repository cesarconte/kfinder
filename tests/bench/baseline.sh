#!/bin/bash
set -euo pipefail

OUT_DIR="/home/cesar/Proyectos/kfinder/docs"
mkdir -p "$OUT_DIR"

echo "=== Benchmarking Dolphin 26.08.3 Baseline ==="

# 1. Startup time to first window
echo "Measuring cold & warm start time..."
sync
# Warm up
dolphin --version

START_TIMES=()
for i in {1..5}; do
    T_START=$(date +%s%N)
    timeout 3s dolphin >/dev/null 2>&1 || true
    T_END=$(date +%s%N)
    ELAPSED_MS=$(( (T_END - T_START) / 1000000 ))
    START_TIMES+=("$ELAPSED_MS")
done

echo "Start times (ms): ${START_TIMES[*]}"

# 2. Idle memory consumption
echo "Measuring RSS / PSS with Dolphin idle..."
dolphin >/dev/null 2>&1 &
PID=$!
sleep 2

if [ -f "/proc/$PID/status" ]; then
    RSS=$(grep VmRSS /proc/$PID/status | awk '{print $2, $3}')
    echo "Dolphin PID $PID VmRSS: $RSS"
else
    echo "Dolphin failed to stay alive"
fi

kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

cat << EOREPORT > "$OUT_DIR/BASELINE.md"
# Línea Base de Rendimiento: Dolphin 26.08.3

- **Fecha:** $(date -Iseconds)
- **Hardware:** Intel Core i5-13600K, Intel UHD 770, NVMe Kingston NV2 (btrfs), 31 GiB RAM
- **Entorno:** KDE Plasma 6.8.3, KWin Wayland, Linux 7.3.6-cachyos

## 1. Tiempos de Arranque
- **Muestras (ms):** ${START_TIMES[*]}
- **Promedio aproximado:** $(( (START_TIMES[0] + START_TIMES[1] + START_TIMES[2] + START_TIMES[3] + START_TIMES[4]) / 5 )) ms

## 2. Memoria en Reposo (1 ventana, ~)
- **VmRSS:** ${RSS:-"N/A"}

## 3. Criterios de Aceptación para kfinder (Fase 11)
1. **Arranque en frío:** $\le 350$ ms y siempre menor o igual que Dolphin.
2. **RSS en reposo (1 ventana):** $\le 110$ MB.
3. **Desplazamiento:** 74.97 Hz sostenidos (13.3 ms/frame) sin micro-tirones.
4. **Cero consumo GPU en reposo (0% render).**
EOREPORT

echo "Baseline saved to $OUT_DIR/BASELINE.md"
