function PricingCard({ title, price, quota, features, featured, buttonText }) {
  return (
    <div
      style={{
        border: "1px solid #2a3557",
        borderRadius: "20px",
        padding: "20px",
        background: featured ? "#16213b" : "#10182d",
      }}
    >
      <h2>{title}</h2>
      <h3>{price}</h3>
      <p>{quota}</p>

      <ul>
        {features.map((item, index) => (
          <li key={index}>{item}</li>
        ))}
      </ul>

      <button style={{ marginTop: "16px" }}>{buttonText}</button>
    </div>
  );
}

export default PricingCard;