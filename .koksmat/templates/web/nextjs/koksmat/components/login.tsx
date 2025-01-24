"use client";


import { MagicboxContext } from "@/koksmat/magicbox-context";
import Link from "next/link";
import { useContext } from "react";

export const LoginButton = () => {
  const magicbox = useContext(MagicboxContext);
  return (
    <button style={{ marginRight: 10 }} onClick={() => {
      
      magicbox.signIn(["openid", "User.Read"],"")
      }}>
      Sign in
    </button>
  );
};

export const RegisterButton = () => {
  return (
    <Link href="/register" style={{ marginRight: 10 }}>
      Register
    </Link>
  );
};

export const LogoutButton = () => {
  const magicbox = useContext(MagicboxContext);
  return (
    <button style={{ marginRight: 10 }} onClick={() => magicbox.signOut()}>
      Sign Out
    </button>
  );
};

export const ProfileButton = () => {
  return <Link href="/profile">Profile</Link>;
};
