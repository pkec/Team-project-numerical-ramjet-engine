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

P1    = 2760;   % (a) Freestream pressure [Pa]
T1    = 221;    % (a) Freestream temperature [K]
M1    = 3.2;    % (b) Flight Mach number
Mx    = 1.2;    % (c) Normal shock strength (Mach just before shock)
M2    = 0.3;    % (d) Burner entry Mach number
Tb    = 1400;   % (e) Burner temperature [K]
Pb_P2 = 1.0;    % (f) Burner pressure ratio (ideal = 1)
P4_P1 = 1.0;    % (g) Exhaust pressure ratio (ideal = 1)
F_req = 50e3;   % (h) Required thrust [N]

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

% ========================================================
% THIS MARKS THE BEGINNING OF PLOTTING LOGIC SECTION
% ========================================================

param_names = {'M1','T1','P1','Mx','M2','Tb','Pb_P2','P4_P1'};

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

% Parameter sweep vectors. Parameters correspond to titles above
vecs{1} = linspace(2.5,  6.0,   120);
vecs{2} = linspace(100,  600,    80);
vecs{3} = linspace(1e3,  101e3,  80);
vecs{4} = linspace(0,    6,      80);
vecs{5} = linspace(0.0,  1,    80);
vecs{6} = linspace(0,  1800,  120);
vecs{7} = linspace(0.7,  1,    80);
vecs{8} = linspace(0.3,  13,    80);

x_scale = [1, 1, 1e-3, 1, 1, 1, 1, 1];  % P1 displayed in kPa

% Beginning of plotting function
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
        [r,v] = ramjet_solve(p1_i,t1_i,m1_i,mx_i,m2_i,tb_i,pb_i,ep_i,F_req,gamma,R, ...
                              param_names{fig}, vec(i)*x_scale(fig));
        if v
            eta_p_vec(i) = r.eta_p;
            eta_c_vec(i) = r.eta_cycle;
        end
    end

    x_plot = vec * x_scale(fig);

    figure(fig); clf; hold on;

    % --- Compute y-axis limits ---
    all_eta = [eta_p_vec, eta_c_vec];
    y_min = min(min(all_eta, [], 'omitnan') - 0.1, 0.0);
    y_max = max(max(all_eta, [], 'omitnan') + 0.1, 1.15);



    % --- Identify bad regions ---
    % Rules:
    %   (1) NaN = no solution — always bad
    %   (2) eta_cycle < 0 = thermodynamic efficiency negative — always impossible
    %   (3) eta_p > 1 = impossible for all plots EXCEPT fig 8 (EPR), where
    %       P4/P1 varies and pressure thrust can legitimately push eta_p > 1
    %   (4) When multiple conditions trigger, the EARLIEST (leftmost) onset is used
    %       since is_bad is a logical OR — the shading starts at whichever comes first
    is_nan    = isnan(eta_p_vec) | isnan(eta_c_vec);
    is_neg_ec = (~is_nan) & (eta_c_vec < 0);
    if fig == 8
        % EPR plot: eta_p > 1 is achievable via pressure thrust — exclude from bad
        is_over = (~is_nan) & (eta_c_vec > 1);
    else
        is_over = (~is_nan) & ((eta_p_vec > 1) | (eta_c_vec > 1));
    end
    is_bad = is_nan | is_neg_ec | is_over;

    % Find contiguous bad blocks
    starts_b = find(diff([false, is_bad]) ==  1);
    ends_b   = find(diff([is_bad, false]) == -1);

    h4 = [];
    for k = 1:length(starts_b)
        sb = starts_b(k);
        eb = ends_b(k);

        % --- Determine if this is a LEFT-side block (starts at or near index 1)
        %     or a RIGHT-side / interior block ---
        is_left_block = (sb == 1);

        if is_left_block
            % LEFT side: shade from x_plot(1) to the interpolated crossing point
            % where the bad region ENDS and valid region begins
            if eb < n
                % Interpolate exit crossing between eb and eb+1
                x_prev = x_plot(eb);
                x_curr = x_plot(eb+1);
                ep_prev = eta_p_vec(eb);   ep_curr = eta_p_vec(eb+1);
                ec_prev = eta_c_vec(eb);   ec_curr = eta_c_vec(eb+1);
                x_cross_p = Inf; x_cross_c = Inf; x_cross_cn = Inf;
                if ~isnan(ep_prev) && ~isnan(ep_curr) && (ep_prev>1) && (ep_curr<=1)
                    x_cross_p = x_prev + (ep_prev-1)/(ep_prev-ep_curr)*(x_curr-x_prev);
                end
                if ~isnan(ec_prev) && ~isnan(ec_curr) && (ec_prev>1) && (ec_curr<=1)
                    x_cross_c = x_prev + (ec_prev-1)/(ec_prev-ec_curr)*(x_curr-x_prev);
                end
                if ~isnan(ec_prev) && ~isnan(ec_curr) && (ec_prev<0) && (ec_curr>=0)
                    x_cross_cn = x_prev + (0-ec_prev)/(ec_curr-ec_prev)*(x_curr-x_prev);
                end
                % Use the earliest (leftmost) crossing as the right edge
                x_cross = min([x_cross_p, x_cross_c, x_cross_cn]);
                if isinf(x_cross); x_cross = x_curr; end
            else
                x_cross = x_plot(end);
            end
            x_lo = x_plot(1);
            x_hi = x_cross;

        else
            % RIGHT side or interior: find left boundary
            if sb > 1
                x_prev = x_plot(sb-1); x_curr = x_plot(sb);
                ep_prev = eta_p_vec(sb-1); ep_curr = eta_p_vec(sb);
                ec_prev = eta_c_vec(sb-1); ec_curr = eta_c_vec(sb);
                x_cross_p = Inf; x_cross_c = Inf; x_cross_cn = Inf;
                if ~isnan(ep_prev) && ~isnan(ep_curr) && (ep_prev<=1) && (ep_curr>1)
                    x_cross_p = x_prev + (1-ep_prev)/(ep_curr-ep_prev)*(x_curr-x_prev);
                end
                if ~isnan(ec_prev) && ~isnan(ec_curr) && (ec_prev<=1) && (ec_curr>1)
                    x_cross_c = x_prev + (1-ec_prev)/(ec_curr-ec_prev)*(x_curr-x_prev);
                end
                if ~isnan(ec_prev) && ~isnan(ec_curr) && (ec_prev>=0) && (ec_curr<0)
                    x_cross_cn = x_prev + (0-ec_prev)/(ec_curr-ec_prev)*(x_curr-x_prev);
                end
                x_lo = min([x_cross_p, x_cross_c, x_cross_cn]);
                % If no crossing found (e.g. NaN block), extend to last valid point
                if isinf(x_lo); x_lo = x_prev; end
            else
                x_lo = x_plot(sb);
            end
            % Right boundary: interpolate where bad region ends, or use next valid point
            if eb < n && ~is_bad(eb+1)
                x_prev = x_plot(eb); x_curr = x_plot(eb+1);
                ep_prev = eta_p_vec(eb); ep_curr = eta_p_vec(eb+1);
                ec_prev = eta_c_vec(eb); ec_curr = eta_c_vec(eb+1);
                x_cross_p = Inf; x_cross_c = Inf; x_cross_cn = Inf;
                if ~isnan(ep_prev) && ~isnan(ep_curr) && (ep_prev>1) && (ep_curr<=1)
                    x_cross_p = x_prev + (ep_prev-1)/(ep_prev-ep_curr)*(x_curr-x_prev);
                end
                if ~isnan(ec_prev) && ~isnan(ec_curr) && (ec_prev>1) && (ec_curr<=1)
                    x_cross_c = x_prev + (ec_prev-1)/(ec_prev-ec_curr)*(x_curr-x_prev);
                end
                if ~isnan(ec_prev) && ~isnan(ec_curr) && (ec_prev<0) && (ec_curr>=0)
                    x_cross_cn = x_prev + (0-ec_prev)/(ec_curr-ec_prev)*(x_curr-x_prev);
                end
                x_hi = min([x_cross_p, x_cross_c, x_cross_cn]);
                % If no crossing (e.g. NaN block ending), extend to next valid point
                if isinf(x_hi); x_hi = x_curr; end
            else
                x_hi = x_plot(end);
            end
        end

        h4 = fill([x_lo, x_hi, x_hi, x_lo], ...
                  [y_min, y_min, y_max, y_max], ...
                  [0.6 0.6 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.35);

        % Dashed line at the meaningful boundary:
        % left block -> right edge (where valid region begins)
        % right block -> left edge (where impossible region begins)
        if is_left_block
            xline(x_hi, 'k--', sprintf('%.2f', x_hi), ...
                  'FontSize', 14, 'LabelVerticalAlignment', 'bottom', ...
                  'LabelHorizontalAlignment', 'right', 'LineWidth', 1.2);
        else
            xline(x_lo, 'k--', sprintf('%.2f', x_lo), ...
                  'FontSize', 14, 'LabelVerticalAlignment', 'bottom', ...
                  'LabelHorizontalAlignment', 'left', 'LineWidth', 1.2);
        end
    end

    % --- eta = 1 reference line ---
    plot([x_plot(1), x_plot(end)], [1, 1], 'k-', 'LineWidth', 1.0);

    % --- Efficiency curves (plotted on top of shading) ---
    h1 = plot(x_plot, eta_p_vec, 'b-',  'LineWidth', 1.8);
    h2 = plot(x_plot, eta_c_vec, 'r--', 'LineWidth', 1.8);

    ylim([y_min, y_max]);
    xlabel(x_labels{fig}, 'FontSize', 22, 'FontWeight', 'bold');
    ylabel('\eta',         'FontSize', 22, 'FontWeight', 'bold');
    title(titles{fig},     'FontSize', 24, 'FontWeight', 'bold');
    if ~isempty(h4)
        legend([h1 h2 h4], '\eta_p', '\eta_{cycle}', ...
               'Impossible / No solution', 'Location', 'best', 'FontSize', 16);
    else
        legend([h1 h2], '\eta_p', '\eta_{cycle}', ...
               'Location', 'best', 'FontSize', 16);
    end
    set(gca, 'FontSize', 20);
    grid on;
end

% ========================================================
% THIS MARKS THE END OF PLOTTING LOGIC SECTION
% ========================================================

% ========================================================
% THIS MARKS THE BEGINNING OF COMPUTATION SECTION
% ========================================================

%% ========================================================
% LOCAL FUNCTION: ramjet_solve
% Inputs:  P1,T1,M1,Mx,M2,Tb,Pb_P2,P4_P1,F_req,gamma,R
% Outputs: res (struct of all results), valid (logical flag)
% ========================================================
function [res, valid] = ramjet_solve(P1,T1,M1,Mx,M2,Tb,Pb_P2,P4_P1,F_req,gamma,R,swept_var,swept_val)
    if nargin < 12; swept_var = 'baseline'; swept_val = NaN; end
    valid = false;
    res   = struct();
    try
        % --- Inlet (1 -> C1, isentropic) ---
        % The following are all standard isentropic flow relations
        T01_T1    = 1 + ((gamma-1)/2)*M1^2; 
        P01_P1    = T01_T1^(gamma/(gamma-1));
        A1_Astar  = (1/M1)*((2/(gamma+1))*T01_T1)^((gamma+1)/(2*(gamma-1)));
        AC1_A1    = 1/A1_Astar;

        % --- Normal shock (x -> y) ---
        % The following are all standard normal shock equations
        if Mx < 1;  return; end  % It assumed that there must be a shock hence Mx must be supersonic
        My        = sqrt(((gamma-1)*Mx^2 + 2) / (2*gamma*Mx^2 - (gamma-1))); 
        Py_Px     = (2*gamma*Mx^2 - (gamma-1)) / (gamma+1); 
        Ty_Tx     = Py_Px * ((gamma+1)*Mx^2) / ((gamma-1)*Mx^2 + 2);
        rhoy_rhox = ((gamma+1)*Mx^2) / ((gamma-1)*Mx^2 + 2);
        T0x_Tx    = 1 + ((gamma-1)/2)*Mx^2;
        Ax_Axstar = (1/Mx)*((2/(gamma+1))*T0x_Tx)^((gamma+1)/(2*(gamma-1)));
        T0y_Ty    = 1 + ((gamma-1)/2)*My^2;
        Ay_Aystar = (1/My)*((2/(gamma+1))*T0y_Ty)^((gamma+1)/(2*(gamma-1)));
        As_AC1    = Ax_Axstar; % By design, at X and C1, is located at the same position.

        % Stagnation pressure ratio across shock
        % Shock relation used
        P0y_P0x = ((((gamma+1)/2)*Mx^2) / (1+((gamma-1)/2)*Mx^2))^(gamma/(gamma-1)) * ...
                  ((2*gamma/(gamma+1))*Mx^2 - (gamma-1)/(gamma+1))^(-1/(gamma-1));

        % --- Burner entry (y -> 2, isentropic) ---
        % The following are all standard isentropic flow relations
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

        % If discriminant is negative, no real Mb exists — burner is choked, notify user of error
        if disc < 0
            fprintf('\n*** CHOKED BURNER: Discriminant = %.6f < 0 ***\n', disc);
            fprintf('    No real solution for Mb exists.\n');
            fprintf('    Tb/T2 = %.4f exceeds maximum allowable.\n', Tb/T2);
            fprintf('    T2 = %.2f K,  Tb = %.2f K\n', T2, Tb);
            fprintf('    Variable being varied: %s = %.4f\n', swept_var, swept_val);
            valid = false;
            return;
        end

        % Solving for Mb quadratically
        term1  = sqrt(T2/Tb) * (M2 + 1/(gamma*M2));
        term2  = sqrt(disc);
        Mb_pos = 0.5*term1 + 0.5*term2;
        Mb_neg = 0.5*term1 - 0.5*term2;

        % Choose subsonic root (0 < Mb < 1) else identify non-real solutions then notify user of error
        % Supersonic combustion (Mb > 1) not considered as not a scramjet
        
        if     Mb_neg > 0 && Mb_neg < 1; Mb = Mb_neg;
        elseif Mb_pos > 0 && Mb_pos < 1; Mb = Mb_pos;
        else
            fprintf('\n*** ERROR: Neither Mb root is subsonic ***\n');
            fprintf('    Mb+ = %.4f,  Mb- = %.4f\n', Mb_pos, Mb_neg);
            error('No subsonic Mb root found: Mb+ = %.4f, Mb- = %.4f', Mb_pos, Mb_neg);
        end

        % Burner exit area from momentum conservation (Pb = P2)
        % The following are all standard isentropic flow relations
        Ab_A2 = (1 + gamma*M2^2) / (1 + gamma*Mb^2);
        Ab_A1 = Ab_A2 * A2_A1;

        % Burner exit stagnation conditions
        % The following are all standard isentropic flow relations
        Pb      = Pb_P2 * P2;
        T0b_Tb  = 1 + ((gamma-1)/2)*Mb^2;
        T0b     = Tb * T0b_Tb;
        P0b_Pb  = T0b_Tb^(gamma/(gamma-1));
        P0b     = Pb * P0b_Pb;

        % --- Nozzle throat (b -> C2, isentropic) ---
        % The following are all standard isentropic flow relations
        Ab_Abstar = (1/Mb)*((2/(gamma+1))*T0b_Tb)^((gamma+1)/(2*(gamma-1)));
        AC2_A1    = (1/Ab_Abstar) * Ab_A1;

        % --- Nozzle exit (C2 -> 4, isentropic) ---
        % Full stagnation pressure chain:
        % P04/P4 = (P0b/Pb) * (Pb/P2) * (P2/P02) * (P0y/P0x) * (P01/P1) * (P1/P4)
        %        =  P0b_Pb  *  Pb_P2  * 1/P02_P2  *  P0y_P0x  *  P01_P1  * 1/P4_P1
        P04_P4 = P0b_Pb * Pb_P2 * (1/P02_P2) * P0y_P0x * P01_P1 * (1/P4_P1);
        % P04_P4 <= 1 would give imaginary M4, leading to code crashing
        %Notify user of error
        if P04_P4 <= 1
            fprintf('\n*** ERROR: Unacceptable P04/P4 ***\n');
            error('P04/P4 = %.4f', P04/P4);
        end
        
        % The following are all standard isentropic flow relations
        
        M4 = sqrt((2/(gamma-1)) * (P04_P4^((gamma-1)/gamma) - 1));

        T04_T4    = 1 + ((gamma-1)/2)*M4^2;
        T4        = T0b / T04_T4;
        % T4 <= 0 nonphysical but allowed for stress testing

        A4_A4star = (1/M4)*((2/(gamma+1))*T04_T4)^((gamma+1)/(2*(gamma-1)));
        A4_A1     = A4_A4star * AC2_A1;

        % --- Velocities ---
        U4 = M4 * sqrt(gamma*R*T4);
        U1 = M1 * sqrt(gamma*R*T1);

        % --- Thrust ---
        % F/(P1*A1) = gamma*(M4^2*(P4/P1)*(A4/A1) - M1^2) + (P4/P1 - 1)*(A4/A1)
        % Non-dimensionalised thrust
        F_over_P1A1 = gamma*(M4^2*P4_P1*A4_A1 - M1^2) + (P4_P1 - 1)*A4_A1;
        % Note: negative value means drag — efficiencies still computed
        A1_val = F_req / (P1 * F_over_P1A1);

        % --- Efficiencies ---
        % Propulsive efficiency from lecture (general, no ideal expansion assumption):
        % eta_p = (F/P1A1) * (2*R*T1) / (U4^2 - U1^2) 
        eta_p     = F_over_P1A1 * (2*R*T1) / (U4^2 - U1^2); % Thrust over jet kinetic energy
        eta_cycle = 1 - (T4 - T1)/(Tb - T2); % Cycle efficiency formula not assuming ideal expansion

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

% ========================================================
% THIS MARKS THE END OF COMPUTATION SECTION
% ========================================================


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