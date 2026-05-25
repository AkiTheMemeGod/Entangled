import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        display: ["'Instrument Serif'", "serif"],
        body: ["'Inter'", "sans-serif"],
      },
      colors: {
        background: "hsl(201 100% 13%)",
        foreground: "hsl(0 0% 100%)",
        "muted-foreground": "hsl(240 4% 66%)",
        primary: "hsl(0 0% 100%)",
        "primary-foreground": "hsl(0 0% 4%)",
        secondary: "hsl(0 0% 10%)",
        muted: "hsl(0 0% 10%)",
        accent: "hsl(0 0% 10%)",
        border: "hsl(0 0% 18%)",
        input: "hsl(0 0% 18%)",
      },
      animation: {
        "fade-rise": "fade-rise 0.8s ease-out both",
        "fade-rise-delay": "fade-rise 0.8s ease-out 0.2s both",
        "fade-rise-delay-2": "fade-rise 0.8s ease-out 0.4s both",
      },
      keyframes: {
        "fade-rise": {
          from: { opacity: "0", transform: "translateY(24px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
