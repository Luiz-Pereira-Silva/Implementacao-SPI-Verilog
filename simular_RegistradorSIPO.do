vlog RegistradorSIPO.v
vlog RegistradorSIPO_tb.v

vsim -voptargs=+acc work.RegistradorSIPO_tb

add wave -r sim:/RegistradorSIPO_tb/uut/*
run -all
wave zoom full
