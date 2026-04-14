import PricingCard from "../components/PricingCard";
import PlanForm from "../components/PlanForm";

function PricingPage() {
  const plans = [
    {
      title: "Starter",
      price: "990K / tháng",
      quota: "10,000 requests / tháng",
      features: [
        "Read-only review public",
        "1 API key",
        "Sandbox test",
      ],
      buttonText: "Mua gói",
      featured: false,
    },
    {
      title: "Growth",
      price: "2.490K / tháng",
      quota: "80,000 requests / tháng",
      features: [
        "Read + write review data",
        "2 API keys",
        "AI moderation tiêu chuẩn",
        "Summary, sentiment, ranking",
      ],
      buttonText: "Dùng thử 7 ngày",
      featured: true,
    },
    {
      title: "Enterprise",
      price: "Liên hệ",
      quota: "Quota tùy chỉnh",
      features: [
        "Nhiều domain",
        "Nhiều API keys",
        "Webhook và SLA nâng cao",
      ],
      buttonText: "Đăng ký tư vấn",
      featured: false,
    },
  ];

  return (
    <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "40px 20px" }}>
      <h1 style={{ textAlign: "center" }}>Pricing Page</h1>
      <p style={{ textAlign: "center", color: "#a9b7d1" }}>
        Trang gói API cho partner
      </p>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: "20px",
          marginTop: "30px",
        }}
      >
        {plans.map((plan, index) => (
          <PricingCard key={index} {...plan} />
        ))}
      </div>

      <PlanForm />
    </div>
  );
}

export default PricingPage;