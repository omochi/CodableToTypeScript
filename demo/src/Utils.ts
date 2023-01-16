import { useEffect, useState } from "react";

const checkColorScheme = (): "dark" | "light" => {
  if (window.matchMedia) {
    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return "dark";
    }
  }
  return "light";
}

export const useColorScheme = (): "dark" | "light" => {
  const [scheme, setScheme] = useState(checkColorScheme);
  useEffect(() => {
    if (window.matchMedia) {
      const query = window.matchMedia("(prefers-color-scheme: dark)");
      const callback = () => setScheme(checkColorScheme);
      query.addEventListener("change", callback);
      return () => query.removeEventListener("change", callback);
    }
  }, []);

  return scheme;
}
