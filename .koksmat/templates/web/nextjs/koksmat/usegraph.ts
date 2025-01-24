"use client"
/*---
title: useGraph

 ---
This is a hook that is used to get data from the Microsoft Graph API.
 
 */
import { useContext, useEffect, useState } from "react"

import { run } from "./server"
import { Result, https } from "./httphelper"
import { useMsal } from "@azure/msal-react"
import { set } from "date-fns"
import { MagicboxContext } from "./magicbox-context"

export const version = 1

export function useGraph(
  url: string,
  scopes: string[]


) {
  const magicbox = useContext(MagicboxContext)
  const [token, settoken] = useState("")
  const [data, setdata] = useState<Result<any>>()
  const [isLoading, setisLoading] = useState(false)
  const [error, seterror] = useState("")
  const [didRun, setdidRun] = useState(false)
  const { accounts, instance,inProgress } = useMsal()
  useEffect(() => {
    /**

    This function is used to get data from the Microsoft Graph API.

    It there is no token, it will try to get a token from the MSAL instance, or it will use a previous token 
    if the auth source is not MSAL.
     */
    const load = async () => {

      
    

      seterror("")
      try {
        let token = magicbox.authtoken
        if (magicbox.authSource === "MSAL") {
          const account = accounts[0]
        const response = await instance.acquireTokenSilent({
          scopes,
          account
        });
         token = response.accessToken
      }
        const testResponse = await https(token, "GET", url)
        setdata(testResponse)
        settoken(token)
        if (magicbox.authSource === "MSAL") {
          magicbox.setAuthToken(token,"MSAL")
        }
        setdidRun(true)
        setisLoading(false)

       

      } catch (error) {
        try {
          if (magicbox.authSource !== "MSAL") {
                
            setdidRun(true)
            setisLoading(false)
  
            seterror((error as any).message ?? "Unknown error")
            return
          }
          const account = accounts[0]
          const response = await instance.acquireTokenPopup({
            scopes: scopes ?? [],
            account
          });
          const token = response.accessToken
          const testResponse = await https(response.accessToken, "GET", url)
          setdata(testResponse)
          settoken(token)
          magicbox.setAuthToken(token,"MSAL")
  
         
        } catch (error) {
       
          
          setdidRun(true)
          setisLoading(false)

          seterror((error as any).message ?? "Unknown error")
         
        }



      }




    
      

    }
    
    if (accounts && accounts.length > 0 && instance) {
      if (inProgress === "none") {
        setisLoading(true)
        load()
      }
      

    }else{
      if (magicbox.authtoken && magicbox.authSource !== "MSAL") {
        setisLoading(true)
        load()
      }
    }
  }, [accounts, instance,inProgress])

  return {
    token,
    result:data,
    error,
    isLoading,
  }
}
