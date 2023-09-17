# FIR_Filter_sv
FIR Filter written in SystemVerilog
by Kevin Coleman (birdybro)

I may make it more parameterizable later, it's not a major priority currently, just got it to the point where I can synthesize it and use it in the [MiSTer FPGA MegaDrive core](https://github.com/MiSTer-devel/MegaDrive_MiSTer).

Written by an amateur who just learned about audio filtering over the course of a week.

Written with the assistance of ChatGPT and Google Bard as I try to see how much AI can be used for daily. AI querying is a good skill to ihave.

# Usage

To generate the coefficients you want and to plot them to a preview, first install the matplotlib and scipy python libraries.

Then run the scipy_filter.py script from this repo.

Then take those values, add commas in between each in the array, and run scipy_scaled_coeffs.py.

Take those values and convert them to an array that systemverilog works with, like in the example below.

To instantiate this module:

```sv
audio_fir_filter
#(
	.IW(16),
	.FILTER_LENGTH(20),
	.MCLK_RATE(53693175),
	.DATA_CLK_IN(300000),
	.DATA_CLK_OUT(48000)
)
psg_filter
(
	.clk(clk),
	.reset(reset),
	.coefficients('{0, -54, 0, 383, 437, -741, -1963, 0, 6133, 12189, 12189, 6133, 0, -1963, -741, 437, 383, 0, -54, 0}),
	.data_in(PSG),
	.data_out(psg)
);
```
