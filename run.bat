iverilog -o tb_spi_master tb_spi_master.sv
vvp tb_spi_master
gtkwave spi_master_tb.vcd