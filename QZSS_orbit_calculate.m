%* for QZSS
clear;clc;
load("nav.mat");
QZSS_a = nav.QZSS.a;
QZSS_e = nav.QZSS.e;
QZSS_inc = nav.QZSS.i;
QZSS_omega = nav.QZSS.omega;
QZSS_M0 = nav.QZSS.M0;
QZSS_RAAN = nav.QZSS.OMEGA;
QZSS_toc = nav.QZSS.toc;

ground_lon = 127;
ground_lat = 37;
ground_h = 1;

mu = 3.986004418e14; %[m^3/s^−2]

date_ini = juliandate(datetime(QZSS_toc));
date_final = juliandate(datetime(QZSS_toc + [0,0,2,0,0,0]));

date_span = (date_final - date_ini)*86400; %[sec]
QZSS_nu = zeros(date_span,1);
QZSS_M = zeros(date_span,1);
QZSS_E = zeros(date_span,1);

if QZSS_omega <= 0
    QZSS_omega = QZSS_omega + 2*pi;
end
if QZSS_M0 <= 0
    QZSS_M0 = QZSS_M0 + 2*pi;
end
for i = 1:date_span
    
    QZSS_M(i) = QZSS_M0 + sqrt(mu/(QZSS_a^3))*(i-1);

    if QZSS_M(i) >= 2*pi
        QZSS_M(i) = QZSS_M(i) - 2*pi;
    elseif QZSS_M(i) < 0
        QZSS_M(i) = QZSS_M(i) + 2*pi;
    end

    E0 = QZSS_M0;
    del = 1;
    while true
        QZSS_E(i) = QZSS_M(i) + QZSS_e*sin(E0);
        del = abs(QZSS_E(i)-E0);
        E0 = QZSS_E(i);
        if del <= 1e-7
            break;
        end
    end

    QZSS_nu(i) = atan2((sqrt(1-QZSS_e^2)*sin(QZSS_E(i)))/(1-QZSS_e*cos(QZSS_E(i))),(cos(QZSS_E(i))-QZSS_e)/(1-QZSS_e*cos(QZSS_E(i))));
end

QZSS_r = QZSS_a.*(1 - QZSS_e.*cos(QZSS_E'));
QZSS_pos_PQW = [QZSS_r.*cos(QZSS_nu');QZSS_r.*sin(QZSS_nu');zeros(1,date_span)];

%% PQW to ECI

DCM_PQW2ECI = PQW2ECI(QZSS_omega, QZSS_inc, QZSS_RAAN);
GPS_pos_ECI = DCM_PQW2ECI * QZSS_pos_PQW;

%% ECI to ECEF
i = 0;
QZSS_pos_ECEF = zeros(3,date_span);
for time = linspace(date_ini,date_final,date_span)
    DCM_ECI2ECEF = ECI2ECEF_DCM(time);
    i = i + 1;
    QZSS_pos_ECEF(:,i) = DCM_ECI2ECEF * GPS_pos_ECI(:,i);
end



%% ECEF to Geodetic

wgs84 = wgs84Ellipsoid('meter');
[QZSS_lat,QZSS_lon,QZSS_h] = ecef2geodetic(wgs84,QZSS_pos_ECEF(1,:),QZSS_pos_ECEF(2,:),QZSS_pos_ECEF(3,:));

%% ECEF to ENU
[QZSS_E,N,U] = ecef2enu(QZSS_pos_ECEF(1,:),QZSS_pos_ECEF(2,:),QZSS_pos_ECEF(3,:),ground_lat,ground_lon,ground_h,wgs84);
QZSS_pos_ENU = [QZSS_E;N;U];

%% elevation & azimuth

el_mask = 5;
QZSS_el = elevation(QZSS_pos_ENU', el_mask);
QZSS_az = azimuth(QZSS_pos_ENU');

for i = 1:date_span
    if isnan(QZSS_el(i))
        QZSS_az(i) = NaN;
    end
end



%% plot
figure;
title("GPS ground track");
geoplot(QZSS_lat,QZSS_lon,'x');
hold on;
geoplot(ground_lat,ground_lon,'or');

figure;
title('GPS skyplot');
skyplot(QZSS_az,QZSS_el);


sc = satelliteScenario(datetime(QZSS_toc),datetime(QZSS_toc)+days(2),180);
sat = satellite(sc,QZSS_a,QZSS_e,rad2deg(QZSS_inc),rad2deg(QZSS_RAAN),rad2deg(QZSS_omega),rad2deg(QZSS_nu(1)),"OrbitPropagator","two-body-keplerian","Name","QZSS");

leadTime = date_span;
trailTime = date_span;
gt = groundTrack(sat,"LeadTime",leadTime,"TrailTime",trailTime);

play(sc)