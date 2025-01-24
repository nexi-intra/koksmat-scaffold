export interface Journey {
  journey: string
  metadata: Metadata
  triggers: Trigger[]
  waypoints: Waypoint[]
}

export interface Metadata {
  app: string
  name: string
  description: string
}

export interface Trigger {
  trigger: any
  name: string
  key: string
  details: string[]
}

export interface Waypoint {
  port: string
  done?: string[]
  loads: Loads
  services?: Service[]
}

export interface Loads {
  containers: Container[]
}

export interface PowerApp {
  name:string
  url:string
}
export interface Container {
  container: any
  name: string
  key: string
  who: string[]
  approve?: string[]
  consult?: string[]
  inform?: string[]
  needs: string[]
  produces: string[]
  powerapp?: PowerApp
  script: string
}

export interface Service {
  tugs: Tug[]
}

export interface Tug {
  tug: any
  name: string
  who: string[]
  needs: string[]
  produces: string[]
  script: string
}
