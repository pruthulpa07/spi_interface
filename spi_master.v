// Parameters:  SPI_MODE, can be 0, 1, 2, or 3.  See above.
//              Can be configured in one of 4 modes:
//              Mode | Clock Polarity (CPOL/CKP) | Clock Phase (CPHA)
//               0   |             0             |        0
//               1   |             0             |        1
//               2   |             1             |        0
//               3   |             1             |        1
//              More: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus#Mode_numbers
//              CLK_RATIO - Sets frequency of o_SPI_Clk.  o_SPI_Clk is
//              derived from clk_i.
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
    input tx_data_valid_i,
    output reg tx_ready_o,

    // RX signals
    output reg [7:0] rx_data_byte_o,
    output reg rx_data_valid_o,
    
    // SPI signals
    output spi_clk_o,
    output reg spi_mosi_o,
    input spi_miso_i
);

    reg [7:0] tx_data_byte_r;
    reg tx_data_valid_r;
    reg [2:0] tx_count_r;
    reg [2:0] rx_count_r;

    reg [2:0] spi_clk_counter_r;

    reg sub_clock_r;
    reg [2:0] clk_counter_r;
    reg spi_clk_enable_r;

    wire CPOL_s;     // Clock polarity
    wire CPHA_s;     // Clock phase

    reg leading_edge_r;
    reg trailing_edge_r;

    // CPOL: Clock Polarity
    // CPOL=0 means clock idles at 0, leading edge is rising edge.
    // CPOL=1 means clock idles at 1, leading edge is falling edge.
    assign CPOL_s  = (SPI_MODE == 2) | (SPI_MODE == 3);

    // CPHA: Clock Phase
    // CPHA=0 means the "out" side changes the data on trailing edge of clock
    //              the "in" side captures data on leading edge of clock
    // CPHA=1 means the "out" side changes the data on leading edge of clock
    //              the "in" side captures data on the trailing edge of clock
    assign CPHA_s  = (SPI_MODE == 1) | (SPI_MODE == 3);

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

    // SPI clock counter
    always @(posedge sub_clock_r or negedge reset_l_i or tx_ready_o) begin
        if (!reset_l_i) begin
            spi_clk_counter_r <= 0;
        end else if (tx_ready_o == 0) begin
            if (spi_clk_counter_r != 7) begin
                spi_clk_counter_r <= spi_clk_counter_r + 1;
            end else begin
                spi_clk_counter_r <= 0;
            end
        end else if (tx_ready_o == 1) begin
            spi_clk_counter_r <= 0;
        end
    end 

    always @(posedge clk_i or negedge reset_l_i) begin
        leading_edge_r <= 1'b0;
        trailing_edge_r <= 1'b0;
        if (!reset_l_i) begin
            sub_clock_r <= CPOL_s; // Default value set to clock polarity
            leading_edge_r <= CPOL_s;
            trailing_edge_r <= ~CPOL_s;
        end else if (clk_counter_r == CLK_RATIO - 1) begin
            sub_clock_r <= ~sub_clock_r;
            leading_edge_r <= ~sub_clock_r;
            trailing_edge_r <= sub_clock_r;
        end
    end

    // Clock gating
    assign spi_clk_o = spi_clk_enable_r ? sub_clock_r : 1'b0;

    // Start transaction on receiving tx_data_valid_i
    always @(posedge clk_i or negedge reset_l_i)
    begin
        if (!reset_l_i)
        begin
            tx_ready_o <= 1'b1;
            spi_clk_enable_r <= 1'b0;
        end
        else
        begin
            if (tx_data_valid_i)
            begin
                tx_ready_o <= 1'b0;
                spi_clk_enable_r <= 1'b1;
            end
            else if (spi_clk_counter_r == 7 & tx_ready_o == 1'b0)
            begin
                tx_ready_o <= 1'b1;
                spi_clk_enable_r <= 1'b0;
            end
        end
    end

    // Register tx_data_byte_i when Data Valid is pulsed.
    // Keeps local storage of byte in case higher level module changes the data
    always @(posedge clk_i or negedge reset_l_i)
    begin
        if (!reset_l_i)
        begin
        tx_data_byte_r <= 8'h00;
        tx_data_valid_r <= 1'b0;
        end
        else
        begin
            tx_data_valid_r <= tx_data_valid_i; // 1 clock cycle delay
            if (tx_data_valid_i)
            begin
            tx_data_byte_r <= tx_data_byte_i;
            end
        end 
    end

    // Generate MOSI data
    // Works with both CPHA=0 and CPHA=1
    always @(posedge clk_i or negedge reset_l_i)
    begin
        if (!reset_l_i)
        begin
        spi_mosi_o     <= 1'b0;
        tx_count_r <= 3'b111; // send MSb first
        end
        else
        begin
        // If ready is high, reset bit counts to default
        if (tx_ready_o)
        begin
            tx_count_r <= 3'b111;
        end
        // Catch the case where we start transaction and CPHA = 0
        else if (tx_data_valid_r & ~CPHA_s)
        begin
            spi_mosi_o     <= tx_data_byte_r[3'b111];
            tx_count_r <= 3'b110;
        end
        else if ((leading_edge_r & CPHA_s) | (trailing_edge_r & ~CPHA_s))
        begin
            tx_count_r <= tx_count_r - 1'b1;
            spi_mosi_o     <= tx_data_byte_r[tx_count_r];
        end
        end
    end

    // Read in MISO data.
    always @(posedge clk_i or negedge reset_l_i)
    begin
        if (!reset_l_i)
        begin
        rx_data_byte_o      <= 8'h00;
        rx_data_valid_o        <= 1'b0;
        rx_count_r <= 3'b111;
        end
        else
        begin

        // Default Assignments
        rx_data_valid_o   <= 1'b0;

        if (tx_ready_o) // Check if ready is high, if so reset bit count to default
        begin
            rx_count_r <= 3'b111;
        end
        else if ((leading_edge_r & ~CPHA_s) | (trailing_edge_r & CPHA_s))
        begin
            rx_data_byte_o[rx_count_r] <= spi_miso_i;  // Sample data
            rx_count_r            <= rx_count_r - 1'b1;
            if (rx_count_r == 3'b000)
            begin
            rx_data_valid_o   <= 1'b1;   // Byte done, pulse Data Valid
            end
        end
        end
    end
    
endmodule