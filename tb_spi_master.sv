`timescale  1ns / 1ps

`include "spi_master.v"	

module tb_spi_master;

// spi_master Parameters
parameter PERIOD     = 40;
parameter SPI_MODE   = 0;
parameter CLK_RATIO  = 4;

// spi_master Inputs
reg   clk_i                                = 0 ;
reg   reset_l_i                            = 0 ;
reg   [7:0]  tx_data_byte_i                = 0 ;
reg   tx_data_valid_o                      = 0 ;
reg   spi_miso_i                           = 0 ;

// spi_master Outputs
wire  tx_ready_o                           ;
wire  [7:0]  rx_data_byte_o                ;
wire  rx_data_valid_o                      ;
wire  spi_clk_o                            ;
wire  spi_mosi_o                           ;


initial
begin
    forever #(PERIOD/2)  clk_i=~clk_i;
end

initial
begin
    #(PERIOD*2) reset_l_i  =  1;
end

spi_master #(
    .SPI_MODE  ( SPI_MODE  ),
    .CLK_RATIO ( CLK_RATIO ))
 u_spi_master (
    .clk_i                   ( clk_i                  ),
    .reset_l_i               ( reset_l_i              ),
    .tx_data_byte_i          ( tx_data_byte_i   [7:0] ),
    .tx_data_valid_o         ( tx_data_valid_o        ),
    .spi_miso_i              ( spi_miso_i             ),

    .tx_ready_o              ( tx_ready_o             ),
    .rx_data_byte_o          ( rx_data_byte_o   [7:0] ),
    .rx_data_valid_o         ( rx_data_valid_o        ),
    .spi_clk_o               ( spi_clk_o              ),
    .spi_mosi_o              ( spi_mosi_o             )
);

initial
begin
    $dumpfile("spi_master_tb.vcd");
    $dumpvars(0, tb_spi_master);
    #1000;
    $finish;
end

endmodule