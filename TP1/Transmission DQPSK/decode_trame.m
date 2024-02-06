function [PID num_trame num_bit_data Data Err]=decode_trame(rxSig,fech)
%cette fonction entre comme paramètre le signal reçu par l’Adalm Pluto et sa fréquence d’échantillonnage. 
%On réalise en réception la synchronisation puis la démodulation. Après détection du préambule dans la trame
%on retourne les différents champs (PID, num_trame, num_bit_data , Data).  
%Le CRC est calculé. Si aucune erreur est détectée, Err=0 sinon Err=1.

Nech_symb=8;
M=4;

agc = comm.AGC('AveragingLength',1000);
rxfilter = comm.RaisedCosineReceiveFilter('RolloffFactor',1,'InputSamplesPerSymbol',Nech_symb,'DecimationFactor',Nech_symb);
coarseSync = comm.CoarseFrequencyCompensator('Modulation','QPSK','FrequencyResolution',10,'SampleRate',fech);
fineSync = comm.CarrierSynchronizer('ModulationPhaseOffset','Custom','CustomPhaseOffset',pi/M,'SamplesPerSymbol',Nech_symb,'Modulation','QPSK');
symbolSync = comm.SymbolSynchronizer('SamplesPerSymbol',Nech_symb);
pskDemodulator = comm.DPSKDemodulator(M,'BitOutput',true);  %demodulation différentielle

rxSig =agc(rxSig); 
syncCoarse = coarseSync(rxSig);
syncFine =fineSync(syncCoarse);
rxData =symbolSync (syncFine); 

demod=pskDemodulator(rxData); 


PID_Data=[1 1 1 1 0 0 0 0];
PID_Ack=[1 0 1 0 1 0 1 0];
PID_Start=[1 1 1 1 1 1 1 1];
PID_Stop=[0 1 0 1 0 1 0 1];
preamb=[1 1 1 1 1 0 0 1 1 0 1 0 1];% séquence de Barker à 13 bits


prbdet = comm.PreambleDetector(preamb.','Input','Bit');
idx = prbdet(demod);

Err=1; % on suppose qu'il y a erreur de transmission tant que le CRC n'est pas calculé.
PID=[];
%Data=[];
num_trame=0;
num_bit_data=0;    
Data=[];

if (numel(idx)~=0) % si on a détecté le préambule dans la trame. 
    Trame_R=demod(idx(1)+1:end);
    if (size(Trame_R,1)>40)
        PID= Trame_R(1:8).'; % Récupère le PID
        num_trame=bi2de(Trame_R(9:24).','left-msb'); % Récupére le numéro de trame
        num_bit_data=bi2de(Trame_R(25:40).','left-msb'); % récupère le nbre de bits dans la trame.
        if (num_bit_data>15)
            if (size(Trame_R,1)>56+num_bit_data)  %calcul du CRC en réception Err=0 si pas d'erreur et Err=1 si erreur
                crcdetector = comm.CRCDetector();
                [~, Err] = crcdetector(Trame_R(41:41+num_bit_data+16-1));
                if PID == PID_Data  % Si le PID corrsepond à Data; on récupère les données
                    Data=Trame_R(41:41+num_bit_data-1);
                end;
            end;
        end;
               
    end;
    
end

 
