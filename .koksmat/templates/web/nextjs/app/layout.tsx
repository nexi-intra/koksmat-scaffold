"use client"
import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider } from "next-themes";
import { MagicboxProvider } from "@/koksmat/magicbox-providers";
import { MSALWrapper } from "@/koksmat/msal/auth";


export default function RootLayout2({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body >
        <MagicboxProvider>

          <MSALWrapper>
            {children}
          </MSALWrapper>

        </MagicboxProvider>
      </body>
    </html>
  )
}
