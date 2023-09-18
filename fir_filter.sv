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

module fir_filter
(
    input  logic        clk,     // 53.693175MHz clock assumed by example
    input  logic        reset,   // Active high reset
    input  logic [15:0] data_in, // 16-bit input data
    output logic [15:0] data_out // 16-bit output data
);

localparam FILTER_LENGTH = 10;               // Adjust according to your coefficients length
logic [15:0] COEFFICIENTS[FILTER_LENGTH-1:0] = '{221, 1073, 2890, 5243, 6956, 6956, 5243, 2890, 1073, 221};
logic [15:0] x[FILTER_LENGTH-1:0];            // Array to store past input values
logic [31:0] mult_results[FILTER_LENGTH-1:0]; // Storing the multiplication results
logic [31:0] sum_result;                      // 32-bit result after summing

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize registers to zero
        for (int i = 0; i < FILTER_LENGTH; i = i + 1)begin
            x[i] <= '0;
            mult_results[i] <= '0;
        end
        sum_result   <= '0;
        data_out     <= '0;
    end else begin
        // Shift old data values
        for(int i = 1; i < FILTER_LENGTH; i = i + 1) begin
            x[i] <= x[i-1];
        end
        x[0] <= data_in;
        // Compute multiplication results
        for(int i = 0; i < FILTER_LENGTH; i = i + 1) begin
            mult_results[i] <= x[i] * COEFFICIENTS[i];
            sum_result <= sum_result + mult_results[i];
        end
        data_out <= sum_result[31:16] + (sum_result[15] ? 1 : 0); // Rounding
    end
end

endmodule
