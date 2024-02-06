clc;
close;
clear;

%% Initialisation des variables
fp = 2.6e9;            % Fréquence porteuse (à adapter suivant votre numéro de canal)

D=200e3;                % Débit
M=4;                    % DQPSK
k=log2(M);
R=D/k;                  % Rapidité
Tb=1/D;                 % durée d'un bit
Ts=1/R;                 % Durée d'un symbole

Nech_symb=8;            %nombre déchantillons par symbole
fech=Nech_symb*R;       %fréquence échantillonnage
Te=1/fech;              %période d'échantillonnage 


%% Création de la trame Data
PID_Data=[1 1 1 1 0 0 0 0];
PID_Ack=[1 0 1 0 1 0 1 0];
Message=input('Entrez le message à transmettre:','s'); 
Data=convert_text_bin(Message); %conversion du missage en tableau binaire.
trame_Data=genere_trame(PID_Data,1,Data); %Génération de la trame Data et modulation en DQPSK.

%% Configuration de l'ADALM PLUTO côté émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);
Nech=16000;    % nombre d'échantillons maximum à recevoir (doit être supérieur au double du nombre d'échantillons d'une trame Data.
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.2.1','CenterFrequency',fp,'GainSource','Manual','Gain',60,'BasebandSampleRate', fech, 'SamplesPerFrame',2*Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
release(tx);
release(rx);

%% Protoclole côté émetteur

fprintf('envoi de la trame ');
while (1)  % Envoi de la trame Data et attente de ack_Data
    tx(trame_Data); %envoi de la trame Data
    rxSig=rx(); % on va recevoir jusqu_à ce qu'on reçoive ack_Data
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech);

    if (Err==0)   % si une trame a bien été reçue
        if (PID == PID_Ack)
            if (num_trame==1)  % Si le PID corrsepond à Ack1;
              break; %Quitte le while si on a reçu 'ack_start'
            end;
        end;          
    end;
end;

disp("la transmission s'est déroulée sans erreur.");

release(tx); % libère l'Adalm Pluto en émission et en réception.
release(rx);


