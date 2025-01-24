"use client";
import { Button } from "@/components/ui/button";
import { MagicboxContext } from "@/koksmat/magicbox-context";
import { useGraph } from "@/koksmat/usegraph";

import { use, useContext, useEffect, useState } from "react";

function ShowNoteBooks() {
  const { result, error, token } = useGraph(
    "https://graph.microsoft.com/v1.0/me/onenote/notebooks",
    ["Notes.Read.All"]
  );
}

export default function RedirectToLoggedinUse() {
  const magicbox = useContext(MagicboxContext);
  const { user, authtoken, authSource } = magicbox;
  const [isSignedIn, setisSignedIn] = useState(false);

  useEffect(() => {
    if (magicbox.user) {
      setisSignedIn(magicbox.user ? true : false);
    }
  }, [magicbox, isSignedIn]);

  return (
    <div className="space-x-2">
      <Button
        disabled={isSignedIn}
        onClick={async () => {
          const signedIn = await magicbox.signIn(["User.Read"], "");
          if (signedIn) {
          }
        }}
      >
        Sign In
      </Button>

      <Button
        disabled={!isSignedIn}
        onClick={async () => {
          const signedIn = await magicbox.signOut();
        }}
      >
        Sign Out
      </Button>

      {isSignedIn && (
        <pre>{JSON.stringify({ user, authtoken, authSource }, null, 2)}</pre>
      )}
    </div>
  );
}
