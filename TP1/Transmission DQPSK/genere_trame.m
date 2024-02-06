function trame_mod=genere_trame(PID,num_trame,data)
%cette fonction créée la trame avec les différents champs complétés en
%fonction du PID, du numéro de trame et de la donnée. %La trame est ensuite modulée en DQPSK.
%% création de la trame
synchro=[1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
preamb=[1 1 1 1 1 0 0 1 1 0 1 0 1]; % séquence de Barker à 13 bits

Nbit_data=size(data,2);
Nbit_data_bin=de2bi(Nbit_data,16,'left-msb');  %converti le nombre de bit du message en binaire sur 16 bits.


num_trame_b=de2bi(num_trame,16,'left-msb'); %converti le numéro de trame en tableau binaire.

crcgenerator = comm.CRCGenerator();
data_CRC = crcgenerator(data.');    

trame=[synchro preamb PID num_trame_b Nbit_data_bin data_CRC'];

Nb=size(trame,2);   % nombre de bits dans la trame
if mod(Nb,2)==1
 trame=[trame 0]; %on rajoute un bit de bourrage pour avoir un nombre pair de bits (et donc un nombre entier de symboles en DQPSK)
end;

pskModulator = comm.DPSKModulator(4,'BitInput',true);  %modulation différentielle DQPSK à cause de l'ambiguitée de phase.
ck=pskModulator(trame');
Nech_symb=8;
trame_mod=rectpulse(ck,Nech_symb);  %nombre d'échantillons par symboles
