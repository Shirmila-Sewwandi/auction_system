import { Route, Routes } from "react-router-dom";
import Footer from "./components/Footer";
import NavBar from "./components/NavBar";
import ProtectedRoute from "./components/ProtectedRoute";
import Home from "./pages/Home";
import ListingDetail from "./pages/ListingDetail";
import Login from "./pages/Login";
import Register from "./pages/Register";
import SellerHub from "./pages/SellerHub";
import BidderHub from "./pages/BidderHub";
import ModeratorHub from "./pages/ModeratorHub";
import AdminHub from "./pages/AdminHub";
import Notifications from "./pages/Notifications";

export default function App() {
  return (
    <>
      <div className="app-shell">
        <NavBar />
        <main>
          <Routes>
            <Route path="/" element={<Home />} />
          <Route path="/listings/:listingId" element={<ListingDetail />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route
            path="/seller"
            element={
              <ProtectedRoute roles={["SELLER"]}>
                <SellerHub />
              </ProtectedRoute>
            }
          />
          <Route
            path="/bidder"
            element={
              <ProtectedRoute roles={["BIDDER"]}>
                <BidderHub />
              </ProtectedRoute>
            }
          />
          <Route
            path="/moderator"
            element={
              <ProtectedRoute roles={["MODERATOR"]}>
                <ModeratorHub />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin"
            element={
              <ProtectedRoute roles={["ADMIN"]}>
                <AdminHub />
              </ProtectedRoute>
            }
          />
          <Route
            path="/notifications"
            element={
              <ProtectedRoute>
                <Notifications />
              </ProtectedRoute>
            }
          />
        </Routes>
        </main>
      </div>
      <Footer />
    </>
  );
}
