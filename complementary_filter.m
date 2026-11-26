function [theta_est, theta_acc, theta_gyro] = complementary_filter(ax, az, gy, dt, alpha)
% COMPLEMENTARY_FILTER Ước lượng góc nghiêng thân trên bằng Bộ lọc bù
% Đề tài: Thắt lưng chống gù thông minh - Nhóm 4 (PTIT HCM)
% Người phụ trách: Phạm Ngô Gia Hạo (DC05)
%
% Cú pháp:
%   [theta_est, theta_acc, theta_gyro] = complementary_filter(ax, az, gy, dt, alpha)
%
% Đầu vào:
%   ax, az : Gia tốc theo trục X và Z (đơn vị: g)
%   gy     : Vận tốc góc quanh trục Y (đơn vị: deg/s)
%   dt     : Chu kỳ lấy mẫu (giây), mặc định dt = 0.02 s (Fs = 50 Hz)
%   alpha  : Hệ số trọng số bộ lọc bù, mặc định alpha = 0.95
%
% Đầu ra:
%   theta_est  : Góc nghiêng ước lượng sau lọc bù (độ)
%   theta_acc  : Góc nghiêng tính thuần từ gia tốc kế (độ)
%   theta_gyro : Góc nghiêng tính thuần tích phân từ con quay hồi chuyển (độ)

    if nargin < 4 || isempty(dt)
        dt = 0.02; % Fs = 50 Hz
    end
    if nargin < 5 || isempty(alpha)
        alpha = 0.95; % Hằng số thời gian tau = alpha*dt / (1 - alpha) = 0.38 s
    end

    N = length(ax);
    theta_est  = zeros(N, 1);
    theta_acc  = zeros(N, 1);
    theta_gyro = zeros(N, 1);

    % Khởi tạo góc tại thời điểm đầu tiên t = 0
    theta_acc(1)  = atan2d(ax(1), az(1));
    theta_est(1)  = theta_acc(1);
    theta_gyro(1) = theta_acc(1);

    % Vòng lặp lọc trực tuyến O(1)
    for k = 2:N
        % 1. Góc gia tốc kế (không trôi nhưng nhạy nhiễu rung)
        theta_acc(k) = atan2d(ax(k), az(k));

        % 2. Góc con quay hồi chuyển tích phân (mượt nhưng bị trôi drift)
        theta_gyro(k) = theta_gyro(k-1) + gy(k) * dt;

        % 3. Bộ lọc bù kết hợp: 95% Gyro + 5% Acc
        theta_est(k) = alpha * (theta_est(k-1) + gy(k) * dt) + (1.0 - alpha) * theta_acc(k);
    end
end
