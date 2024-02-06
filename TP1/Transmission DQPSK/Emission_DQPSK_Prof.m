clc;
close;
clear;

%% Définition des variables
fp = 2.6e9;    % Fréquence porteuse de l'Adalm Pluto

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


%% création de la trame
Data=[1 1 1 1  0 0 0 0 1 1 1 1 0 0 0 0 ];  % Cas ou les données sont une séquence binaire prédéfinie.

% Décommenter les lignes suivantes si on veut maintenant transmette un texte.
Message=input('Entrez le message à transmettre:','s'); 
Data=convert_text_bin(Message);


synchro=[1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
preamb=[1 1 1 1 1 0 0 1 1 0 1 0 1]; % séquence de Barker à 13 bits

crcgenerator = comm.CRCGenerator();
Data_CRC = crcgenerator(Data');   
 
Nbit_Data=de2bi(size(Data,2),16,'left-msb');  %converti le nombre de bit du message en binaire sur 16 bits.

Trame=[synchro preamb  Nbit_Data Data_CRC.' ]; 

if (mod(size(Trame,2),2)==1)  %si le nombre de bits dans la trame est impair 
    Trame=[Trame 0];             % on rajoute un 0 en fin de trame (afin d'avoir un nombre enttier de symboles.
end;


% Modulation pi/4-DQPSK: génération des symboles complexes c=I+jQ
txSig=mod_trame(Trame,Nech_symb);

% Emission sur Adalm pluto
% Configuration de l'ADALM PLUTO émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);

% Emission continuelle de txSig.
transmitRepeat(tx, txSig); % émission du signal: s est transposé car la fonction émet des vecteur colonnes...

