function visualize_all_4_scenarios(T_sim)
% VISUALIZE_ALL_4_SCENARIOS Mô phỏng đồng thời 4 kịch bản tư thế (K1, K2, K3, K4)
% Đề tài: Thắt lưng chống gù thông minh - Nhóm 4 (PTIT HCM)
%
% Bố cục: Khung lưới 2x2 chạy song song 4 kịch bản trong thời gian thực:
%   - Ô 1 (Trên - Trái): K1 - Ngồi thẳng chuẩn (5°) [An toàn]
%   - Ô 2 (Trên - Phải): K2 - Gù lưng tiến triển (5° -> 20°) [Rung cảnh báo]
%   - Ô 3 (Dưới - Trái): K3 - Cúi nhặt đồ 3s (1.5s > 15° < 3s) [Không rung nhầm - FAR = 0%]
%   - Ô 4 (Dưới - Phải): K4 - Đi lại / Di chuyển [Đứng bước đi & Khóa rung bằng gia tốc động]
%
% Cú pháp chạy trên MATLAB Online:
%   visualize_all_4_scenarios;       % Mặc định chạy 20 giây
%   visualize_all_4_scenarios(25);   % Chạy 25 giây

    if nargin < 1 || isempty(T_sim), T_sim = 20; end

    dt = 0.02; % Tần số lấy mẫu Fs = 50 Hz
    t  = (0:dt:T_sim)';
    N  = length(t);

    %% 1. TÍNH TOÁN QUỸ ĐẠO GÓC CHO CẢ 4 KỊCH BẢN
    % K1: Ngồi thẳng chuẩn (5°)
    th_K1 = 5.0 + 0.2 * sin(2 * pi * 0.1 * t);

    % K2: Gù lưng tiến triển (5° -> 20°)
    th_K2 = 5.0 + 15.0 * (1.0 - exp(-t / 10.0));

    % K3: Cúi nhặt đồ trong đúng 3.0 giây (giây 5.0 -> 8.0)
    th_K3 = 5.0 * ones(N, 1);
    idx1 = t >= 5.0 & t <= 6.5;
    th_K3(idx1) = 5.0 + 20.0 * (t(idx1) - 5.0) / 1.5;
    idx2 = t > 6.5 & t <= 8.0;
    th_K3(idx2) = 25.0 - 20.0 * (t(idx2) - 6.5) / 1.5;

    % K4: Đi lại di chuyển (±7° quanh 5°)
    th_K4 = 5.0 + 7.0 * sin(2 * pi * t / 4.0);

    all_theta = [th_K1, th_K2, th_K3, th_K4];

    titles = { ...
        'K1: Ngồi thẳng chuẩn (5°) — An toàn', ...
        'K2: Gù lưng tiến triển (5° → 20°) — Rung cảnh báo', ...
        'K3: Cúi nhặt đồ 3s (1.5s > 15°) — Lọc không rung', ...
        'K4: Đi lại di chuyển — Khóa rung bằng gia tốc' ...
    };

    tags = {'K1: NGỒI CHUẨN', 'K2: GÙ TIẾN TRIỂN', 'K3: CÚI NHẶT ĐỒ 3s', 'K4: ĐI BỘ DI CHUYỂN'};

    %% 2. CHẠY THUẬT TOÁN PHÁN ĐOÁN CẢNH BÁO CHO CẢ 4 KỊCH BẢN
    theta_thresh = 15.0;  % Ngưỡng góc gù (độ)
    t_confirm    = 3.0;   % Thời gian xác nhận duy trì (giây)
    hyst         = 2.0;   % Ngưỡng tắt trễ (13.0 độ)

    all_alerts = zeros(N, 4);
    all_timers = zeros(N, 4);

    for sc = 1:4
        cur_th    = all_theta(:, sc);
        cur_timer = 0;
        is_alt    = 0;
        for k = 1:N
            is_walking = (sc == 4);
            if cur_th(k) >= theta_thresh && ~is_walking
                cur_timer = cur_timer + dt;
                if cur_timer >= t_confirm
                    is_alt = 1;
                end
            elseif cur_th(k) < (theta_thresh - hyst)
                is_alt = 0;
                cur_timer = 0;
            else
                if is_alt == 0
                    cur_timer = 0;
                end
            end
            all_alerts(k, sc) = is_alt;
            all_timers(k, sc) = cur_timer;
        end
    end

    %% 3. THIẾT KẾ GIAO DIỆN KHUNG LƯỚI 2x2 ĐỒNG BỘ NỀN TỐI HIỆN ĐẠI
    fig = figure(1);
    clf(fig);
    set(fig, 'Name', 'Mô phỏng 4 Kịch Bản Tư Thế Cùng Lúc (K1 - K4)', ...
             'NumberTitle', 'off', 'Color', [0.08 0.10 0.14]);

    % Tiêu đề tổng hợp với bộ đếm thời gian
    h_master_title = sgtitle(fig, 'MÔ PHỎNG ĐỒNG THỜI 4 KỊCH BẢN TƯ THẾ (K1 – K4) | ⏱ Thời gian: 0.0 s', ...
                             'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.85 0.92 1.0]);

    % Tham số hình học cơ thể
    L_lumbar   = 18;
    L_thoracic = 24;
    L_neck     = 10;
    R_head     = 7.0;
    theta_circle = linspace(0, 2*pi, 36);

    % Mảng lưu trữ handle đồ họa cho 4 ô
    h_torso      = gobjects(4, 1);
    h_spine      = gobjects(4, 1);
    h_neck       = gobjects(4, 1);
    h_head       = gobjects(4, 1);
    h_arm        = gobjects(4, 1);
    h_strap      = gobjects(4, 1);
    h_sensor     = gobjects(4, 1);
    h_buzz_badge = gobjects(4, 1);

    % Mảng lưu Dashboard Card (Xếp dọc tại X=63, tuyệt đối không bị đè chữ)
    h_th_txt     = gobjects(4, 1);
    h_motor_txt  = gobjects(4, 1);
    h_bar        = gobjects(4, 1);
    h_tmr_txt    = gobjects(4, 1);
    h_stat_badge = gobjects(4, 1);
    h_stat_sub   = gobjects(4, 1);

    % Handles chân đi bộ cho K4
    h_leg1  = gobjects(1); h_shoe1 = gobjects(1);
    h_leg2  = gobjects(1); h_shoe2 = gobjects(1);

    for sc = 1:4
        ax = subplot(2, 2, sc);
        hold(ax, 'on');
        set(ax, 'Color', [0.11 0.13 0.18], 'XColor', [0.35 0.4 0.5], 'YColor', [0.35 0.4 0.5], ...
                'GridColor', [0.2 0.25 0.35], 'GridAlpha', 0.4);

        % Trục tham chiếu 0° đứng thẳng
        plot(ax, [0, 0], [0, 68], 'LineStyle', ':', 'Color', [0.4 0.45 0.55], 'LineWidth', 1.1);
        text(ax, 0, 71, 'Trục 0°', 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', [0.55 0.6 0.7]);

        if sc <= 3
            % --- PHẦN TỬ CHO K1, K2, K3: NGỒI LÀM VIỆC VỚI BÀN GHẾ & LAPTOP ---
            % Ghế tựa văn phòng (X = -18 đến 14)
            plot(ax, [-15, 14], [-2, -2], 'Color', [0.38 0.44 0.54], 'LineWidth', 3.5); % Đệm ngồi
            plot(ax, [-15, -15], [-2, 42], 'Color', [0.38 0.44 0.54], 'LineWidth', 3.5); % Tựa lưng
            plot(ax, [-13, -13], [-2, -22], 'Color', [0.45 0.5 0.6], 'LineWidth', 3);    % Trục chân
            plot(ax, [-19, -7], [-22, -22], 'Color', [0.45 0.5 0.6], 'LineWidth', 2.5);  % Bánh xe
            
            % Bàn làm việc & Laptop (X = 22 đến 35)
            plot(ax, [22, 35], [14, 14], 'Color', [0.6 0.45 0.3], 'LineWidth', 3.5);     % Mặt bàn
            plot(ax, [34, 34], [14, -24], 'Color', [0.4 0.45 0.55], 'LineWidth', 2.5);   % Chân bàn
            plot(ax, [23, 31], [15, 15], 'Color', [0.7 0.75 0.8], 'LineWidth', 2);       % Đế laptop
            plot(ax, [31, 35], [15, 26], 'Color', [0.7 0.75 0.8], 'LineWidth', 2);       % Màn hình laptop
            fill(ax, [31.2, 34.8, 34.8, 31.2], [15.5, 25.5, 25.5, 15.5], [0.3 0.65 0.95], 'EdgeColor', 'none');
            
            % Chân người ngồi tĩnh
            plot(ax, [0, 18], [0, 0], 'Color', [0.25 0.38 0.55], 'LineWidth', 8.5);      % Đùi
            plot(ax, [18, 18], [0, -22], 'Color', [0.25 0.38 0.55], 'LineWidth', 7);     % Cẳng chân
            plot(ax, [16, 24], [-22, -22], 'Color', [0.15 0.15 0.2], 'LineWidth', 5);    % Giày
        else
            % --- PHẦN TỬ CHO K4: ĐI LẠI / DI CHUYỂN (MẶT SÀN & CHÂN BƯỚC ĐI) ---
            plot(ax, [-22, 36], [-22, -22], 'Color', [0.45 0.5 0.6], 'LineWidth', 3);
            plot(ax, [-22, 36], [-23, -23], 'Color', [0.3 0.35 0.45], 'LineWidth', 1.5, 'LineStyle', '--');
            
            h_leg1  = plot(ax, [0 0 0], [0 -11 -22], 'Color', [0.28 0.42 0.6], 'LineWidth', 8);
            h_shoe1 = plot(ax, [0 6], [-22 -22], 'Color', [0.15 0.15 0.2], 'LineWidth', 5);
            h_leg2  = plot(ax, [0 0 0], [0 -11 -22], 'Color', [0.2 0.3 0.45], 'LineWidth', 8);
            h_shoe2 = plot(ax, [0 6], [-22 -22], 'Color', [0.1 0.1 0.15], 'LineWidth', 5);
        end

        % CƠ THỂ NGƯỜI (Thanh thoát theo cột sống, KHÔNG có khối xanh thừa)
        h_torso(sc) = plot(ax, [0 0 0], [0 18 42], 'Color', [0.35 0.52 0.78], 'LineWidth', 11);
        h_spine(sc) = plot(ax, [0 0 0], [0 18 42], 'Color', [1.0 0.85 0.25], 'LineWidth', 3);
        h_neck(sc)  = plot(ax, [0 0], [42 53], 'Color', [0.96 0.84 0.75], 'LineWidth', 6);
        h_head(sc)  = fill(ax, R_head*cos(theta_circle), 54 + R_head*sin(theta_circle), ...
                           [0.96 0.84 0.75], 'EdgeColor', [0.55 0.4 0.3], 'LineWidth', 1.2);
        h_arm(sc)   = plot(ax, [0 0 0], [0 0 0], 'Color', [0.25 0.38 0.6], 'LineWidth', 5);

        % ĐAI THẮT LƯNG & HỘP MCU
        rectangle(ax, 'Position', [-7, -4, 14, 8], 'Curvature', 0.4, ...
                  'FaceColor', [0.2 0.32 0.52], 'EdgeColor', [0.4 0.6 0.9], 'LineWidth', 1.2);
        h_strap(sc) = plot(ax, [0 0 0], [0 18 42], 'm--', 'LineWidth', 2);

        % CẢM BIẾN IMU TẠI LƯNG TRÊN (T1-T4)
        h_sensor(sc) = plot(ax, 0, 42, 's', 'MarkerSize', 13, ...
                            'MarkerFaceColor', [0.2 0.85 0.35], 'MarkerEdgeColor', 'w', 'LineWidth', 1.2);
        h_buzz_badge(sc) = text(ax, 0, 64, '', 'FontSize', 9.5, 'FontWeight', 'bold', ...
                                'HorizontalAlignment', 'center', 'Color', [1 0.25 0.25], ...
                                'BackgroundColor', 'none', 'EdgeColor', 'none', 'Margin', 2);

        % =========================================================================
        % BẢNG ĐIỀU KHIỂN & THÔNG SỐ (DASHBOARD CARD) — BÊN PHẢI (X=[40, 86])
        % Toàn bộ nhãn được xếp thẳng hàng dọc theo tâm X = 63, KHÔNG BAO GIỜ CHỒNG CHÉO!
        % =========================================================================
        rectangle(ax, 'Position', [40, -16, 46, 88], 'Curvature', 0.08, ...
                  'FaceColor', [0.14 0.17 0.24], 'EdgeColor', [0.3 0.42 0.6], 'LineWidth', 1.2);

        % Tầng 1: Tên kịch bản (Y = 64)
        text(ax, 63, 64, tags{sc}, 'FontSize', 9, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'center', 'Color', [0.75 0.88 1.0]);
        plot(ax, [43, 83], [59, 59], 'Color', [0.25 0.35 0.5], 'LineWidth', 1);

        % Tầng 2: Góc đo điện tử to rõ (Y = 51)
        h_th_txt(sc) = text(ax, 63, 51, 'Góc: 5.0°', 'FontSize', 12, 'FontWeight', 'bold', ...
                            'HorizontalAlignment', 'center', 'Color', [0.25 0.9 0.45]);

        % Tầng 3: Trạng thái Mô-tơ (Y = 40)
        h_motor_txt(sc) = text(ax, 63, 40, 'Mô-tơ: TẮT', 'FontSize', 8.5, 'FontWeight', 'bold', ...
                               'HorizontalAlignment', 'center', 'Color', [0.7 0.75 0.85]);
        plot(ax, [43, 83], [34, 34], 'Color', [0.25 0.35 0.5], 'LineWidth', 1);

        % Tầng 4: Tiến trình lọc cử động Debounce 3.0s (Y = 14 -> 28)
        text(ax, 63, 28, 'Lọc Debounce (3.0s):', 'FontSize', 7.5, ...
             'HorizontalAlignment', 'center', 'Color', [0.75 0.8 0.9]);
        rectangle(ax, 'Position', [44, 20, 38, 5], 'Curvature', 0.4, ...
                  'FaceColor', [0.18 0.22 0.3], 'EdgeColor', [0.35 0.45 0.6]);
        h_bar(sc) = rectangle(ax, 'Position', [44, 20, 0.1, 5], 'Curvature', 0.4, ...
                              'FaceColor', [1.0 0.6 0.1], 'EdgeColor', 'none');
        h_tmr_txt(sc) = text(ax, 63, 13, '0.0s / 3.0s', 'FontSize', 8, 'FontWeight', 'bold', ...
                             'HorizontalAlignment', 'center', 'Color', [0.85 0.9 0.95]);
        plot(ax, [43, 83], [7, 7], 'Color', [0.25 0.35 0.5], 'LineWidth', 1);

        % Tầng 5: Huy hiệu trạng thái & Diễn giải (Y = -9 -> 0)
        h_stat_badge(sc) = text(ax, 63, 0, '✔ AN TOÀN', 'FontSize', 9, 'FontWeight', 'bold', ...
                                'HorizontalAlignment', 'center', 'Color', [0.25 0.9 0.45]);
        h_stat_sub(sc)   = text(ax, 63, -9, '(Tư thế chuẩn)', 'FontSize', 7.5, ...
                                'HorizontalAlignment', 'center', 'Color', [0.65 0.72 0.85]);

        title(ax, titles{sc}, 'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.85 0.92 1.0]);
        axis(ax, 'equal');
        xlim(ax, [-28, 90]);
        ylim(ax, [-26, 76]);
        grid(ax, 'on');
        box(ax, 'on');
    end

    %% 4. VÒNG LẶP ĐỒNG BỘ THỜI GIAN THỰC (REAL-TIME ANIMATION)
    frame_step = round(0.04 / dt); % 25 FPS
    t_start = tic;

    for k = 1:frame_step:N
        if ~ishandle(fig), break; end

        % Cập nhật tiêu đề tổng hợp
        set(h_master_title, 'String', ...
            sprintf('MÔ PHỎNG ĐỒNG THỜI 4 KỊCH BẢN TƯ THẾ (K1 – K4) | ⏱ Thời gian: %.1f s / %.0f s', t(k), T_sim));

        % Duyệt qua cả 4 kịch bản cùng lúc
        for sc = 1:4
            cur_th     = all_theta(k, sc);
            is_buzzing = all_alerts(k, sc);
            cur_timer  = all_timers(k, sc);

            % Tính tọa độ xương sống & đầu
            th_rad   = deg2rad(cur_th);
            x1       = L_lumbar * sin(th_rad * 0.35);
            y1       = L_lumbar * cos(th_rad * 0.35);
            x_sensor = x1 + L_thoracic * sin(th_rad);
            y_sensor = y1 + L_thoracic * cos(th_rad);
            x_neck   = x_sensor + L_neck * sin(th_rad * 1.15);
            y_neck   = y_sensor + L_neck * cos(th_rad * 1.15);
            x_head   = x_neck + R_head * sin(th_rad * 1.2);
            y_head   = y_neck + R_head * cos(th_rad * 1.2);

            % Cập nhật thân, cột sống, dây đai, cổ, đầu
            set(h_torso(sc), 'XData', [0, x1, x_sensor], 'YData', [0, y1, y_sensor]);
            set(h_spine(sc), 'XData', [0, x1, x_sensor], 'YData', [0, y1, y_sensor]);
            set(h_strap(sc), 'XData', [0, x1, x_sensor], 'YData', [0, y1, y_sensor]);
            set(h_neck(sc),  'XData', [x_sensor, x_neck], 'YData', [y_sensor, y_neck]);
            set(h_head(sc),  'XData', x_head + R_head*cos(theta_circle), ...
                             'YData', y_head + R_head*sin(theta_circle));

            % Vị trí vai
            shoulder_x = x_sensor + 1 * cos(th_rad);
            shoulder_y = y_sensor - 1 * sin(th_rad);

            if sc <= 3
                % Tay ngồi làm việc hướng về laptop
                elbow_x = shoulder_x + 5;
                elbow_y = shoulder_y - 12;
                hand_x  = 28; hand_y = 15;
                set(h_arm(sc), 'XData', [shoulder_x, elbow_x, hand_x], 'YData', [shoulder_y, elbow_y, hand_y]);
            else
                % K4: Đi bộ - chân và tay bước đi luân phiên
                phi = 2 * pi * t(k) / 1.0; % Chu kỳ bước 1 giây
                
                % Chân 1 (Chân trước)
                foot1_x = 13 * sin(phi);
                foot1_y = -22 + 2.5 * max(0, cos(phi));
                knee1_x = 7 * sin(phi);
                knee1_y = -11 + 1.2 * max(0, cos(phi));
                set(h_leg1,  'XData', [0, knee1_x, foot1_x], 'YData', [0, knee1_y, foot1_y]);
                set(h_shoe1, 'XData', [foot1_x - 1, foot1_x + 6], 'YData', [foot1_y, foot1_y]);
                
                % Chân 2 (Chân sau)
                foot2_x = -13 * sin(phi);
                foot2_y = -22 + 2.5 * max(0, -cos(phi));
                knee2_x = -7 * sin(phi);
                knee2_y = -11 + 1.2 * max(0, -cos(phi));
                set(h_leg2,  'XData', [0, knee2_x, foot2_x], 'YData', [0, knee2_y, foot2_y]);
                set(h_shoe2, 'XData', [foot2_x - 1, foot2_x + 6], 'YData', [foot2_y, foot2_y]);
                
                % Tay đánh nhẹ nhàng dọc thân
                arm_swing   = -5 * sin(phi);
                arm_elbow_x = shoulder_x + 0.5 * arm_swing;
                arm_elbow_y = shoulder_y - 12;
                arm_hand_x  = shoulder_x + arm_swing;
                arm_hand_y  = shoulder_y - 21;
                set(h_arm(sc), 'XData', [shoulder_x, arm_elbow_x, arm_hand_x], 'YData', [shoulder_y, arm_elbow_y, arm_hand_y]);
            end

            % Vị trí cảm biến IMU
            set(h_sensor(sc), 'XData', x_sensor, 'YData', y_sensor);

            % Cập nhật trạng thái CẢNH BÁO RUNG & DASHBOARD CARD
            if sc == 4
                % K4: Đi bộ - Khóa rung tự động
                set(h_sensor(sc), 'Marker', 's', 'MarkerSize', 13, 'MarkerFaceColor', [0.25 0.75 1.0]);
                set(h_buzz_badge(sc), 'String', '');
                set(h_motor_txt(sc), 'String', '🚶 MÔ-TƠ: KHÓA RUNG', 'Color', [0.35 0.75 1.0]);
                set(h_stat_badge(sc), 'String', '🚶 ĐI BỘ (KHÓA RUNG)', 'Color', [0.35 0.75 1.0]);
                set(h_stat_sub(sc), 'String', '(Khóa rung bằng gia tốc)', 'Color', [0.65 0.75 0.9]);
                set(h_tmr_txt(sc), 'String', 'KHÓA (Gia tốc động)');
                set(h_bar(sc), 'Position', [44, 20, 0.1, 5], 'FaceColor', [0.3 0.65 0.95]);
                set(h_th_txt(sc), 'String', sprintf('Góc: %.1f°', cur_th), 'Color', [0.35 0.75 1.0]);
            elseif is_buzzing
                % K2 khi gù > 3s: RUNG CẢNH BÁO
                set(h_sensor(sc), 'Marker', 'p', 'MarkerSize', 18, 'MarkerFaceColor', [1 0.2 0.2]);
                set(h_buzz_badge(sc), 'Position', [x_sensor, y_sensor + 12, 0], ...
                    'String', ' ⚡ RUNG! ', 'BackgroundColor', [0.4 0.1 0.1], 'EdgeColor', 'r', 'LineWidth', 1.2);
                set(h_motor_txt(sc), 'String', '⚡ MÔ-TƠ: ĐANG RUNG!', 'Color', [1.0 0.3 0.3]);
                set(h_stat_badge(sc), 'String', '⚡ ĐANG RUNG CẢNH BÁO!', 'Color', [1.0 0.3 0.3]);
                set(h_stat_sub(sc), 'String', '(Phát hiện gù > 3.0s)', 'Color', [1.0 0.6 0.6]);
                set(h_tmr_txt(sc), 'String', 'ĐẠT 3.0s (CẢNH BÁO)');
                set(h_bar(sc), 'Position', [44, 20, 38, 5], 'FaceColor', [1.0 0.25 0.25]);
                set(h_th_txt(sc), 'String', sprintf('Góc: %.1f° (GÙ!)', cur_th), 'Color', [1.0 0.3 0.3]);
            else
                % An toàn hoặc đang lọc cử động thoáng qua
                set(h_buzz_badge(sc), 'String', '', 'BackgroundColor', 'none', 'EdgeColor', 'none');
                set(h_motor_txt(sc), 'String', 'Mô-tơ: TẮT', 'Color', [0.7 0.75 0.85]);
                
                bar_w = max(0.1, min(38, (cur_timer / t_confirm) * 38));
                set(h_bar(sc), 'Position', [44, 20, bar_w, 5]);

                if cur_th >= theta_thresh
                    set(h_sensor(sc), 'Marker', 's', 'MarkerSize', 13, 'MarkerFaceColor', [1 0.65 0.15]);
                    set(h_stat_badge(sc), 'String', '⏳ ĐANG LỌC GÙ', 'Color', [1.0 0.7 0.2]);
                    set(h_stat_sub(sc), 'String', '(Chờ xác nhận 3s)', 'Color', [1.0 0.8 0.4]);
                    set(h_tmr_txt(sc), 'String', sprintf('%.1fs / 3.0s', cur_timer));
                    set(h_bar(sc), 'FaceColor', [1.0 0.6 0.15]);
                    set(h_th_txt(sc), 'String', sprintf('Góc: %.1f°', cur_th), 'Color', [1.0 0.7 0.2]);
                else
                    set(h_sensor(sc), 'Marker', 's', 'MarkerSize', 13, 'MarkerFaceColor', [0.2 0.85 0.35]);
                    if sc == 3 && t(k) > 8.0
                        set(h_stat_badge(sc), 'String', '✔ AN TOÀN (LỌC)', 'Color', [0.25 0.9 0.45]);
                        set(h_stat_sub(sc), 'String', '(Nhặt đồ < 3s - FAR=0%)', 'Color', [0.65 0.85 0.7]);
                    else
                        set(h_stat_badge(sc), 'String', '✔ AN TOÀN', 'Color', [0.25 0.9 0.45]);
                        set(h_stat_sub(sc), 'String', '(Tư thế chuẩn)', 'Color', [0.65 0.72 0.85]);
                    end
                    set(h_tmr_txt(sc), 'String', '0.0s / 3.0s');
                    set(h_th_txt(sc), 'String', sprintf('Góc: %.1f°', cur_th), 'Color', [0.25 0.9 0.45]);
                end
            end
        end

        drawnow;

        % Đồng bộ thời gian thực 1:1 mượt mà
        t_target  = t(k);
        t_elapsed = toc(t_start);
        delay_sec = t_target - t_elapsed;
        if delay_sec > 0.001
            pause(delay_sec);
        end
    end

    fprintf('Mô phỏng đồng thời 4 kịch bản hoàn thành (Thời gian thực: %.1f s).\n', toc(t_start));
end