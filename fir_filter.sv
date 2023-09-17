//
// Copyright (c) 2023 Kevin Coleman
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//
//
// audio_fir_filter.sv
//
// FIR filter, parameterized taps for coefficients using for loops.
// Used as pre-filter for genesis PSG to get it ready for interpolation
// reduces harmful high frequencies which get amplified upon resampling
// Should reduce the aliasing from the Nyquist-Shannon sampling theorem
// https://en.wikipedia.org/wiki/Nyquist%E2%80%93Shannon_sampling_theorem
//
// The ringing artifacts are likely due to the gibbs phenomenon
// https://en.wikipedia.org/wiki/Gibbs_phenomenon
//

module fir_filter #(
    parameter IW=16,
    parameter FILTER_LENGTH=20, // (AKA number of taps)
    parameter MCLK_RATE=53693175,
    parameter DATA_CLK_IN=300000,
    parameter DATA_CLK_OUT=48000
)
(
    input  logic          clk,                             // 53.693175MHz Clock
    input  logic          reset,                           // Active high reset
    input  logic [IW-1:0] coefficients[FILTER_LENGTH-1:0], // Scaled coefficients array with fixed-point values
    input  logic [IW-1:0] data_in,                         // 16-bit input data
    output logic [IW-1:0] data_out                         // 16-bit output data
);

// Counter values for clock division for input and output data sampling rates
localparam SAMPLE_RATE_IN  = MCLK_RATE / DATA_CLK_IN;  // Sample rate divider for incoming data
localparam SAMPLE_RATE_OUT = MCLK_RATE / DATA_CLK_OUT; // Sample rate divider for outgoing data
logic [31:0] counter_in;                               // Counter with enough bits to count to SAMPLE_RATE_IN
logic [31:0] counter_out;                              // Counter with enough bits to count to SAMPLE_RATE_OUT
logic in_sample_valid, out_sample_valid;   // Indicates when a new sample should be processed

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter_in       <= '0;
        counter_out      <= '0;
        in_sample_valid  <=  0;
        out_sample_valid <=  0;
    end else begin
        // DATA_CLK_IN Sample rate clock divider
        if (counter_in == SAMPLE_RATE_IN) begin
            in_sample_valid <= 1'b1;
            counter_in <= 0;
        end else begin
            in_sample_valid <= 1'b0;
            counter_in <= counter_in + 1;
        end
        // DATA_CLK_OUT Sample rate clock divider
        if (counter_out == SAMPLE_RATE_OUT) begin
            out_sample_valid <= 1'b1;
            counter_out <= 0;
        end else begin
            out_sample_valid <= 1'b0;
            counter_out <= counter_out + 1;
        end
    end
end

// FIR pipeline registers and parameters
localparam SUM_WIDTH = (2*IW) + $clog2(FILTER_LENGTH); // Prevent worst case overflow possibilities
logic [IW-1:0] x[FILTER_LENGTH-1:0];                   // Array to store past input values
logic [2*IW-1:0] mult_results[FILTER_LENGTH-1:0];      // Storing the multiplication results
logic [SUM_WIDTH-1:0] sum_result, pipeline_sum;        // SUM_WIDTH-bit result after summing
logic [IW-1:0] downsample_out;                         // Downsampled signals output, updates from sum_result at DATA_CLK_OUT rate

// Systolic array logic
logic [SUM_WIDTH-1:0] PE_out[FILTER_LENGTH];
logic [SUM_WIDTH-1:0] PE_accum_in[FILTER_LENGTH], PE_accum_out[FILTER_LENGTH];

// Instantiating PEs
generate
    for (int i = 0; i < FILTER_LENGTH; i++) begin: PE_INST
        PE u_PE #(
            .IW(IW),
            .SUM_WIDTH(SUM_WIDTH)
        )
        (
            .clk(clk),
            .reset(reset),
            .x(x[i]),
            .coeff(coefficients[i]),
            .accum_in(i == 0 ? 0 : PE_accum_out[i-1]),
            .accum_out(PE_accum_out[i])
        );
    end
endgenerate

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        data_out <= '0;
        for (int i = FILTER_LENGTH-1; i >= 0; i = i-1)begin
            x[i] <= '0;
        end
    end else begin
        // Input sampling
        if (in_sample_valid) begin
            // Shift old data values
            x[0] <= data_in;
            for(int i = 1; i < FILTER_LENGTH; i = i+1)
                x[i] <= x[i-1];
        end

        // Downsample to DATA_CLK_OUT sample rate
        if (out_sample_valid) begin
            data_out <= PE_accum_out[FILTER_LENGTH-1][SUM_WIDTH-1:SUM_WIDTH-IW] + (PE_accum_out[FILTER_LENGTH-1][SUM_WIDTH-IW-1] ? 1 : 0); // Right shift by IW-1 and round
        end
    end
end

endmodule


// Processing Element (PE) for Systolic array
module PE #(
    parameter IW = 16,
    parameter SUM_WIDTH = 32
)
(
    input logic           clk,
    input logic           reset,
    input logic [IW-1:0]  x,
    input logic [IW-1:0]  coeff,
    input logic [SUM_WIDTH-1:0] accum_in,
    output logic [SUM_WIDTH-1:0] accum_out
);
    logic [2*IW-1:0] mult_result;
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            accum_out <= 0;
        else
            accum_out <= accum_in + mult_result;
    end
    assign mult_result = x * coeff;
endmodule
