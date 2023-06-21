function E = cal_eccentric_anomaly(e,M)

E0 = M;
del = 1;
while del <= e-5
    E = M + e*sin(E0);
    del = abs(E - E0);
    E0 = E;
end