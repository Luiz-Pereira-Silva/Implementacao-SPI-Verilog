vlog RegistradorPISO.v
vlog RegistradorSIPO.v
vlog Periferico.v
vlog Periferico_tb.v

vsim -voptargs=+acc work.Periferico_tb

add wave sim:/Periferico_tb/uut/*
run -all
wave zoom full
