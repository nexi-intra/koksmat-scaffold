<#---
title: Generate Microservice Integration Code
tag: generateapp
api: post

---

# Intro

This script generates the code for the microservice integration. The code is generated from the `magicapp.yaml` file. The code is generated in the following steps:

1. Generate the service endpoint for the microservice
2. Generate the web proxy endpoint for the microservice
3. Generate the web component for the microservice
4. Generate the test page for the microservice
5. Generate the Go service endpoint for the microservice

The code is generated in the following directories:

- `app/services/<service-name>/endpoints/<method-name>`
- `web/services/<service-name>/endpoints/<method-name>`
- `web/services/<service-name>/endpoints/<method-name>/webcomponent`
- `web/app/test/services/<service-name>/endpoints/<method-name>`
- `app/services/<service-name>.go`

The code is generated in the following files:

- `index.ts`
- `index.tsx`
- `page.tsx`
- `<method-name>.go`



#>
param (
    # $kitchenname = "magic-messages",
    # $kitchenname = "magic-people",
    # $kitchenname = "magic-share",
    # $kitchenname = "magic-it",
    # $kitchenname = "magic-facility",
    # $kitchenname = "nexi-infocast",
    # $kitchenname = "magic-boxes",
    # $kitchenname = "magic-apps",
    # $kitchenname = "magic-meeting",
    # $kitchenname = "magic-zones",
    # $kitchenname = "magic-it",
    #$kitchenname = "nexi-toolsv2",
    # $kitchenname = "magic-work",
    $kitchenname = "magic-mix",
    # $kitchenname = "nexi-booking-v2",
    $verbose = $false

  
)
$migrationId = 0
$ISREQUIRED = $true
$ISNOTREQUIRED = $false
$ErrorActionPreference = "Stop"
$TextInfo = (Get-Culture).TextInfo
$koksmatDir = join-path $ENV:KITCHENROOT $kitchenname ".koksmat" 
$mapicapp = yq (join-path $koksmatDir "magicapp.yaml") -o json | ConvertFrom-Json
yq (join-path $koksmatDir "magicapp.yaml") -o json > (join-path $koksmatDir "magicapp.json")

$entitiesInOrder = yq (join-path $koksmatDir "magicapp.yaml") -o json  | jq '.entities | keys_unsorted' | ConvertFrom-Json

#region Support functions

if (-not $mapicapp) {
    throw "No magicapp.yaml found in $koksmatDir"
}

if ($mapicapp.magicappversion -ne "v0.0.1") {
    throw "Unsupported version $mapicapp.version"
}



$serviceInstancePath = join-path $koksmatDir "app" "services"  
$serviceWebProxyPath = join-path $koksmatDir "web" "services"  $kitchenname 
$serviceWebTestPagePath = join-path $koksmatDir "web" "app" "magic" "services"  $kitchenname 

<#

## Supporting functions
#>
function EnsurePath($path) {
    if (-not (Test-Path $path)) {
        write-host "Creating directory  $path"
        New-Item -Path  $path -ItemType Directory | Out-Null
    }

}

function EnsurePathWithId($path) {
    if (-not (Test-Path $path)) {
        write-host "Creating directory  $path"
        New-Item -Path  $path -ItemType Directory | Out-Null
        New-Item -Path  (join-path $path "[id]") -ItemType Directory | Out-Null

    }

}

function YamlMultilineComment {
    param (
        [string]$InputString
    )

    # Split the input string into an array of lines
    $lines = $InputString -split "`r`n|`n|`r"

    # Prefix each line with "# "
    $commentedLines = $lines | ForEach-Object { "# $_" }

    # Join the lines back into a single string
    $outputString = $commentedLines -join "`n"

    return $outputString
}

function WriteTextFile($filepath, $content) {
    if (Test-Path $filepath) {
        $existingcontent = Get-Content $filepath
        

        # find the string "keep: true" in the $content read from Get-Content
        $keep = $existingcontent | Select-String -Pattern "keep: true"
        if ($keep) {
            # if the string is found, remove it from the $content
            write-host "Keeping $filepath" -ForegroundColor Yellow
            return
        }
    }
    $content | Out-File -FilePath $filepath -Encoding utf8NoBOM
    if ($verbose) {
        write-host "Writing $filepath" -ForegroundColor Yellow
    
    }
}

#endregion 
$fileHeader = @"
/* 
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´keep´ to ´true´ syntax for the code snippet
---
keep: false
---
*/
"@

#region Outputters
<#

## Web service proxy

This is used by the Web app


#>


function GenerateServiceWebProxyEndpoint($service, $name, $methodName, $description, $returnType, [array]$parameters, $entity) {

    return ##v3
    $servicePath = join-path $serviceWebProxyPath "endpoints" $name  $methodName 
    EnsurePath $servicePath
    $parametersCode = "" # Can be empty
    $parametersServiceCode = "" # Can be empty
    $parametersHelperCode = "" # Can be empty
    $returnHelperCode = $returnType # Can be empty

    foreach ($parameter in $parameters) {
       
        switch ($parameter.type) {
            "object" {
                $parametersCode += "," + $parameter.name + ": " + $entity.objectname 
                $parametersServiceCode += ", JSON.stringify(" + $parameter.name + ")" 
            }
            Default { 
                $parametersCode += "," + $parameter.name + ": " + $parameter.type 
                $parametersServiceCode += ", " + $parameter.name 
            }
        }
       
        $parametersHelperCode += "* " + $parameter.name + " - " + $parameter.description + "`n"
    }
    
    $code = @"
"use server";
/*
Parameters

*/
$fileHeader 
import { run } from "@/app/koksmat/magicservices";
import { ShowCodeFragment } from "@/services/ShowCodeFragment";
import { $returnType } from "@/services/$($service)/models/$($entity.model)";
/**
 * $description
 * 
 $parametersHelperCode
 * @returns
 * 
 * $returnHelperCode
 */
export default async function call(transactionId: string $parametersCode) {
  console.log( "$($service).$($name)", "$methodName");

  return run<$($returnType)>(
    "$($service).$($name)",
    ["$methodName" $parametersServiceCode],
    transactionId,
    600,
    transactionId
  );
}

"@
    #  $code | Out-File -FilePath (join-path $servicePath "index.ts") -Encoding utf8NoBOM
    WriteTextFile (join-path $servicePath "index.ts") $code
}

<#
## Web test component

#>

function GenerateServiceWebComponent($service, $name, $methodName, $description, $returnType, [array]$parameters, $entity) {
    return ##v3    
    $servicePath = join-path  $serviceWebProxyPath "endpoints"  $name $methodName "webcomponent"  
    $serviceEndpointname = $name + (Get-Culture).TextInfo.ToTitleCase($methodName)

    EnsurePath $servicePath
    $parametersCode = "" # Can be empty
    $parametersServiceCode = "" # Can be empty
    $parametersHelperCode = "" # Can be empty
    $returnHelperCode = $returnType # Can be empty

    foreach ($parameter in $parameters) {
       
        switch ($parameter.type) {
            "object" {
                $parametersCode += "," + $parameter.name + ": " + $entity.objectname 
                $parametersServiceCode += ", JSON.stringify(" + $parameter.name + ")" 
            }
            Default { 
                $parametersCode += "," + $parameter.name + ": " + $parameter.type 
                $parametersServiceCode += ", " + $parameter.name 
            }
        }
       
        $parametersHelperCode += "* " + $parameter.name + " - " + $parameter.description + "`n"
    }
    if ($null -eq $entity.objectname) {
        write-host "No entity found for $name.$methodName" -ForegroundColor Red
    }

    $resultParser = ""
    switch ($returnType) {
        "void" {
            $resultParser = " setOutput(null);"
        }
        "page" {
            $resultParser = @" 
            setOutput(result.data)

"@
        }
        "object" {
            $resultParser = @" 
            setOutput(result.data)

"@
        }
        default {
            write-host $service, $name, $methodName, $description, $returnType -ForegroundColor Red
            throw "Unknown return type $returnType"
            
        }
    }

    $backtick = "``"

    $ImportStatementCodeFragment = @"
$backtick     
import { $serviceEndpointname } from "@/services/$($service)/endpoints/$($name)/$methodName";
$backtick 
"@    


    $CallStatementCodeFragment = @"
$backtick     
const [input, setInput] = useState<any>();
const [output, setOutput] = useState<any>();
const [errorMessage, seterrorMessage] = useState("");

const invokeServiceEndpoint = async () => {
    setOutput(null);
    seterrorMessage("");
const result = await $($serviceEndpointname)(transactionId,input);
if (result.hasError) {
    seterrorMessage(result.errorMessage ?? "Unknown error");
    return;
}
if (result.data) {
    $resultParser
}
};$backtick 
"@    
    $code = @"
$fileHeader 
"use client";

import { MagicboxContext } from "@/app/koksmat/magicbox-context";

import  $serviceEndpointname from "@/services/$($service)/endpoints/$($name)/$methodName";
import { useContext, useState } from "react";
import { Button } from "@/components/ui/button";
import { ShowCodeFragment } from "@/services/ShowCodeFragment";
import { TestServicesCall } from "@/services/testserviceexecute";

export default function TestServiceComponent() {
    const magicbox = useContext(MagicboxContext);
    const { transactionId } = magicbox;
    
 
    const [input, setInput] = useState<any>();
    const [output, setOutput] = useState<any>();
    const [errorMessage, seterrorMessage] = useState("");
    const invokeServiceEndpoint = async () => {
        setOutput(null);
        seterrorMessage("");
    
    const result = await $($serviceEndpointname)(transactionId,input);
    if (result.hasError) {
        seterrorMessage(result.errorMessage ?? "Unknown error");
        return;
    }
    if (result.data) {
        $resultParser
    }
    };

    return (
    
    <div >
    <div>
    
   
    <div>
   
  
    <div className="flex">
   
        </div>
        <div>
        <div className="text-xl my-4 spy-l-2">Test</div>
        <textarea
        style={{ height: "50vh" }}
        className="w-full border border-gray-300 rounded-lg p-2 h-1/3"
        
        value={input}
        onChange={(e) => setInput(e.target.value)}
        />
        <div className="p-3">
        <Button onClick={invokeServiceEndpoint}>Invoke</Button>
        <div>
        </div>
      
        </div>
        </div>
        <pre>
            {JSON.stringify(
            { errorMessage, input,output, transactionId },
            null,
            2
            )}
        </pre>  </div>
     
    </div>
    <ShowCodeFragment
    title="Import statement" code={$ImportStatementCodeFragment} 
    />
    <ShowCodeFragment
    title="Call" code={$CallStatementCodeFragment} 
    />
    </div>

    
    );
}
"@
    
    # $code | Out-File -FilePath (join-path $servicePath "index.tsx") -Encoding utf8NoBOM
    WriteTextFile (join-path $servicePath "index.tsx")  $code

}

<#
Web Pages
#>
function GenerateServicePage($service, $name) {
    return ##v3

    $pagePath = join-path $koksmatDir  "web" "app" $service "service" $name 
    write-host  $pagePath -ForegroundColor:Green    
    EnsurePathWithId $pagePath 

    $code = @"
$fileHeader     
"use client";


export default function Page() {
    return (
        <div>
        <h1 className="text-2xl">$name</h1>
        
        </div>
    );
}

"@
    WriteTextFile (join-path $pagePath "page.tsx")  $code


    $code = @"
    $fileHeader     
    "use client";
    import { $name } from "@/services/$service/endpoints/$name";
    
    
    export default function Page(props : {params:{id:string}}) {
        const {id} = props.params
        return (
            <div>
            $name
            </div>
        );
    }
    
"@
    # WriteTextFile (join-path $pagePath "[id]" "page.tsx")  $code
    
}

<#
## Web test page

#>
function GenerateServicePages($service, $name, $methodName, $description, $returnType, $entity, $tsInterface, $itemView, $itemForm, $zodModel) {
    
    return ##v3
    $methodName = "components"
    $description = "Test page for $name.$methodName"
    $returnType = ""
    $pagePath = join-path $serviceWebTestPagePath  $name
    $pageComponentPath = join-path $pagePath "components"
    $pageAppLogicPath = join-path $pagePath "applogic"
    $webcomponentPath = join-path "@" "app" "magic" "services" $service  $name  "components"
    $pageRelativePath = join-path "app" "magic" "services" $kitchenname $name   "page.tsx"
    $componentName = $entity.objectname #+ (Get-Culture).TextInfo.ToTitleCase($methodName)
    EnsurePath $pagePath
    EnsurePath $pageComponentPath
    EnsurePath $pageAppLogicPath
    $code = @"

"use client";
$fileHeader 
/* dumle */
import {
    Sheet,
    SheetContent,
    SheetDescription,
    SheetHeader,
    SheetTitle,
    SheetTrigger,
  } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import Search$componentName from "$webcomponentPath/search";
import Create$componentName from "$webcomponentPath/create";
import {useState} from "react";

export default function $($componentName)() {
    const [isCreating, setisCreating] = useState(false);
return (
<div>
<div>
<Button variant="secondary" onClick={() => setisCreating(true)}>Create</Button>
</div>
<Search$componentName />
<Sheet open={isCreating} onOpenChange={setisCreating}>
<SheetContent>
  <SheetHeader>
    <SheetTitle>Create $componentName</SheetTitle>
    <SheetDescription>
      <Create$($componentName)  />
    </SheetDescription>
  </SheetHeader>
</SheetContent>
</Sheet>
</div>
);
}
    
"@
    #  $code | Out-File -FilePath (join-path $pagePath "page.tsx") -Encoding utf8NoBOM
    $searchcode = @"

    "use client";

    import { Input } from "@/components/ui/input";
import { useService } from "@/app/koksmat/useservice";
import { useSQLSelect } from "@/app/koksmat/usesqlselect";
import { set } from "date-fns";
import { tr } from "date-fns/locale";
import { useMemo, useState } from "react";
import $($componentName)SmallCard from "./smallcard";
import {$($componentName)Item} from "../applogic/model";

  
    $fileHeader 
    /* guldbar */

   

    export interface Root {
        totalPages: number
        totalItems: number
        currentPage: number
        items: $($componentName)Item[]
      }
   

    export default function Search$($componentName)(
        props: {
          onItemClick? : (item:$($componentName)Item) => void
        }

    ) {
        const [transactionId, settransactionId] = useState(0);
        const search = useMemo(() => {
          return { text: "" };
        }, []);
        const searchResult = useService<Root>(
          "$service.$name",
          ["search", "%" + search.text + "%"],
          "",
          6000,
          transactionId.toString()
        );
        return (
          <div>
            Search
            <Input
              type="text"
              value={search.text}
              className="mx-2"
              onChange={(e) => {
                search.text = e.target.value;
                settransactionId(transactionId + 1);
              }}
            />
            {searchResult?.error && (
                <div className="text-red-500">Error: {searchResult.error}</div>
              )}
              {searchResult?.isLoading && <div>Loading</div>}
              {searchResult?.data && (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 ">
                  {searchResult.data.items.map((item, index) => {
                    return <div key={index}>
                    <$($componentName)SmallCard item={item} 
                  
                    onClick={()=>{
                        if (props.onItemClick) {
                            props.onItemClick(item)
                    }}}
                    />

                    
                    
                    
                    </div>;
                  })}
                </div>
              )}
        
         
          </div>
    );
    }
        
"@
   
    $createcode = @"
    $fileHeader 
    "use client";
    import { useService } from "@/app/koksmat/useservice";
    import { useState } from "react";
    import {$($componentName)Form} from "./form";
    
    import {$($componentName)Item} from "../applogic/model";
    export default function Create$($componentName)() {
       
        const $name = {} as $($componentName)Item;
        return (
          <div>{$name && 
          <$($componentName)Form $name={$name} editmode="create"/>}
         
          </div>
        );
    }
"@

    $readcode = @"
    $fileHeader 
"use client";
import { useService } from "@/app/koksmat/useservice";
import { useState } from "react";
import {$($componentName)Item} from "../applogic/model";


/* yankiebar */

export default function Read$($componentName)(props: { id: number }) {
    const { id } = props;
    const [transactionId, settransactionId] = useState(0);
    const readResult = useService<$($componentName)Item>(
      "$service.$name",
      ["read", id?.toString()],
      "",
      6000,
      transactionId.toString()
    );
    const $name = readResult.data;
    return (
      <div>
      $itemView
     
      </div>
    );
  }
      
"@

    $updatecode = @"
$fileHeader 
"use client";
// piratos
import { useService } from "@/app/koksmat/useservice";
import { useState } from "react";
import {$($componentName)Form} from "./form";

import {$($componentName)Item} from "../applogic/model";
export default function Update$($componentName)(props: { id: number }) {
    const { id } = props;
 
    const [transactionId, settransactionId] = useState(0);
    const readResult = useService<$($componentName)Item>(
      "$service.$name",
      ["read", id?.toString()],
      "",
      6000,
      transactionId.toString()
    );
    const $name = readResult.data;
    return (
      <div>{$name && 
      <$($componentName)Form $name={$name} editmode="update"/>}
     
      </div>
    );
}
"@

    $formcode = @"
    $fileHeader 
"use client";
import { useState,useEffect } from "react";
import {$($componentName)Item} from "../applogic/model";
import {$($componentName)Schema} from "../applogic/model";
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { Button } from "@/components/ui/button";
import { toast } from "@/components/ui/use-toast"
import {
    Form,
    FormControl,
    FormDescription,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
  } from "@/components/ui/form"
  import { Input } from "@/components/ui/input"
/* marsbar */



export function $($componentName)Form(props : {$($name): $($componentName)Item,editmode:"create"|"update"}) {
    const {$name,editmode} = props;
    function onSubmit(data: z.infer<typeof $($componentName)Schema>) {
        toast({
          title: "You submitted the following values:",
          description: (
            <pre className="mt-2 w-[340px] rounded-md bg-slate-950 p-4">
              <code className="text-white">{JSON.stringify(data, null, 2)}</code>
            </pre>
          ),
        })
      }
    const form = useForm<z.infer<typeof $($componentName)Schema>>({
        resolver: zodResolver($($componentName)Schema)
      })

      useEffect(() => {
        form.reset($name);
      }, [$name]);
    return (
      <div>
      <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
       
      $itemForm
      <Button  type="submit">{editmode === "create"?"Create":"Update"}</Button>
      </form>
     </Form>
      </div>
    );
  }
      
"@


    $deletecode = @"
"use client";
$fileHeader
import { Button } from "@/components/ui/button";
/* spejderhagl */

export default function Delete$($componentName)(props: { id: number ,onDeleteConfirmed:()=>void}) {
    const { id,onDeleteConfirmed } = props;
return (
<div>
<Button variant="destructive" onClick={onDeleteConfirmed}>Delete</Button><Button variant="secondary">Cancel</Button>


</div>
);
}
    
"@

    $smallcardcode = @"
"use client";
$fileHeader
/* citronmåne */

import {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
  } from "@/components/ui/card";
  import { useState } from "react";
  import {
    Sheet,
    SheetContent,
    SheetDescription,
    SheetHeader,
    SheetTitle,
    SheetTrigger,
  } from "@/components/ui/sheet";

  import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
  } from "@/components/ui/dropdown-menu"
  import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogTrigger,
  } from "@/components/ui/alert-dialog"
  
  import { Ellipsis } from "lucide-react";
  import { Button } from "@/components/ui/button";
  import {$($componentName)Item} from "../applogic/model";
  import Read$($componentName) from "./read";
  import Update$($componentName) from "./update";

  export default function $($componentName)SmallCard(props: {
    item: $($componentName)Item;
    onClick?: () => void;
  }) {
    const { item,onClick} = props;
   
    const [isEditing, setisEditing] = useState(false);
    const [isViewing, setisViewing] = useState(false);
    const [isDeleting, setisDeleting] = useState(false);


    return (
        <div>
      <Card className="m-2 hover:shadow-lg cursor-pointer" onClick={onClick}  >
        <CardHeader>
          <CardTitle>
          <div className="flex">
          <div>
          {item.name}
          </div>
          <div className="grow">
          </div>
          <div>
          <DropdownMenu>
          <DropdownMenuTrigger  onClick={(e) => {
            e.stopPropagation();
          }}
        >
          <Ellipsis size={"18px"} />
          
          </DropdownMenuTrigger>
          <DropdownMenuContent>
            <DropdownMenuLabel>{item.name}</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem
            onClick={(e) => {
              e.stopPropagation();
              setisViewing(true);
            }}
          >
            View
          </DropdownMenuItem>
          <DropdownMenuItem
            onClick={(e) => {
              e.stopPropagation();
              setisEditing(true);
            }}
          >
            Edit
          </DropdownMenuItem>          
          <DropdownMenuItem
            onClick={(e) => {
              e.stopPropagation();
              setisDeleting(true);
            }}
          >
            Delete
          </DropdownMenuItem>          
          </DropdownMenuContent>
        </DropdownMenu>

            </div>
            </div>
        </CardTitle>
          <CardDescription>{item.description}</CardDescription>
        </CardHeader>
        <CardContent></CardContent>
        <CardFooter></CardFooter>
      </Card>
      <Sheet open={isViewing} onOpenChange={setisViewing}>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>{item.name}</SheetTitle>
          <SheetDescription>
            {isViewing && (item.id>0) && <Read$($componentName) id={item.id} />}
          </SheetDescription>
        </SheetHeader>
      </SheetContent>
    </Sheet>
    <Sheet open={isEditing} onOpenChange={setisEditing}>
    <SheetContent>
      <SheetHeader>
        <SheetTitle>{item.name}</SheetTitle>
        <SheetDescription>
          {isEditing && (item.id>0) && <Update$($componentName) id={item.id} />}
        </SheetDescription>
      </SheetHeader>
    </SheetContent>
  </Sheet>

  <AlertDialog open={isDeleting} onOpenChange={setisDeleting}>
  <AlertDialogContent>
    <AlertDialogHeader>
      <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
      <AlertDialogDescription>
        This action cannot be undone. This will permanently delete your account
        and remove your data from our servers.
      </AlertDialogDescription>
    </AlertDialogHeader>
    <AlertDialogFooter>
      <AlertDialogCancel>Cancel</AlertDialogCancel>
      <AlertDialogAction>Continue</AlertDialogAction>
    </AlertDialogFooter>
  </AlertDialogContent>
</AlertDialog>

  </div>
    );
  }
  
    
"@


    $modelCode = @"
    
$fileHeader       
"use client";
import { z } from "zod";
$tsInterface
$zodModel
"@
    WriteTextFile (join-path $pagePath "page.tsx")  $code
    WriteTextFile (join-path $pageComponentPath "search.tsx")  $searchcode
    WriteTextFile (join-path $pageComponentPath "create.tsx")  $createcode
    WriteTextFile (join-path $pageComponentPath "read.tsx")  $readcode
    WriteTextFile (join-path $pageComponentPath "update.tsx")  $updatecode
    WriteTextFile (join-path $pageComponentPath "delete.tsx")  $deletecode
    WriteTextFile (join-path $pageComponentPath "smallcard.tsx")  $smallcardcode
    WriteTextFile (join-path $pageComponentPath "form.tsx")  $formcode
    WriteTextFile (join-path $pageAppLogicPath "model.ts")  $modelCode 

}

<#
## Service endpoint
.
├── cmds
├── endpoints
├── execution
├── magicapp
├── models
├── schemasx
├── services
│   └── nexi-infocast
│       ├── endpoints
│       │   ├── group
│       │   ├── groupsegment
│       │   └── user
│       ├── logic
│       └── models
│           ├── InfocastGroupSegmentsmodel
│           ├── InfocastGroupsmodel
│           ├── all-groupsmodel
│           ├── all-segmentsmodel
│           ├── groupmodel
│           ├── groupsegmentmodel
│           ├── pongmodel
│           ├── usermodel
│           ├── usersmodel
│           └── userssamplemodel
└── utils



#>
function GenerateGoServiceEndpoint($organisation, $service, $name, $methodName, $description, $returnType, [array]$parameters, $entity) {
    return ##v3
    #noma

    $goFilePath = join-path $serviceInstancePath "endpoints" $name 
    EnsurePath $goFilePath
    $goTestFilePath = join-path $serviceInstancePath "tests" 
    EnsurePath $goTestFilePath 
    $componentName = $entity.objectname + (Get-Culture).TextInfo.ToTitleCase($methodName)
   
    $callerParameters = ""
    $testcallerParameters = ""
    if ($parameters.Count -gt 1) {
        Throw "Only 0 or 1 parameter is currently supported"
    }
    $testimportStatement = ""
    $parameterTransformer = ""
    $testparameterTransformer = ""
    for ($i = 0; $i -lt $parameters.Count; $i++) {
        $parameter = $parameters[$i]
        switch ($parameter.type) {

            "object" {
                $testimportStatement = @"
            "github.com/$($organisation)/$($service)/services/models/$($name)model"
"@
                $parameterTransformer = @"
            // transformer v1
            object := $($name + "model." + $entity.objectname){}
            body := ""

            json.Unmarshal([]byte(payload.Args[1]), &body)
            err := json.Unmarshal([]byte(body), &object)
    
            if err != nil {
                log.Println("Error", err)
                ServiceResponseError(req, "Error unmarshalling $name")
                return
            }
                     
"@
                $testparameterTransformer = @"
            // transformer v1
            object := $($name + "model." + $entity.objectname){}
         
"@

                $callerParameters += "object"
                $testcallerParameters = "object"
                if ($i -lt $parameters.Count - 1) {
                    $callerParameters += ","
                    $testcallerParameters += ","
                }
            }
       
            "int" {
                $callerParameters += "payload.Args[$($i+1)]"
                $testcallerParameters = '""'

                if ($i -lt $parameters.Count - 1) {
                    $callerParameters += ","
                    $testcallerParameters += ","
                }
            }
            Default {
                $callerParameters += "payload.Args[$($i+1)]"
                $testcallerParameters = """."""

                if ($i -lt $parameters.Count - 1) {
                    $callerParameters += ","
                    $testcallerParameters += ","
                }
            }
        }

    }

    $receiverParameters = ""
 
    for ($i = 0; $i -lt $parameters.Count; $i++) {
        $parameter = $parameters[$i]
        switch ($parameter.type) {
            "object" { 
                $receiverParameters += $parameter.name + " " + $name + "model." + $entity.objectname
            }
            "int" {
                $receiverParameters += $parameter.name + " " + $parameter.type
            }
            Default {
                $receiverParameters += $parameter.name + " " + $parameter.type
            }
        }

        if ($i -lt $parameters.Count - 1) {
            $receiverParameters += ","
        }
    }
    $callerCode = @"
    $parameterTransformer
    result,err := $($entity.model).$($componentName)($callerParameters)
    if (err != nil) {
        log.Println("Error", err)
        ServiceResponseError(req, fmt.Sprintf("Error calling $($componentName): %s", err))


        return
    }

    ServiceResponse(req, result)
"@


    if ( $returnType -eq "void") {
        $testCallerCode = @"
        // noma4.1.1
        $testparameterTransformer
        err := $($entity.model).$($componentName)($testcallerParameters)
        if err != nil {
            t.Errorf("Error %s", err)
        }
        assert.True(t, true) // for additional tests
       
"@
    }
    else {
        $testCallerCode = @"
            $testparameterTransformer
            result,err := $($entity.model).$($componentName)($testcallerParameters)
            if err != nil {
                t.Errorf("Error %s", err)
            }
            assert.NotNil(t, result)
"@
                    
    }
    
    $importStatement = @"
// noma2    
import (
	"log"
    "errors"
    "github.com/$($organisation)/$($service)/services/models/$($name)model"
    )
"@
    $returnSignature = ""
    $returnTypeCode = "*$($name)model.$($entity.objectname)"

    $functionBody = @"
    
    
    
    return nil,errors.New("Not implemented")



"@
    

    switch ($returnType) {
        "void" {
            $importStatement = @"
            import (
                "log"
                "errors"
                )
"@            
           
            $returnSignature = "error"
            $functionBody = @"
return errors.New("Not implemented")
"@
            
            $callerCode = @"
            err :=  $($entity.model).$($componentName)($callerParameters)
            if (err != nil) {
                log.Println("Error", err)
                ServiceResponseError(req, fmt.Sprintf("Error calling $($componentName): %s", err))


                return
            }
            ServiceResponse(req, "")
"@
        }
        "page" {
         
            $importStatement = @"
import (
    "log"
    "errors"
    "github.com/$($organisation)/$($service)/services/models/$($name)model"
    . "github.com/$($organisation)/$($service)/utils"
)
"@
            
           
            $returnSignature = "(*Page[$($name)model.$($entity.objectname)],error)"


        }
        "object" {
            
            $returnSignature = "($returnTypeCode,error)"

        }
        default {
            write-host $organisation, $service, $name, $methodName, $description, $returnType -ForegroundColor Red
            throw "Unknown return type $returnType"
            
        }
    }
  
    $code = @"
$fileHeader
//generator:  noma3
package $name
$importStatement


func $($componentName)($receiverParameters ) $returnSignature {
log.Println("Calling $($componentName)")
$functionBody

}
    
"@
    #  $code | Out-File -FilePath (join-path $pagePath "page.tsx") -Encoding utf8NoBOM

    $testcode = @"
    $fileHeader
    //generator:  noma4.1
    package tests
    import (
        "testing"
        "github.com/$($mapicapp.organisation)/$($kitchenname)/services/endpoints/$name"
        $testimportStatement
        "github.com/stretchr/testify/assert"
    )
    
    func Test$($entity.objectname)$($methodName)(t *testing.T) {
        $testCallerCode
        
    
    }
    
"@    


    switch ($methodName) {
        "create" {
            $code = @"
/*
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´´keep´´ to ´´true´´ syntax for the code snippet
---
keep: false
---
*/
//generator:  noma3.create.v2
package $($name)

import (
    "log"
   
    "github.com/$($mapicapp.organisation)/$($kitchenname)/applogic"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/database"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/services/models/$($name)model"

)

func $($entity.objectname)Create(item $($name)model.$($entity.objectname)) (*$($name)model.$($entity.objectname), error) {
    log.Println("Calling $($entity.objectname)$($methodName)")

    return applogic.Create[database.$($entity.objectname), $($name)model.$($entity.objectname)](item, applogic.Map$($entity.objectname)Incoming, applogic.Map$($entity.objectname)Outgoing)

}
"@
        }
        "read" {
            $code = @"
/*
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´´keep´´ to ´´true´´ syntax for the code snippet
---
keep: false
---
*/
//generator:  noma3.read.v2
package $($name)

import (
    "log"
    "strconv"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/applogic"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/database"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/services/models/$($name)model"

)

func $($entity.objectname)Read(arg0 string) (*$($name)model.$($entity.objectname), error) {
    id,_ := strconv.Atoi(arg0)
    log.Println("Calling $($entity.objectname)$($methodName)")

    return applogic.Read[database.$($entity.objectname), $($name)model.$($entity.objectname)](id, applogic.Map$($entity.objectname)Outgoing)

}
"@
        }
        "update" {
            $code = @"
/*
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´´keep´´ to ´´true´´ syntax for the code snippet
---
keep: false
---
*/
//generator:  noma3.update.v2
package $($name)

import (
    "log"

    "github.com/$($mapicapp.organisation)/$($kitchenname)/applogic"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/database"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/services/models/$($name)model"

)

func $($entity.objectname)Update(item $($name)model.$($entity.objectname)) (*$($name)model.$($entity.objectname), error) {
    log.Println("Calling $($entity.objectname)$($methodName)")

    return applogic.Update[database.$($entity.objectname), $($name)model.$($entity.objectname)](item.ID,item, applogic.Map$($entity.objectname)Incoming, applogic.Map$($entity.objectname)Outgoing)

}
"@
        }
        "delete" {
            $code = @"
            /*
            File have been automatically created. To prevent the file from getting overwritten
            set the Front Matter property ´´keep´´ to ´´true´´ syntax for the code snippet
            ---
            keep: false
            ---
            */
            //generator:  noma3.delete.v2
            package $($name)
            
            import (
                "log"
                "strconv"
                "github.com/$($mapicapp.organisation)/$($kitchenname)/applogic"
                "github.com/$($mapicapp.organisation)/$($kitchenname)/database"
                "github.com/$($mapicapp.organisation)/$($kitchenname)/services/models/$($name)model"
            
            )
            
            func $($entity.objectname)Delete(arg0 string) ( error) {
                id,_ := strconv.Atoi(arg0)
                log.Println("Calling $($entity.objectname)$($methodName)")
            
                return applogic.Delete[database.$($entity.objectname), $($name)model.$($entity.objectname)](id)
            
            }
"@
        }
        "search" {
            $code = @"
/*
File have been automatically created. To prevent the file from getting overwritten
set the Front Matter property ´´keep´´ to ´´true´´ syntax for the code snippet
---
keep: false
---
*/
//generator:  noma3.search.v2
package $($name)

import (
    "log"

    "github.com/$($mapicapp.organisation)/$($kitchenname)/applogic"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/database"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/services/models/$($name)model"
    . "github.com/$($mapicapp.organisation)/$($kitchenname)/utils"
)

func $($entity.objectname)Search(query string) (*Page[$($name)model.$($entity.objectname)], error) {
    log.Println("Calling $($entity.objectname)$($methodName)")

    return applogic.Search[database.$($entity.objectname), $($name)model.$($entity.objectname)]("searchindex", query, applogic.Map$($entity.objectname)Outgoing)

}
"@
        }
        Default {
           
        }
    }

    WriteTextFile (join-path $goFilePath "$methodName.go")  $code
    WriteTextFile (join-path $goTestFilePath "$($entity.objectname)_$($methodName)_test.go")  $testcode

    
    $callCode = @"
// macd.2
case "$methodName":
if (len(payload.Args) < $($parameters.Count+1)) {
    log.Println("Expected $($parameters.Count+1) arguments, got %d", len(payload.Args))
    ServiceResponseError(req, "Expected $($parameters.Count) arguments")
    return
}


$callerCode


"@

    return $callCode

}

function column($name, $type, $map) {
    return @"
    $($name) $($type) ``json:"$($map)"``

"@
}
function sqlcolumn($name, $type, $map) {
    return @"
    $($name) $($type) ``bun:"$($map)"``

"@
}

function GenerateGoModel($organisation, $serviceName, $name, $classname, $entity) {
    return ##v3
    $goAppLogicPath = join-path $koksmatDir "app"  "applogic" 
    EnsurePath $goAppLogicPath 

    $goModelPath = join-path $koksmatDir "app"  "services" "models" "$($name)model"
    EnsurePath $goModelPath
   
    $goAPIClientPath = join-path $koksmatDir "app"  "client" $serviceName
    EnsurePath $goAPIClientPath

    $inmap = ""
    $outmap = ""
    $columns = ""
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)
    if ($name -eq "importdata") {
        write-host "x"
    }
    $hasReference = $false
    $searchIndex = @()
    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
           
            continue
        }
        if ($null -ne $attribute.hidden -and $attribute.hidden) {
            continue
        }

        $columnname = $TextInfo.ToTitleCase($attribute.name)

        if ($null -ne $attribute.searchindex -and $attribute.searchindex) {
            $searchIndex += @"
"$($attribute.name):" + in.$($columnname ) 
"@    
        }        
        $type = "string"
        $map = $attribute.name
        switch ($attribute.type) {
            "string" { 
                $columns += column $columnname "string" $map
                $outmap += @"
        $columnname : db.$columnname,

"@
                $inmap += @"
        $columnname : in.$columnname,

"@
            }
            "number" { 
                $columns += column $columnname "int" $map
            }
            "json" { 
                $columns += column $columnname "interface{}" $map
                $outmap += @"
        $columnname : db.$columnname,

"@
                $inmap += @"
        $columnname : in.$columnname,

"@                
            }
            "int" { 
                $columns += column $columnname "int" $map
                
            }
            "boolean" { 
                $columns += column $columnname "bool" $map
            }
            "datetime" { 
                $columns += column $columnname "time.Time" $map
            }
            "reference" { 
                $columns += column "$($columnname)_id" "int" "$($map)_id"
                $hasReference = $true
                $outmap += @"
                $($columnname)_id : db.$($columnname)_id,

"@
                $inmap += @"
                $($columnname)_id : in.$($columnname)_id,

"@

            }
            "array" { 
                # $columns += column $columnname "[]databasetypes.Page" $map
                # $hasReference = $true
            }
            Default {
                throw "Unknown type  $($attribute.type)"
            }
        }
        
    }


    if ($searchIndex.Length -lt 1) {
        $inmap += @"
        Searchindex : in.Name,

"@
    }
    else {
        
        $inmap += @"
        Searchindex : $($searchIndex  -join " + "),

"@

    }

    $referenceDatabase = ""
    if ($hasReference) {
        $referenceDatabase = @"
"github.com/$($organisation)/$($serviceName)/database/databasetypes"
"@
    }


    $tsFileContent = @"
$fileHeader   
//GenerateGoModel v2
package $($name)model
import (
	"encoding/json"
	"time"
    // $referenceDatabase
)

func Unmarshal$($classname)(data []byte) ($classname, error) {
	var r $classname
	err := json.Unmarshal(data, &r)
	return r, err
}

func (r *$classname) Marshal() ([]byte, error) {
	return json.Marshal(r)
}

type $classname struct {
    ID        int    ``json:"id"``
    CreatedAt time.Time ``json:"created_at"``
    CreatedBy string ``json:"created_by"``
    UpdatedAt time.Time ``json:"updated_at"``
    UpdatedBy string ``json:"updated_by"``
    $columns
}

"@

    $apiClientFileContent = @"
$fileHeader   
//GenerateGoModel v3.api
package $($serviceName -replace "-","")
import (

	"time"
    // $referenceDatabase
)


type $classname struct {
    ID        int    ``json:"id"``
    CreatedAt time.Time ``json:"created_at"``
    CreatedBy string ``json:"created_by"``
    UpdatedAt time.Time ``json:"updated_at"``
    UpdatedBy string ``json:"updated_by"``
    $columns
}

"@

    $mapContent = @"
$fileHeader
//GenerateMapModel v1.1
package applogic
import (
	//"encoding/json"
	//"time"
	"github.com/$($organisation)/$($serviceName)/database"
	"github.com/$($organisation)/$($serviceName)/services/models/$($name)model"
   
)


func Map$($classname)Outgoing(db database.$classname) $($name)model.$classname {
    return $($name)model.$classname{
        ID:        db.ID,
        CreatedAt: db.CreatedAt,
        CreatedBy: db.CreatedBy,
        UpdatedAt: db.UpdatedAt,
        UpdatedBy: db.UpdatedBy,
        $outmap
    }
}

func Map$($classname)Incoming(in $($name)model.$classname) database.$classname {
    return database.$classname{
        ID:        in.ID,
        CreatedAt: in.CreatedAt,
        CreatedBy: in.CreatedBy,
        UpdatedAt: in.UpdatedAt,
        UpdatedBy: in.UpdatedBy,
        $inmap
    }
}
"@
    WriteTextFile (join-path $goModelPath "$name.go") $tsFileContent

    WriteTextFile (join-path $goAPIClientPath "$name.go") $apiClientFileContent

    WriteTextFile (join-path $goAppLogicPath "map_$($name).go") $mapContent
}

function tscolumn($name, $type, $map) {
    return @"
    $($name) : $($type) `;`

"@
}

function GenerateTypeScriptModel($organisation, $serviceName, $name, $classname, $entity) {
    return ##v3
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)

    $hasReference = $false
    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
           
            continue
        }
        if ($null -ne $attribute.hidden -and $attribute.hidden) {
            continue
        }

        $columnname = $attribute.name
        $type = "string"
        
        switch ($attribute.type) {
            "string" { 
                $columns += tscolumn $columnname "string" 
            }
            "number" { 
                $columns += tscolumn $columnname "number" 
            }
            "json" { 
                $columns += tscolumn $columnname "object" 
            }
            "int" { 
                $columns += tscolumn $columnname "number" 
                
            }
            "boolean" { 
                $columns += tscolumn $columnname "boolean" 
            }
            "datetime" { 
                $columns += tscolumn $columnname "string" 
            }
            "reference" { 
                $columns += tscolumn "$($columnname)_id" "number" 

            }
            "array" { 
                # $columns += column $columnname "[]databasetypes.Page" $map
                # $hasReference = $true
            }
            Default {
                throw "Unknown type  $($attribute.type)"
            }
        }
        
    }


    $tsCode = @"
// spunk
// $classname
export interface $($classname)Item  {
    id: number;
    created_at: string;
    created_by: string;
    updated_at: string;
    updated_by: string;
    $columns
}

"@

    return $tsCode

    
}
function zodcolumn($name, $type, $map, $aditional) {
    return @"
    $($name) : z.$($type)($map)$aditional, 

"@
}
function GenerateZodModel($organisation, $serviceName, $name, $classname, $entity) {
    return ##v3
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)

    $hasReference = $false
    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
           
            continue
        }
        if ($null -ne $attribute.hidden -and $attribute.hidden) {
            continue
        }
        $columnname = $attribute.name
        $aditional = ""
        if ($null -ne $attribute.required -and !$attribute.required) {
            $aditional = ".optional()"
        }

        $type = "string"
        
        switch ($attribute.type) {
            "string" { 
                $columns += zodcolumn $columnname "string" "" $aditional
            }
            "number" { 
                $columns += zodcolumn $columnname "number" "" $aditional
            }
            "json" { 
                $columns += zodcolumn $columnname "object" "{}"  $aditional
            }
            "int" { 
                $columns += zodcolumn $columnname "number" "" $aditional
                
            }
            "boolean" { 
                $columns += zodcolumn $columnname "boolean" "" $aditional
            }
            "datetime" { 
                $columns += zodcolumn $columnname "string" "" $aditional
            }
            "reference" { 
                $columns += zodcolumn "$($columnname)_id" "number" "" $aditional

            }
            "array" { 
                # $columns += column $columnname "[]databasetypes.Page" $map
                # $hasReference = $true
            }
            Default {
                throw "Unknown type  $($attribute.type)"
            }
        }
        
    }


    $zodelModel = @"

// $classname
export const $($classname)Schema = z.object({  
   
    $columns
});

"@

    return $zodelModel

    
}
function reactViewcolumn($serviceName, $caption, $name, $type, $map) {
    return @"
    <div>
        <div className="font-bold" >$($caption)</div>
        <div>{$($serviceName).$($name)}</div>
    </div>
"@
}
function GenerateItemView($organisation, $serviceName, $name, $classname, $entity) {
    return ##v3
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)

    $hasReference = $false
    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
           
            continue
        }
        if ($null -ne $attribute.hidden -and $attribute.hidden) {
            continue
        }

        $columnname = $attribute.name
        $displayname = $attribute.displayname
        if ($null -eq $displayname) {
            $displayname = $columnname
        }

        $type = "string"
        
        switch ($attribute.type) {
            "string" { 
                $columns += reactViewcolumn $name $displayname $columnname "string" 
            }
            "number" { 
                $columns += reactViewcolumn $name $displayname $columnname "number" 
            }
            "json" { 
                $columns += @"
                <div>
                    <div className="font-bold" >$($displayname)</div>
                    <div>{JSON.stringify($($Name).$($columnname),null,2)}</div>
                </div>
"@
            }
            "int" { 
                $columns += reactViewcolumn $name $displayname $columnname "number" 
                
            }
            "boolean" { 
                $columns += reactViewcolumn $name $displayname $columnname "boolean" 
            }
            "datetime" { 
                $columns += reactViewcolumn $name $displayname $columnname "string" 
            }
            "reference" { 
                $columns += reactViewcolumn $name $displayname  "$($columnname)_id" "number" 

            }
            "array" { 
                # $columns += column $columnname "[]databasetypes.Page" $map
                # $hasReference = $true
            }
            Default {
                throw "Unknown type  $($attribute.type)"
            }
        }
        
    }


    $tsCode = @"
    
    {$name && <div>
    $columns
    <div>
    $(reactViewcolumn $name "id" "id" )
    $(reactViewcolumn $name "created_at" "created_at" )
    $(reactViewcolumn $name "created_by" "created_by" )
    $(reactViewcolumn $name "updated_at" "updated_at" )
    $(reactViewcolumn $name "updated_by" "updated_by" )
    </div>
    </div>}


"@

    return $tsCode

    
}


function reactEditcolumn($serviceName, $caption, $name, $type) {
    return @"
    <div>
        <div className="font-bold" >$($caption)</div>
        <div><input type="text" name="$name" value={$($serviceName).$($name)}></input></div>
    </div>
"@
}
function GenerateItemEdit($organisation, $serviceName, $name, $classname, $entity, $react) {
    return ##v3
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)

    $hasReference = $false
    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
           
            continue
        }
        if ($attribute.type -eq "array") {
            continue
        }
        if ($null -ne $attribute.hidden -and $attribute.hidden) {
            continue
        }

        $columnname = $attribute.name
        $displayname = $attribute.displayname
        if ($null -eq $displayname) {
            $displayname = $columnname
        }

        $type = "string"

        $reactCode = $react.components."$($attribute.type)formfield"
        if ($null -eq $reactCode) {
            throw "No react component found for $($attribute.type)"
        }

        $template = $reactCode.template
        if ($null -eq $template) {
            throw "No React template found for $($attribute.type)"
        }
        $columnnamesuffix = ""
        if ($attribute.type -eq "reference") {
            $columnnamesuffix = "_id"
        }
        $markup = $template.markup
        $markup = $markup -replace "##NAME##", "$($columnname)$($columnnamesuffix)"
        $markup = $markup -replace "##LABEL##", $displayname
        $markup = $markup -replace "##DESCRIPTION##", ""

        $formControl = $reactCode.markup 
        $formControl = $formControl -replace "##PLACEHOLDER##", ""
        $markup = $markup -replace "##FORMCONTROL##", $formControl

        $columns += @"
    {/* $($attribute.type) */}
"@
        $columns += $markup

        
    }


    $tsCode = @"
    
    {$name && <div>
    $columns
    <div>
   
    </div>
    </div>}


"@

    return $tsCode

    
}
function NullContraint($required) {
    if ($required -eq $ISREQUIRED) {
        return " NOT NULL"
    }
    else {
        return ""
    }
}
function sqlString($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default" $(NullContraint $required)

"@
}
function sqlJSON($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name JSONB  $(NullContraint $required)

"@
}
function sqlNumber($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default"  $(NullContraint $required)

"@
}

function sqlInteger($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default"  $(NullContraint $required)

"@
}

function sqlBoolean($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name boolean  $(NullContraint $required)

"@
}

function sqlDatetime($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }

    return @"
    ,$name character varying COLLATE pg_catalog."default"  $(NullContraint $required)

"@
}

function sqlReference($name, $required) {
    if ($null -eq $required) {
        throw "Missing required parameter required for sqlReference"
    }
    return @"
    ,$($name)_id int  $(NullContraint $required)

"@
}

function GenerateDatabaseMigration( $organisation, $serviceName, $name, $entity, $migrationId ) {
    $goDatabasePath = join-path $koksmatDir "app"  "database" 
    EnsurePath $goDatabasePath
    $goDatabaseMigrationPath = join-path $goDatabasePath "tern" 
    EnsurePath $goDatabaseMigrationPath
    $translationsPath = join-path $koksmatDir "app"  "translations" 
    EnsurePath $translationsPath

    $columns = ""
    $references = ""
    $dropCmd = ""
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)
    if ($null -ne $entity.parent ) {
        $columns += sqlReference $entity.parent.name $ISNOTREQUIRED
       
        $references += @"
        ALTER TABLE IF EXISTS public.$($name)
        ADD FOREIGN KEY ($($entity.parent.name)_id)
        REFERENCES public.$($entity.parent.name) (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID;
"@
    }

    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
       
            continue
        }
        $columnname = $attribute.name
    
        $map = $attribute.name
        switch ($attribute.type) {
            "string" { 
                $columns += sqlString $columnname $attribute.required
            }
            "json" { 
                $columns += sqlJSON $columnname $attribute.required
            }
            "number" { 
                $columns += sqlNumber $columnname $attribute.required
            }
            "int" { 
                $columns += sqlInteger $columnname $attribute.required
            }
            "boolean" { 
                $columns += sqlBoolean $columnname $attribute.required
            }
            "datetime" { 
                $columns += sqlDatetime $columnname $attribute.required
            }
            "reference" { 
                $columns += sqlReference $columnname $attribute.required
                if ($null -eq $attribute.entity.name) {
                    throw "No entity name found for $($name).$($columnname)"
                }
                $references += @"
                ALTER TABLE IF EXISTS public.$($name)
                ADD FOREIGN KEY ($($columnname)_id)
                REFERENCES public.$($attribute.entity.name) (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                NOT VALID;
"@
            }
            "array" { 

                $manytomanytablename = "$($name)_m2m_$($attribute.entity.name)"
                $dropCmd += @"
DROP TABLE IF EXISTS public.$($manytomanytablename);
"@
                $references += @"
                -- lollipop
                CREATE TABLE public.$($manytomanytablename) (
                id SERIAL PRIMARY KEY,
                created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
                created_by character varying COLLATE pg_catalog."default"  ,
                updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_by character varying COLLATE pg_catalog."default",
                deleted_at timestamp with time zone,
                koksmat_masterdataref VARCHAR COLLATE pg_catalog.`"default`",
                koksmat_masterdata_id VARCHAR COLLATE pg_catalog.`"default`",
                koksmat_masterdata_etag VARCHAR COLLATE pg_catalog.`"default`",
                koksmat_compliancetag VARCHAR COLLATE pg_catalog.`"default`",
                koksmat_state VARCHAR COLLATE pg_catalog.`"default`",

                koksmat_bucket JSONB 
                $(sqlReference $($name)_id) $REQUIRED
                $(sqlReference $($attribute.entity.name)_id) $REQUIRED

                );
            

                ALTER TABLE public.$($manytomanytablename)
                ADD FOREIGN KEY ($($name)_id)
                REFERENCES public.$($name) (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                NOT VALID;

                ALTER TABLE public.$($manytomanytablename)
                ADD FOREIGN KEY ($($attribute.entity.name)_id)
                REFERENCES public.$($attribute.entity.name) (id) MATCH SIMPLE
                ON UPDATE NO ACTION
                ON DELETE NO ACTION
                NOT VALID;
"@
                
                # $columns += sqlString $columnname 
            }
            Default {
              
                write-host "Unknown type  $($attribute.type)"
                throw $errormessage
            }
        }
    
    }

    $sqlMigrationFileContent = @"
$fileHeader   


-- sure sild

CREATE TABLE public.$($name)
(
    id SERIAL PRIMARY KEY,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by character varying COLLATE pg_catalog."default"  ,

    updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by character varying COLLATE pg_catalog."default" ,

    deleted_at timestamp with time zone,
    koksmat_masterdataref VARCHAR COLLATE pg_catalog.`"default`",
    koksmat_masterdata_id VARCHAR COLLATE pg_catalog.`"default`",
    koksmat_masterdata_etag VARCHAR COLLATE pg_catalog.`"default`",
    koksmat_compliancetag VARCHAR COLLATE pg_catalog.`"default`",
    koksmat_state VARCHAR COLLATE pg_catalog.`"default`",


    koksmat_bucket JSONB 

$columns

);

$references


---- create above / drop below ----
$dropCmd
DROP TABLE public.$($name);

"@

    

    $migrationTag = '{0:d4}' -f $migrationId

    WriteTextFile (join-path $goDatabaseMigrationPath "$($migrationTag)_create_table_$name.sql") $sqlMigrationFileContent

    $translations = @"
$(YamlMultilineComment $fileHeader)

"@    
    WriteTextFile (join-path $translationsPath "database.$name.en-us.yaml") $translations

}
function GenerateDatabaseModel( $organisation, $serviceName, $name, $classname, $entity ) {
    $goDatabasePath = join-path $koksmatDir "app"  "database" 
    EnsurePath $goDatabasePath
    $goDatabaseMigrationPath = join-path $goDatabasePath "tern" 
    EnsurePath $goDatabaseMigrationPath

    $columns = ""
    $attributes = $($entity.baselineattributes; $entity.additionalattributes)
    $hasReference = $false
    if ( $name -eq "importdata") {
        write-host "x"
    }


    foreach ($attribute in $attributes) {
        if ($null -eq $attribute) {
            # Typical result of a empty baselineattributes or additionalattributes
           
            continue
        }
        $columnname = $TextInfo.ToTitleCase($attribute.name)
        $type = "string"
        $map = $attribute.name
        switch ($attribute.type) {
            "string" { 
                $columns += sqlcolumn $columnname "string" $map
            }
            "json" { 
                $columns += sqlcolumn $columnname "interface{}" $map
            }
            "number" { 
                $columns += sqlcolumn $columnname "int" $map
            }
            "int" { 
                $columns += sqlcolumn $columnname "int" $map
            }
            "boolean" { 
                $columns += sqlcolumn $columnname "bool" $map
            }
            "datetime" { 
                $columns += sqlcolumn $columnname "time.Time" $map
            }
            "reference" { 
                $columns += sqlcolumn "$($columnname)_id" "int" "$($map)_id"
                #   $hasReference = $true
            }
            "array" { 
                #                $columns += column $columnname "[]databasetypes.Page" $map
                #                $hasReference = $true
            }
            Default {
                write-host "Unknown type  $($attribute.type)"
                throw "Unknown type  $($attribute.type)"
            }
        }
        
    }
    

    $importDatabaseTypes = ""
    if ($hasReference) {
        $importDatabaseTypes = @"
        "github.com/$($organisation)/$($serviceName)/database/databasetypes"

"@
    }

    $goFileContent = @"
$fileHeader   
//version: pølsevogn2
package database

import (
	"time"
    $importDatabaseTypes
	"github.com/uptrace/bun"
)

type $classname struct {
	bun.BaseModel ``bun:"table:$($name),alias:$($name)"``

	ID             int     ``bun:"id,pk,autoincrement"``
	CreatedAt      time.Time ``bun:",nullzero,notnull,default:current_timestamp"``
	CreatedBy      string ``bun:"created_by,"``
	UpdatedAt      time.Time ``bun:",nullzero,notnull,default:current_timestamp"``
	UpdatedBy      string ``bun:"updated_by,"``
	DeletedAt      time.Time ``bun:",soft_delete,nullzero"``
    $columns
}

"@

    # WriteTextFile (join-path $goDatabasePath "$name.go") $goFileContent
    

    
}
#endregion
#region Main
<#

## Main program

#>

write-host "Generating code for $($mapicapp.name)" -ForegroundColor Yellow
write-host $mapicapp.services.Count "services found" -ForegroundColor Yellow

$map = @{
    name     = $mapicapp.name
    services = @()
}

$appRegisterEndpoints = @"
$fileHeader
package magicapp

import (
	"github.com/$($mapicapp.organisation)/$($kitchenname)/services"
	"github.com/nats-io/nats.go/micro"
)

func RegisterServiceEndpoints(root micro.Group) {

"@


foreach ($entityKey in $entitiesInOrder ) {
    $entity = $mapicapp.entities.$entityKey
    $migrationId += 1
    GenerateDatabaseMigration $mapicapp.organisation  $kitchenname $entity.name $entity $migrationId
}
foreach ($service in $mapicapp.services) {

    $appRegisterEndpoints += @"
    root.AddEndpoint("$($service.name)", micro.HandlerFunc(services.Handle$($service.entity.objectname)Requests))
    
"@
    GenerateDatabaseModel   $mapicapp.organisation  $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity 

    GenerateGoModel $mapicapp.organisation  $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity

    $tsCode = GenerateTypeScriptModel $mapicapp.organisation  $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity
    $zodModel = GenerateZodModel $mapicapp.organisation  $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity
    $itemView = GenerateItemView $mapicapp.organisation  $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity
    $editView = GenerateItemEdit $mapicapp.organisation  $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity $mapicapp.react
    # GenerateWebModel $kitchenname $service.entity.entity.name $service.entity.objectname $service.entity.entity

    # write-host "Generating code for $($service.name)" -ForegroundColor Green
    #GenerateServiceEndpoint $service.name
    $serviceMap = @{
        name      = $service.name
        endpoints = @()
    }
    $callEndPoint = @"
$fileHeader   
// macd.1
package services
import (
	"encoding/json"
    "fmt"
	"log"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/services/endpoints/$($service.entity.model)"
    "github.com/$($mapicapp.organisation)/$($kitchenname)/services/models/$( $service.name)model"

	. "github.com/$($mapicapp.organisation)/$($kitchenname)/utils"
	"github.com/nats-io/nats.go/micro"
)

func Handle$($service.entity.objectname)Requests(req micro.Request) {

    rawRequest := string(req.Data())
	if rawRequest == "ping" {
		req.Respond([]byte("pong"))
		return

	}

var payload ServiceRequest
_ = json.Unmarshal([]byte(req.Data()), &payload)
if len(payload.Args) < 1 {
    ServiceResponseError(req, "missing command")
    return

}
switch payload.Args[0] {



"@

    GenerateServicePages `
        -service $kitchenname `
        -name $service.name `
        -methods $service.methods `
        -entity $service.entity   `
        -tsInterface $tsCode `
        -itemView $itemView `
        -itemForm  $editView `
        -zodModel $zodModel

    foreach ($method in $service.methods) {
        # write-host "Generating web code for $($service.name).$($method.name)" -ForegroundColor Cyan
        # GenerateServiceWebProxyEndpoint `
        #     -service $kitchenname `
        #     -name $service.name `
        #     -methodName $method.name `
        #     -description  $method.description `
        #     -returnType $service.entity.objectname   `
        #     -parameters $method.parameters `
        #     -entity $service.entity

        # GenerateServiceWebComponent `
        #     -service $kitchenname `
        #     -name $service.name `
        #     -methodName $method.name `
        #     -description  $method.description `
        #     -returnType $method.returns.type   `
        #     -parameters $method.parameters `
        #     -entity $service.entity

        # GenerateServicePage `
        #     -service $kitchenname `
        #     -name $service.name 

    
            
        $callEndPoint += GenerateGoServiceEndpoint `
            -organisation $mapicapp.organisation `
            -service $kitchenname `
            -name $service.name `
            -methodName $method.name `
            -description  $method.description `
            -returnType $method.returns.type `
            -parameters $method.parameters   `
            -entity $service.entity                 
        $serviceMap.endpoints += @{
            name = $method.name
        }
    }
    $callEndPoint += @"
default:
ServiceResponseError(req, "Unknown command")
}
}
"@


    ##v3    WriteTextFile (join-path $serviceInstancePath  "$($service.name).go") $callEndPoint 

    $map.services += $serviceMap 
    $json = $map | ConvertTo-Json -Depth 10 
    $code = @"


    
export interface EndPoint {
    name: string;

}

export interface Service {
    name: string;

    endpoints: EndPoint[]
}

export interface AppMap {
    name: string;

    services: Service[]
}
export const pagemap : AppMap = $json

"@

}

##v3 $code | Out-File -FilePath (join-path $serviceWebTestPagePath "index.ts") -Encoding utf8NoBOM
$appRegisterEndpoints += @"
}
"@
##v3 WriteTextFile (join-path $koksmatDir "app" "magicapp" "register-service-endpoints.go") $appRegisterEndpoints




#endregion