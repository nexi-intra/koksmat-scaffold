"use server"

import * as fs from "fs"
import yaml from "js-yaml"
import { Journey } from "@/koksmat/schemas/journey-schema"
import {  Map } from "@/koksmat/schemas/map-schema"

export async function  loadTravelPlan(path : string,source?:"filesystem"|"mongo"|"sharepoint"){
 
   
 const data  =  yaml.load(fs.readFileSync(path).toString())
 fs.writeFileSync(path.replace(".yaml",".json"),JSON.stringify(data,null,2))
    return data as Journey //JSON.parse(data.toString())
}

export async function  listTravelPlans(path : string,source?:"filesystem"|"mongo"|"sharepoint"){
  
   return fs.readdirSync(path,{withFileTypes:true}).filter(file=>file.isFile).filter(file=>file.name.endsWith(".yaml"))
   .sort((a,b)=>a.name.localeCompare(b.name))
   .map((file)=>file.name.replace(".json","").replace(".yaml",""))
   
   }
   
  