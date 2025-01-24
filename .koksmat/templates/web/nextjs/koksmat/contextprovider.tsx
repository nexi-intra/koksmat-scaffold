

"use client"

import { useContext, useEffect, useState } from "react"



import { Map } from "./contextdefinition"

import {
  KoksmatContext,
  MagicboxContextType,
  Session,
} from "./contextdefinition"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { set } from "date-fns"
import { TopNav } from "./components/topnav"
import { loadMap } from "./server/loadmap"





type Props = {
  children?: React.ReactNode
  isLocalEnv ?: boolean
  app: string
}

export const KoksmatProvider = ({ children ,isLocalEnv,app}: Props) => {

  const [root, setroot] = useState("")
  const [kitchenroot, setkitchenroot] = useState("")
  const [rootpath, setrootpath] = useState("")
const [hasLeftbar, sethasLeftbar] = useState(isLocalEnv??false)
  const [map, setmap] = useState<Map>()

 


  const magicbox: MagicboxContextType = {
    tenant: "christianiabpos",
    root,
    kitchenroot,
    setPaths: function (root: string, kitchen: string): void {
      setroot(root)
      setkitchenroot(kitchen)
    },
    setRootPath: function (rootpath: string): void {
      setrootpath(rootpath)
    },
    setAppMenu: function (menu: Map): void {
      setmap(menu)
    },
    hasLeftbar,
    setHasLeftbar: function (hasLeftbar: boolean): void {
      sethasLeftbar(hasLeftbar)
    },
    version: 0,
    refresh: function (): void {
      throw new Error("Function not implemented.")
    }
  }

 useEffect(() => {
  const load = async () => {
    if (!app) return
   
    const map = await loadMap(app)
  setrootpath("/"+app+"/")
    setmap(map)
}
load()
 
   
 }, [app])
 

  return (
    <KoksmatContext.Provider value={magicbox}>

        <div className="flex">

          <div>
        
          {hasLeftbar &&
          <div className="sticky top-[64px] h-screen w-[64px] overflow-hidden bg-slate-200">
            {/* Left tool */}
            
          </div>}
          </div>
          <div className="grow">
            <div className=" sticky top-0 z-50 border-b bg-white">
          
              {/* Top nav */}
              <div className="container my-5 flex">
              {map && map.metadata.logo && <Link href="/">
              <img src={map?.metadata.logo} className="mr-4 h-[32px] " alt="logo"/>
              </Link>}
              <div className="grow">
              {map && <TopNav rootpath={rootpath} map={map} />}
              </div>
              </div>
            </div>
          
            <div className="container">
            {/* Main content */}

            {children}
          </div>
          
  
          </div>
{/* 
          <div className="sticky top-0 h-screen w-[64px] bg-slate-400">
           
              Right
            </div> */}
        </div>
     

    </KoksmatContext.Provider>
  )
}
