"use client"
/*---
title: If Iframed
---*/


import { useEffect, useState } from "react";

type Props = {
    children?: React.ReactNode;
  
  };
export default function HideIfFramed ({ children }: Props)  {
    const [inFrame, setinFrame] = useState(true)
    useEffect(() => {
      setinFrame(window.parent !== window)
    }, [])
    if (inFrame) {
      return null
    }
    return (
        <>{children}</>
    )
    }