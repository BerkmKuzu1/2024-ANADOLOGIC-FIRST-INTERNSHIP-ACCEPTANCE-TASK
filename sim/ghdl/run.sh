#!/usr/bin/env bash
# GHDL: bash run.sh [--wave]
set -euo pipefail
cd "$(dirname "$0")"

RTL=../../rtl
TB=../../tb
FLAGS="--std=08 --workdir=work"

SRCS="
    $RTL/msg_pkg.vhd
    $RTL/uart_rx.vhd
    $RTL/uart_tx.vhd
    $RTL/msg_rx.vhd
    $RTL/alu.vhd
    $RTL/msg_tx.vhd
    $RTL/top.vhd
    $TB/tb_top.vhd
"

mkdir -p work
ghdl -a $FLAGS $SRCS
ghdl -e $FLAGS tb_top

if [ "${1:-}" = "--wave" ]; then
    ghdl -r $FLAGS tb_top --wave=tb_top.ghw
else
    ghdl -r $FLAGS tb_top
fi
