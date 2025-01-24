"use server"

import { runProcess } from "./runProcess"

export async function test() {
  const t = await runProcess("az",["--version"],20,"test")
  return t.data
}

export async function run(cmd:string, args:string[], timeout:number,channel:string,cwd?:string,debug?:boolean) {
  const result = await runProcess(cmd,args,timeout,channel,cwd,debug)
  //console.log("run",result)
  return result
}
