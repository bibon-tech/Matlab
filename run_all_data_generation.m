%% RUN_ALL_DATA_GENERATION - Tiện ích tự động tạo trọn bộ 4 kịch bản dữ liệu IMU
% Đề tài: Thắt lưng chống gù thông minh (Mô phỏng trên MATLAB)
% Nhóm thực hiện: Nhóm 4 (PTIT HCM)
% Người phụ trách: Đoàn Gia Bảo

clear; clc; close all;

fprintf('========================================================================\n');
fprintf('  TIỆN ÍCH TỰ ĐỘNG KHỞI TẠO 4 BỘ DỮ LIỆU IMU CHUẨN HÓA (NHÓM 4)\n');
fprintf('========================================================================\n');

scenarios = {'K1', 'K2', 'K3', 'K4'};
noise_level = 'thap'; % Mức nhiễu chuẩn theo Datasheet MPU-6050 (Bảng DC04)

sub_dest = fullfile('MAT02_MophongdulieuIMU_DoanGiaBao_20261122', '02_Dulieu&Dothikiemtra_IMU');

for i = 1:length(scenarios)
    k_code = scenarios{i};
    fprintf('[%d/4] Đang sinh dữ liệu kịch bản %s (%s)... ', i, k_code, noise_level);
    
    % Gọi hàm sinh dữ liệu chuẩn
    data = gen_imu_data(k_code, noise_level, 42);
    
    % Tên file xuất
    csv_name = sprintf('IMU_%s_%s.csv', k_code, noise_level);
    mat_name = sprintf('IMU_%s_%s.mat', k_code, noise_level);
    
    % Tự động đồng bộ sang thư mục lưu trữ bài tập lớn nếu có
    if exist(sub_dest, 'dir')
        copyfile(csv_name, fullfile(sub_dest, csv_name));
        if exist(mat_name, 'file')
            copyfile(mat_name, fullfile(sub_dest, mat_name));
        end
    end
    
    fprintf('Xong!\n');
end

fprintf('------------------------------------------------------------------------\n');
fprintf('>> HOÀN THÀNH: Đã xuất trọn bộ 4 file CSV & MAT chuẩn hóa thành công!\n');
fprintf('>> Bạn có thể chạy ngay lệnh: main_posture_corrector để xem kết quả đánh giá.\n');
fprintf('========================================================================\n');
