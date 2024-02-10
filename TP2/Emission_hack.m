% Partie 3
clear
close
clc

fp = 433.2e6;
fech = 250e3;
Tacq = 40;
Nech = Tacq * fech;

identifiant = 17
num_canal = 1

false_identifiant = de2bi(identifiant, 8, "left-msb");
false_num_canal = de2bi(num_canal, 4, "left-msb");
false_temp1 = de2bi(8, 4, "left-msb");
false_temp2 = de2bi(14, 4, "left-msb");
false_temp3 = de2bi(3, 4, "left-msb");
false_end0 = zeros(1, 8);

false_gen_CRC = comm.CRCGenerator("Polynomial", "z^4 + z + 1");
trame_bin = [false_identifiant false_num_canal false_temp1 false_temp2 false_temp3 false_end0];
false_CRC = false_gen_CRC(trame_bin.');

false_start = [2 2 0 0];
false_CRC = false_CRC.'
false_trame = [false_start false_CRC(1:32) 0 0 0 0 false_CRC(33:end)]

haut = ones(1,120)
start = zeros(1,2007)
un = zeros(1,1007)
zero = zeros(1,507)

emission = []


for i = 1:length(false_trame)
    emission = [emission haut];
    if false_trame(i) == 2
        emission = [emission start];
    end
    if false_trame(i) == 1
        emission = [emission un];
    end
    if false_trame(i) == 0
        emission = [emission zero];
    end
end

emission = [emission zeros(1,100000)]
complex_emission = complex(emission, 0);

% Configuration de l'ADALM PLUTO émetteur
tx = sdrtx('Pluto', 'RadioID', 'ip:192.168.3.1', 'CenterFrequency', fp,'BasebandSampleRate', fech, 'Gain',0,'ShowAdvancedProperties', true);

% Emission continuelle de txSig.
release(tx)
transmitRepeat(tx, complex_emission.'); % émission du signal


