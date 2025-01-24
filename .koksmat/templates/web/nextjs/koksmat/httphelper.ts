// import {
//     IPublicClientApplication,
//     InteractionRequiredAuthError,
//     Logger,
//     InteractionStatus,
//     AccountInfo,
//   } from "@azure/msal-browser";
import { Method } from "axios";

//import axios, { AxiosError, AxiosRequestConfig, Method } from "axios";
//import { logVerbose } from "./logging";
const sleep = (ms: number) => {
  return new Promise((resolve, reject) => {
    setTimeout(() => resolve(1), ms);
  });
};

export interface Result<T> {
  hasError: boolean;
  timedOut?: boolean;
  errorMessage?: string;
  data?: T;
}

export interface PartialResult<T> {
  hasError: boolean;
  nextLink?: string;
  timedOut?: boolean;
  errorMessage?: string;
  data?: T;
}


export const https = <T>(
  token: string,
  method: Method,
  url: string,
  data?: any,
  contentType?: string,
  additionalConfig?: any
): Promise<Result<T>> => {
  return new Promise((resolve, reject) => {
    var headers: any = {
      "Content-Type": contentType ? contentType : "application/json",
      Prefer: "HonorNonIndexedQueriesWarningMayFailRandomly",
      ConsistencyLevel: "eventual"
    };
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }

    // var config: AxiosRequestConfig = {
    //   method,
    //   data,
    //   url,
    //   headers,
    //   ...additionalAxiosConfig,
    // };
    const dataType = typeof data;
const dataText =  data ? (dataType === "string" ? data :  JSON.stringify(data)) : null
    //logVerbose("https",method,url)
    const send = (retryNumber: number) => {
      fetch(url, {
        method: method,
        headers: headers,
        body: dataText,
        ...additionalConfig
      })
        //axios(config)
        .then(async function (response: Response) {
          if (
            response.status === 404 ||
            response.status === 401 ||
            response.status === 400
          ) {
            // await logMagicpot("general", "https_error", { status: "Error 40X", url,contentType,headers, method, data:dataText, statusText: response.statusText , statusCode: response.status})
            // resolve({
            //   hasError: true,

            //   errorMessage:
            //     response.statusText,
            // });
            
            return;
          }
          if (response.status > 400) {
            if (retryNumber < 3) {
              await sleep(1000 * (retryNumber + 1));
              send(retryNumber + 1);
            } else {
              // await logMagicpot("general", "https_error", { status: "Error Other", url,contentType,headers, method, data:dataText, statusText: response.statusText , statusCode: response.status})
              return resolve({
                hasError: true,
                errorMessage:
                  response.statusText,
              });
            }
          }
          var data = await response.json();

          resolve({ hasError: false, data, errorMessage: "" });
        })
        .catch((error) => {
          resolve({
            hasError: true,
            errorMessage:
              JSON.stringify(error),
          });
        })


    };
    send(0);
  });
};

export const httpsGetAll = <T>(
  token: string,
  url: string,
  options?: {
    maxRows?: number
  }
): Promise<Result<T[]>> => {
  return new Promise((resolve, reject) => {
    var data: T[] = [];
    const next = async (nexturl: string) => {
      var response = await https<any>(token, "GET", nexturl);

      if (response.hasError) {
        resolve({ hasError: true, errorMessage: response.errorMessage });

        return;
      }
      data.push(...response.data.value);
      console.log("data", data.length)
      const maxResponseItems = options?.maxRows ?? 1000000
      if (data.length > maxResponseItems) {
        resolve({ hasError: false, data });
        return;
      }
      if (response.data["@odata.nextLink"]) {
        next(response.data["@odata.nextLink"]);
      } else {
        resolve({ hasError: false, data });
        return;
      }
    };
    next(url);
  });
};

export const httpsGetPage = <T>(
  token: string,
  url: string,
  options?: {
    maxRows?: number
  }
): Promise<PartialResult<T[]>> => {
  return new Promise((resolve, reject) => {
    var data: T[] = [];
    const next = async (nexturl: string) => {
      
      var response = await https<any>(token, "GET", nexturl);
      
      if (response.hasError) {
        resolve({ hasError: true, errorMessage: response.errorMessage });

        return;
      }
      
      data.push(...response.data.value);
      console.log("data", data.length)
      const maxResponseItems = options?.maxRows ?? 1000000
      if (data.length > maxResponseItems) {
        resolve({ hasError: false, data });
        return;
      }


      resolve({ hasError: false, data, nextLink: response.data["@odata.nextLink"] });
      return;

    };
    next(url);
  });
};

var lastProgress: string = "";
export const consoleShowProgress = (text: string) => {
  lastProgress = text;
  process.stdout.write("\b".repeat(text.length) + text);
};

export const consoleClearProgress = () => {
  process.stdout.write("\b".repeat(lastProgress.length));
};

