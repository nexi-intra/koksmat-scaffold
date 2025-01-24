"use client"
import { Button } from "@/components/ui/button"
import { useGraph } from "@/koksmat/usegraph"
import { useState } from "react"

function UseGraph() {
    const {result,error,token} = useGraph("https://graph.microsoft.com/v1.0/me/onenote/notebooks", ["Notes.Read.All"])
return (
    <div>
{result && <pre>{JSON.stringify(result,null,2)}</pre>}  
{error && <pre>{JSON.stringify(error,null,2)}</pre>}
{token && <pre>{JSON.stringify(token,null,2)}</pre>}

    </div>
)
}

export default function Page() {
    const [show, setshow] = useState(false)
    return <div>
    <UseGraph/>
    {/* <Button onClick={()=>setshow(true)}> Show</Button>
    {show && <UseGraph/>} */}
    </div>
}