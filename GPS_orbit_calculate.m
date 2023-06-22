%* for GPS
clear;clc;
load("nav.mat");
GPS_a = nav.GPS.a;
GPS_e = nav.GPS.e;
GPS_inc = nav.GPS.i;
GPS_omega = nav.GPS.omega;
GPS_M0 = nav.GPS.M0;
GPS_RAAN = nav.GPS.OMEGA;
GPS_toc = nav.GPS.toc;

ground_lon = 127;
ground_lat = 37;
ground_h = 1;

mu = 3.986004418e14; %[m^3/s^−2]

date_ini = juliandate(datetime(GPS_toc));
date_final = juliandate(datetime(GPS_toc + [0,0,2,0,0,0]));

date_span = (date_final - date_ini)*86400; %[sec]
GPS_nu = zeros(date_span,1);
GPS_M = zeros(date_span,1);
GPS_E = zeros(date_span,1);

if GPS_omega <= 0
    GPS_omega = GPS_omega + 2*pi;
end
if GPS_M0 <= 0
    GPS_M0 = GPS_M0 + 2*pi;
end
for i = 1:date_span
    
    GPS_M(i) = GPS_M0 + sqrt(mu/(GPS_a^3))*(i-1);

    if GPS_M(i) >= 2*pi
        GPS_M(i) = GPS_M(i) - 2*pi;
    elseif GPS_M(i) < 0
        GPS_M(i) = GPS_M(i) + 2*pi;
    end

    E0 = GPS_M0;
    del = 1;
    while true
        GPS_E(i) = GPS_M(i) + GPS_e*sin(E0);
        del = abs(GPS_E(i)-E0);
        E0 = GPS_E(i);
        if del <= 1e-7
            break;
        end
    end

    GPS_nu(i) = atan2((sqrt(1-GPS_e^2)*sin(GPS_E(i)))/(1-GPS_e*cos(GPS_E(i))),(cos(GPS_E(i))-GPS_e)/(1-GPS_e*cos(GPS_E(i))));
end

GPS_r = GPS_a.*(1 - GPS_e.*cos(GPS_E'));
GPS_pos_PQW = [GPS_r.*cos(GPS_nu');GPS_r.*sin(GPS_nu');zeros(1,date_span)];

%% PQW to ECI

DCM_PQW2ECI = PQW2ECI(GPS_omega, GPS_inc, GPS_RAAN);
GPS_pos_ECI = DCM_PQW2ECI * GPS_pos_PQW;

%% ECI to ECEF
i = 0;
GPS_pos_ECEF = zeros(3,date_span);
for time = linspace(date_ini,date_final,date_span)
    DCM_ECI2ECEF = ECI2ECEF_DCM(time);
    i = i + 1;
    GPS_pos_ECEF(:,i) = DCM_ECI2ECEF * GPS_pos_ECI(:,i);
end



%% ECEF to Geodetic

wgs84 = wgs84Ellipsoid('meter');
[GPS_lat,GPS_lon,GPS_h] = ecef2geodetic(wgs84,GPS_pos_ECEF(1,:),GPS_pos_ECEF(2,:),GPS_pos_ECEF(3,:));

%% ECEF to ENU
[GPS_E,N,U] = ecef2enu(GPS_pos_ECEF(1,:),GPS_pos_ECEF(2,:),GPS_pos_ECEF(3,:),ground_lat,ground_lon,ground_h,wgs84);
GPS_pos_ENU = [GPS_E;N;U];

%% elevation & azimuth

el_mask = 5;
GPS_el = elevation(GPS_pos_ENU', el_mask);
GPS_az = azimuth(GPS_pos_ENU');

for i = 1:date_span
    if isnan(GPS_el(i))
        GPS_az(i) = NaN;
    end
end



%% plot
figure;
title("GPS ground track");
geoplot(GPS_lat,GPS_lon,'x');
hold on;
geoplot(ground_lat,ground_lon,'or');

figure;
title('GPS skyplot');
skyplot(GPS_az,GPS_el);


sc = satelliteScenario(datetime(GPS_toc),datetime(GPS_toc)+days(2),180);
sat = satellite(sc,GPS_a,GPS_e,rad2deg(GPS_inc),rad2deg(GPS_RAAN),rad2deg(GPS_omega),rad2deg(GPS_nu(1)),"OrbitPropagator","two-body-keplerian","Name","GPS");

leadTime = date_span;
trailTime = date_span;
gt = groundTrack(sat,"LeadTime",leadTime,"TrailTime",trailTime);

play(sc)