import type { Metadata } from "next";
import { Geist, Geist_Mono, Pixelify_Sans } from "next/font/google";
import { getLocale } from "@/lib/i18n/locale";
import { dictionaries } from "@/lib/i18n/dictionaries";
import { I18nProvider } from "@/lib/i18n/I18nProvider";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const pixelify = Pixelify_Sans({
  variable: "--font-pixelify",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
});

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getLocale();
  return {
    title: "Magaly",
    description: dictionaries[locale].landing.tagline,
  };
}

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const locale = await getLocale();

  return (
    <html
      lang={locale}
      className={`${geistSans.variable} ${geistMono.variable} ${pixelify.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-background text-foreground">
        <I18nProvider locale={locale}>{children}</I18nProvider>
      </body>
    </html>
  );
}
