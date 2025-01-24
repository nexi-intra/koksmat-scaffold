"use server"

import * as fs from "fs"
import yaml from "js-yaml"
import { Journey } from "@/koksmat/schemas/journey-schema"
import {Map } from "@/koksmat/schemas//map-schema"
import path from "path"
import { cwd } from "process"

export async function  loadMap(app : string){
   
   const filepath = path.join(cwd(),"src","app",app,"map.yaml")
console.log("map filepath",filepath)
    const data  =  yaml.load(fs.readFileSync(filepath).toString())
    //fs.writeFileSync(path.replace(".yaml",".json"),JSON.stringify(data,null,2))
       return data as Map //JSON.parse(data.toString())
   }
   