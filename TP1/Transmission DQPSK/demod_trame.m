function demod=demod_trame(rxSig,Nech_symb,fe)

agc = comm.AGC('AveragingLength',1000);
rxfilter = comm.RaisedCosineReceiveFilter('RolloffFactor',1,'InputSamplesPerSymbol',Nech_symb,'DecimationFactor',Nech_symb);
coarseSync = comm.CoarseFrequencyCompensator('Modulation','QPSK','FrequencyResolution',10,'SampleRate',fe);
fineSync = comm.CarrierSynchronizer('ModulationPhaseOffset','Custom','CustomPhaseOffset',pi/4,'SamplesPerSymbol',Nech_symb,'Modulation','QPSK');
symbolSync = comm.SymbolSynchronizer('SamplesPerSymbol',Nech_symb);
pskDemodulator = comm.DPSKDemodulator(4,'BitOutput',true);  %demodulation différentielle

rxSig =agc(rxSig); 
syncCoarse = coarseSync(rxSig);
syncFine =fineSync(syncCoarse);
rxData =symbolSync (syncFine); 

demod=pskDemodulator(rxData); 



