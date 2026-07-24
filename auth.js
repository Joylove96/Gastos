// Auth gate: wraps App, blocks until user is authenticated

function LoginScreen({onSuccess}) {
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!email || !password) {
      setError("Completa correo y contraseña");
      return;
    }

    setLoading(true);
    try {
      const sb = await initSB();
      const { data: { user }, error: err } = await sb.auth.signInWithPassword({
        email,
        password
      });

      if (err) throw err;

      // Validate email
      if (user.email !== "joylovemypets@gmail.com") {
        await sb.auth.signOut();
        setError("Solo joylovemypets@gmail.com puede acceder");
        setLoading(false);
        return;
      }

      onSuccess();
    } catch (err) {
      const msg = err?.message || "Error desconocido";
      setError(
        msg.includes("Invalid login")
          ? "Correo o contraseña incorrectos"
          : msg
      );
      setLoading(false);
    }
  };

  return React.createElement(
    "div",
    { style: { display: "flex", alignItems: "center", justifyContent: "center", minHeight: "100vh", padding: 16 } },
    React.createElement(
      "div",
      { className: "modal", style: { maxWidth: 400 } },
      React.createElement(
        "div",
        { style: { textAlign: "center", marginBottom: 22 } },
        React.createElement("img", {
          src: "./joylovepets-logo.png",
          alt: "JoyLovePets",
          style: { width: 80, height: 80 },
          onError: (e) => { e.currentTarget.style.display = "none"; }
        }),
        React.createElement("div", { style: { fontSize: 21, fontWeight: 800, marginTop: 10, letterSpacing: "-.5px" } }, "JoyRegist"),
        React.createElement("div", { style: { fontSize: 12, color: "var(--txt2)" } }, "JoyLovePets SpA")
      ),
      React.createElement(
        "form",
        { onSubmit: handleSubmit, style: { display: "flex", flexDirection: "column", gap: 14 } },
        React.createElement("div", { className: "fld", style: { marginBottom: 0 } },
          React.createElement("label", { className: "lbl" }, "Correo"),
          React.createElement("input", {
            className: "inp",
            type: "email",
            autoFocus: true,
            value: email,
            onChange: (e) => setEmail(e.target.value.trim()),
            placeholder: "joylovemypets@gmail.com"
          })
        ),
        React.createElement("div", { className: "fld", style: { marginBottom: 0 } },
          React.createElement("label", { className: "lbl" }, "Contraseña"),
          React.createElement("input", {
            className: "inp",
            type: "password",
            value: password,
            onChange: (e) => setPassword(e.target.value),
            onKeyDown: (e) => e.key === "Enter" && handleSubmit(e),
            placeholder: "••••••"
          })
        ),
        error && React.createElement("div", { className: "banner banner-e", style: { marginBottom: 14 } },
          React.createElement("span", null, "⚠ "),
          React.createElement("span", null, error)
        ),
        React.createElement("button", {
          type: "submit",
          disabled: loading,
          className: "btn btn-p btn-full",
          style: { opacity: loading ? 0.6 : 1, cursor: loading ? "default" : "pointer" }
        }, loading ? "Ingresando..." : "Ingresar")
      )
    )
  );
}

function AuthGate() {
  const [session, setSession] = React.useState(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    let unsubscribe = null;

    (async () => {
      try {
        const sb = await initSB();
        const { data: { session: s } } = await sb.auth.getSession();
        setSession(s);

        const { data: { subscription } } = sb.auth.onAuthStateChange((event, s) => {
          setSession(s);
        });

        unsubscribe = () => subscription?.unsubscribe();
      } catch (e) {
        console.error("Auth init failed:", e);
      } finally {
        setLoading(false);
      }
    })();

    return () => unsubscribe?.();
  }, []);

  if (loading) {
    return React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "center", height: "100vh", gap: 10, color: "var(--txt2)" } },
      React.createElement("div", { className: "spin" }),
      "Cargando…"
    );
  }

  if (!session) {
    return React.createElement(LoginScreen, { onSuccess: () => window.location.reload() });
  }

  return React.createElement(App, null);
}

// Replace the root render when this script loads
setTimeout(() => {
  const root = ReactDOM.createRoot(document.getElementById("root"));
  root.render(React.createElement(AuthGate, null));
}, 0);
