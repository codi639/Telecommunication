clc;
close;
clear;

%% Initialisation des variables
fp = 2.7e9;    % Fréquence porteuse

D=200e3;    % Débit
M=4;        % DQPSK
k=log2(M);
R=D/k;      % Rapidité
Tb=1/D;     % durée d'un bit
Ts=1/R;     % Durée d'un symbole

Nech_symb=8;    %nombre déchantillons par symbole
fech=Nech_symb*R;    %fréquence échantillonnage
Te=1/fech; %période d'échantillonnage 


%% Création des différentes trames à émettre

PID_Data=[1 1 1 1 0 0 0 0];
PID_Ack=[1 0 1 0 1 0 1 0];
PID_Start=[1 1 1 1 1 1 1 1];
PID_Stop=[0 1 0 1 0 1 0 1];
 

% création des trames Start, Stop
trame_Start=genere_trame(PID_Start,0,zeros(1,16));
trame_Stop=genere_trame(PID_Stop,1000,zeros(1,16));

% création de la trame Data
Message=input('Entrez le message à transmettre:','s'); 
Data=convert_text_bin(Message);
trame_Data=genere_trame(PID_Data,1,Data);

%% Configuration de l'ADALM PLUTO côté émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.2.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);
Nech=16000;    % nombre d'échantillonsà ecevoir
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.2.1','CenterFrequency',fp,'GainSource','Manual','Gain',60,'BasebandSampleRate', fech, 'SamplesPerFrame',2*Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
release(tx);
release(rx);

%% Protoclole côté émetteur
fprintf("envoi de la START \n");
while (1)  % Envoi de Start et attente de ack_0
    tx(trame_Start); %envoi de la trame Start
    rxSig=rx(); % acquisition d'une trame par l'Adalm Pluto
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); % Démodulation puis décodage de la trame
    
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Ack) 
            if (num_trame==0)  % Si le PID corrsepond à Ack 0;
               break; %Quitte le while si on a reçu 'Ack0'
            end;
        end;
    end;
end;

fprintf("Ack 0 bien reçu! \n");

release(tx);

fprintf("envoi de la trame Data \n");
while (1)  % Envoi de la trame Data n°1 et attente de Ack1
    tx(trame_Data); %envoi de la trame Data
    rxSig=rx();  % acquisition d'une trame par l'Adalm Pluto
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); % Démodulation puis décodage de la trame

    if (Err==0)   % si une trame a bien été reçue
        if (PID == PID_Ack)
            if (num_trame==1)  % Si le PID corrsepond à Ack1;
              break; %Quitte le while si on a reçu 'Ack1'
            end;
        end;          
    end;
end;

fprintf("Ack 1 bien reçu !");
%% PARTIE A Compléter
release(tx);

fprintf("envoi de la trame stop \n");
while (1)
    tx(trame_Stop);
    rxSig=rx();
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); % Démodulation puis décodage de la trame
    
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Ack) 
            if (num_trame==1000)  % Si le PID corrsepond à Ack 0;
               break; %Quitte le while si on a reçu 'Ack0'
            end;
        end;
    end;
end
 fprintf("Ack 2 bien reçu !");

