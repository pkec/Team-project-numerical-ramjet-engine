clc; close all; clear;

%% ========================================================
% RAMJET ENGINE DESIGN CODE
% Stations: 1 (freestream) -> C1 (inlet throat) -> x (pre-shock)
%           -> y (post-shock) -> 2 (burner entry) -> b (burner exit)
%           -> C2 (nozzle throat) -> 4 (exhaust)
% Assumptions:
%   (1) Exhaust has same properties as air (gamma, R constant)
%   (2) gamma = 1.4 throughout
%   (3) Compression and expansion are isentropic (except across shock)
%   (4) Engine is adiabatic
%   (5) Fuel mass addition neglected
%   (6) Ideal expansion is not assumed but BPR and EPR are kept at 1 for
%       simplicity for variation of other input parameters
% ========================================================

%% --- BASELINE INPUTS ---
gamma = 1.4;
R     = 287;
Cp    = gamma*R/(gamma-1); 

P1    = 70e3;   % (a) Freestream pressure [Pa]
T1    = 210;    % (a) Freestream temperature [K]
M1    = 3.24;    % (b) Flight Mach number
Mx    = 1.2;    % (c) Normal shock strength (Mach just before shock)
M2    = 0.3;    % (d) Burner entry Mach number
Tb    = 1400;   % (e) Burner temperature [K]
Pb_P2 = 1.0;    % (f) Burner pressure ratio (ideal = 1)
P4_P1 = 1.0;    % (g) Exhaust pressure ratio (ideal = 1)
F_req = 10e3;   % (h) Required thrust [N]

%% ========================================================
% BASELINE DESIGN — full printed output
% ========================================================
fprintf('========================================\n');
fprintf('       BASELINE RAMJET DESIGN\n');
fprintf('========================================\n');
[res, valid] = ramjet_solve(P1,T1,M1,Mx,M2,Tb,Pb_P2,P4_P1,F_req,gamma,R);
if valid
    print_results(res);
else
    fprintf('Baseline inputs produce an invalid design.\n');
end

%% ========================================================
% EFFICIENCY PLOTS vs EACH INPUT PARAMETER
% When varying one parameter, all others stay at baseline.
% Pb_P2 and P4_P1 are always held at 1.0 (ideal) when NOT
% the parameter being swept, as stated in the project brief.
% ========================================================

%--- (b) Flight Mach number M1 ---
M1_vec = linspace(1.5, 10.0, 120);
[eta_p_M1, eta_c_M1] = deal(nan(size(M1_vec)));
for i = 1:length(M1_vec)
    Mx_i = min(Mx, M1_vec(i)-0.05);   % Mx cannot exceed M1
    [r,v] = ramjet_solve(P1,T1,M1_vec(i),Mx_i,M2,Tb,1.0,1.0,F_req,gamma,R);
    if v; eta_p_M1(i)=r.eta_p; eta_c_M1(i)=r.eta_cycle; end
end
figure(1);
plot(M1_vec,eta_p_M1,'b-','LineWidth',1.5); hold on;
plot(M1_vec,eta_c_M1,'r-','LineWidth',1.5);
xlabel('Flight Mach Number M_1'); ylabel('\eta');
title('Efficiency vs Flight Mach Number');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (a) Freestream temperature T1 ---
T1_vec = linspace(180, 300, 80);
[eta_p_T1, eta_c_T1] = deal(nan(size(T1_vec)));
for i = 1:length(T1_vec)
    [r,v] = ramjet_solve(P1,T1_vec(i),M1,Mx,M2,Tb,1.0,1.0,F_req,gamma,R);
    if v; eta_p_T1(i)=r.eta_p; eta_c_T1(i)=r.eta_cycle; end
end
figure(2);
plot(T1_vec,eta_p_T1,'b-','LineWidth',1.5); hold on;
plot(T1_vec,eta_c_T1,'r-','LineWidth',1.5);
xlabel('Freestream Temperature T_1 [K]'); ylabel('\eta');
title('Efficiency vs Freestream Temperature');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (a) Freestream pressure P1 ---
P1_vec = linspace(20e3, 101e3, 80);
[eta_p_P1, eta_c_P1] = deal(nan(size(P1_vec)));
for i = 1:length(P1_vec)
    [r,v] = ramjet_solve(P1_vec(i),T1,M1,Mx,M2,Tb,1.0,1.0,F_req,gamma,R);
    if v; eta_p_P1(i)=r.eta_p; eta_c_P1(i)=r.eta_cycle; end
end
figure(3);
plot(P1_vec/1e3,eta_p_P1,'b-','LineWidth',1.5); hold on;
plot(P1_vec/1e3,eta_c_P1,'r-','LineWidth',1.5);
xlabel('Freestream Pressure P_1 [kPa]'); ylabel('\eta');
title('Efficiency vs Freestream Pressure');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (c) Normal shock strength Mx ---
Mx_vec = linspace(1.01, min(M1-0.05, 3.0), 80);
[eta_p_Mx, eta_c_Mx] = deal(nan(size(Mx_vec)));
for i = 1:length(Mx_vec)
    [r,v] = ramjet_solve(P1,T1,M1,Mx_vec(i),M2,Tb,1.0,1.0,F_req,gamma,R);
    if v; eta_p_Mx(i)=r.eta_p; eta_c_Mx(i)=r.eta_cycle; end
end
figure(4);
plot(Mx_vec,eta_p_Mx,'b-','LineWidth',1.5); hold on;
plot(Mx_vec,eta_c_Mx,'r-','LineWidth',1.5);
xlabel('Shock Mach Number M_x'); ylabel('\eta');
title('Efficiency vs Normal Shock Strength');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (d) Burner entry Mach number M2 ---
M2_vec = linspace(0.05, 0.7, 80);
[eta_p_M2, eta_c_M2] = deal(nan(size(M2_vec)));
for i = 1:length(M2_vec)
    [r,v] = ramjet_solve(P1,T1,M1,Mx,M2_vec(i),Tb,1.0,1.0,F_req,gamma,R);
    if v; eta_p_M2(i)=r.eta_p; eta_c_M2(i)=r.eta_cycle; end
end
figure(5);
plot(M2_vec,eta_p_M2,'b-','LineWidth',1.5); hold on;
plot(M2_vec,eta_c_M2,'r-','LineWidth',1.5);
xlabel('Burner Entry Mach Number M_2'); ylabel('\eta');
title('Efficiency vs Burner Entry Mach Number');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (e) Burner temperature Tb ---
Tb_vec = linspace(500, 2500, 120);
[eta_p_Tb, eta_c_Tb] = deal(nan(size(Tb_vec)));
for i = 1:length(Tb_vec)
    [r,v] = ramjet_solve(P1,T1,M1,Mx,M2,Tb_vec(i),1.0,1.0,F_req,gamma,R);
    if v; eta_p_Tb(i)=r.eta_p; eta_c_Tb(i)=r.eta_cycle; end
end
figure(6);
plot(Tb_vec,eta_p_Tb,'b-','LineWidth',1.5); hold on;
plot(Tb_vec,eta_c_Tb,'r-','LineWidth',1.5);
xlabel('Burner Temperature T_b [K]'); ylabel('\eta');
title('Efficiency vs Burner Temperature');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (f) Burner pressure ratio Pb/P2 ---
Pb_P2_vec = linspace(0.1, 2.0, 80);
[eta_p_Pb, eta_c_Pb] = deal(nan(size(Pb_P2_vec)));
for i = 1:length(Pb_P2_vec)
    [r,v] = ramjet_solve(P1,T1,M1,Mx,M2,Tb,Pb_P2_vec(i),1.0,F_req,gamma,R);
    if v; eta_p_Pb(i)=r.eta_p; eta_c_Pb(i)=r.eta_cycle; end
end
figure(7);
plot(Pb_P2_vec,eta_p_Pb,'b-','LineWidth',1.5); hold on;
plot(Pb_P2_vec,eta_c_Pb,'r-','LineWidth',1.5);
xlabel('Burner Pressure Ratio P_b/P_2'); ylabel('\eta');
title('Efficiency vs Burner Pressure Ratio');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);

%--- (g) Exhaust pressure ratio P4/P1 ---
P4_P1_vec = linspace(0.1, 3.0, 80);
[eta_p_P4, eta_c_P4] = deal(nan(size(P4_P1_vec)));
for i = 1:length(P4_P1_vec)
    [r,v] = ramjet_solve(P1,T1,M1,Mx,M2,Tb,1.0,P4_P1_vec(i),F_req,gamma,R);
    if v; eta_p_P4(i)=r.eta_p; eta_c_P4(i)=r.eta_cycle; end
end
figure(8);
plot(P4_P1_vec,eta_p_P4,'b-','LineWidth',1.5); hold on;
plot(P4_P1_vec,eta_c_P4,'r-','LineWidth',1.5);
xlabel('Exhaust Pressure Ratio P_4/P_1'); ylabel('\eta');
title('Efficiency vs Exhaust Pressure Ratio');
legend('\eta_p','\eta_{cycle}','Location','best');
grid on; ylim([0 1]);


%% ========================================================
% LOCAL FUNCTION: ramjet_solve
% Inputs:  P1,T1,M1,Mx,M2,Tb,Pb_P2,P4_P1,F_req,gamma,R
% Outputs: res (struct of all results), valid (logical flag)
% ========================================================
function [res, valid] = ramjet_solve(P1,T1,M1,Mx,M2,Tb,Pb_P2,P4_P1,F_req,gamma,R)
    valid = false;
    res   = struct();
    try
        % --- Inlet (1 -> C1, isentropic) ---
        T01_T1    = 1 + ((gamma-1)/2)*M1^2;
        P01_P1    = T01_T1^(gamma/(gamma-1));
        A1_Astar  = (1/M1)*((2/(gamma+1))*T01_T1)^((gamma+1)/(2*(gamma-1)));
        AC1_A1    = 1/A1_Astar;

        % --- Normal shock (x -> y) ---
        if Mx < 1 || Mx >= M1; return; end
        My        = sqrt(((gamma-1)*Mx^2 + 2) / (2*gamma*Mx^2 - (gamma-1)));
        Py_Px     = (2*gamma*Mx^2 - (gamma-1)) / (gamma+1);
        Ty_Tx     = Py_Px * ((gamma+1)*Mx^2) / ((gamma-1)*Mx^2 + 2);
        rhoy_rhox = ((gamma+1)*Mx^2) / ((gamma-1)*Mx^2 + 2);
        T0x_Tx    = 1 + ((gamma-1)/2)*Mx^2;
        Ax_Axstar = (1/Mx)*((2/(gamma+1))*T0x_Tx)^((gamma+1)/(2*(gamma-1)));
        T0y_Ty    = 1 + ((gamma-1)/2)*My^2;
        Ay_Aystar = (1/My)*((2/(gamma+1))*T0y_Ty)^((gamma+1)/(2*(gamma-1)));
        As_AC1    = Ax_Axstar;

        % Stagnation pressure ratio across shock
        P0y_P0x = ((((gamma+1)/2)*Mx^2) / (1+((gamma-1)/2)*Mx^2))^(gamma/(gamma-1)) * ...
                  ((2*gamma/(gamma+1))*Mx^2 - (gamma-1)/(gamma+1))^(-1/(gamma-1));

        % --- Burner entry (y -> 2, isentropic) ---
        T02_T2    = 1 + ((gamma-1)/2)*M2^2;
        P02_P2    = T02_T2^(gamma/(gamma-1));
        A2_A2star = (1/M2)*((2/(gamma+1))*T02_T2)^((gamma+1)/(2*(gamma-1)));
        A2_A1     = A2_A2star * (1/Ay_Aystar) * As_AC1 * AC1_A1;

        % T0 conserved across adiabatic shock: T0y = T0x = T01
        T0y = T1 * T01_T1;
        T02 = T0y;
        T2  = T02 / T02_T2;
        if T2 <= 0 || T2 >= Tb; return; end   % nonphysical T2

        P0y = P1 * P01_P1 * P0y_P0x;
        P02 = P0y;
        P2  = P02 / P02_P2;

        % --- Burner (2 -> b, constant pressure Pb = Pb_P2 * P2) ---
        % Quadratic from lecture (slide 39), combining mass + momentum with Pb = Pb_P2*P2:
        % Note: the quadratic below is derived assuming Pb = P2 (Pb_P2 = 1).
        % When Pb_P2 ≠ 1 the momentum equation changes; here we retain the
        % standard form and account for Pb_P2 only in the pressure chain.
        disc = (T2/Tb)*(M2 + 1/(gamma*M2))^2 - 4/gamma;
        if disc < -1e-9; return; end   % genuinely choked, no real Mb
        disc = max(disc, 0);           % snap to zero at choking boundary

        term1  = sqrt(T2/Tb) * (M2 + 1/(gamma*M2));
        term2  = sqrt(disc);
        Mb_pos = 0.5*term1 + 0.5*term2;
        Mb_neg = 0.5*term1 - 0.5*term2;

        % Choose subsonic root (0 < Mb < 1) for subsonic combustion ramjet
        if     Mb_neg > 0 && Mb_neg < 1; Mb = Mb_neg;
        elseif Mb_pos > 0 && Mb_pos < 1; Mb = Mb_pos;
        else; return;
        end
        
        % Burner exit area from momentum conservation (Pb = P2)
        Ab_A2 = (1 + gamma*M2^2) / (1 + gamma*Mb^2);
        Ab_A1 = Ab_A2 * A2_A1;

        % Burner exit stagnation conditions
        Pb      = Pb_P2 * P2;
        T0b_Tb  = 1 + ((gamma-1)/2)*Mb^2;
        T0b     = Tb * T0b_Tb;
        P0b_Pb  = T0b_Tb^(gamma/(gamma-1));
        P0b     = Pb * P0b_Pb; %#ok

        % --- Nozzle throat (b -> C2, isentropic) ---
        Ab_Abstar = (1/Mb)*((2/(gamma+1))*T0b_Tb)^((gamma+1)/(2*(gamma-1)));
        AC2_A1    = (1/Ab_Abstar) * Ab_A1;

        % --- Nozzle exit (C2 -> 4, isentropic) ---
        % Full stagnation pressure chain (all =1 terms cancel):
        % P04/P4 = (P0b/Pb) * (Pb/P2) * (P2/P02) * (P0y/P0x) * (P01/P1) * (P1/P4)
        %        =  P0b_Pb  *  Pb_P2  * 1/P02_P2  *  P0y_P0x  *  P01_P1  * 1/P4_P1
        P04_P4 = P0b_Pb * Pb_P2 * (1/P02_P2) * P0y_P0x * P01_P1 * (1/P4_P1);
        if P04_P4 <= 1; return; end

        M4 = sqrt((2/(gamma-1)) * (P04_P4^((gamma-1)/gamma) - 1));

        T04_T4    = 1 + ((gamma-1)/2)*M4^2;
        T4        = T0b / T04_T4;
        if T4 <= 0; return; end

        A4_A4star = (1/M4)*((2/(gamma+1))*T04_T4)^((gamma+1)/(2*(gamma-1)));
        A4_A1     = A4_A4star * AC2_A1;

        % --- Velocities ---
        U4 = M4 * sqrt(gamma*R*T4);
        U1 = M1 * sqrt(gamma*R*T1);

        % --- Thrust (general P4, from momentum + pressure terms) ---
        % F = rho4*U4^2*A4 + P4*A4 - rho1*U1^2*A1 - P1*A1
        %   = gamma*P4*M4^2*A4 + P4*A4 - gamma*P1*M1^2*A1 - P1*A1   [ideal gas: rho*U^2=gamma*P*M^2]
        % Divide by P1*A1:
        % F/(P1*A1) = (gamma*M4^2 + 1)*P4_P1*A4_A1 - (gamma*M1^2 + 1)
        F_over_P1A1 = gamma * (M4^2*P4_P1*A4_A1-M1^2) + (P4_P1 - 1)*A4_A1;
        if F_over_P1A1 <= 0; return; end

        A1_val = F_req / (P1 * F_over_P1A1);

        % --- Efficiencies ---
        eta_p     = 2*U1 / (U4 + U1);   % propulsive efficiency
        eta_cycle = 1 - (T4 - T1)/(Tb - T2);          % thermodynamic cycle efficiency (not ideal Brayton)

        % --- Pack all results ---
        res.T01_T1      = T01_T1;
        res.P01_P1      = P01_P1;
        res.AC1_A1      = AC1_A1;
        res.My          = My;
        res.Py_Px       = Py_Px;
        res.Ty_Tx       = Ty_Tx;
        res.rhoy_rhox   = rhoy_rhox;
        res.P0y_P0x     = P0y_P0x;
        res.T02_T2      = T02_T2;
        res.A2_A2star   = A2_A2star;
        res.A2_A1       = A2_A1;
        res.T2          = T2;
        res.P2          = P2;
        res.Mb          = Mb;
        res.Ab_A2       = Ab_A2;
        res.Ab_A1       = Ab_A1;
        res.T0b         = T0b;
        res.Ab_Abstar   = Ab_Abstar;
        res.AC2_A1      = AC2_A1;
        res.P04_P4      = P04_P4;
        res.M4          = M4;
        res.T4          = T4;
        res.U4          = U4;
        res.U1          = U1;
        res.A4_A1       = A4_A1;
        res.F_over_P1A1 = F_over_P1A1;
        res.A1          = A1_val;
        res.AC1         = AC1_A1  * A1_val;
        res.A2          = A2_A1   * A1_val;
        res.Ab          = Ab_A1   * A1_val;
        res.AC2         = AC2_A1  * A1_val;
        res.A4          = A4_A1   * A1_val;
        res.eta_p       = eta_p;
        res.eta_cycle   = eta_cycle;

        valid = true;
    catch
        valid = false;
    end
end

%% ========================================================
% LOCAL FUNCTION: print_results
% ========================================================
function print_results(r)
    fprintf('\n--- INLET ---\n');
    fprintf('T01/T1    = %.4f\n', r.T01_T1);
    fprintf('P01/P1    = %.4f\n', r.P01_P1);
    fprintf('AC1/A1    = %.4f\n', r.AC1_A1);

    fprintf('\n--- NORMAL SHOCK ---\n');
    fprintf('My        = %.4f\n', r.My);
    fprintf('Py/Px     = %.4f\n', r.Py_Px);
    fprintf('Ty/Tx     = %.4f\n', r.Ty_Tx);
    fprintf('rho_y/rho_x = %.4f\n', r.rhoy_rhox);
    fprintf('P0y/P0x   = %.4f\n', r.P0y_P0x);

    fprintf('\n--- BURNER ENTRY ---\n');
    fprintf('T02/T2    = %.4f\n', r.T02_T2);
    fprintf('A2/A2*    = %.4f\n', r.A2_A2star);
    fprintf('A2/A1     = %.4f\n', r.A2_A1);
    fprintf('T2        = %.2f K\n', r.T2);
    fprintf('P2        = %.2f Pa\n', r.P2);

    fprintf('\n--- BURNER ---\n');
    fprintf('Mb        = %.4f\n', r.Mb);
    fprintf('Ab/A2     = %.4f\n', r.Ab_A2);
    fprintf('Ab/A1     = %.4f\n', r.Ab_A1);
    fprintf('T0b       = %.2f K\n', r.T0b);

    fprintf('\n--- NOZZLE ---\n');
    fprintf('Ab/Ab*    = %.4f\n', r.Ab_Abstar);
    fprintf('AC2/A1    = %.4f\n', r.AC2_A1);
    fprintf('P04/P4    = %.4f\n', r.P04_P4);
    fprintf('M4        = %.4f\n', r.M4);
    fprintf('T4        = %.2f K\n', r.T4);
    fprintf('U4        = %.2f m/s\n', r.U4);
    fprintf('U1        = %.2f m/s\n', r.U1);
    fprintf('A4/A1     = %.4f\n', r.A4_A1);

    fprintf('\n--- THRUST & AREAS ---\n');
    fprintf('F/(P1*A1) = %.4f\n', r.F_over_P1A1);
    fprintf('A1  (Inlet area)         = %.6f m^2\n', r.A1);
    fprintf('AC1 (Inlet throat area)  = %.6f m^2\n', r.AC1);
    fprintf('A2  (Burner entry area)  = %.6f m^2\n', r.A2);
    fprintf('Ab  (Burner exit area)   = %.6f m^2\n', r.Ab);
    fprintf('AC2 (Nozzle throat area) = %.6f m^2\n', r.AC2);
    fprintf('A4  (Exhaust area)       = %.6f m^2\n', r.A4);

    fprintf('\n--- EFFICIENCY ---\n');
    fprintf('eta_p     = %.4f (%.2f%%)\n', r.eta_p,     r.eta_p*100);
    fprintf('eta_cycle = %.4f (%.2f%%)\n', r.eta_cycle, r.eta_cycle*100);
end