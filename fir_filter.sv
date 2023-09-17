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
//
// Coefficients calculated with the following example python code:
//
// import numpy as np
// import matplotlib.pyplot as plt
// from scipy.signal import firwin, freqz
//
// # Filter specifications
// num_taps = 20  # number of filter coefficients (taps)
// cutoff_hz = 60e3  # cutoff frequency, e.g., 80 kHz
// fs = 300e3  # sampling rate, e.g., 300 kHz
//
// # Design the filter using firwin
// coefficients = firwin(num_taps, cutoff_hz, fs=fs, window="barthann")
//
// # Print the coefficients
// print("FIR filter coefficients:")
// print(coefficients)
//
// # Optional: Plot the frequency response
// w, h = freqz(coefficients, worN=8000)
// plt.plot(0.5 * fs * w / np.pi, np.abs(h), 'b')
// plt.title('FIR Filter Frequency Response')
// plt.xlabel('Frequency [Hz]')
// plt.ylabel('Gain')
// plt.grid()
// plt.show()
//
//
// Scaling for coefficients done with the following example python code:
//
// coeffs = [-0.00000000e+00, -1.65280117e-03,  2.06185994e-18,  1.16875861e-02,
//            1.33504934e-02, -2.26262259e-02, -5.98970277e-02,  1.28491969e-17,
//            1.87164918e-01,  3.71973057e-01,  3.71973057e-01,  1.87164918e-01,
//            1.28491969e-17, -5.98970277e-02, -2.26262259e-02,  1.33504934e-02,
//            1.16875861e-02,  2.06185994e-18, -1.65280117e-03, -0.00000000e+00]
//
// scaled_coeffs = [round(c * (2**15)) for c in coeffs]
// print(scaled_coeffs)


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
logic in_sample_valid, out_sample_valid;               // Indicates when a new sample should be processed

logic [IW-1:0] x[FILTER_LENGTH-1:0];               // Array to store past input values
logic [IW*2-1:0] mult_results[FILTER_LENGTH-1:0];  // Storing the multiplication results
logic [IW*2-1:0] sum_result;                       // 32-bit result after summing

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter_in       <= 0;
        counter_out      <= 0;
        in_sample_valid  <= 0;
        out_sample_valid <= 0;
        data_out         <= 0;
        // Initialize sample storage registers to zero
        for (int i = FILTER_LENGTH-1; i> 0; i = i-1)begin
            x[i] <= '0;
        end
        // Initialize multiplication result registers to zero
        for (int i = FILTER_LENGTH-1; i> 0; i = i-1)begin
            mult_results[i] <= '0;
        end

    end else begin
        // Counter Logic
        if (counter_in == SAMPLE_RATE_IN) begin
            in_sample_valid <= 1'b1;
            counter_in <= 0;
        end else begin
            in_sample_valid <= 1'b0;
            counter_in <= counter_in + 1;
        end
        if (counter_out == SAMPLE_RATE_OUT) begin
            out_sample_valid <= 1'b1;
            counter_out <= 0;
        end else begin
            out_sample_valid <= 1'b0;
            counter_out <= counter_out + 1;
        end

        if (in_sample_valid) begin
            // Shift old data values
            for(int i = FILTER_LENGTH-1; i > 0; i = i-1) begin
                x[i] <= x[i-1];
            end
            x[0] <= data_in;

            // Compute multiplication results
            for(int i = 0; i < FILTER_LENGTH; i = i+1) begin
                mult_results[i] <= x[i] * coefficients[i];
                // Sum the results
                sum_result <= sum_result + mult_results[i];
            end
        end
        // Downsample to DATA_CLK_OUT sample rate
        if (out_sample_valid) begin
            // Downscale and round
            data_out <= sum_result[IW*2-1:IW] + (sum_result[IW-1] ? 1 : 0); // Right shift by IW-1 and round
        end
    end
end

endmodule
