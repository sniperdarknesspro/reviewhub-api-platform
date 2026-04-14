function PlanForm() {
  return (
    <div
      style={{
        marginTop: "24px",
        border: "1px solid #2a3557",
        borderRadius: "20px",
        padding: "20px",
        background: "#10182d",
      }}
    >
      <h2>Đăng ký gói API</h2>

      <div style={{ display: "grid", gap: "12px", marginTop: "16px" }}>
        <input placeholder="Tên doanh nghiệp" />
        <input placeholder="Email quản trị" />
        <input placeholder="Website / App domain" />
        <select>
          <option>Nhà xe / OTA vé xe</option>
          <option>Hotel</option>
          <option>Tour</option>
        </select>
        <select>
          <option>Growth</option>
          <option>Starter</option>
          <option>Enterprise</option>
        </select>
        <textarea placeholder="Mô tả nhu cầu tích hợp" rows="5"></textarea>
        <button>Tiếp tục đăng ký gói</button>
      </div>
    </div>
  );
}

export default PlanForm;