// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//              More: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
//              CLK_RATIO - Sets frequency of o_SPI_Clk.  o_SPI_Clk is
//              derived from i_Clk.
//
///////////////////////////////////////////////////////////////////////////////

module spi_master #(
    parameter SPI_MODE = 0,
    parameter CLK_RATIO = 4
) (
    input clk_i,
    input reset_l_i,

    // TX signals
    input [7:0] tx_data_byte_i,
    input tx_data_valid_o,
    output tx_ready_o,

    // RX signals
    output [7:0] rx_data_byte_o,
    output rx_data_valid_o,
    
    // SPI signals
    output spi_clk_o,
    output spi_mosi_o,
    input spi_miso_i
);

    reg [7:0] tx_data_byte_r;
    reg tx_data_valid_r;
    reg [2:0] tx_count_r;
    reg [2:0] rx_count_r;

    reg sub_clock_r;
    reg [2:0] clk_counter_r;
    reg spi_clk_enable_r;

    // Generate SPI clock
    always @(posedge clk_i or negedge reset_l_i) begin
        if (!reset_l_i) begin
            clk_counter_r <= 0;
        end else if (clk_counter_r != CLK_RATIO - 1) begin
            clk_counter_r <= clk_counter_r + 1;
        end else begin
            clk_counter_r <= 0;
        end
    end 

    always @(posedge clk_i  or negedge reset_l_i) begin
        if (!reset_l_i) begin
            sub_clock_r <= 0;
        end else if (clk_counter_r == CLK_RATIO - 1) begin
            sub_clock_r <= ~sub_clock_r;
        end
    end

    // Clock gating
    assign spi_clk_o = spi_clk_enable_r ? sub_clock_r : 1'b0;
    
endmodule