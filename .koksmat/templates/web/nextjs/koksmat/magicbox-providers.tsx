"use client";

import { useEffect, useState } from "react";
import { MagicboxContextType, MagicboxContext, Session, User, AuthSource } from "./magicbox-context";
import { IPublicClientApplication, PopupRequest } from "@azure/msal-browser";

type Props = {
  children?: React.ReactNode;

};

export const MagicboxProvider = ({ children }: Props) => {
  const [session, setsession] = useState<Session>()
  const [version, setversion] = useState(0)
  const [user, setuser] = useState<User>()
  const [authtoken, setauthtoken] = useState("")
  const [authSource, setauthSource] = useState<AuthSource>("")
  const [pca, setpca] = useState<IPublicClientApplication>()


  const magicbox: MagicboxContextType = {
    session, version, refresh: () => {
      setversion(version + 1);
    },
    signIn: async function (scopes: string[], loginHint?: string): Promise<boolean> {
      if (!pca) throw new Error("MSAL not registered");

      const request: PopupRequest = {
        scopes,
        loginHint
      };

      try {
        const result = await pca.loginPopup(request);
        setuser({ name: result.account.name ?? result.account.username, email: result.account.username, image: "", id: result.account.localAccountId,roles: result.account.idTokenClaims?.roles ?? [] });
        return true;
      } catch (error) {
        return false;
      }


    },
    signOut: function (): void {
      pca?.loginRedirect();
    },
    setAccount: function (username: string, email: string, image: string, id: string,roles : string[]): void {

      setuser({ name: username, email: email, image: image, id,roles });
    },

    user,
    registerAuth: function (pca: IPublicClientApplication): void {
      setpca(pca);
    },
    authtoken,
    authSource,
    setAuthToken: function (token: string, source: AuthSource): void {
      setauthSource(source);
      setauthtoken(token);
    }
  }
  return (

    <MagicboxContext.Provider value={magicbox}>

      {children}

    </MagicboxContext.Provider>
  )
};
