function visualize_posture_3d(k_code, T_max)
% VISUALIZE_POSTURE_3D Mô phỏng tư thế người và cụm cảm biến IMU thắt lưng chống gù
% Đề tài: Thắt lưng chống gù thông minh - Nhóm 4 (PTIT HCM)
%
% Cú pháp:
%   visualize_posture_3d('K4')        % Kịch bản K4: Đi bộ di chuyển (Đứng bước đi & Khóa rung)
%   visualize_posture_3d('K2')        % Kịch bản K2: Gù lưng tiến triển (Có cảnh báo rung)
%   visualize_posture_3d('K3')        % Kịch bản K3: Cúi nhặt đồ 3s (KHÔNG rung nhầm)
%   visualize_posture_3d('K1')        % Kịch bản K1: Ngồi thẳng chuẩn

    if nargin < 1 || isempty(k_code), k_code = 'K2'; end

    dt = 0.02; % Tần số lấy mẫu Fs = 50 Hz
    
    % Thiết lập thời lượng tối ưu cho từng kịch bản
    if nargin < 2 || isempty(T_max)
        switch upper(k_code)
            case 'K1', T_max = 15; % Ngồi thẳng 15s
            case 'K2', T_max = 22; % Gù dần và rung cảnh báo ở giây 14
            case 'K3', T_max = 16; % Cúi nhặt trong 3s (giây 5-8)
            case 'K4', T_max = 18; % Đi bộ dao động
            otherwise, T_max = 20;
        end
    end

    t = (0:dt:T_max)';
    N = length(t);

    %% 1. TẠO QUỸ ĐẠO GÓC THEO KỊCH BẢN
    switch upper(k_code)
        case 'K1'
            theta = 5 + 0.2 * sin(2 * pi * 0.1 * t);
            scen_title = 'K1: Ngồi thẳng chuẩn (5°) - An toàn';

        case 'K2'
            % Gù lưng tiến triển từ 5° lên 20°
            theta = 5 + 15 * (1 - exp(-t / 10));
            scen_title = 'K2: Gù lưng tiến triển (5° -> 20°) - Cảnh báo rung';

        case 'K3'
            % Cúi nhặt đồ trong đúng 3.0 giây (giây 5.0 -> 8.0)
            theta = 5 * ones(N, 1);
            t_start = 5.0; t_peak = 6.5; t_end = 8.0;
            idx1 = t >= t_start & t <= t_peak;
            theta(idx1) = 5 + 20 * (t(idx1) - t_start) / 1.5;
            idx2 = t > t_peak & t <= t_end;
            theta(idx2) = 25 - 20 * (t(idx2) - t_peak) / 1.5;
            scen_title = 'K3: Cúi nhặt đồ 3s (Lệch >15° chỉ 1.5s -> KHÔNG rung nhầm)';

        case 'K4'
            % Đi lại di chuyển
            theta = 5 + 7 * sin(2 * pi * t / 4);
            scen_title = 'K4: Đi lại di chuyển - Khóa rung bằng gia tốc động';

        otherwise
            theta = 5 + 15 * (1 - exp(-t / 10));
            scen_title = 'Mô phỏng tư thế';
    end

    %% 2. CHẠY LOGIC PHÁN ĐOÁN CẢNH BÁO (DEBOUNCE TIMER & HYSTERESIS)
    theta_thresh = 15.0;  % Ngưỡng góc gù (độ)
    t_confirm    = 3.0;   % Thời gian xác nhận duy trì (giây)
    hyst         = 2.0;   % Vùng đệm trễ (tắt khi < 13°)

    alert  = zeros(N, 1);
    timers = zeros(N, 1);
    cur_timer = 0;
    is_alt    = 0;

    for k = 1:N
        is_walking = strcmp(upper(k_code), 'K4');
        if theta(k) >= theta_thresh && ~is_walking
            cur_timer = cur_timer + dt;
            if cur_timer >= t_confirm
                is_alt = 1;
            end
        elseif theta(k) < (theta_thresh - hyst)
            is_alt = 0;
            cur_timer = 0;
        else
            if is_alt == 0
                cur_timer = 0;
            end
        end
        alert(k)  = is_alt;
        timers(k) = cur_timer;
    end

    %% 3. THIẾT KẾ GIAO DIỆN MÔ PHỎNG (FIGURE 2 CỘT CHUYÊN NGHIỆP)
    fig = figure('Name', sprintf('Mô phỏng Tư thế & Cảm biến IMU - [%s]', upper(k_code)), ...
                 'Position', [60, 50, 1180, 680], 'Color', [0.97 0.98 1.0]);

    % -------------------------------------------------------------------------
    % CỘT 1: MÔ PHỎNG CON NGƯỜI & HỆ THỐNG ĐAI ĐEO THỰC TẾ
    % -------------------------------------------------------------------------
    ax1 = subplot(1, 2, 1);
    hold(ax1, 'on');

    is_walking = strcmp(upper(k_code), 'K4');
    
    % Trục tham chiếu 0° (đặt trên cao Y=73, không bị đầu chạm)
    plot(ax1, [0, 0], [0, 70], 'k:', 'LineWidth', 1.2);
    text(ax1, 0, 73, 'Trục 0° (Đứng thẳng)', 'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', [0.4 0.4 0.4]);
    
    if ~is_walking
        % BỐ CỤC K1, K2, K3: NGỒI LÀM VIỆC VỚI GHẾ & BÀN LAPTOP
        plot(ax1, [-16, 16], [-2, -2], 'Color', [0.2 0.2 0.2], 'LineWidth', 5); % Đệm ngồi ghế
        plot(ax1, [-16, -16], [-2, 45], 'Color', [0.2 0.2 0.2], 'LineWidth', 5); % Lưng ghế tựa
        plot(ax1, [-14, -14], [-2, -22], 'Color', [0.3 0.3 0.3], 'LineWidth', 4); % Chân ghế
        plot(ax1, [-22, -6], [-22, -22], 'Color', [0.3 0.3 0.3], 'LineWidth', 3); % Bánh xe ghế
        
        plot(ax1, [24, 48], [14, 14], 'Color', [0.45 0.3 0.2], 'LineWidth', 4); % Mặt bàn
        plot(ax1, [44, 44], [14, -24], 'Color', [0.4 0.4 0.4], 'LineWidth', 3); % Chân bàn
        plot(ax1, [26, 36], [15, 15], 'k-', 'LineWidth', 2.5); % Đế laptop
        plot(ax1, [36, 42], [15, 27], 'Color', [0.15 0.15 0.15], 'LineWidth', 2.5); % Màn hình laptop
        fill(ax1, [36.2, 41.8, 41.8, 36.2], [15.5, 26.5, 26.5, 15.5], [0.8 0.9 1.0], 'EdgeColor', 'none'); % Ánh sáng màn hình
        
        % Chân người tĩnh khi ngồi (Đùi, cẳng chân, giày)
        plot(ax1, [0, 20], [0, 0], 'Color', [0.2 0.3 0.45], 'LineWidth', 11);
        plot(ax1, [20, 20], [0, -22], 'Color', [0.2 0.3 0.45], 'LineWidth', 9);
        plot(ax1, [18, 27], [-22, -22], 'k-', 'LineWidth', 6);
        panel1_title = 'MÔ HÌNH NGƯỜI NGỒI LÀM VIỆC & HỆ THỐNG ĐAI ĐEO';
    else
        % BỐ CỤC K4: ĐI LẠI / DI CHUYỂN (KHÔNG BÀN GHẾ, ĐỨNG BƯỚC TRÊN SÀN)
        plot(ax1, [-26, 52], [-22, -22], 'Color', [0.3 0.3 0.3], 'LineWidth', 3); % Mặt sàn di chuyển
        plot(ax1, [-26, 52], [-23, -23], 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5, 'LineStyle', '--');
        
        % Chân động bước đi luân phiên
        h_leg1  = plot(ax1, [0, 0, 0], [0, -11, -22], 'Color', [0.2 0.3 0.45], 'LineWidth', 9);
        h_shoe1 = plot(ax1, [0, 6], [-22, -22], 'k-', 'LineWidth', 6);
        h_leg2  = plot(ax1, [0, 0, 0], [0, -11, -22], 'Color', [0.15 0.22 0.35], 'LineWidth', 9);
        h_shoe2 = plot(ax1, [0, 6], [-22, -22], 'Color', [0.25 0.25 0.25], 'LineWidth', 6);
        panel1_title = 'MÔ HÌNH NGƯỜI ĐI LẠI / DI CHUYỂN & KHÓA CẢNH BÁO';
    end

    % Phần tử cơ thể người (Thân thanh thoát, không có khối xanh thừa)
    h_torso = plot(ax1, [0 0 0], [0 18 42], 'Color', [0.28 0.42 0.65], 'LineWidth', 12); % Thân mình (áo)
    h_spine = plot(ax1, [0 0 0], [0 18 42], 'Color', [0.95 0.75 0.15], 'LineWidth', 3.5); % Đường cột sống
    h_neck  = plot(ax1, [0 0], [42 53], 'Color', [0.95 0.82 0.72], 'LineWidth', 7); % Cổ
    theta_init = linspace(0, 2*pi, 40);
    h_head  = fill(ax1, 7.5*cos(theta_init), 55 + 7.5*sin(theta_init), [0.95 0.82 0.72], 'EdgeColor', [0.5 0.35 0.25], 'LineWidth', 1.5); % Đầu
    
    % Cánh tay người (Nằm gọn gàng, tự nhiên ngay trên thân mình)
    h_arm   = plot(ax1, [0 0 0], [0 0 0], 'Color', [0.2 0.32 0.52], 'LineWidth', 5.5);

    % DÂY ĐAI ĐỊNH HÌNH & HỘP MCU THẮT LƯNG (Nhãn đặt lệch trái, tuyệt đối không đè chân)
    h_waist_box = rectangle(ax1, 'Position', [-8, -4, 16, 8], 'Curvature', 0.4, ...
                            'FaceColor', [0.15 0.25 0.45], 'EdgeColor', 'k', 'LineWidth', 1.5);
    plot(ax1, [-11, -8], [0, 0], 'Color', [0.3 0.4 0.6], 'LineWidth', 1.2); % Đường nối chỉ thị
    text(ax1, -12, 0, sprintf('Khối thắt lưng\n(MCU + Pin)'), 'FontSize', 8, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'right', 'Color', [0.1 0.25 0.5]);
    h_strap = plot(ax1, [0 0 0], [0 18 42], 'm--', 'LineWidth', 2.2); % Dây đai nẹp sống lưng

    % CỤM CẢM BIẾN IMU MPU-6050 TẠI LƯNG TRÊN (T1-T4)
    h_sensor = plot(ax1, 0, 42, 's', 'MarkerSize', 16, ...
                    'MarkerFaceColor', [0.2 0.8 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    
    % Nhãn cảm biến đặt lệch trái phía sau lưng (không đè lên ngực hay tay)
    h_sensor_label = text(ax1, -6, 42, 'Cảm biến IMU T1–T4', 'FontSize', 8, 'FontWeight', 'bold', ...
                          'HorizontalAlignment', 'right', 'Color', [0 0.45 0.2], ...
                          'BackgroundColor', [0.95 1 0.95], 'Margin', 2);
    h_buzz_badge   = text(ax1, 0, 66, '', 'FontSize', 11, 'FontWeight', 'bold', ...
                          'HorizontalAlignment', 'center', 'Color', [0.85 0 0], ...
                          'BackgroundColor', 'none', 'EdgeColor', 'none', 'Margin', 3);

    title(ax1, {panel1_title, scen_title}, 'FontSize', 11, 'FontWeight', 'bold');
    axis(ax1, 'equal');
    xlim(ax1, [-26, 52]);
    ylim(ax1, [-28, 80]);
    grid(ax1, 'on'); box(ax1, 'on');

    % -------------------------------------------------------------------------
    % CỘT 2: CHI TIẾT CẢM BIẾN IMU MPU-6050 & THÔNG SỐ HOẠT ĐỘNG
    % -------------------------------------------------------------------------
    ax2 = subplot(1, 2, 2);
    hold(ax2, 'on');

    % KHỐI 1: HỘP MÔ-ĐUN CẢM BIẾN MPU-6050 PHÓNG TO (Lưng trên T1-T4)
    rectangle(ax2, 'Position', [-48, 36, 96, 36], 'Curvature', 0.08, ...
              'FaceColor', [0.94 0.97 1.0], 'EdgeColor', [0.4 0.6 0.8], 'LineWidth', 1.5);
    text(ax2, -45, 68, 'CỤM CẢM BIẾN LƯNG TRÊN (T1–T4) — MPU-6050 & MÔ-TƠ', ...
         'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.1 0.25 0.55]);

    % Mạch PCB cảm biến MPU-6050
    rectangle(ax2, 'Position', [-44, 40, 46, 24], 'Curvature', 0.1, ...
              'FaceColor', [0.08 0.45 0.28], 'EdgeColor', 'k', 'LineWidth', 1.2);
    rectangle(ax2, 'Position', [-41, 44, 18, 16], 'Curvature', 0.08, ...
              'FaceColor', [0.15 0.15 0.15], 'EdgeColor', [0.8 0.8 0.8], 'LineWidth', 1);
    text(ax2, -32, 53, 'MPU-6050', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w', 'HorizontalAlignment', 'center');
    text(ax2, -32, 47, '6-DOF IMU', 'FontSize', 6.5, 'Color', [0.8 0.8 0.8], 'HorizontalAlignment', 'center');

    % Trục tọa độ 3D của cảm biến (Bố trí thoáng đãng bên cạnh chip)
    quiver(ax2, -12, 52, 0, 9, 0, 'Color', 'r', 'LineWidth', 2, 'MaxHeadSize', 2);
    text(ax2, -12, 64, 'X(dọc)', 'FontSize', 7.5, 'FontWeight', 'bold', 'Color', 'r', 'HorizontalAlignment', 'center');
    quiver(ax2, -12, 52, 9, 0, 0, 'Color', [0 0.5 0], 'LineWidth', 2, 'MaxHeadSize', 2);
    text(ax2, -1, 52, 'Z', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0 0.5 0]);
    plot(ax2, -12, 52, 'bo', 'MarkerSize', 5, 'MarkerFaceColor', 'b');
    text(ax2, -12, 45, 'Y(Pitch)', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'b', 'HorizontalAlignment', 'center');

    % Mô-tơ rung phản hồi sinh học (Coin Vibration Motor)
    h_motor = rectangle(ax2, 'Position', [16, 43, 19, 19], 'Curvature', 1.0, ...
                        'FaceColor', [0.75 0.78 0.82], 'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 1.5);
    text(ax2, 25.5, 65, 'Mô-tơ rung Haptic', 'FontSize', 8, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', [0.2 0.2 0.2]);
    h_motor_txt = text(ax2, 25.5, 52.5, 'TẮT', 'FontSize', 9, 'FontWeight', 'bold', ...
                       'HorizontalAlignment', 'center', 'Color', [0.3 0.3 0.3]);

    % KHỐI 2: ĐỒNG HỒ ĐO GÓC NGHIÊNG SINH HỌC (POSTURE GAUGE)
    rectangle(ax2, 'Position', [-48, 0, 96, 32], 'Curvature', 0.08, ...
              'FaceColor', [1 1 1], 'EdgeColor', [0.7 0.75 0.8], 'LineWidth', 1.2);
    text(ax2, -45, 28, 'ĐỒNG HỒ ĐO GÓC NGHIÊNG THÂN TRÊN (GÓC PITCH)', ...
         'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.15 0.25 0.45]);

    % Chú thích vùng góc bên trái (X = -45)
    text(ax2, -45, 20, '● Vùng chuẩn: 0–13° (An toàn)', 'FontSize', 7.5, 'Color', [0 0.6 0]);
    text(ax2, -45, 13, '● Vùng trễ: 13–15° (Hysteresis)', 'FontSize', 7.5, 'Color', [0.8 0.5 0]);
    text(ax2, -45, 6,  '● Vùng gù: > 15° (Cảnh báo rung)', 'FontSize', 7.5, 'Color', [0.85 0 0]);

    % Cung tròn đo góc bên phải (Tâm cx = 24, cy = 6, không bao giờ đè chú thích)
    cx = 24; cy = 6; R_gauge = 18;
    th_safe = deg2rad(0:13);
    plot(ax2, cx + R_gauge * sin(th_safe), cy + R_gauge * cos(th_safe), 'Color', [0.2 0.8 0.2], 'LineWidth', 6);
    th_hyst = deg2rad(13:15);
    plot(ax2, cx + R_gauge * sin(th_hyst), cy + R_gauge * cos(th_hyst), 'Color', [0.95 0.75 0.1], 'LineWidth', 6);
    th_risk = deg2rad(15:35);
    plot(ax2, cx + R_gauge * sin(th_risk), cy + R_gauge * cos(th_risk), 'Color', [0.9 0.2 0.2], 'LineWidth', 6);

    % Kim chỉ góc & Số đo điện tử
    h_needle = plot(ax2, [cx, cx], [cy, cy + R_gauge - 2], 'Color', [0.1 0.1 0.1], 'LineWidth', 2.5);
    plot(ax2, cx, cy, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
    h_gauge_val = text(ax2, 24, 25, '5.0°', 'FontSize', 13, 'FontWeight', 'bold', ...
                       'HorizontalAlignment', 'center', 'Color', [0 0.6 0]);

    % KHỐI 3: TIẾN TRÌNH LỌC CỬ ĐỘNG (DEBOUNCE 3.0s) & TRẠNG THÁI HỆ THỐNG
    % Chiều cao 38 đơn vị, chia 4 tầng riêng biệt, tuyệt đối không đè nhau!
    rectangle(ax2, 'Position', [-48, -42, 96, 38], 'Curvature', 0.08, ...
              'FaceColor', [0.98 0.98 0.98], 'EdgeColor', [0.7 0.75 0.8], 'LineWidth', 1.2);
    text(ax2, -45, -8, 'TIẾN TRÌNH LỌC CỬ ĐỘNG (DEBOUNCE 3.0s)', ...
         'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);

    % Thanh đo tiến trình (Progress bar)
    rectangle(ax2, 'Position', [-45, -18, 90, 6.5], 'Curvature', 0.3, ...
              'FaceColor', [0.9 0.9 0.9], 'EdgeColor', [0.6 0.6 0.6]);
    h_bar = rectangle(ax2, 'Position', [-45, -18, 0.1, 6.5], 'Curvature', 0.3, ...
                      'FaceColor', [0.9 0.4 0.1], 'EdgeColor', 'none');
    h_timer_lbl = text(ax2, 0, -15, '0.0s / 3.0s', 'FontSize', 8, 'FontWeight', 'bold', ...
                       'HorizontalAlignment', 'center', 'Color', 'k');

    % DÒNG 1: Thời gian mô phỏng (Y = -26)
    h_time_txt = text(ax2, -45, -26, '⏱ Thời gian mô phỏng: 0.0 s', ...
                      'FontSize', 8.5, 'Color', [0.3 0.3 0.3]);

    % DÒNG 2: Huy hiệu trạng thái (Y = -35, cách dòng 1 tới 9 đơn vị!)
    h_status_badge = text(ax2, -45, -35, '✔ TRẠNG THÁI: AN TOÀN (TƯ THẾ CHUẨN)', ...
                          'FontSize', 9, 'FontWeight', 'bold', 'Color', [0 0.6 0]);

    axis(ax2, 'equal');
    xlim(ax2, [-52, 52]);
    ylim(ax2, [-45, 76]);
    axis(ax2, 'off');

    %% 4. VÒNG LẶP ĐỒNG BỘ THỜI GIAN THỰC (REAL-TIME ANIMATION)
    L_lumbar   = 18;
    L_thoracic = 24;
    L_neck     = 10;
    R_head     = 7.5;
    theta_circle = linspace(0, 2*pi, 40);

    frame_step = round(0.04 / dt); % 25 fps mượt mà
    t_start = tic;

    for k = 1:frame_step:N
        if ~ishandle(fig), break; end

        current_th = theta(k);
        is_buzzing = alert(k);
        cur_timer  = timers(k);

        % Tính toán tọa độ cơ sinh học cơ thể
        th_rad   = deg2rad(current_th);
        x1       = L_lumbar * sin(th_rad * 0.35);
        y1       = L_lumbar * cos(th_rad * 0.35);
        x_sensor = x1 + L_thoracic * sin(th_rad);
        y_sensor = y1 + L_thoracic * cos(th_rad);
        x_neck   = x_sensor + L_neck * sin(th_rad * 1.15);
        y_neck   = y_sensor + L_neck * cos(th_rad * 1.15);
        x_head   = x_neck + R_head * sin(th_rad * 1.2);
        y_head   = y_neck + R_head * cos(th_rad * 1.2);

        % Cập nhật thân người thanh thoát theo đường cong cột sống
        set(h_torso, 'XData', [0, x1, x_sensor], 'YData', [0, y1, y_sensor]);

        shoulder_x = x_sensor + 1 * cos(th_rad);
        shoulder_y = y_sensor - 1 * sin(th_rad);

        if ~is_walking
            % Khi ngồi: Cánh tay đặt gọn gàng trên thân rồi vươn tới laptop
            elbow_x = shoulder_x + 5;
            elbow_y = shoulder_y - 13;
            hand_x  = 30; hand_y = 15;
            set(h_arm, 'XData', [shoulder_x, elbow_x, hand_x], 'YData', [shoulder_y, elbow_y, hand_y]);
        else
            % Khi đi bộ: Cánh tay nằm dọc thân mình và đánh nhẹ nhàng tự nhiên
            phi = 2 * pi * t(k) / 1.0; % Chu kỳ bước 1.0 giây
            
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
            
            % Cánh tay nằm ngay trên thân mình, dao động nhẹ nhàng (biên độ nhỏ ±4 đơn vị)
            arm_swing   = -5 * sin(phi);
            arm_elbow_x = shoulder_x + 0.5 * arm_swing;
            arm_elbow_y = shoulder_y - 12;
            arm_hand_x  = shoulder_x + arm_swing;
            arm_hand_y  = shoulder_y - 21;
            set(h_arm, 'XData', [shoulder_x, arm_elbow_x, arm_hand_x], 'YData', [shoulder_y, arm_elbow_y, arm_hand_y]);
        end

        % Cập nhật cột sống, cổ, đầu
        set(h_spine, 'XData', [0, x1, x_sensor], 'YData', [0, y1, y_sensor]);
        set(h_neck,  'XData', [x_sensor, x_neck], 'YData', [y_sensor, y_neck]);
        set(h_head,  'XData', x_head + R_head * cos(theta_circle), ...
                     'YData', y_head + R_head * sin(theta_circle));

        % Cập nhật dây đai nẹp sống lưng
        set(h_strap, 'XData', [0, x1, x_sensor], 'YData', [0, y1, y_sensor]);

        % Cập nhật Cảm biến IMU T1-T4 trên người
        set(h_sensor, 'XData', x_sensor, 'YData', y_sensor);
        set(h_sensor_label, 'Position', [x_sensor - 5, y_sensor, 0]);

        % Cập nhật trạng thái CẢNH BÁO RUNG
        if is_walking
            set(h_sensor, 'Marker', 's', 'MarkerSize', 15, 'MarkerFaceColor', [0.2 0.7 0.9]);
            set(h_buzz_badge, 'String', '');
            set(h_motor, 'FaceColor', [0.75 0.78 0.82]);
            set(h_motor_txt, 'String', 'KHÓA', 'Color', [0.2 0.35 0.55]);
            set(h_status_badge, 'String', '🚶 TRẠNG THÁI: ĐANG ĐI BỘ (KHÓA RUNG TỰ ĐỘNG)', 'Color', [0 0.45 0.75]);
            set(h_timer_lbl, 'String', 'KHÓA RUNG (Gia tốc động)');
            set(h_bar, 'Position', [-45, -18, 0.1, 6.5], 'FaceColor', [0.4 0.7 0.9]);
        elseif is_buzzing
            set(h_sensor, 'Marker', 'p', 'MarkerSize', 22, 'MarkerFaceColor', [1 0 0]);
            set(h_buzz_badge, 'Position', [x_sensor, y_sensor + 14, 0], ...
                'String', ' ⚡ ĐANG RUNG CẢNH BÁO! ', ...
                'BackgroundColor', [1 0.9 0.9], 'EdgeColor', [0.85 0 0], 'LineWidth', 1.5);
            set(h_motor, 'FaceColor', [1 0.2 0.2]);
            set(h_motor_txt, 'String', '⚡ RUNG!', 'Color', 'w');
            set(h_status_badge, 'String', '⚡ TRẠNG THÁI: ĐANG RUNG CẢNH BÁO GÙ!', 'Color', [0.85 0 0]);
        else
            set(h_buzz_badge, 'String', '', 'BackgroundColor', 'none', 'EdgeColor', 'none');
            set(h_motor, 'FaceColor', [0.75 0.78 0.82]);
            set(h_motor_txt, 'String', 'TẮT', 'Color', [0.3 0.3 0.3]);
            if current_th >= theta_thresh
                set(h_sensor, 'Marker', 's', 'MarkerSize', 16, 'MarkerFaceColor', [1 0.6 0]);
                set(h_status_badge, 'String', sprintf('⏳ ĐANG LỌC CỬ ĐỘNG THOÁNG QUA (%.1fs / 3.0s)', cur_timer), ...
                    'Color', [0.85 0.5 0]);
            else
                set(h_sensor, 'Marker', 's', 'MarkerSize', 16, 'MarkerFaceColor', [0.2 0.8 0.2]);
                set(h_status_badge, 'String', '✔ TRẠNG THÁI: AN TOÀN (TƯ THẾ CHUẨN)', 'Color', [0 0.6 0]);
            end
        end

        % Cập nhật kim đồng hồ đo góc nghiêng
        th_clamp = max(0, min(35, current_th));
        needle_rad = deg2rad(th_clamp);
        set(h_needle, 'XData', [cx, cx + (R_gauge-2)*sin(needle_rad)], ...
                      'YData', [cy, cy + (R_gauge-2)*cos(needle_rad)]);
        if current_th >= theta_thresh
            set(h_gauge_val, 'String', sprintf('%.1f° (Gù!)', current_th), 'Color', [0.85 0 0]);
        else
            set(h_gauge_val, 'String', sprintf('%.1f°', current_th), 'Color', [0 0.6 0]);
        end

        % Cập nhật thanh Debounce Timer
        bar_w = max(0.1, min(90, (cur_timer / t_confirm) * 90));
        set(h_bar, 'Position', [-45, -18, bar_w, 6.5]);
        if cur_timer >= t_confirm
            set(h_bar, 'FaceColor', [0.85 0.1 0.1]);
        else
            set(h_bar, 'FaceColor', [0.95 0.55 0.1]);
        end
        set(h_timer_lbl, 'String', sprintf('%.1fs / 3.0s', cur_timer));
        set(h_time_txt, 'String', sprintf('⏱ Thời gian mô phỏng: %.1f s', t(k)));

        drawnow;

        % Đồng bộ thời gian thực chuẩn xác 1:1
        t_target  = t(k);
        t_elapsed = toc(t_start);
        delay_sec = t_target - t_elapsed;
        if delay_sec > 0.001
            pause(delay_sec);
        end
    end

    fprintf('Mô phỏng hoàn thành cho kịch bản %s (Tổng thời gian: %.1f s).\n', upper(k_code), toc(t_start));
end