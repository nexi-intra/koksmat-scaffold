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
  