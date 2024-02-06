function trame_mod=mod_trame(trame,Nech_symb)
pskModulator = comm.DPSKModulator(4,'BitInput',true);  %modulation différentielle DQPSK à cause de l'ambiguitée de phase.
ck=pskModulator(trame');
trame_mod=rectpulse(ck,Nech_symb);  %nombre d'échantillons par symboles