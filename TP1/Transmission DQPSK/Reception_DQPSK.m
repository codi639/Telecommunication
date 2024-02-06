clc;
close;
clear;

%% Définition des variables
fp = 2.39e9;    % Fréquence porteuse de l'Adalm Pluto à adapter selon votre n° de canal

D=200e3;    % Débit

M=4;    
Mod='QPSK';  % choix de la modulation QPSK

k=log2(M);
R=D/k;      % Rapidité
Tb=1/D;     % durée d'un bit
Ts=1/R;     % Durée d'un symbole

Nech_symb=8;       %nombre déchantillons par symbole
fech=Nech_symb*R;   %fréquence échantillonnage
Tech=1/fech;        %période d'échantillonnage 

Nech=5000;  % nombre maximum d'échantillons dans une trame

%% Reception du signal
numSamples = 2*Nech; % On reçoit 2 trames pour en avoir au moins une en entier.
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.2.1','CenterFrequency',fp,'GainSource','Manual','Gain',30,'BasebandSampleRate', fech, 'SamplesPerFrame', numSamples,'OutputDataType', 'double', 'ShowAdvancedProperties', true);

demod=demod_trame(rx(),Nech_symb,fech); 


%% Détermination de la position du préambule par corrélation
preamb=[1 1 1 1 1 0 0 1 1 0 1 0 1]; % séquence de Barker à 13 bits
prbdet = comm.PreambleDetector(preamb','Input','Bit');
idx = prbdet(demod);
data_r=demod(idx(1)+1:end).';  % récupérations des données reçues à partir de la fin du SFD


%% Décodage de la trame  
% dans cette partie, il faut récupérer le champ 'nombre de bits de Data'.On pourra
% utiliser  la fonction de2bi pour convertir le résultat en binaire.
% il faudra ensuite récupérer le champ Data

rec_nb_Data = data_r(1, 1:16);
nb_Data = bi2de(rec_nb_Data, 'left-msb');

rec_Data = data_r(1, 17:nb_Data);
Data = convert_bin_texte(rec_Data);



%% Verification du CRC
CRC = comm.CRCDetector();


[~, error] = CRC(data_r(17:nb_data+32));

% Il faut vérifier que le message a été transmis sans erreur.
% A compléter

%% Si le message a été transmis sans erreur, afficher la  Data reçue

% A compléter.