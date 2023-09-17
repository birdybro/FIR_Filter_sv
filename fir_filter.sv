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


module fir_filter (
    input  logic        clk,     // 53.693175MHz clock assumed by example
    input  logic        reset,   // Active high reset
    input  logic [15:0] data_in, // 16-bit input data
    output logic [15:0] data_out // 16-bit output data
);

// Counter values - 53.693175MHz to get 300kHz sampling rate requires 178.97725 counter
localparam COUNTER_MAX = 178;   // Assuming 178.97725 gets truncated to 178, almost 50% duty cycle
logic [7:0] counter;            // Counter with enough bits to count to COUNTER_MAX
logic sample_valid;             // Indicates when a new sample should be processed

// Define your filter length
localparam FILTER_LENGTH = 20; // Adjust according to your coefficients length
logic [15:0] COEFFICIENTS[FILTER_LENGTH-1:0] = '{0, -54, 0, 383, 437, -741, -1963, 0, 6133, 12189, 12189, 6133, 0, -1963, -741, 437, 383, 0, -54, 0};

logic [15:0] x[FILTER_LENGTH-1:0];             // Array to store past input values
logic [31:0] mult_results[FILTER_LENGTH-1:0];  // Storing the multiplication results
logic [31:0] sum_result;                       // 32-bit result after summing

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 0;
        sample_valid <= 0;
        // Initialize sample storage registers to zero
        for (int i = FILTER_LENGTH-1; i> 0; i = i-1)begin
            x[i] <= '0;
        end
        // Initialize multiplication result registers to zero
        for (int i = FILTER_LENGTH-1; i> 0; i = i-1)begin
            mult_results[i] <= '0;
        end
        data_out <= 0;
    end else begin
        // Counter Logic
        if (counter == COUNTER_MAX) begin
            sample_valid <= 1'b1;
            counter <= 0;
        end else begin
            sample_valid <= 1'b0;
            counter <= counter + 1;
        end

        if (sample_valid) begin
            // Shift old data values
            for(int i = FILTER_LENGTH-1; i > 0; i = i-1) begin
                x[i] <= x[i-1];
            end
            x[0] <= data_in;

            // Compute multiplication results
            for(int i = 0; i < FILTER_LENGTH; i = i+1) begin
                mult_results[i] <= x[i] * COEFFICIENTS[i];
                // Sum the results
                sum_result <= sum_result + mult_results[i];
            end

            // Downscale and round
            data_out <= sum_result[31:16] + (sum_result[15] ? 1 : 0); // Right shift by 16 and round
        end
    end
end

endmodule
