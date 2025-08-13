import sounddevice as sd
import numpy as np
import matplotlib.pyplot as plt
from scipy.io.wavfile import write, read
from scipy.signal import welch
from scipy.signal.windows import hann  # Corregido: Importar hann desde scipy.signal.windows

def grabar_audio(duracion, fs=44100):
    print("Comenzando la grabación...")
    grabacion = sd.rec(int(duracion * fs), samplerate=fs, channels=1)
    sd.wait()  # Espera hasta que la grabación termine
    print("Grabación finalizada.")
    write('audio.wav', fs, grabacion)  # Guarda la grabación en un archivo .wav
    print("Archivo de audio grabado correctamente.")
    return grabacion, fs

def reproducir_audio():
    try:
        fs, data = read('audio.wav')
        sd.play(data, fs)
        sd.wait()  # Espera hasta que la reproducción termine
    except Exception as e:
        print("Error al reproducir el audio:", e)

def graficar_audio():
    try:
        fs, data = read('audio.wav')
        tiempo = np.linspace(0, len(data) / fs, num=len(data))
        plt.plot(tiempo, data)
        plt.xlabel('Tiempo (s)')
        plt.ylabel('Amplitud')
        plt.title('Audio')
        plt.show()
    except Exception as e:
        print("Error al graficar el audio:", e)

def graficar_espectro_frecuencia():
    try:
        print("Graficando espectro de frecuencia...")
        fs, audio = read('audio.wav')
        N = len(audio)  # Número de muestras de la señal
        f, Sxx = welch(audio, fs, window=hann(N), nperseg=N, noverlap=0)
        plt.plot(f, 10 * np.log10(Sxx))  # Gráfica el espectro de frecuencia en dB
        plt.xlabel('Frecuencia (Hz)')
        plt.ylabel('Densidad espectral de potencia (dB/Hz)')
        plt.title('Espectro de frecuencia de la señal grabada')
        plt.show()
    except Exception as e:
        print("Error al graficar el espectro de frecuencia:", e)

def main():
    while True:
        print("Seleccione una opción:")
        print("1. Grabar")
        print("2. Reproducir")
        print("3. Graficar")
        print("4. Graficar densidad")
        print("5. Salir")
        opcion = input("Ingrese su elección: ")

        if opcion == '1':
            duracion = float(input("Ingrese la duración de la grabación en segundos: "))
            grabar_audio(duracion)
        elif opcion == '2':
            reproducir_audio()
        elif opcion == '3':
            graficar_audio()
        elif opcion == '4':
            graficar_espectro_frecuencia()
        elif opcion == '5':
            print("Saliendo del programa...")
            break
        else:
            print("Opción no válida.")

if __name__ == "__main__":
    main()