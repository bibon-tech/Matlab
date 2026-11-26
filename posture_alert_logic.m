function [alert_status, confirm_timer] = posture_alert_logic(theta_est, ax, az, dt, theta_thresh, t_confirm, hyst, ay)
% POSTURE_ALERT_LOGIC Phán đoán tư thế và kích hoạt cảnh báo chống báo nhầm
% Đề tài: Thắt lưng chống gù thông minh - Nhóm 4 (PTIT HCM)
% Người phụ trách: Võ Kiến Văn & Đoàn Gia Bảo
%
% Cú pháp:
%   [alert_status, confirm_timer] = posture_alert_logic(theta_est, ax, az, dt, theta_thresh, t_confirm, hyst, ay)
%
% Đầu vào:
%   theta_est    : Vector góc nghiêng ước lượng từ bộ lọc bù (độ)
%   ax, az       : Gia tốc đo theo trục X và Z (đơn vị: g)
%   dt           : Chu kỳ lấy mẫu (giây), mặc định dt = 0.02 s (50 Hz)
%   theta_thresh : Ngưỡng phát hiện góc gù (độ), mặc định 15.0° (lệch tương đối)
%   t_confirm    : Thời gian xác nhận duy trì gù (giây), mặc định 3.0 s
%   hyst         : Vùng đệm trễ Hysteresis (độ), mặc định 2.0° (tắt ở < 13°)
%   ay           : (Tùy chọn) Gia tốc đo theo trục Y (đơn vị: g) để kiểm tra động học 3D
%
% Đầu ra:
%   alert_status  : Vector trạng thái cảnh báo rung (0: Tắt, 1: Bật)
%   confirm_timer : Vector theo dõi thời gian đếm xác nhận (giây)

    if nargin < 4 || isempty(dt), dt = 0.02; end
    if nargin < 5 || isempty(theta_thresh), theta_thresh = 15.0; end
    if nargin < 6 || isempty(t_confirm), t_confirm = 3.0; end
    if nargin < 7 || isempty(hyst), hyst = 2.0; end
    use_3axis = (nargin >= 8 && ~isempty(ay));

    N = length(theta_est);
    alert_status  = zeros(N, 1);
    confirm_timer = zeros(N, 1);

    cur_timer = 0.0;
    is_alert  = 0;
    dynamic_counter = 0; % Đếm thời gian rung lắc động học liên tục

    for k = 1:N
        % 1. Lọc chuyển động động học mạnh (ví dụ đi bộ K4, rung lắc):
        % Tính độ lớn vector gia tốc toàn phần:
        if use_3axis
            a_mag = sqrt(ax(k)^2 + ay(k)^2 + az(k)^2);
        else
            a_mag = sqrt(ax(k)^2 + az(k)^2);
        end
        
        % Chuyển động động học khi gia tốc lệch đáng kể khỏi trọng trường tĩnh 1.0g
        is_dynamic = abs(a_mag - 1.0) > 0.25;

        if is_dynamic
            dynamic_counter = dynamic_counter + dt;
        else
            dynamic_counter = 0.0;
        end

        % 2. Logic phán đoán trạng thái góc và bộ đếm xác nhận
        if theta_est(k) >= theta_thresh
            if ~is_dynamic
                cur_timer = cur_timer + dt;
            else
                % Nếu chuyển động động học kéo dài > 0.5s (đi lại), suy hao bộ đếm để chống tích lũy sai
                if dynamic_counter > 0.5
                    cur_timer = max(0.0, cur_timer - 2 * dt);
                end
            end
            
            % Khi duy trì góc gù liên tục đủ thời gian xác nhận -> Kích hoạt rung
            if cur_timer >= t_confirm
                is_alert = 1;
            end
        elseif theta_est(k) < (theta_thresh - hyst)
            % Chỉ tắt rung khi người dùng đã ngồi thẳng hẳn về dưới (15 - 2 = 13°)
            is_alert  = 0;
            cur_timer = 0.0;
        else
            % Trong vùng đệm trễ (13° <= theta_est < 15°):
            % Giữ nguyên trạng thái cảnh báo cũ, nếu chưa bật thì không cộng dồn timer
            if is_alert == 0
                cur_timer = max(0.0, cur_timer - dt);
            end
        end

        confirm_timer(k) = cur_timer;
        alert_status(k)  = is_alert;
    end
end
