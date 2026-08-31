> **Phiên bản:** 8.5  
> **Thư mục cài đặt:** `D:\LMIGuardian_Cleaner`  
> **Tác giả:** KN  
> **Đối tượng bảo vệ đặc thù:** Máy tính Windows & USB An Toàn Thông Tin (ATTT) / Kiểm Ngư VN (`KN-260`)

---

## 1. TỔNG QUAN VÀ BỐI CẢNH MÃ ĐỘC

### 1.1. Mã độc LMIGuardian / PlugX là gì?
* **Cơ chế lây nhiễm (DLL Side-loading):** Kẻ tấn công lợi dụng file thực thi sạch có chữ ký số của LogMeIn (`LMIGuardianSvc.exe`) để ngầm nạp thư viện chứa mã độc (`LMIGuardianDll.dll`) và giải mã payload (`LMIGuardianDat.dat` / `data.dat`).
* **Hành vi trên máy tính:** Mã độc ghi khóa tự khởi động vào Registry (`HKCU\...\Run\LMIGuardianuAS`) và ẩn nấp trong các thư mục `C:\ProgramData\LMIGuardianuAS` hoặc `C:\Users\Public\LMIGuardian`.
* **Hành vi trên USB:**
  1. Tạo thư mục chứa mã độc mang tên **`Docusment`** (hoặc `Documents`).
  2. Tạo các Shortcut giả mạo (**`[Tên Thư Mục].lnk`**) ở thư mục gốc USB để lừa người dùng bấm vào.
  3. Tạo một **"Thư mục không tên"** (sử dụng ký tự rỗng `Alt+255`, khoảng trắng `\xA0` hoặc `...`) bên trong Thư mục Mẹ của người dùng (ví dụ: `KIEMNGU260`), sau đó chuyển toàn bộ tài liệu thật vào thư mục không tên này và đặt thuộc tính ẩn hệ thống (`+s +h`).

---

## 2. CẤU TRÚC BỘ CÔNG CỤ TRÊN Ổ `D:\`

Thư mục lưu trữ: [`D:\LMIGuardian_Cleaner`](file:///D:/LMIGuardian_Cleaner)

```text
D:\LMIGuardian_Cleaner\
│
├── run_cleaner.bat               # File thực thi quét & diệt thủ công (Scan-First)
├── clean_lmiguardian.ps1          # Kịch bản PowerShell xử lý lõi (Core Engine)
├── CleanLog.txt                  # File lưu nhật ký kết quả quét & xử lý
│
├── install_auto_usb_guard.bat    # Cài đặt tự động quét ngầm mỗi khi cắm USB
├── usb_watcher.ps1               # Tiến trình WMI lắng nghe sự kiện cắm USB
├── uninstall_auto_usb_guard.bat  # Gỡ bỏ tính năng tự động quét
│
├── README.md                     # Tài liệu hướng dẫn sử dụng và kỹ thuật
└── walkthrough.md                # Bản ghi tóm tắt hệ thống
```

---

## 3. NGUYÊN LÝ HOẠT ĐỘNG VÀ CÁC TÍNH NĂNG CỐT LÕI

### 3.1. Cơ chế Quét Trước - Chỉ Nâng Quyền Khi Có Virus (Scan-First Architecture)
* **Khi mở `run_cleaner.bat`:** Chạy ở quyền người dùng thông thường (Standard User), **không xuất hiện hộp thoại UAC (Yes/No)**.
* **Nếu hệ thống & USB SẠCH:** Công cụ báo màu xanh an toàn, ghi kết quả và thoát ngay lập tức trong 1 giây.
* **Nếu phát hiện CÓ MÃ ĐỘC:** Tự động kích hoạt hộp thoại UAC xin quyền Administrator để tiến hành tiêu diệt nguồn lây trên máy tính và giải cứu file trên USB.

### 3.2. Chống bẫy vòng lặp vô tận (.NET Direct I/O)
* Mã độc tạo thư mục ảo tuần hoàn nhằm gây lỗi tràn bộ nhớ (`StackOverflowException`) khi các phần mềm diệt virus quét đệ quy.
* Công cụ sử dụng trực tiếp thư viện **.NET `[System.IO.Directory]`** để quét trực diện 1 cấp, xử lý nhanh chóng trong vài giây và **miễn nhiễm 100% với bẫy StackOverflow**.

### 3.3. Tương thích chuyên biệt với USB An Toàn ATTT (Kiểm Ngư 260)
* **Danh sách Whitelist bảo vệ:** Công cụ tự động nhận diện và bỏ qua các file cấu hình bảo mật được khóa quyền của USB ATTT:
  * `ATTT.ico`, `AUTORUN.INF`, `inf.bin`, `Mtext.bin`, `RECYCLER`, `System Volume Information`.
* Không gây ra thông báo lỗi `Access denied` và không làm hỏng cơ chế bảo vệ của USB.

### 3.4. Thuật toán cứu dữ liệu về Thư mục Mẹ (Dynamic Folder Rescue)
* Tự động nhận diện Thư mục Mẹ tại gốc USB (bất kể tên là `KIEMNGU260`, `A`, `TaiLieu`, `Data`...).
* Dò tìm thư mục con không tên bên trong Thư mục Mẹ.
* Di chuyển toàn bộ tài liệu từ thư mục không tên ra lại Thư mục Mẹ an toàn.
* Xóa thư mục không tên rác và gỡ bỏ hoàn toàn thuộc tính ẩn (`-s -h -r`).

### 3.5. Nhật ký tinh gọn (Clean Result Logging)
* Chỉ lưu lại thông số phần cứng USB kết nối (`DeviceID`, `VolumeName`, `FileSystem`, `Size`, `Serial`), các mối đe dọa phát hiện được, danh sách file đã xóa/cứu và dòng tổng kết kết quả.
* Tự động cách dòng trống giữa các phiên quét.

---

## 4. HƯỚNG DẪN SỬ DỤNG

### Cách 1: Quét thủ công bất cứ lúc nào
1. Cắm USB vào máy tính.
2. Bấm đúp vào file **[`run_cleaner.bat`](file:///D:/LMIGuardian_Cleaner/run_cleaner.bat)**.
3. Nếu có virus: Bấm **Yes** khi được hỏi quyền Admin để công cụ tự động dọn sạch.

### Cách 2: Bật chế độ Tự động bảo vệ mỗi khi cắm USB (Khuyên dùng)
1. Bấm đúp vào file **[`install_auto_usb_guard.bat`](file:///D:/LMIGuardian_Cleaner/install_auto_usb_guard.bat)** (Chỉ cần chạy 1 lần duy nhất).
2. **Từ thời điểm này:** Bất cứ khi nào bạn cắm USB vào máy tính, Windows sẽ tự động kích hoạt công cụ quét và giải cứu dữ liệu tức thì.
3. **Khi muốn tắt:** Bấm đúp vào file **[`uninstall_auto_usb_guard.bat`](file:///D:/LMIGuardian_Cleaner/uninstall_auto_usb_guard.bat)**.

---

## 5. BẢNG MÃ NHẬT KÝ
### 1.2. Mẫu hiển thị trong `CleanLog.txt`:
```text
[2026-08-31 11:09:30] [USB_KET_NOI] O dia: E: | Nhan: KN-260 | Dinh dang: NTFS | Dung luong: 28.67 GB (Con trong: 27.86 GB) | Serial: FE3AE0A0 | Danh sach: KIEMNGU260 (KeHoachTuan.docx, BaoCaoThang8.xlsx, HoSoTau)
```

| Thẻ Tag | Ý nghĩa |
| :--- | :--- |
| `[USB_KET_NOI]` | Thông tin phần cứng USB vừa cắm (Ký tự ổ, Nhãn, Định dạng NTFS/FAT32, Dung lượng, Serial). |
| `[PHAT_HIEN]` | Phát hiện mối đe dọa (Shortcut, file PC, thư mục Docusment, thư mục ẩn giấu file). |
| `[DA_DUNG_TIEN_TRINH]` | Buộc dừng tiến trình mã độc chạy ngầm trên RAM máy tính. |
| `[DA_XOA_REGISTRY]` | Đã xóa khóa Registry khởi động cùng Windows. |
| `[DA_XOA_FILE_PC]` | Đã tiêu diệt file mã độc trong `%ProgramData%`, `%Public%` hoặc `%Temp%`. |
| `[DA_XOA_SHORTCUT_USB]` | Đã xóa lối tắt giả mạo `.lnk` trên USB. |
| `[DA_XOA_THU_MUC_MA_DOC]` | Đã xóa vĩnh viễn thư mục chứa payload mã độc `Docusment`. |
| `[DA_CUU_DU_LIEU]` | Đã chuyển file từ thư mục ẩn về Thư mục Mẹ của người dùng thành công. |
| `[DA_XOA_THU_MUC_AN]` | Đã dọn dẹp thư mục không tên rỗng sau khi cứu file. |
| `[KET_QUA]` | Báo cáo tổng kết trạng thái an toàn cuối cùng. |
