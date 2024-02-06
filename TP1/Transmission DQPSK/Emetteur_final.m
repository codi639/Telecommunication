clc;
close;
clear;

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

% convertion de Message en tableau binaire
Message="Longtemps, je me suis couché de bonne heure. Parfois, à peine ma bougie éteinte, mes yeux se fermaient si vite que je n’avais pas le temps de me dire : « Je m’endors. » Et, une demi-heure après, la pensée qu’il était temps de chercher le sommeil m’éveillait ; je voulais poser le volume que je croyais avoir encore dans les mains et souffler ma lumière ; je n’avais pas cessé en dormant de faire des réflexions sur ce que je venais de lire, mais ces réflexions avaient pris un tour un peu particulier ; il me semblait que j’étais moi-même ce dont parlait l’ouvrage : une église, un quatuor, la rivalité de François Ier et de Charles-Quint. Cette croyance survivait pendant quelques secondes à mon réveil ; elle ne choquait pas ma raison, mais pesait comme des écailles sur mes yeux et les empêchait de se rendre compte que le bougeoir n’était pas allumé. Puis elle commençait à me devenir inintelligible, comme après la métempsycose les pensées d’une existence antérieure ; le sujet du livre se détachait de moi, j’étais libre de m’y appliquer ou non ; aussitôt je recouvrais la vue et j’étais bien étonné de trouver autour de moi une obscurité, douce et reposante pour mes yeux, mais peut-être plus encore pour mon esprit, à qui elle apparaissait comme une chose sans cause, incompréhensible, comme une chose vraiment obscure. Je me demandais quelle heure il pouvait être ; j’entendais le sifflement des trains qui, plus ou moins éloigné, comme le chant d’un oiseau dans une forêt, relevant les distances, me décrivait l’étendue de la campagne déserte où le voyageur se hâte vers la station prochaine ; et le petit chemin qu’il suit va être gravé dans son souvenir par l’excitation qu’il doit à des lieux nouveaux, à des actes inaccoutumés, à la causerie récente et aux adieux sous la lampe étrangère qui le suivent encore dans le silence de la nuit, à la douceur prochaine du retour.";   

Data=convert_text_bin(Message);

%CDécoupage de la trame Data en plusieurs sous trames 
N_bit_trame=2000;   %définition de la taille du champ Data dans une trame
N_bit_total=size(Data,2);

nb_bourrage=N_bit_trame-mod(N_bit_total,N_bit_trame);   % ajout de zeros (bourrage) en fin de Data afin d'obtenir
                                                        %un nombre entier de trames de longueur N_bit_trame
Data_bour=[Data zeros(1,nb_bourrage)];

Tab_message=reshape(Data_bour,N_bit_trame,[]).';        % création d'un tableau contenant les 'nb_trame' champs Data.
nb_trame=size(Tab_message,1);

for num_trame=1:nb_trame
    data=Tab_message(num_trame,:);
    trame_Data(:,num_trame)=genere_trame(PID_Data,num_trame,data);
end;



%% Configuration de l'ADALM PLUTO côté émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.3.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);
Nech=16000;    % nombre d'échantillons maximum à transmettre
rx = sdrrx('Pluto', 'RadioID', 'ip:192.168.3.1','CenterFrequency',fp,'GainSource','Manual','Gain',60,'BasebandSampleRate', fech, 'SamplesPerFrame',2*Nech,'OutputDataType', 'double', 'ShowAdvancedProperties', true);
release(tx);
release(rx);

%% Protoclole côté émetteur
while (1)  % Envoi de Start et attente de ack_0
    tx(trame_Start); %envoi de la trame Start
    rxSig=rx();
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech);
    
    if (Err==0)   % si une trame a été reçue sans erreur
        if (PID == PID_Ack)
            if (num_trame==0)  % Si le PID corrsepond à Ack_start;
               break; %Quitte le while si on a reçu 'ack_start'
            end;
        end;
    end;
end;

etape_0='ack_Start recu'

release(tx);



for num_trame=1:nb_trame  %envoi des différentes trames de données
   fprintf('envoi de la trame n° %d \n',num_trame);

    while (1)  % Envoi de la trame Data et attente de ack_Data
        tx(trame_Data(:,num_trame)); %envoi de la trame Data
        rxSig=rx(); % on va recevoir jusqu_à ce qu'on reçoive ack_Data
        [PID num_trameR num_bit_data Data Err]=decode_trame(rxSig,fech);

        if (Err==0)   % si une trame a bien été reçue
            if (PID == PID_Ack)
                if (num_trameR==num_trame)  % Si le PID corrsepond à Ack deu bon numéro de trame;
                  break; %Quitte le while
                end;
            end;          
        end;
    end;
end


fprintf('envoi de la trame stop \n');
release(tx);
while (1)  % Envoi de la trame Stop et attente de ack_Stop
    tx(trame_Stop); %envoi de la trame Stop
    rxSig=rx();
    [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech);

    if (Err==0)   % si une trame a bien été reçue
        if (PID == PID_Ack)
            if (num_trame==1000)  % Si le PID corrsepond à Ack_Stop;
              break; %Quitte le while si on a reçu 'ack_stop'
            end;
        end;          
    end;
   
end;

release(tx);



