
import { Result, https } from "@/koksmat/httphelper";
import { SpawnOptionsWithoutStdio, spawn } from "child_process";
import { MessageType } from "./MessageType";
import { ko } from "date-fns/locale";


const broadcast = async (channel:string,text: string, isError?: boolean) => {
  if (!channel) return
  const message: MessageType = {
    timestamp: new Date().getTime(),
    message: text,
    isError
  };
  // console.log(`koksmat stdout: ${data}`)
  await https("", "POST", "http://localhost:8000/api/publish", {
    channel,
    data: message,
  }, "application/json",
    {
      headers: {
        'X-API-Key': '913f84d9-797c-49e7-b2ac-8bacb40f7637'
      }
    }
  );
}

export const runProcess = (command: string, args : string[], timeout: number,channel:string,cwd?:string,debug?:boolean): Promise<Result<string>> => {
  return new Promise((resolve, reject) => {
    let stdoutput = "";
    let stderror = "";
   
    const result: Result<string> = {
      hasError: false,
      errorMessage: "",
      data: "",
    };
    const timer = setTimeout(() => {
      if (debug) debugger
      processHandler.kill();
      result.hasError = true;
      result.errorMessage = "Timeout";
      result.data = "Timeout";
      resolve(result);
      //reject("Timeout");
    }, timeout * 1000);
    
    const options : SpawnOptionsWithoutStdio = {env: process.env,cwd}

    console.log("runProcess",command,args) //.map(x=>{if (x.indexOf(" ")> -1){return `"${x}"`} else return x}).join(" "))
    const processHandler = spawn(command, args,options);

    // processHandler.stdio[2].on("data", async (data) => {
    //   const text = data.toString();
    //   broadcast(channel,text)
    //   stdoutput += text;
     
    // });
    processHandler.stdout.on("data", async (data) => {
     
      const text = data.toString();
      if (debug) debugger
      // broadcast(channel,text)
      stdoutput += text;
     
    });
    
    processHandler.stderr.on("data", (data) => {
      
      const text = data.toString();
      stderror += text;
      if (debug) debugger
      // broadcast(channel,text,true)
  
    });

    processHandler.on("error", (error) => {
      stderror += error.message;
      if (debug) debugger
      // broadcast(channel,error.message,true)
 
    });

    processHandler.on("close", (code) => {
      if (debug) debugger
      clearTimeout(timer);
      //debugger
      // console.log(`koksmat child process exited with code ${code}`);
      // console.log(`koksmat stdout: ${stdoutput}`);
      if (code !== 0) {
        result.hasError = true;
        result.errorMessage = stderror;
      }
      result.data = stdoutput;
      resolve(result);
    });
  });
};
