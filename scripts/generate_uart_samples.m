% Konfiguracja portu (zmień COM na odpowiedni)
port = "COM4";       % np. "COM3" w Windows lub "/dev/ttyUSB0" w Linux
baudrate = 115200;     % ustaw zgodnie z Twoim urządzeniem
s = serialport(port, baudrate,Parity="odd",Databits=8,StopBits=1);
numoftaps=26;
screenwidth=623;
n=screenwidth+numoftaps-1;
angle1=linspace(0,4*pi,n);
angle2=linspace(0,200*pi,n);
%sinus=127*(sin(angle1)+1);
sinus=127*(sin(angle1)+0.5*sin(angle2))/1.5;
writematrix(int8(sinus)','sinus.csv');
data_g=int8(sinus);
%plot(data_g);
% Przygotowanie danych
data_F = repmat(uint8(127), 1, 500);
data_0 = repmat(uint8(255),  1, 1000);
%plot(data_g);
% Wysłanie danych
write(s, data_g, "int8");
%write(s, uint8(127), "uint8");

% Zamknięcie portu (opcjonalnie)
clear s;