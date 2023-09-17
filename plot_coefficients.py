# Generates and plots coefficients

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, freqz

# Filter specifications
num_taps = 20  # number of filter coefficients (taps)
cutoff_hz = 60e3  # cutoff frequency, e.g., 80 kHz
fs = 300e3  # sampling rate, e.g., 300 kHz

# Design the filter using firwin
coefficients = firwin(num_taps, cutoff_hz, fs=fs, window="barthann")

# Print the coefficients
print("FIR filter coefficients:")
print(coefficients)

# Optional: Plot the frequency response
w, h = freqz(coefficients, worN=8000)
plt.plot(0.5 * fs * w / np.pi, np.abs(h), 'b')
plt.title('FIR Filter Frequency Response')
plt.xlabel('Frequency [Hz]')
plt.ylabel('Gain')
plt.grid()
plt.show()
