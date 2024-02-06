fp = 2.5e9;  %fréquence de la porteuse du poste numéro 10: à modifier selon votre numéro de canal
 
Fech = 1e6; %fréquence d'échantillonnage du signal c(t) transmis à l'Adalm Pluto
Nech=10000; % nombre d'échantillons à transmettre
 
c=complex(ones(1,Nech),zeros(1,Nech)); % pour transmettre la porteuse C=1+0.j  (I=1 et Q=0)
 
%% Configuration de l'ADALM PLUTO émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', fp,'BasebandSampleRate', Fech);
       
transmitRepeat(tx, c'); % émission du signal: c' est le transposé de c car la fonction émet des vecteurs colonnes...
