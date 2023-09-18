module ResampleAudio #(
  parameter int SAMPLE_RATE = 223722 // Sample rate of the input audio signal
) (
  input logic clk,
  input logic reset,
  input logic unsigned [15:0] in,
  output logic unsigned [15:0] out
);

  // Declare the polyphase filter
  PolyphaseFilter filter #(
    .N(64),
    .M(4)
  ) filter_inst (
    .clk(clk),
    .reset(reset),
    .in(in),
    .out(out)
  );

  // Downsample the output of the polyphase filter
  always @(posedge clk) begin
    out <= out[15:0];
  end

endmodule

module PolyphaseFilter #(
  parameter int N = 64, // Number of filter taps
  parameter int M = 4 // Number of filter phases
) (
  input logic clk,
  input logic reset,
  input logic signed [15:0] in,
  output logic signed [15:0] out
);

  // Declare the filter coefficients
  logic signed [15:0] coeffs [N-1:0];

  // Declare the filter state variables
  logic signed [15:0] state [M-1:0];

  // Initialize the filter state variables
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= '0;
    end else begin
      state <= {state[M-2:0], in};
    end
  end

  // Compute the filter output
  always @(posedge clk) begin
    out <= 0;
    for (int i = 0; i < N; i++) begin
      out <= out + coeffs[i] * state[i];
    end
  end

endmodule