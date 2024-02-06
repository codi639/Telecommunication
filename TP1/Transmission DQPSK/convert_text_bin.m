function Data=convert_text_bin(Message)
% Cette fonction entre une chaine de caractères (Message) et la convertit en un vecteur ligne binaire (Data).
Message_char = convertStringsToChars(Message);
A=cast(Message_char,'uint8');    %converti les caractéres en nombre
B=double(de2bi(A,8,'left-msb'));     %converti les nombres en binaireM
Data=reshape(B.',1,[]);

