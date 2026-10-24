# Questa: vsim -c -do run.do (batch) | vsim -do run.do (GUI)
quietly set rtl ../../rtl
quietly set tb  ../../tb

if {[batch_mode]} {
    onerror {quit -f -code 1}
} else {
    catch {quit -sim}
}

# Questa 10.7c cannot write its library under a non-ASCII path, use TEMP then
quietly set lib work
if {[regexp {[^\x00-\x7f]} [pwd]] && [info exists ::env(TEMP)]} {
    quietly set lib [file join $::env(TEMP) first_intern_anl_task_2024 work]
    echo "Non-ASCII path, library: $lib"
}
quietly set wlf [file join [file dirname $lib] vsim.wlf]

if {[file exists $lib]} {
    file delete -force $lib
}
file mkdir [file dirname $lib]
vlib $lib

vcom -2008 -work $lib \
    $rtl/msg_pkg.vhd \
    $rtl/uart_rx.vhd \
    $rtl/uart_tx.vhd \
    $rtl/msg_rx.vhd \
    $rtl/alu.vhd \
    $rtl/msg_tx.vhd \
    $rtl/top.vhd \
    $tb/tb_top.vhd

if {[batch_mode]} {
    onbreak {quit -f -code 1}
    vsim -onfinish exit -lib $lib -wlf $wlf tb_top
    run -all
} else {
    onbreak {resume}
    vsim -onfinish stop -lib $lib -wlf $wlf -voptargs=+acc tb_top
    do wave.do
    run -all
    wave zoom full
}
