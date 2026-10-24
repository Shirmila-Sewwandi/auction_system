import { createContext, useContext, useEffect, useState, useCallback } from "react";
import { api, clearToken, getToken, setToken } from "../api/client";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const loadMe = useCallback(async () => {
    if (!getToken()) {
      setUser(null);
      setLoading(false);
      return;
    }
    try {
      const me = await api.get("/api/auth/me");
      setUser(me);
    } catch {
      clearToken();
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadMe();
  }, [loadMe]);

  async function login(email, password) {
    const resp = await api.post("/api/auth/login", { email, password });
    setToken(resp.access_token);
    await loadMe();
    return resp;
  }

  async function register(payload) {
    return api.post("/api/auth/register", payload);
  }

  function logout() {
    clearToken();
    setUser(null);
  }

  function hasRole(...roles) {
    return !!user && roles.some((r) => user.roles.includes(r));
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, hasRole, refresh: loadMe }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
