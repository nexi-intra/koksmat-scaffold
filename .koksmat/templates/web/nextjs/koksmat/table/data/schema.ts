import { z } from "zod"

// We're keeping a simple non-relational schema here.
// IRL, you will have a schema for your data models.
export const schema = z.object({
  title:z.string(),
  link:z.string().nullable(),
  details:z.string().nullable(),
  id:z.string(),
  string1:z.string().nullable(),  
  string2:z.string().nullable(),
  string3:z.string().nullable(),
  refObject1:z.any().nullable(),
  // created_at:z.date().nullable(),
  // updated_at:z.date().nullable(),

})


export type GenericItem<T> = {
  id:string
  title:string
  link?:string 
  details?:string 
  string1?:string 
  string2?:string 
  string3?:string 
  refObject1?:T 
  // created_at:Date | null
  // updated_at:Date | null
}