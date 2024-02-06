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

% création de la trame trames Ack 

trame_ack_Start=genere_trame(PID_Ack,0,zeros(1,16));
trame_ack_Data=genere_trame(PID_Ack,1,zeros(1,16));
trame_ack_Stop=genere_trame(PID_Ack,1000,zeros(1,16));


%%  Configuration de l'ADALM PLUTO  côté récepteur

tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.3.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);
Nech=32000;
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.3.1','CenterFrequency',fp,'GainSource','Manual','Gain',30,'BasebandSampleRate', fech, 'SamplesPerFrame',2*Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
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


etap='START RECU'


trame=trame_ack_Start;
num_trame=1;
Data_recue=[];
while (1)  % Envoi de ack_Start et attente de la trame Data
    tx(trame); %envoi de l'aquittement du Start
    rxSig=rx(); % on va maintenant recevoir jusqu'à obtenir une trame data
    [PID num_trameR num_bit_data Data Err]=decode_trame(rxSig,fech);
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Data)   % Si le PID corrsepond à start;
            if (num_trameR==num_trame)
                fprintf('reception de la trame n° %d \n',num_trame);
                Data_recue=[Data_recue Data];
                trame=genere_trame(PID_Ack,num_trame,zeros(1,16));
                num_trame=num_trame+1;
            end;
        end;
        if (PID==PID_Stop)
            break; %Quitte le while si on a reçu 'start'
        end;
    end;
end;

release(tx);


Texte_R=convert_bin_texte(Data_recue);
display(Texte_R);


tic;
while(1)
    tx(trame_ack_Stop);
    if (toc>1)
        release(tx);
        break;
    end;
end;