#funcion
#hacer una funcion
#edit hipotenusa.m
#edit funcion.m
#x = hipotenusa (1,2)
#[x,b]=hipotenusa (2,2)
#x = [-3:0.1:1];
#x = linespace (-3,1,50);
#plot (x, funcion(x),'color', 'red')
#plot (x, funcion(x),'LineStyle', ':');
#stem (x, funcion(x),'LineStyle', ':');
#title('TITULO');
#ylabel('Eje y');
#xlabel('Eje x');
#legend('Función');

#Hacer gráfica
x = [0:0.1:4*pi];
y1 = sin(x);
y2 = cos(x);
hold on;
p1 = plot(x,y1);
p2 = plot(x,y2);
set(p1, 'color', 'red', 'LineWidth', 2);
set(p2, 'color', 'blue', 'LineWidth', 1);
ylabel('Eje y');
xlabel('Eje x');
title('Seno y coseno');
legend('Seno', 'Coseno');
hold off;

