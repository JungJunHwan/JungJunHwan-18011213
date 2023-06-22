function az = azimuth(ENU)
% - function 명 : az = azimuth(ENU)
% - input : ENU (행이 시각 또는 위성수, 열이 ENU로 구성된 위성 ENU 위치로 구성된 n-by-3 matrix, 단위 km)
% - output : azimuth angle (1-by-n, 단위 deg)

E = ENU(:,1);
N = ENU(:,2);

az = acos(N./sqrt(E.^2 + N.^2));
for i = 1:size(az,1)
    if E(i) < 0
        az(i) = -az(i);
    end

    if az(i) < 0
        az(i) = az(i) + 2*pi;
    elseif az(i) >= 2*pi
        az(i) = az(i) - 2*pi;
    end
end
az = rad2deg(az);