import numpy as np
import matplotlib.pyplot as plt

x = np.arange(0, 2 * np.pi, 0.01)  # Rango de 0 a 2*pi
y = np.sin(x)  # Calcular seno

plt.plot(x, y)  # Graficar
plt.xlim(0, 2 * np.pi)  # Limitar eje X
plt.ylim(-1.5, 1.5)  # Limitar eje Y
plt.show()  # Mostrar gráfica
