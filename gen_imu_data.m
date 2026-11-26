function data = gen_imu_data(kich_ban, muc_nhieu, seed)
% GEN_IMU_DATA - Mô phỏng dữ liệu cảm biến quán tính IMU MPU-6050
% Đề tài: Thắt lưng chống gù thông minh - Nhóm 4 (PTIT HCM)
% Người phụ trách: Đoàn Gia Bảo (MAT02 / DC04)
%
% Cú pháp:
%   data = gen_imu_data(kich_ban, muc_nhieu, seed)
%
% Tham số đầu vào:
%   kich_ban  : 'K1' (Ngồi thẳng), 'K2' (Gù tiến triển), 'K3' (Cúi nhặt đồ 3s), 'K4' (Đi lại)
%   muc_nhieu : 'thap' (Mặc định chuẩn MPU-6050), 'vua', 'cao'
%   seed      : Giá trị seed ngẫu nhiên (mặc định = 42)

if nargin < 1 || isempty(kich_ban), kich_ban = "K1"; end
if nargin < 2 || isempty(muc_nhieu), muc_nhieu = "thap"; end
if nargin < 3 || isempty(seed), seed = 42; end

rng(seed);

%% 1. THIẾT LẬP THÔNG SỐ LẤY MẪU (CHUẨN HÓA 50 HZ)
Fs = 50;              % Tần số lấy mẫu: 50 Hz
dt = 1 / Fs;          % Chu kỳ lấy mẫu: 0.02 s
T = 60;               % Thời gian mô phỏng: 60 s
t = (0:dt:T)';
N = length(t);

%% 2. TẠO GÓC NGHIÊNG THỰC TẾ (THETA_TRUE) CHO 4 KỊCH BẢN
theta_true = zeros(N, 1);

switch upper(string(kich_ban))
    case "K1"
        % Kịch bản 1: Ngồi thẳng chuẩn (5° kèm dao động nhịp thở ±0.2°)
        theta_true(:) = 5.0 + 0.2 * sin(2 * pi * 0.1 * t);

    case "K2"
        % Kịch bản 2: Gù lưng tiến triển từ 5° lên 20° (lệch Δθ = 15°)
        theta_true = 5.0 + 15.0 * (1.0 - exp(-t / 12.0));

    case "K3"
        % Kịch bản 3: Cúi nhặt đồ và ngồi lại trong 3 giây (giây 10.0 -> 13.0)
        % Vượt ngưỡng 15° chỉ kéo dài 1.5s (< 3.0s xác nhận) -> FAR = 0%
        theta_true = 5.0 * ones(N, 1);
        idx1 = t >= 10.0 & t <= 11.5;
        theta_true(idx1) = 5.0 + 20.0 * (t(idx1) - 10.0) / 1.5;
        idx2 = t > 11.5 & t <= 13.0;
        theta_true(idx2) = 25.0 - 20.0 * (t(idx2) - 11.5) / 1.5;

    case "K4"
        % Kịch bản 4: Đứng dậy đi lại dao động
        theta_true = 5.0 + 10.0 * sin(2 * pi * t / 8.0);

    otherwise
        error('Kịch bản không hợp lệ! Vui lòng chọn K1, K2, K3 hoặc K4.');
end

%% 3. TÍNH VẬN TỐC GÓC PITCH CHUẨN TỪ ĐẠO HÀM
gyro_true = gradient(theta_true, dt);

%% 4. MÔ HÌNH HÓA THÀNH PHẦN TRỌNG LỰC TĨNH (GIA TỐC KẾ)
% Trục X: Dọc sống lưng (chịu sin theta)
% Trục Y: Ngang hai vai
% Trục Z: Vuông góc mặt lưng (chịu cos theta)
ax_true = sind(theta_true);
ay_true = zeros(N, 1);
az_true = cosd(theta_true);

% Nếu là K4 (Đi bộ): Bổ sung thành phần gia tốc động học bước chân
if upper(string(kich_ban)) == "K4"
    ax_true = ax_true + 0.15 * sin(4 * pi * t);
end

%% 5. THIẾT LẬP NHIỄU VÀ SAI LỆCH THEO DATASHEET MPU-6050 (BẢNG DC04)
switch lower(string(muc_nhieu))
    case "thap"
        sigma_a = 0.005;  % Nhiễu gia tốc: 5 mg (Datasheet 400 ug/sqrt(Hz))
        sigma_g = 0.05;   % Nhiễu con quay: 0.05 deg/s
    case "vua"
        sigma_a = 0.015;
        sigma_g = 0.15;
    case "cao"
        sigma_a = 0.030;
        sigma_g = 0.30;
    otherwise
        error('Mức nhiễu phải là thap, vua hoặc cao.');
end

% Zero-G Offset theo Datasheet MPU-6050 (DC04)
bias_ax = 0.05;   % Sai lệch ban đầu trục X (50 mg)
bias_az = 0.08;   % Sai lệch ban đầu trục Z (80 mg)

% Sai lệch và độ trôi nhiệt của con quay hồi chuyển
bias_gx = 0.05 + 0.02 * randn();
bias_gy = 0.15 + (t / 60.0) * 0.05 + cumsum(0.001 * sqrt(dt) * randn(N, 1)); % Trôi chậm
bias_gz = 0.05 + 0.02 * randn();

%% 6. TỔNG HỢP TÍN HIỆU CẢM BIẾN MPU-6050 HOÀN CHỈNH
ax = ax_true + bias_ax + sigma_a * randn(N, 1);
ay = ay_true + sigma_a * randn(N, 1);
az = az_true + bias_az + sigma_a * randn(N, 1);

% Lưu ý chuẩn động học: gy là trục quay Pitch (cúi gập thân trên)
gx = bias_gx + sigma_g * randn(N, 1);
gy = gyro_true + bias_gy + sigma_g * randn(N, 1);
gz = bias_gz + sigma_g * randn(N, 1);

%% 7. ĐÓNG GÓI VÀ XUẤT TỆP DỮ LIỆU
data = table(t, ax, ay, az, gx, gy, gz, theta_true, ...
    'VariableNames', {'time','ax','ay','az','gx','gy','gz','theta_true'});

ten_file = sprintf('IMU_%s_%s', upper(string(kich_ban)), lower(string(muc_nhieu)));

% Xuất CSV và MAT
writetable(data, ten_file + ".csv");
save(ten_file + ".mat", 'data');

fprintf('>> Đã tạo thành công bộ dữ liệu: %s.csv và %s.mat\n', ten_file, ten_file);
end
