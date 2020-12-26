function [K_c_fixed] = crack_fixed_coordinates(K_c,phi)

Tr = [cos(phi) -sin(phi);
      sin(phi) cos(phi)];

Z2 = zeros(2,2);

Gamm = [Tr,Z2,Z2,Z2;
        Z2,Tr,Z2,Z2;
        Z2,Z2,Tr,Z2;
        Z2,Z2,Z2,Tr];

K_c_fixed = Gamm*K_c*Gamm';

end