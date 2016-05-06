function check(n)

% N0 = n.getOriginalNeurites();
% N1 = n.getNeuriteExtensions();
% figure, imshow(double(cat(3, N0,N0,N1)));
% 
% C = n.getClosedNeuriteMask();
% figure, imshow(double(cat(3, N0, C, N1)));
% 
% S = n.getNeuriteSkeleton();
% figure, imshow(double(cat(3,C,S,C)));

N1 = n.getFirstNeuriteMask();
B = n.getOpenedCellBodyMask();
figure, imshow(double(cat(3,B,N1,B)));

B2 = n.getExtendedCellBodyMask();
N2 = n.getSecondNeuriteMask();
figure, imshow(double(cat(3,N2,N1,B2&~B)))

C2=n.getSecondConnectedNeuriteMask();
U2=n.getSecondUnconnectedNeuriteMask();
figure, imshow(double(cat(3,U2,C2,B)))

Cl=n.getClosedNeuriteMask();
figure, imshow(double(cat(3,Cl,Cl,B)))

S=n.getNeuriteSkeleton();
%figure, imshow(double(cat(3,S,S,B)))
figure, imshow(double(cat(3,Cl,S,B)))

end