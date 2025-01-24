"use client"

import path from "path"
import React, { useContext, useEffect, useState } from "react"
import { useRouter } from "next/navigation"

import {
  Menubar,
  MenubarContent,
  MenubarItem,
  MenubarMenu,
  MenubarSeparator,
  MenubarShortcut,
  MenubarSub,
  MenubarSubContent,
  MenubarSubTrigger,
  MenubarTrigger,
} from "@/components/ui/menubar"
import {
  Map,
  Menuitem,
  RootItem,
} from "@/koksmat/contextdefinition"

export function Menu(props: { rootpath: string; menu: RootItem[] }) {
  const router = useRouter()
  const { menu, rootpath } = props

  const subMenuItems = (menuitem: Menuitem) => {

      return (
        <MenubarSub >
          <MenubarSubTrigger>{menuitem.name}</MenubarSubTrigger>
          <MenubarSubContent>
            {menuitem.menuitems?.map((submenuitem, ix) => {
              return (
                <MenubarItem
                  key={ix}
                  className={submenuitem.menuitem.path ? "cursor-pointer" : ""}
                  onClick={() => {
                    if (submenuitem.menuitem.path)
                      router.push(rootpath + submenuitem.menuitem.path)
                  }}
                >
                  {submenuitem.menuitem.name}
                </MenubarItem>
              )
            })}
          </MenubarSubContent>
        </MenubarSub>
      )
    
  }

  return (
    <Menubar className="border-0">
      {menu.map((menuItem, ix) => {
        return (
          <MenubarMenu key={ix}>
            <MenubarTrigger>{menuItem.menuitem.name}</MenubarTrigger>
            <MenubarContent>
              {menuItem.menuitem.menuitems?.map((item, ix) => {
                if (
                  item.menuitem.menuitems &&
                  item.menuitem.menuitems.length > 0
                ) {
                  return subMenuItems(item.menuitem)
                } else {
                  return (
                    <MenubarItem
                      key={ix}
                      className={item.menuitem.path ? "cursor-pointer" : ""}
                      onClick={() => {
                        if (item.menuitem.path)
                          router.push(rootpath + item.menuitem.path)
                      }}
                    >
                      {item.menuitem.name}
                    </MenubarItem>
                  )
                }
              })}
            </MenubarContent>
          </MenubarMenu>
        )
      })}
    </Menubar>
  )
}
export function TopNav(props: { map: Map; rootpath: string }) {
  const { map, rootpath } = props
  return (
    <div className="flex">
      <div>
        <Menu rootpath={rootpath} menu={map?.menus?.leftmenu} />
      </div>
      <div className="grow"></div>
      <div>
        <Menu rootpath={rootpath} menu={map?.menus?.rightmenu} />
      </div>
    </div>
  )
}
