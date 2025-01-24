"use client"

import { useEffect, useState } from "react"

import { run } from "./server"
import { Result } from "./httphelper"

export const version = 1

export function   useProcess(
  cmd: string,
  args: string[],
  timeout: number,
  channel: string,
  cwd?:string,
  ran?: boolean,

  setran?: (ran: boolean) => void,
  setresult?: (result: Result<string>) => void,
  debug?:boolean,
 
) {
  const [data, setdata] = useState<any>()
  const [isLoading, setisLoading] = useState(false)
  const [error, seterror] = useState("")
 const [didRun, setdidRun] = useState(false)
  useEffect(() => {
    const load = async () => {
      
      if (didRun) return
    
      seterror("")
    
      
      const result = await run(cmd, args, timeout, channel,cwd,debug)
      setdidRun(true)
      setisLoading(false)
      if (setresult) {setresult(result)}
      if (result.hasError) {
   
        seterror(result.errorMessage ?? "Unknown error")
       
        return
      }else
      {
        setdata(result.data)
      }
    }
    if (channel && cmd && timeout && args) {
     
        load()
      
    }
  }, [cmd, timeout, args, cwd])

  return {
    data,
    error,
    isLoading,
  }
}
