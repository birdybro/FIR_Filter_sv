import numpy as np
import matplotlib.pyplot as plt
import librosa
import librosa.display
from scipy.signal import kaiserord, firwin, lfilter, resample

# Load audio file
y, sr = librosa.load('ab2.wav', sr=223722)  # Replace with your audio file path

# Assuming your loaded audio is sampled at 300kHz
fs = sr

# Filter specifications
f_pass = 20e3
f_stop = 24e3
ripple_db = 0.1
attenuation_db = 40

# Calculate the order and the beta parameter for the Kaiser window
N, beta = kaiserord(attenuation_db, (f_stop - f_pass) / (fs/2))

# Compute the taps of the FIR filter
taps = firwin(N, f_stop/(fs/2), window=('kaiser', beta))

# Spectrogram of original signal
plt.figure(figsize=(10, 4))
D_original = librosa.amplitude_to_db(np.abs(librosa.stft(y)), ref=np.max)
librosa.display.specshow(D_original, sr=sr, x_axis='time', y_axis='log')
plt.colorbar(format='%+2.0f dB')
plt.title('Spectrogram of Original Signal')
plt.tight_layout()
plt.show()

# Apply the filter to the audio signal
filtered_signal = lfilter(taps, 1, y)

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
