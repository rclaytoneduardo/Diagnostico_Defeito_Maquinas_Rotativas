function [Kc] = crack_ele_papa(E,I,a,R,abar,Poisson,L)

if abar >= 1
    zeta = 0.93;
else
    zeta = 1;
end
    
    bbar = zeta*sqrt(1-(1-abar)^2);
    hxbar = @(xbar)2.*sqrt(1-xbar.^2);
    axbar = @(xbar)hxbar(xbar)/(2)-(1-abar);
    lamb = @(xbar,ybar)pi*ybar./(2*hxbar(xbar));

    F1 = @(x,y)sqrt(tan(lamb(x,y))./(lamb(x,y))).*(0.752+2.02*(2/pi)*lamb(x,y)+0.37*(1-sin(lamb(x,y))).^3)./cos(lamb(x,y));
    F2 = @(x,y)sqrt(tan(lamb(x,y))./(lamb(x,y))).*(0.923+0.199*(1-sin(lamb(x,y))).^4)./cos(lamb(x,y));
    FIII = @(x,y)sqrt(tan(lamb(x,y))./lamb(x,y));
    FII = @(xbar,ybar)(1.122-0.561.*(axbar(xbar)./hxbar(xbar))+0.085.*(axbar(xbar)./hxbar(xbar)).^2+0.18.*(axbar(xbar)./hxbar(xbar)).^3)./sqrt(1-(axbar(xbar)./hxbar(xbar)));

    f55bar = @(xbar,ybar)(32/pi)*(1-xbar.^2).*ybar.*F2(xbar,ybar).^2;
    c55bar = integral2(f55bar,-bbar,bbar,0,axbar);
    c55 = c55bar*(1-Poisson^2)/(E*R^3);

    f44bar = @(xbar,ybar)(16/pi)*xbar.^2.*ybar.*F1(xbar,ybar).^2;
    c44bar = integral2(f44bar,-bbar,bbar,0,axbar);
    c44 = c44bar*(1-Poisson^2)/(E*R^3);

    f45bar = @(xbar,ybar)(16/pi).*ybar.*hxbar(xbar).*F1(xbar,ybar).*F2(xbar,ybar);
%     f45bar = @(xbar,ybar)(16/pi).*xbar.*ybar.*hxbar(xbar).*F1(xbar,ybar).*F2(xbar,ybar);
    c45bar = integral2(f45bar,-bbar,bbar,0,axbar);
    c45 = c45bar*(1-Poisson^2)/(E*R^3);

    f22bar = @(xbar,ybar)(2/pi)*ybar.*FIII(xbar,ybar).^2;
    c22bar = integral2(f22bar,-bbar,bbar,0,axbar);
    c22 = c22bar*(1-Poisson^2)/(E*R);
    
    f33bar = @(xbar,ybar)(2/pi)*ybar.*FII(xbar,ybar).^2;
    c33bar = integral2(f33bar,-bbar,bbar,0,axbar);
    c33 = c33bar*(1-Poisson^2)/(E*R);
    
    Ccr = zeros(4,4);
    Ccr(1,1) = c22;
    Ccr(2,2) = c33;
    Ccr(3,3) = c44;
    Ccr(3,4) = c45;
    Ccr(4,3) = c45;
    Ccr(4,4) = c55;

    C0 = zeros(4,4);
    C0(1,1) = (L^3/3)*(1+a/4);
    C0(2,2) = C0(1,1);
    C0(3,3) = L;
    C0(4,4) = L;
    C0(4,1) = L^2/2;
    C0(3,2) = -L^2/2;

C0 = (1/(E*I))*(C0.'+C0-diag(diag(C0)));

Cce = C0 + Ccr;

Kce = inv(Cce);

 Tc = [-1  0  0 0;
       0 -1  0 0;
       0  L -1 0;
      -L  0  0 -1;
       1  0  0 0;
       0  1  0 0;
       0  0  1 0;
       0  0  0 1];
   
Kc = Tc*Kce*Tc';

end
