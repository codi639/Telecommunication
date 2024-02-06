clc;
close;
clear;

fp = 2.42e9;    % Fréquence porteuse

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

% création dest différentes trames d'acquittement 

trame_ack_Start=genere_trame(PID_Ack,0,[0 0 0 0 0 0 0 ]); % Ack 0 pour acquitter un Start
trame_ack_Data=genere_trame(PID_Ack,1,[0 0 0 0 0 0 0 ]);    % Ack 1 pour acquiter la trame Data n°1
trame_ack_Stop=genere_trame(PID_Ack,1000,[0 0 0 0 0 0 0 ]); % Ack 1000 pur acquitter le Stop


%%  Configuration de l'ADALM PLUTO  côté récepteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.3.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);
Nech=16000;
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.3.1','CenterFrequency',fp,'GainSource','Manual','Gain',60,'BasebandSampleRate', fech, 'SamplesPerFrame',2*Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
release(rx);
release(tx);

%% Protoclole côté récepteur
while (1)  % attente de la reception de Start
    rxSig=rx();
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech);
    if (Err==0)   % si une trame a été reçue sans erreur
        if PID == PID_Start
             if (num_trame==0)  % Si le PID corrsepond à start;
               break; %Quitte le while si on a reçu 'start'
           end;
        end;
    end;
end;

fprintf("START bien reçue \n");
fprintf("envoi de Ack0 \n");
release (tx);
while (1)  % Envoi de Ack0 et attente de la trame Data n°1
    tx(trame_ack_Start); %envoi de l'aquittement du Start
    rxSig=rx(); %reception d'une trame de l'Adalm Pluto 
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); % Démodulation puis décodage de la trame.
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Data)  % Si le PID corrsepond à Data;
            if (num_trame==1)   % si c'est bien la trame n°1
                Data_recue=Data;    % Stocke la Data reçue
                break; %Quitte le while si on a reçu 'start'
            end;
        end;
    end;
end;


fprintf("trame DATA1 bien reçue \n");
fprintf("envoi de Ack1 \n");
release(tx);

while (1)  % Envoi de Ack0 et attente de la trame Data n°1
    tx(trame_ack_Data); %envoi de l'aquittement du Start
    rxSig=rx(); %reception d'une trame de l'Adalm Pluto 
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); % Démodulation puis décodage de la trame.
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Data)  % Si le PID corrsepond à Data;
            if (num_trame==2)   % si c'est bien la trame n°1
                Data_recue=Data;    % Stocke la Data reçue
                break; %Quitte le while si on a reçu 'data'
            end;
        end;
    end;
end;

while (1)  % attente de la reception de Stop
    rxSig=rx();
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech);
    if (Err==0)   % si une trame a été reçue sans erreur
        if PID == PID_Stop
             if (num_trame==3)  % Si le PID corrsepond à stop;
               break; %Quitte le while si on a reçu 'start'
           end;
        end;
    end;
end;

fprintf("STOP bien reçue \n");
fprintf("envoi de Ack3 \n");
release(tx);

while (1)  % Envoi de Ack0 et attente de la trame Data n°1
    tx(trame_ack_Stop); %envoi de l'aquittement du Start
    rxSig=rx(); %reception d'une trame de l'Adalm Pluto 
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); % Démodulation puis décodage de la trame.
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Stop)  % Si le PID corrsepond à Data;
            if (num_trame==2)   % si c'est bien la trame n°1
                Data_recue=Data;    % Stocke la Data reçue
                break; %Quitte le while si on a reçu 'data'
            end;
        end;
    end;
end;



