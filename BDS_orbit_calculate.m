%* for BDS
clear;clc;
load("nav.mat");
BDS_a = nav.BDS.a;
BDS_e = nav.BDS.e;
BDS_inc = nav.BDS.i;
BDS_omega = nav.BDS.omega;
BDS_M0 = nav.BDS.M0;
BDS_RAAN = nav.BDS.OMEGA;
BDS_toc = nav.BDS.toc;

ground_lon = 127;
ground_lat = 37;
ground_h = 1;

mu = 3.986004418e14; %[m^3/s^−2]

date_ini = juliandate(datetime(BDS_toc));
date_final = juliandate(datetime(BDS_toc + [0,0,2,0,0,0]));

date_span = (date_final - date_ini)*86400; %[sec]
BDS_nu = zeros(date_span,1);
BDS_M = zeros(date_span,1);
BDS_E = zeros(date_span,1);

if BDS_omega <= 0
    BDS_omega = BDS_omega + 2*pi;
end
if BDS_M0 <= 0
    BDS_M0 = BDS_M0 + 2*pi;
end
for i = 1:date_span
    
    BDS_M(i) = BDS_M0 + sqrt(mu/(BDS_a^3))*(i-1);

    if BDS_M(i) >= 2*pi
        BDS_M(i) = BDS_M(i) - 2*pi;
    elseif BDS_M(i) < 0
        BDS_M(i) = BDS_M(i) + 2*pi;
    end

    E0 = BDS_M0;
    del = 1;
    while true
        BDS_E(i) = BDS_M(i) + BDS_e*sin(E0);
        del = abs(BDS_E(i)-E0);
        E0 = BDS_E(i);
        if del <= 1e-7
            break;
        end
    end

    BDS_nu(i) = atan2((sqrt(1-BDS_e^2)*sin(BDS_E(i)))/(1-BDS_e*cos(BDS_E(i))),(cos(BDS_E(i))-BDS_e)/(1-BDS_e*cos(BDS_E(i))));
end

BDS_r = BDS_a.*(1 - BDS_e.*cos(BDS_E'));
BDS_pos_PQW = [BDS_r.*cos(BDS_nu');BDS_r.*sin(BDS_nu');zeros(1,date_span)];

%% PQW to ECI

DCM_PQW2ECI = PQW2ECI(BDS_omega, BDS_inc, BDS_RAAN);
GPS_pos_ECI = DCM_PQW2ECI * BDS_pos_PQW;

%% ECI to ECEF
i = 0;
BDS_pos_ECEF = zeros(3,date_span);
for time = linspace(date_ini,date_final,date_span)
    DCM_ECI2ECEF = ECI2ECEF_DCM(time);
    i = i + 1;
    BDS_pos_ECEF(:,i) = DCM_ECI2ECEF * GPS_pos_ECI(:,i);
end



%% ECEF to Geodetic

wgs84 = wgs84Ellipsoid('meter');
[BDS_lat,BDS_lon,BDS_h] = ecef2geodetic(wgs84,BDS_pos_ECEF(1,:),BDS_pos_ECEF(2,:),BDS_pos_ECEF(3,:));

%% ECEF to ENU
[BDS_E,N,U] = ecef2enu(BDS_pos_ECEF(1,:),BDS_pos_ECEF(2,:),BDS_pos_ECEF(3,:),ground_lat,ground_lon,ground_h,wgs84);
BDS_pos_ENU = [BDS_E;N;U];

%% elevation & azimuth

el_mask = 5;
BDS_el = elevation(BDS_pos_ENU', el_mask);
BDS_az = azimuth(BDS_pos_ENU');

for i = 1:date_span
    if isnan(BDS_el(i))
        BDS_az(i) = NaN;
    end
end



%% plot
figure;
title("GPS ground track");
geoplot(BDS_lat,BDS_lon,'x');
hold on;
geoplot(ground_lat,ground_lon,'or');

figure;
title('GPS skyplot');
skyplot(BDS_az,BDS_el);


sc = satelliteScenario(datetime(BDS_toc),datetime(BDS_toc)+days(2),180);
sat = satellite(sc,BDS_a,BDS_e,rad2deg(BDS_inc),rad2deg(BDS_RAAN),rad2deg(BDS_omega),rad2deg(BDS_nu(1)),"OrbitPropagator","two-body-keplerian","Name","BDS");

leadTime = date_span;
trailTime = date_span;
gt = groundTrack(sat,"LeadTime",leadTime,"TrailTime",trailTime);

play(sc)