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
reg   tx_data_valid_i                      = 0 ;
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
    .tx_data_valid_i         ( tx_data_valid_i        ),
    .spi_miso_i              ( spi_mosi_o             ), // looping back

    .tx_ready_o              ( tx_ready_o             ),
    .rx_data_byte_o          ( rx_data_byte_o   [7:0] ),
    .rx_data_valid_o         ( rx_data_valid_o        ),
    .spi_clk_o               ( spi_clk_o              ),
    .spi_mosi_o              ( spi_mosi_o             )
);

// Sends a single byte from master.
task SendSingleByte(input [7:0] data);
    @(posedge clk_i);
    tx_data_byte_i <= data;
    tx_data_valid_i   <= 1'b1;
    @(posedge clk_i);
    tx_data_valid_i <= 1'b0;
    @(posedge tx_ready_o);
endtask // SendSingleByte

initial
begin
    $dumpfile("spi_master_tb.vcd");
    $dumpvars;
    // $dumpvars(0, tb_spi_master, spi_master);

    #(PERIOD*2);
    // Test single byte
    SendSingleByte(8'hC1);
    $display("Sent out 0xC1, Received 0x%X", rx_data_byte_o); 
    
    // Test double byte
    SendSingleByte(8'hBE);
    $display("Sent out 0xBE, Received 0x%X", rx_data_byte_o); 
    SendSingleByte(8'hEF);
    $display("Sent out 0xEF, Received 0x%X", rx_data_byte_o); 
    repeat(10) @(posedge clk_i);

    #4000;

    $finish;
end

endmodule