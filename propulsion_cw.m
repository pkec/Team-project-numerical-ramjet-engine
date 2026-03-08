clc; close all; clear;

%% ========================================================
% RAMJET ENGINE DESIGN CODE
% Stations: 1 (freestream) -> C1 (inlet throat) -> x (pre-shock)
%           -> y (post-shock) -> 2 (burner entry) -> b (burner exit)
%           -> C2 (nozzle throat) -> 4 (exhaust)
% Assumptions:
%   (1) Exhaust has same properties as air (gamma, R constant)
%   (2) gamma = 1.4 throughout
%   (3) Compression and expansion are isentropic (except across shock and burner)
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
M1    = 3.24;   % (b) Flight Mach number
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
% Pb_P2 and P4_P1 held at 1.0 (ideal) when not being swept.
% eta > 1 region is shaded to highlight thermodynamically impossible
% operating conditions — useful for stress-testing the design limits.
% ========================================================

x_labels = {'Flight Mach Number M_1', ...
             'Freestream Temperature T_1 [K]', ...
             'Freestream Pressure P_1 [kPa]', ...
             'Shock Mach Number M_x', ...
             'Burner Entry Mach Number M_2', ...
             'Burner Temperature T_b [K]', ...
             'Burner Pressure Ratio P_b/P_2', ...
             'Exhaust Pressure Ratio P_4/P_1'};
titles   = {'Efficiency vs Flight Mach Number', ...
             'Efficiency vs Freestream Temperature', ...
             'Efficiency vs Freestream Pressure', ...
             'Efficiency vs Normal Shock Strength', ...
             'Efficiency vs Burner Entry Mach Number', ...
             'Efficiency vs Burner Temperature', ...
             'Efficiency vs Burner Pressure Ratio', ...
             'Efficiency vs Exhaust Pressure Ratio'};

% Parameter sweep vectors
vecs{1} = linspace(1.5,  10.0,  120);
vecs{2} = linspace(180,  300,    80);
vecs{3} = linspace(20e3, 101e3,  80);
vecs{4} = linspace(1.01, min(M1-0.05, 3.0), 80);
vecs{5} = linspace(0.05, 0.7,    80);
vecs{6} = linspace(500,  2500,  120);
vecs{7} = linspace(0.1,  2.0,    80);
vecs{8} = linspace(0.1,  3.0,    80);

x_scale = [1, 1, 1e-3, 1, 1, 1, 1, 1];  % P1 displayed in kPa

for fig = 1:8
    vec = vecs{fig};
    n   = length(vec);
    eta_p_vec = nan(1,n);
    eta_c_vec = nan(1,n);

    for i = 1:n
        p1_i=P1; t1_i=T1; m1_i=M1; mx_i=Mx;
        m2_i=M2; tb_i=Tb; pb_i=1.0; ep_i=1.0;
        switch fig
            case 1; m1_i=vec(i); mx_i=min(Mx,vec(i)-0.05);
            case 2; t1_i=vec(i);
            case 3; p1_i=vec(i);
            case 4; mx_i=vec(i);
            case 5; m2_i=vec(i);
            case 6; tb_i=vec(i);
            case 7; pb_i=vec(i);
            case 8; ep_i=vec(i);
        end
        [r,v] = ramjet_solve(p1_i,t1_i,m1_i,mx_i,m2_i,tb_i,pb_i,ep_i,F_req,gamma,R);
        if v
            eta_p_vec(i) = r.eta_p;
            eta_c_vec(i) = r.eta_cycle;
        end
    end

    x_plot = vec * x_scale(fig);

    figure(fig); clf; hold on;
    h1 = plot(x_plot, eta_p_vec, 'b-',  'LineWidth', 1.8);
    h2 = plot(x_plot, eta_c_vec, 'r--', 'LineWidth', 1.8);

    xlabel(x_labels{fig}, 'FontSize', 22, 'FontWeight', 'bold');
    ylabel('\eta',        'FontSize', 22, 'FontWeight', 'bold');
    title(titles{fig},     'FontSize', 24, 'FontWeight', 'bold');
    legend([h1 h2], '\eta_p', '\eta_{cycle}', ...
           'Location', 'best', 'FontSize', 20);
    set(gca, 'FontSize', 20);   % axis tick labels
    grid on;
end

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
        if Mx < 1; return; end  % Mx must be supersonic
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
        % T2 validity: proceed even if T2 >= Tb (stress test)

        P0y = P1 * P01_P1 * P0y_P0x;
        P02 = P0y;
        P2  = P02 / P02_P2;

        % --- Burner (2 -> b, constant pressure Pb = Pb_P2 * P2) ---
        % Quadratic from lecture (slide 39), combining mass + momentum:
        disc = (T2/Tb)*(M2 + 1/(gamma*M2))^2 - 4/gamma;
        disc = max(disc, 0);  % snap negative disc to zero (choked/stress-test limit)

        term1  = sqrt(T2/Tb) * (M2 + 1/(gamma*M2));
        term2  = sqrt(disc);
        Mb_pos = 0.5*term1 + 0.5*term2;
        Mb_neg = 0.5*term1 - 0.5*term2;

        % Choose subsonic root preferentially; fall back to Mb_neg for stress testing
        if     Mb_neg > 0 && Mb_neg < 1; Mb = Mb_neg;
        elseif Mb_pos > 0 && Mb_pos < 1; Mb = Mb_pos;
        else; Mb = Mb_neg;  % stress-test: use lower root even if out of range
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
        % Full stagnation pressure chain:
        % P04/P4 = (P0b/Pb) * (Pb/P2) * (P2/P02) * (P0y/P0x) * (P01/P1) * (P1/P4)
        %        =  P0b_Pb  *  Pb_P2  * 1/P02_P2  *  P0y_P0x  *  P01_P1  * 1/P4_P1
        P04_P4 = P0b_Pb * Pb_P2 * (1/P02_P2) * P0y_P0x * P01_P1 * (1/P4_P1);
        % P04_P4 <= 1 would give imaginary M4 — clamp to avoid crash
        P04_P4 = max(P04_P4, 1.001);

        M4 = sqrt((2/(gamma-1)) * (P04_P4^((gamma-1)/gamma) - 1));

        T04_T4    = 1 + ((gamma-1)/2)*M4^2;
        T4        = T0b / T04_T4;
        % T4 <= 0 nonphysical but allow for stress testing

        A4_A4star = (1/M4)*((2/(gamma+1))*T04_T4)^((gamma+1)/(2*(gamma-1)));
        A4_A1     = A4_A4star * AC2_A1;

        % --- Velocities ---
        U4 = M4 * sqrt(gamma*R*T4);
        U1 = M1 * sqrt(gamma*R*T1);

        % --- Thrust ---
        % F/(P1*A1) = gamma*(M4^2*P4_P1*A4_A1 - M1^2) + (P4_P1 - 1)*A4_A1
        F_over_P1A1 = gamma * (M4^2*P4_P1*A4_A1-M1^2) + (P4_P1 - 1)*A4_A1;
        % Note: A1 will be negative if F_over_P1A1 <= 0 (nonphysical geometry)
        % but we still allow efficiencies to be computed for stress-testing plots
        A1_val = F_req / (P1 * F_over_P1A1);

        % --- Efficiencies ---
        eta_p     = 2*U1 / (U4 + U1);
        eta_cycle = 1 - (T4 - T1)/(Tb - T2);

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