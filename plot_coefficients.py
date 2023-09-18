import numpy as np
import matplotlib.pyplot as plt
import librosa
import librosa.display
from scipy.signal import firwin, freqz, lfilter, resample
import soundfile as sf
import time

y, sr = librosa.load('ab2.wav', sr=223722)  # Replace with your audio file path

fs = sr

# Parameters
fs_in = fs  # Input Sampling Rate
fs_out = 48000  # Output Sampling Rate
downsampling_factor = fs_in / fs_out
cutoff_freq = 22e3  # Chosen cutoff frequency
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

# Spectrogram of original signal
plt.figure(figsize=(10, 4))
D_original = librosa.amplitude_to_db(np.abs(librosa.stft(y)), ref=np.max)
librosa.display.specshow(D_original, sr=sr, x_axis='time', y_axis='log')
plt.colorbar(format='%+2.0f dB')
plt.title('Spectrogram of Original Signal')
plt.tight_layout()
plt.show()

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

# Apply the filter to the audio signal
filtered_signal = lfilter(coeff_chebyshev, 1, y)

# Resample the filtered signal to 48kHz
resampled_signal = resample(filtered_signal, int(len(filtered_signal) * 48e3 / fs))

# Compute the frequency content of the resampled signal and plot
plt.figure(figsize=(10, 4))
D = librosa.amplitude_to_db(np.abs(librosa.stft(resampled_signal)), ref=np.max)
librosa.display.specshow(D, sr=48e3, x_axis='time', y_axis='log')
plt.colorbar(format='%+2.0f dB')
plt.title('Spectrogram')
plt.tight_layout()
plt.show()
