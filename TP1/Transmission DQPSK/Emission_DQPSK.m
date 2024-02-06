clc;
close;
clear;

%% Définition des variables
fp = 2.6e9;    % Fréquence porteuse de l'Adalm Pluto à adapter selon votre n° de canal

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

%% création d'une trame 

Synchro = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
SFD = [1 1 1 1 1 0 0 1 1 0 1 0 1];
% Data = [1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0];

txt_Data = 'A vanille et framboise, sont les mamelles du destin.';
Data = convert_text_bin(txt_Data);
temp=size(Data,2);
Nbr_bit_Data = de2bi(size(Data,2),16, 'left-msb');
CRC = comm.CRCGenerator;
encodeCRC = CRC(Data.');

Trame = [Synchro SFD Nbr_bit_Data encodeCRC.'];

if mod(size(Trame,2),2) ~= 0
    Trame = [Trame 0];
end


%% Modulation pi/4-DQPSK: génération des symboles complexes c=I+jQ
pskModulator = comm.DPSKModulator(M,pi/4,'BitInput',true,'SymbolMapping','Binary');  %modulation différentielle DQPSK à cause de l'ambiguitée de phase.
C=pskModulator(Trame');
txSig = mod_trame(Trame,Nech_symb);


% % Ajout optionnel d'un filtre de Nyquist
% txfilter = comm.RaisedCosineTransmitFilter('Shape','Normal','OutputSamplesPerSymbol',Nech_symb,'RolloffFactor',0.5,'Gain',sqrt(Nech_symb-1));
% txSig=txfilter(C);     % rajout d'un filtre de Nyquist  en cos raidi de coefficient 0,5

%% Emission sur Adalm pluto
% Configuration de l'ADALM PLUTO émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);

%Emission continuelle de txSig.
transmitRepeat(tx, txSig); % émission du signal: s est transposé car la fonction émet des vecteur colonnes...

