import { BrowserRouter, Routes, Route } from "react-router-dom";
import PricingPage from "./pages/PricingPage";
import PartnerPortalPage from "./pages/PartnerPortalPage";
import ApiDocsPage from "./pages/ApiDocsPage";
import AdminLitePage from "./pages/AdminLitePage";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<PricingPage />} />
        <Route path="/portal" element={<PartnerPortalPage />} />
        <Route path="/docs" element={<ApiDocsPage />} />
        <Route path="/admin" element={<AdminLitePage />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;