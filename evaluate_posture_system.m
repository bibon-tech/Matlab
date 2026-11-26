function metrics = evaluate_posture_system(theta_true, theta_est, alert_status, dt, theta_thresh, t_confirm)
% EVALUATE_POSTURE_SYSTEM Đánh giá chỉ số định lượng của hệ thống
% Đề tài: Thắt lưng chống gù thông minh - Nhóm 4 (PTIT HCM)
% Người phụ trách: Huỳnh Tuấn Khoa & Trần Thanh Thiên An

    if nargin < 4 || isempty(dt), dt = 0.02; end
    if nargin < 5 || isempty(theta_thresh), theta_thresh = 15.0; end
    if nargin < 6 || isempty(t_confirm), t_confirm = 3.0; end

    N = length(theta_true);

    % 1. Đánh giá sai số góc
    err = theta_est - theta_true;
    rmse = sqrt(mean(err.^2));
    mae  = mean(abs(err));
    max_err = max(abs(err));

    % 2. Xây dựng nhãn tư thế gù thực tế (Ground Truth Alert):
    % Trạng thái thực tế là gù nếu góc thực theta_true >= 15° và duy trì >= 3s
    true_alert = zeros(N, 1);
    timer_true = 0.0;
    for k = 1:N
        if theta_true(k) >= theta_thresh
            timer_true = timer_true + dt;
            if timer_true >= t_confirm
                true_alert(k) = 1;
            end
        else
            timer_true = 0.0;
        end
    end

    % 3. Phân loại theo Ma trận nhầm lẫn (Confusion Matrix)
    TP = sum(alert_status == 1 & true_alert == 1); % Báo gù đúng
    FP = sum(alert_status == 1 & true_alert == 0); % Báo nhầm (False Alarm)
    FN = sum(alert_status == 0 & true_alert == 1); % Bỏ sót gù
    TN = sum(alert_status == 0 & true_alert == 0); % Đúng trạng thái an toàn

    % Độ nhạy (Recall / True Positive Rate)
    if (TP + FN) > 0
        recall = (TP / (TP + FN)) * 100;
    else
        recall = 100.0; % Không có tình huống gù trong kịch bản
    end

    % Độ chính xác (Precision)
    if (TP + FP) > 0
        precision = (TP / (TP + FP)) * 100;
    else
        precision = 100.0;
    end

    % Tỷ lệ báo động giả (False Alarm Rate - FAR)
    if (FP + TN) > 0
        far = (FP / (FP + TN)) * 100;
    else
        far = 0.0;
    end

    metrics.rmse = rmse;
    metrics.mae = mae;
    metrics.max_err = max_err;
    metrics.TP = TP;
    metrics.FP = FP;
    metrics.FN = FN;
    metrics.TN = TN;
    metrics.recall = recall;
    metrics.precision = precision;
    metrics.far = far;
    metrics.total_alert_steps = sum(alert_status);
end
