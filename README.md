# NGHIÊN CỨU VÀ MÔ PHỎNG HỆ THỐNG PHÁT HIỆN, CẢNH BÁO TƯ THẾ GÙ LƯNG BẰNG MATLAB ỨNG DỤNG CHO THẮT LƯNG THÔNG MINH

> **Học viện Công nghệ Bưu chính Viễn thông (PTIT HCM)**  
> **Khoa Kỹ thuật Điện tử 2**  
> **Nhóm thực hiện:** Nhóm 4  

---

## 📌 1. Giới thiệu Đề tài
Dự án phát triển thuật toán ước lượng tư thế và cảnh báo chống gù lưng thông minh sử dụng cảm biến quán tính 6-DOF IMU (MPU-6050) đặt tại vùng lưng trên (T1–T4) kết hợp với khối xử lý trung tâm và mô-tơ rung Haptic đặt tại thắt lưng.

### Các thông số kỹ thuật cốt lõi:
* **Tần số lấy mẫu:** $F_s = 50\text{ Hz}$ ($dt = 0.02\text{ s}$).
* **Thuật toán bộ lọc bù (Complementary Filter):** $\alpha = 0.95$ kết hợp gia tốc kế và con quay hồi chuyển trục Pitch ($g_y$).
* **Ngưỡng phát hiện gù:** $\Delta\theta \ge 15.0^\circ$ (so với tư thế thẳng chuẩn $5^\circ$).
* **Thời gian xác nhận (Debounce Timer):** $t_{confirm} = 3.0\text{ s}$ nhằm loại trừ các cử động cúi thoáng qua (FAR = 0%).
* **Vùng trễ tắt cảnh báo (Hysteresis):** $2.0^\circ$ (chỉ ngắt rung khi ngồi thẳng về dưới $13.0^\circ$).
* **Khóa cảnh báo động học:** Tự động khóa rung khi người dùng đứng dậy đi lại di chuyển dựa trên gia tốc động đa trục.

---

## 📂 2. Cấu trúc Thư mục Dự án

```text
├── 01_DeCuong/          # Đề cương chi tiết theo chuẩn mẫu PTIT HCM
│   └── DeCuong_Nhom4_ThatLungChongGuThongMinh.docx
├── 02_BaoCao/           # Thuyết minh kỹ thuật, linh kiện, nguồn & cảm biến
│   └── ThuyetMinh_ChiTiet_LinhKien_CamBien_BoNguon_Nhom4.pdf
├── 07_MATLAB/           # Toàn bộ mã nguồn mô phỏng & dữ liệu thực nghiệm
│   ├── main_posture_corrector.m      # Chương trình chính đánh giá tổng thể 4 kịch bản
│   ├── visualize_posture_3d.m        # Mô phỏng 3D hoạt động cơ thể người thời gian thực 1:1
│   ├── visualize_all_4_scenarios.m   # Mô phỏng đồng thời cả 4 kịch bản trên lưới 2x2
│   ├── complementary_filter.m        # Hàm bộ lọc bù (alpha = 0.95, Fs = 50 Hz)
│   ├── posture_alert_logic.m         # Hàm logic cảnh báo chống rung nhầm
│   ├── gen_imu_data.m                # Hàm tạo dữ liệu cảm biến MPU-6050
│   ├── run_all_data_generation.m     # Script tự động xuất toàn bộ 4 bộ dữ liệu CSV
│   └── IMU_K1_thap.csv ... K4        # Dữ liệu 4 kịch bản chuẩn hóa (50 Hz, 60s, N=3001)
└── README.md
```

---

## 🚀 3. Hướng dẫn Chạy Mô phỏng trên MATLAB

1. Mở thư mục `07_MATLAB` trong MATLAB hoặc tải lên [MATLAB Online](https://matlab.mathworks.com).
2. **Khởi tạo dữ liệu:**
   ```matlab
   run_all_data_generation;
   ```
3. **Chạy đánh giá thuật toán và vẽ đồ thị 4 kịch bản:**
   ```matlab
   main_posture_corrector;
   ```
4. **Chạy mô hình 3D trực quan từng kịch bản:**
   ```matlab
   visualize_posture_3d('K2');  % Kịch bản gù lưng (có rung)
   visualize_posture_3d('K3');  % Cúi nhặt đồ 3s (không rung nhầm)
   visualize_posture_3d('K4');  % Đi bộ di chuyển (đứng bước đi & khóa rung)
   ```
5. **Chạy cùng lúc cả 4 kịch bản trên lưới $2 \times 2$:**
   ```matlab
   visualize_all_4_scenarios;
   ```
