function Texte=convert_bin_texte(Data_bin)
%cette fonction entre des données binaires (vecteur ligne) et les convertit en chaine de caractères (Texte).
A2=reshape(Data_bin,8,[]).';  
B2=char(A2+'0');
C2=bin2dec(B2);
D2=char(C2);
Texte=strcat(D2');