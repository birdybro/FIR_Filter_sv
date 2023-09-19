//
// Copyright (c) 2023 Kevin Coleman (kcoleman@misterfpga.co)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
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
logic [15:0] COEFFICIENTS[FILTER_LENGTH-1:0] = '{89, 795, 2665, 5374, 7461, 7461, 5374, 2665, 795, 89};
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
        x[0] <= data_in;
        for(int i = 1; i < FILTER_LENGTH; i = i + 1) begin
            x[i] <= x[i-1];
        end
        // Compute multiplication results
        for(int i = 0; i < FILTER_LENGTH; i = i + 1) begin
            mult_results[i] <= x[i] * COEFFICIENTS[i];
            sum_result <= sum_result + mult_results[i];
        end
        data_out <= sum_result[31:16] + (sum_result[15] ? 1 : 0); // Rounding
    end
end

endmodule
