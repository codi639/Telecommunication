clc;
close;
clear;

fp = 2.3e9;    % Fréquence porteuse

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
PID_Ack=[1 0 1 0 1 0 1 0];
PID_Data=[1 1 1 1 0 0 0 0]; 
trame_ack_Data=genere_trame(PID_Ack,1,zeros(1,16)); % création de la trame trames Ack et modulation


%%  Configuration de l'ADALM PLUTO  côté récepteur

tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.3.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);
Nech=16000;
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.3.1','CenterFrequency',fp,'GainSource','Manual','Gain',60,'BasebandSampleRate', fech, 'SamplesPerFrame',2*Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
release(rx);
release(tx);
%% Protoclole côté récepteur
while (1)  % attente de la trame Data
    rxSig=rx();     % lecture des données reçues par lAdalm Pluto
    
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech); %démodulation et décodage de la trame reçue.
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Data)  % Si le PID corrsepond à start;
            if (num_trame==1) % s'il s'agit biende la trame n°1
                Data_recue=Data;    % on stocke la Data dans Data_reçue
                break; %Quitte le while si on a reçu 'start'
            end;
        end;
    end;
end;


%% conversion de la donnée reçue en texte puis affichage du résultat
Texte_R=convert_bin_texte(Data_recue);
display(Texte_R);

%% Envoi de Ack 1 pendant 1 s
%trame_ACK = genere_trame(PID_Ack,1,)
time = 0;
while time < 0
    tic;
    tx(trame_ack_Data);
    time = time + toc;
end


