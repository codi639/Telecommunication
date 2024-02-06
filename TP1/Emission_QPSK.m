clc;
close;
clear;

%% Définition des variables
fp = 2.5e9;    % Fréquence porteuse de l'Adalm Pluto (à modifier selon votre canal)

D=200e3;    % Débit

%choix de la modulation QPSK ou PSK-8
M=4;        % M est la valence de la PSK_M 
if (M==4)
    Mod='QPSK';  % choix de la modulation QPSK
end;
if (M==8)
    Mod='8PSK';  % choix de la modulation 8-PSK
end;

k=log2(M);
R=D/k;      % Rapidité
Tb=1/D;     % durée d'un bit
Ts=1/R;     % Durée d'un symbole

Nech_symb=8;       %nombre déchantillons par symbole
fech=Nech_symb*R;   %fréquence échantillonnage
Tech=1/fech;        %période d'échantillonnage 

%% création d'une trame 10110001 suivie de 5002 bits aléatoires
Trame=[1 0 1 1 0 0 0 1];
Trame=[Trame randi([0,1],1,5002)]; % on rajoute 5000 bits aléatoires à la fin du message à transmettre
% Trame=ones(1,5002);
% création dune trame dont le motif se répète 2500 fois
motif=[0 0];
Trame=repmat(motif,1,2500); % si on ne veut émettre que des 0

%% Modulation QPSK: génération des symboles complexes c=I+jQ
% pskModulator = comm.PSKModulator(M,'PhaseOffset',pi/M,'BitInput',true);
% C=pskModulator(Trame');

%% Modulation pi/4-DQPSK: génération des symboles complexes c=I+jQ
pskModulator = comm.DPSKModulator(M,pi/4,'BitInput',true,'SymbolMapping','Binary');  %modulation différentielle DQPSK à cause de l'ambiguitée de phase.
C=pskModulator(Trame');

% %% affichage des 4 premiers symboles C=I+jQ
% figure;
% subplot(2,1,1);
% t=(0:3)*Ts;
% stem(t,real(C(1:4)));
% legend('Chronogramme de I=Re(C)');
% subplot(2,1,2);
% stem(t,imag(C(1:4)));
% legend('Chronogramme de Q=Im(C)');

% Echantillonnage des symboles: Nech_symb=32 échantillons par symbole
txSig=rectpulse(C,Nech_symb);  

% Ajout optionnel d'un filtre de Nyquist
txfilter = comm.RaisedCosineTransmitFilter('Shape','Normal','OutputSamplesPerSymbol',Nech_symb,'RolloffFactor',0.5,'Gain',sqrt(Nech_symb-1));
txSig=txfilter(C);     % rajout d'un filtre de Nyquist  en cos raidi de coefficient 0,5

% % affichage des 4 premiers symboles de I(t) et de Q(t) après échantillonnage
% figure;
% subplot(2,1,1);
% t=(0:4*Nech_symb-1)*Tech;
% stem(t(1:4*Nech_symb),real(txSig(1:4*Nech_symb)));
% legend('Chronogramme de I après échantillonnage');
% subplot(2,1,2);
% stem(t(1:4*Nech_symb),imag(txSig(1:4*Nech_symb)));
% legend('Chronogramme de Q après échantillonnage');
% ajout optionnel du bruit de liaison
% channel = comm.AWGNChannel('EbNo',30,'BitsPerSymbol',log2(M),'SamplesPerSymbol',Nech_symb);
% txSig = channel(txSig);
% % 
% % ajout optionnel d'un offset de phase 
% phaseFreqOffset = comm.PhaseFrequencyOffset('FrequencyOffset',50,'PhaseOffset',0,'SampleRate',fech);
% txSig=phaseFreqOffset(txSig);
% % 
% affichage du diagramme de l'oeil
eyediagram(txSig(2000:end),2*Nech_symb,2*Ts,Nech_symb/2);
% 
%% Calcul puis affichage du spectre des symboles C échantillonnés
% figure;
% [Y f]=spectre(txSig,fech); 
% plot(f,Y,"b");
% title('représentation du spectre en amplitude  des symboles complexes C=I+jQ')
% xlabel('f (Hz)')
% ylabel('Volt')
% legend('Spectre du signal émis')
% axis([0 3*R -60 0])  %affichage entre 0 et 100kHz
% grid on
% 
%% Visualisation de la constellation en émission
constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',Nech_symb,'SymbolsToDisplaySource','Property','SymbolsToDisplay',20000,'ShowTrajectory',false,'ChannelNames',{'Constellation en émission'},'ShowLegend',true,'ReferenceMarker','o','EnableMeasurements',true);
release(constDiagram);
constDiagram(txSig(2001:end));


% Emission sur Adalm pluto
% Configuration de l'ADALM PLUTO émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);

% Emission continuelle de txSig.
transmitRepeat(tx, txSig); % émission du signal: s est transposé car la fonction émet des vecteur colonnes...

