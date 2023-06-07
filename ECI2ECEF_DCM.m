function DCM = ECI2ECEF_DCM(time)
% - function name : DCM=ECI2ECEF_DCM(time) 
% - input : time ([YYYY,MM,DD,hh,mm,ss] format)
% - output : DCM matrix (3-by-3)

theta_g = deg2rad(siderealTime(juliandate(time)));
Cos = cos(theta_g);
Sin = sin(theta_g);

DCM = [Cos Sin 0;-Sin Cos 0;0 0 1];