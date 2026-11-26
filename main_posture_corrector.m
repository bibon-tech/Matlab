%% CHƯƠNG TRÌNH MÔ PHỎNG VÀ ĐÁNH GIÁ THẮT LƯNG CHỐNG GÙ THÔNG MINH
% Đề tài: Thắt lưng chống gù thông minh (Mô phỏng trên MATLAB)
% Nhóm thực hiện: Nhóm 4 (Học viện Công nghệ Bưu chính Viễn thông - PTIT HCM)
% Tính năng: Tự động nạp dữ liệu từ file CSV hoặc tự động sinh dữ liệu nếu thiếu file!

clear; clc; close all;

%% 1. THIẾT LẬP THAM SỐ TOÀN CỤC
Fs = 50;              % Tần số lấy mẫu (Hz)
dt = 1 / Fs;          % Chu kỳ lấy mẫu: 0.02 giây
alpha = 0.95;         % Trọng số bộ lọc bù (hằng số thời gian tau = 0.38 s)
theta_thresh = 15.0;  % Ngưỡng góc bắt đầu coi là gù (độ)
t_confirm = 3.0;      % Thời gian xác nhận duy trì tư thế gù (giây)
hyst = 2.0;           % Độ trễ Hysteresis: tắt rung khi góc < 13° (15 - 2)

scenarios = {'K1', 'K2', 'K3', 'K4'};
scenario_names = { ...
    'K1: Ngồi thẳng chuẩn (5°)', ...
    'K2: Gù lưng tiến triển (5° -> 20°)', ...
    'K3: Cúi nhặt đồ thoáng qua (25° trong 2s)', ...
    'K4: Đứng dậy đi lại (±5° kèm gia tốc bước)' ...
};

fprintf('========================================================================\n');
fprintf('  KẾT QUẢ ĐÁNH GIÁ HỆ THỐNG THẮT LƯNG CHỐNG GÙ THÔNG MINH (NHÓM 4)\n');
fprintf('========================================================================\n');
fprintf('%-6s | %-10s | %-10s | %-10s | %-10s | %-10s\n', ...
    'K.Bản', 'RMSE (°)', 'MAE (°)', 'Đúng (%)', 'Báo nhầm(%)', 'Số bước rung');
fprintf('------------------------------------------------------------------------\n');

%% 2. CHẠY MÔ PHỎNG TỪNG KỊCH BẢN
for i = 1:length(scenarios)
    k_code = scenarios{i};
    
    % Tìm đường dẫn tệp CSV kịch bản
    possible_paths = { ...
        sprintf('IMU_%s_thap.csv', k_code), ...
        fullfile('data', sprintf('IMU_%s_thap.csv', k_code)), ...
        fullfile('02_Dulieu&Dothikiemtra_IMU', sprintf('IMU_%s_thap.csv', k_code)), ...
        fullfile('MAT02_MophongdulieuIMU_DoanGiaBao_20261122', '02_Dulieu&Dothikiemtra_IMU', sprintf('IMU_%s_thap.csv', k_code)), ...
        fullfile('07_MATLAB', 'MAT02_MophongdulieuIMU_DoanGiaBao_20261122', '02_Dulieu&Dothikiemtra_IMU', sprintf('IMU_%s_thap.csv', k_code)) ...
    };
    
    found_csv = false;
    for p = 1:length(possible_paths)
        if exist(possible_paths{p}, 'file')
            csv_file = possible_paths{p};
            found_csv = true;
            break;
        end
    end

    if found_csv
        % 1. Đọc từ tệp CSV có sẵn
        opts = detectImportOptions(csv_file);
        data_tbl = readtable(csv_file, opts);
        t = data_tbl.time;
        ax = data_tbl.ax;
        az = data_tbl.az;
        gy = data_tbl.gy;
        theta_true = data_tbl.theta_true;
    else
        % 2. TỰ ĐỘNG TẠO DỮ LIỆU TRỰC TIẾP (Nếu chưa upload thư mục chứa CSV)
        rng(1);
        T = 60;
        t = (0:dt:T)';
        N = length(t);
        theta_true = zeros(N, 1);
        
        switch k_code
            case 'K1'
                theta_true = 5 + 0.2*sin(2*pi*0.1*t);
            case 'K2'
                theta_true = 5 + 15*(1 - exp(-t/12));
            case 'K3'
                % K3 chuẩn: Cúi xuống nhặt đồ và ngồi lại trong đúng 3 giây (giây 10 -> 13)
                % Thời gian vượt 15° chỉ kéo dài 1.5s (< 3.0s xác nhận) -> Không rung nhầm
                theta_true = 5*ones(N,1);
                idx1 = t >= 10.0 & t <= 11.5;
                theta_true(idx1) = 5 + 20*(t(idx1)-10.0)/1.5;
                idx2 = t > 11.5 & t <= 13.0;
                theta_true(idx2) = 25 - 20*(t(idx2)-11.5)/1.5;
            case 'K4'
                theta_true = 5 + 10*sin(2*pi*t/8);
        end
        
        % Tính đạo hàm vận tốc góc và gia tốc trọng trường
        gyro_true = gradient(theta_true, dt);
        ax_true = sind(theta_true);
        az_true = cosd(theta_true);
        if strcmp(k_code, 'K4')
            ax_true = ax_true + 0.15*sin(4*pi*t); % Gia tốc bước chân
        end
        
        % Cộng nhiễu Gaussian và trôi MPU-6050
        ax = ax_true + 0.05 + 0.01*randn(N, 1);
        az = az_true + 0.08 + 0.01*randn(N, 1);
        gy = gyro_true + 0.20 + (t/60)*0.10 + 0.10*randn(N, 1);
    end

    % Khối 2: Ước lượng góc nghiêng bằng Bộ lọc bù
    [theta_est, theta_acc, theta_gyro] = complementary_filter(ax, az, gy, dt, alpha);

    % Khối 3: Logic phán đoán cảnh báo chống rung nhầm
    [alert_status, confirm_timer] = posture_alert_logic(theta_est, ax, az, dt, theta_thresh, t_confirm, hyst);

    % Khối 4: Đánh giá chỉ số định lượng
    metrics = evaluate_posture_system(theta_true, theta_est, alert_status, dt, theta_thresh, t_confirm);

    % In kết quả ra Command Window
    fprintf('%-6s | %10.3f | %10.3f | %9.2f%% | %9.2f%% | %10d\n', ...
        k_code, metrics.rmse, metrics.mae, metrics.recall, metrics.far, metrics.total_alert_steps);

    %% 3. VẼ ĐỒ THỊ 3 TẦNG TRỰC QUAN CHO TỪNG KỊCH BẢN
    h_fig = figure('Name', sprintf('Đánh giá %s', k_code), 'Position', [80 + i*30, 80, 880, 620]);

    % Tầng 1: So sánh góc thực tế và các tín hiệu góc ước lượng
    subplot(3, 1, 1);
    plot(t, theta_true, 'k-', 'LineWidth', 2.0, 'DisplayName', 'Góc thực \theta_{true}');
    hold on;
    plot(t, theta_acc, 'Color', [0.7 0.7 0.7], 'LineStyle', ':', 'DisplayName', 'Gia tốc thô \theta_{acc} (nhiễu)');
    plot(t, theta_est, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Bộ lọc bù \theta_{est} (\alpha=0.95)');
    yline(theta_thresh, 'r--', 'Ngưỡng gù 15°', 'LineWidth', 1.2, 'DisplayName', 'Ngưỡng 15°');
    yline(theta_thresh - hyst, 'm:', 'Ngưỡng tắt 13° (Hysteresis)', 'LineWidth', 1.2, 'DisplayName', 'Ngưỡng 13°');
    ylabel('Góc nghiêng (độ)');
    title(sprintf('KỊCH BẢN %s - %s (RMSE = %.3f°, MAE = %.3f°)', k_code, scenario_names{i}, metrics.rmse, metrics.mae));
    legend('Location', 'best');
    grid on;
    xlim([0, max(t)]);

    % Tầng 2: Bộ đếm thời gian xác nhận (Confirm Timer)
    subplot(3, 1, 2);
    plot(t, confirm_timer, 'Color', [0.85 0.33 0.1], 'LineWidth', 1.6);
    hold on;
    yline(t_confirm, 'r--', 'Thời gian kích hoạt: 3.0s', 'LineWidth', 1.2);
    ylabel('Bộ đếm xác nhận (s)');
    title('Tiến trình xác nhận duy trì tư thế gù (Debounce Timer)');
    grid on;
    xlim([0, max(t)]);
    ylim([0, max(max(confirm_timer) * 1.2, t_confirm + 1)]);

    % Tầng 3: Trạng thái kích hoạt cảnh báo rung
    subplot(3, 1, 3);
    area(t, alert_status, 'FaceColor', [0.9 0.2 0.2], 'FaceAlpha', 0.4, 'EdgeColor', 'r', 'LineWidth', 1.2);
    xlabel('Thời gian (giây)');
    ylabel('Cảnh báo rung');
    yticks([0 1]);
    yticklabels({'TẮT (Bình thường)', 'BẬT (Rung nhắc gù)'});
    title(sprintf('Trạng thái cảnh báo (FAR = %.2f%%, Độ nhạy = %.2f%%)', metrics.far, metrics.recall));
    grid on;
    xlim([0, max(t)]);
    ylim([-0.1, 1.1]);
end

fprintf('========================================================================\n');
fprintf('KẾT LUẬN: Đã hoàn thành đánh giá 4 kịch bản tư thế thành công!\n');
