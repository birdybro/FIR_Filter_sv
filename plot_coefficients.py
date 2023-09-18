import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, freqz, lfilter
import soundfile as sf
import time

# Parameters
fs_in = 300e3  # Input Sampling Rate
fs_out = 48e3  # Output Sampling Rate
downsampling_factor = fs_in / fs_out
cutoff_freq = 24e3  # Chosen cutoff frequency
transition_bandwidth = 2e3  # Chosen transition bandwidth
nyq = 0.5 * fs_in  # Nyquist Frequency for the input sample rate
attenuation_dB = 45  # Example value; adjust based on requirements
num_taps = 10
chunk_size = 10**5  # 100,000 samples per chunk, control memory flow

# Using firwin to design the filter with a Dolph-Chebyshev window
coeff_chebyshev = firwin(num_taps, cutoff_freq/nyq, window=('chebwin', attenuation_dB))

print("Number of Taps:", num_taps)
print("Dolph-Chebyshev Filter Coefficients:", coeff_chebyshev)

# Scale the coefficients for 16-bit fixed point representation
scaling_factor = 2**15 - 1  # For 16-bit signed integer representation
scaled_taps = np.round(coeff_chebyshev * scaling_factor).astype(int)

print("\nScaled coefficients for 16-bit fixed point:")
print(scaled_taps)

# Plotting the filter's frequency response using freqz
w_chebyshev, h_chebyshev = freqz(coeff_chebyshev, worN=8000)

plt.figure(figsize=(10, 6))
plt.plot(0.5 * fs_in * w_chebyshev / np.pi, np.abs(h_chebyshev), 'g', label='Dolph-Chebyshev')
plt.plot(cutoff_freq, 0.5*np.sqrt(2), 'ko')
plt.axvline(cutoff_freq, color='k')
plt.xlim(0, 0.5 * fs_in)
plt.title('Lowpass Filter Frequency Response')
plt.xlabel('Frequency [Hz]')
plt.ylabel('Gain')
plt.legend()
plt.grid()
plt.show()
