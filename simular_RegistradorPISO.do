vlog RegistradorPISO.v
vlog RegistradorPISO_tb.v

vsim -voptargs=+acc work.RegistradorPISO_tb

add wave -r sim:/RegistradorPISO_tb/uut/*
run -all
wave zoom full

