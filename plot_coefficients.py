
# my first iteration

# import numpy as np
# import matplotlib.pyplot as plt
# from scipy.signal import firwin, freqz

# # Filter specifications
# num_taps = 20 # number of filter coefficients (taps)
# cutoff_hz = 20e3  # cutoff frequency, e.g., 80 kHz
# fs = 48e3  # sampling rate, e.g., 300 kHz

# # Design the filter using firwin
# coefficients = firwin(num_taps, cutoff_hz, fs=fs, window="blackman")

# # Print the coefficients
# print("FIR filter coefficients:")
# print(coefficients)

# # Optional: Plot the frequency response
# w, h = freqz(coefficients, worN=8000)
# plt.plot(0.5 * fs * w / np.pi, np.abs(h), 'b')
# plt.title('FIR Filter Frequency Response')
# plt.xlabel('Frequency [Hz]')
# plt.ylabel('Gain')
# plt.grid()
# plt.show()


# second iteration

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, freqz

# Parameters
fs_in = 300e3  # Input Sampling Rate: 300kHz
cutoff_freq = 22e3  # Chosen cutoff frequency: 22kHz
transition_bandwidth = 1e3  # Chosen transition bandwidth: 1kHz
nyq = 0.5 * fs_in  # Nyquist Frequency for the input sample rate

# Using firwin to design the filter with a Blackman window
# The numtaps argument in firwin can help achieve a desired transition bandwidth
# Adjust numtaps as needed for your specific requirements
num_taps = 101
coefficients = firwin(num_taps, cutoff_freq/nyq, window='blackman')

print("Number of Taps:", num_taps)
print("Filter Coefficients:", coefficients)

# Plotting the filter's frequency response using freqz
w, h = freqz(coefficients, worN=8000)
plt.plot(0.5 * fs_in * w / np.pi, np.abs(h), 'b')
plt.plot(cutoff_freq, 0.5*np.sqrt(2), 'ko')
plt.axvline(cutoff_freq, color='k')
plt.xlim(0, 0.5 * fs_in)
plt.title('Lowpass Filter Frequency Response')
plt.xlabel('Frequency [Hz]')
plt.ylabel('Gain')
plt.grid()
plt.show()

