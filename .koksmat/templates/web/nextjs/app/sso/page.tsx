"use client"
/*---
title: SSO
description: Single Sign On endpoint
 ---

 This endpoint is designed to accept a token from SharePoint and use that to authenticate the user. 

 This endpoint can be called with a query parameter `cmd` to see the token or the user information.

 ## Show "Me"
 ./sso?token=<TOKEN>?cmd=me

  ## Show "JWT"
 ./sso?token=<TOKEN>?cmd=jwt
 
 If no `cmd` is provided, the user will be redirected to the profile page router endpoint 
 
 */


import { https } from '@/koksmat/httphelper'
import { MagicboxContext } from '@/koksmat/magicbox-context'
import { redirect, useRouter, useSearchParams } from 'next/navigation'
import { useContext, useEffect, useState } from 'react'
import jwt from "jsonwebtoken"
import { set } from 'date-fns'
import { APPNAME } from '@/app/global'
import { useMsal } from '@azure/msal-react'
export interface Me {
  "@odata.context": string
  businessPhones: string[]
  displayName: string
  givenName: string
  jobTitle: any
  mail: string
  mobilePhone: string
  officeLocation: string
  preferredLanguage: string
  surname: string
  userPrincipalName: string
  id: string
}

export default function SSO() {
  const magicbox = useContext(MagicboxContext)
  const searchParams = useSearchParams()
  const [jwtToken, setjwtToken] = useState<jwt.JwtPayload>()
  const token = searchParams.get('token')
  const cmd = searchParams.get('cmd')
  const [data, setdata] = useState<any>()
  const router = useRouter()
  const [frameHref, setframeHref] = useState("")
  const msal = useMsal()

  useEffect(() => {
    const load = async () => {
      if (!token) {
        return
      } 
      const result = await https<Me>(token , "GET", "https://graph.microsoft.com/v1.0/me")
      if (cmd === "login" ) {
        //msal
alert(result.data?.userPrincipalName)
      }
      magicbox.setAccount(result.data?.displayName ??"", result.data?.mail??"", "", result.data?.id??"",[])
      magicbox.setAuthToken(token, "SharePoint")

      if (!cmd){
        setframeHref("/sso/?cmd=framed&token=" + token)
        
      }else
      if (cmd === "framed") {
        router.push("/"+APPNAME)
       
      }
      setdata(result)
    }
    if (token) {
      const jwtToken = jwt.decode(token) as jwt.JwtPayload
      setjwtToken(jwtToken)
    
      load()
    }


  }, [token])
  switch (cmd) {
    case "login":
      return <pre>{JSON.stringify(data, null, 2)}</pre>

    case "me":
      return <pre>{JSON.stringify(data, null, 2)}</pre>
    case "jwt":
      return <pre>{JSON.stringify(jwtToken, null, 2)}</pre>
    case "framed":
      return <div></div>  
    default:

      return <div>
{frameHref &&
<div>

<iframe src={frameHref} width="100%" height="100%" style={{height:"100vh",border:""}}></iframe>
</div>
  }


      </div>
  }

  
}
