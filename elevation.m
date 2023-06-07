function el = elevation(ENU, el_mask)
% - input : ENU (행이 시각 또는 위성수, 열이 ENU로 구성된 위성 ENU 위치로 구성된 n-by-3 matrix, 단위 km), el_mask (위성 최소 앙각, deg)
% - output : elevation angle (1-by-n, 단위 deg)
% - description : 계산된 elevation angle이 el_mask보다 커야만 정상적으로 출력하고, 크지 않을 경우 NaN으로 처리

E = ENU(:,1);
N = ENU(:,2);
U = ENU(:,3);

R_rel = sqrt(E.^2 + N.^2 + U.^2);
el = asin(U./R_rel);

i=1;
while i <= size(el,1)
    if el(i) < el_mask
        el(i) = NaN;
    end
    i=i+1;
end
el = rad2deg(el);