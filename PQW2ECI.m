function ECI = PQW2ECI(arg_prg, inc_angle, RAAN)

DCM_arg_prg = [cos(arg_prg) -sin(arg_prg) 0;...
               sin(arg_prg) cos(arg_prg) 0;...
               0 0 0];

DCM_inc_angle = [1 0 0;...
                 0 cos(inc_angle) -sin(inc_angle);...
                 0 sin(inc_angle) cos(inc_angle)];

DCM_RAAN = [cos(RAAN) -sin(RAAN) 0;...
               sin(RAAN) cos(RAAN) 0;...
               0 0 0];


ECI = (DCM_arg_prg * DCM_inc_angle * DCM_RAAN)';