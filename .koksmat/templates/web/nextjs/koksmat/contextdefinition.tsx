"use client"
import { createContext } from "react";
export interface Map {
  navigation: string
  metadata: Metadata
  menus: Menus
}

export interface Metadata {
  app: string
  name: string
  logo: string 
  favicon: string
  socialimage: string
  description: string
}

export interface Menus {
  leftmenu: RootItem[]
  rightmenu: RootItem[]
}

export interface RootItem {
 menuitem: Menuitem
}


export interface Menuitem {
  name: any
  type?: string
  path?: string
  disabled?: boolean
  unauthenticated?: boolean
  menuitems: RootItem[]
}

export interface Session {
  user: User;
  expires: string;
  roles: string[];
  accessToken: string;
}

export interface User {
  name: string;
  email: string;
  image: string;
}


export type  MagicboxContextType= {
  session?:Session,
  version:number,
  tenant:string,
  refresh:()=>void,
  root:string
  kitchenroot:string
  hasLeftbar:boolean

  setPaths:(root:string,kitchen:string)=>void
  setRootPath:(rootpath:string)=>void
  setAppMenu(menu:Map):void
  setHasLeftbar:(hasLeftbar:boolean)=>void
}
export const KoksmatContext = createContext<MagicboxContextType>({
  session: { user: { name: "", email: "", image: "" }, expires: "", roles: [], accessToken: "" }, version: 0, refresh: () => { },
  tenant: "",
  root: "",
  kitchenroot: "",
  setPaths: (root: string, kitchen: string) => { },
  setRootPath: function (rootpath: string): void {
    throw new Error("Function not implemented.");
  },
  setAppMenu: function (menu: Map): void {
    throw new Error("Function not implemented.");
  },
  hasLeftbar: false,
  setHasLeftbar: function (hasLeftbar: boolean): void {
    throw new Error("Function not implemented.");
  }
}); 


