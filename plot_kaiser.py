import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import kaiserord, firwin, freqz

# Sampling frequency of the input signal
fs = 300e3

# Desired passband edge frequency
f_pass = 20e3

# Desired stopband edge frequency
f_stop = 22e3

# Ripple in the passband (in dB)
ripple_db = 0.1

# Attenuation in the stopband (in dB)
attenuation_db = 40

# Calculate the order and the beta parameter for the Kaiser window
N, beta = kaiserord(attenuation_db, (f_stop - f_pass) / (fs/2))

# Compute the taps of the FIR filter
taps = firwin(N, f_stop/(fs/2), window=('kaiser', beta))

# Plot the Kaiser window
plt.figure()
plt.plot(taps)
plt.title('Kaiser Window')
plt.xlabel('Sample')
plt.ylabel('Amplitude')

# Compute the frequency response of the filter
w, h = freqz(taps, worN=8000)

# Plot the magnitude response of the filter
plt.figure()
plt.plot(0.5*fs*w/np.pi, 20 * np.log10(np.abs(h)), 'b')
plt.axvline(f_pass, color='r')
plt.axvline(f_stop, color='r')
plt.title('Frequency Response')
plt.xlabel('Frequency [Hz]')
plt.ylabel('Gain [dB]')
plt.grid()

plt.tight_layout()
plt.show()
