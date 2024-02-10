% clc;
% close;
% clear;
% 
% % Définition des variables
% fp = 433e6;     % Fréquence porteuse de l'Adalm Pluto (à modifier selon votre canal)
% fech = 5e6;    % Fréquence échantillonnage
% Tacq = 1;    % Durée d'acquisition à faire 60 fois
% Nech = 5e6 * Tacq;    % Nombre d'échantillons
% 
% %% Partie 1
% rx1 = sdrrx('Pluto', 'RadioID', 'ip:192.168.3.1','CenterFrequency',fp,'GainSource','Manual','Gain', 50,'BasebandSampleRate', fech, 'SamplesPerFrame',Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
% 
% rxMax = 0;
% for i = 1:60
% 
%     rx = rx1();
%     max1 = 0;
%     
%     valAbs = abs(rx);
%     max1 = max(valAbs);
% 
%     if max1 > rxMax;
%         rxMax = max1;
%         resultat = rx;
%         release(rx1)
%     else
%         release(rx1);
%     end
%     disp(i)
%     disp(rxMax)
% 
% end
% 
% subplot(2,1,1)
% plot(abs(resultat))
% 
% max(resultat)
% 
% 
% 
% subplot(2,1,2)
% [Y f]= spectre(resultat,fech);
% plot(f + fp, Y, "b")
% title('représentation du spectre en amplitude  des symboles complexes C=I+jQ')
% xlabel('f (Hz)')
% ylabel('Volt')
% legend('Spectre du signal émis')
% axis([433e6 435e6 -60 -20])  %affichage entre 0 et 100kHz
% grid on
% 
% [M indice] = max(Y)
% freq_centrale = fp + f(indice)



% Partie 2
fp = 433.93e6;
fech = 250e3;
Tacq = 40;
Nech = Tacq * fech;

rx2 = sdrrx('Pluto', 'RadioID', 'ip:192.168.3.1','CenterFrequency',fp,'GainSource','Manual','Gain', 50,'BasebandSampleRate', fech, 'SamplesPerFrame',Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
% received_data = rx2();
% load "received_data.mat"

plot(abs(received_data));
axis([5.8e6 6.1e6 0 0.02]);

[M2 indice2] = max(abs(received_data));

Vmax = M2
seuil = Vmax / 2
abs_data = abs(received_data);

abs_data = min(round(abs_data/seuil),1);

plot(abs_data);

indice1 = 4.82e6;
indice2 = 4.861e6;

shorted_trame = 0;

indice=1;
while [indice<length(abs_data)]
    if abs_data(indice) == 1
        break
    end
    indice = indice + 1;
end


shorted_trame = abs_data(indice:indice + 41000);
plot(shorted_trame);


started_bit = 0;
nb_1 = [];
nb_0 = [];
nb_bits = [];
cpt1 = 0;
cpt0 = 1;

for i = 1:length(shorted_trame)
    if shorted_trame(i) == 1
        if started_bit
            cpt1 = cpt1 + 1;
            
        else
            started_bit = 1;
            nb_1 = [nb_1 cpt1];
            nb_0 = [nb_0 cpt0];
            nb_bits = [nb_bits cpt1 cpt0];
            cpt1 = 1;
            cpt0 = 0;
        end
    else
        cpt0 = cpt0 + 1;
        started_bit = 0;
    end
end

nb_0;
nb_1;
nb_bits;

easy_bits = round(nb_bits/(118*4));
% easy_bits = easy_bits(4:90) % to keep only from our start to our end (without any other tram)

simple_bits = [];

for i = 1:length(easy_bits)
    if easy_bits(i) ~= 0
        simple_bits = [simple_bits easy_bits(i)];
    end
end

simple_bits;

trame_finale = simple_bits(5:end);
trame_finale = trame_finale - 1;

bin_id = trame_finale(1:8);
identifiant = bi2de(trame_finale(1:8), "left-msb")
bin_canal = trame_finale(9:12);
num_canal = bi2de(trame_finale(9:12), "left-msb") + 1
bin_temp1 = trame_finale(13:16);
temp1 = bi2de(trame_finale(13:16), "left-msb")
bin_temp2 = trame_finale(17:20);
temp2 = bi2de(trame_finale(17:20), "left-msb")
bin_temp3 = trame_finale(21:24);
temp3 = bi2de(trame_finale(21:24), "left-msb")
bin_end0 = trame_finale(25:36);
end0 = bi2de(trame_finale(25:36), "left-msb")
CRC = bi2de(trame_finale(37:40), "left-msb")

CRC_Detect = comm.CRCDetector("Polynomial", "z^4 + z + 1");

CRC_Test = [];
CRC_Test = [CRC_Test trame_finale(1:32)];
CRC_Test = [CRC_Test trame_finale(37:40)];
[out error] = CRC_Detect(CRC_Test.')

temperature = temp1 + temp2 * 16 + temp3 * 256;
temp_faren = (temperature - 900) / 1000;
temp_celsius = (temp_faren - 32) * (5/9)




