

import { https, httpsGetAll, Result } from "../httphelper"

import path from "path"
import fs from "fs"
import axios from "axios";
import { consoleShowProgress, consoleClearProgress } from '../httphelper';

export async function getToken(tenant:string,app:string,appsecret:string): Promise<string> {
    return new Promise(async (resolve, reject) => {
        var url = `https://login.microsoftonline.com/${tenant}/oauth2/v2.0/token`;
        var body = `grant_type=client_credentials&client_id=${app}&client_secret=${appsecret}&scope=https%3A//graph.microsoft.com/.default`;
        var config = { headers: { 'Content-Type': "application/x-www-form-urlencoded" } };
        axios.post(url, body, config)
            .then(({ data }) => {


                resolve(data.access_token);
            })
            .catch(e => reject(e));

        //APPCLIENT_ID
        //APPCLIENT_SECRET        
    });
}

export async function getSpAuthToken(){
    return getToken(process.env.SPAUTH_TENANTID as string, process.env.SPAUTH_CLIENTID as string, process.env.SPAUTH_CLIENTSECRET as string)

}
export interface SiteCollection {
    hostname: string;
}

export interface SharePointSite {

    createdDateTime: Date;
    description: string;
    id: string;
    lastModifiedDateTime: Date;
    name: string;
    webUrl: string;
    displayName: string;
    siteCollection: SiteCollection;
}


export interface File {
    name: string,
    displayName: string,
    folderName?: string
    editorEmail: string
    editorName: string
    modifiedDate: Date
    webUrl: string,
    thumbNailUrl?: string,
    previewUrl?: string,
    downloadUrl?: string,
    sharePoint?: SharePoint.File
    heading?: string,
    description?: string
    text?: string,
    backColor?: string,
    minHeight?: string,
    isFolder?: boolean,
    linkedFiles?: File[],
    hidden?: boolean
    liveTile?: boolean
}

export interface Folder {
    name: string
    modifiedDate: Date,
    sharePoint?: SharePoint.LibraryFolder,
    webUrl: string,
    backColor?: string,
    minHeight: string
}

export interface Files {
    root: Folder
    files: File[]
    folders: Folder[]
}


export interface User {
    displayName: string;
    email: string;
    id: string;
}

export interface CreatedBy {
    user: User;
}


export interface Owner {
    user: User;
}

export interface Quota {
    deleted: number;
    remaining: any;
    state: string;
    total: any;
    used: number;
}



export interface LastModifiedBy {
    user: User;
}

export interface Drive {
    createdDateTime: Date;
    description: string;
    id: string;
    lastModifiedDateTime: Date;
    name: string;
    webUrl: string;
    driveType: string;
    createdBy: CreatedBy;
    owner: Owner;
    quota: Quota;
    lastModifiedBy: LastModifiedBy;
}

declare module Intra365 {

    export interface WebInfo {
        pageUrl: string;
        heading: string;
        type: string;
        image: string;
        description: string;
        content: string;
        body: string;
        text: string;
    }

}



declare module SharePoint {
    export interface Preview {

        getUrl: string;
        postParameters?: any;
        postUrl?: any;
    }
    export interface Large {
        height: number;
        url: string;
        width: number;
    }

    export interface Medium {
        height: number;
        url: string;
        width: number;
    }

    export interface Small {
        height: number;
        url: string;
        width: number;
    }

    export interface Thumbnail {
        id: string;
        large: Large;
        medium: Medium;
        small: Small;
    }

    export interface Hashes {
        quickXorHash: string;
    }

    export interface File {
        mimeType: string;
        hashes: Hashes;
    }

    export interface Image {
        height: number;
        width: number;
    }


    export interface ParentReference {
        driveId: string;
        driveType: string;
    }

    export interface FileSystemInfo {
        createdDateTime: Date;
        lastModifiedDateTime: Date;
    }

    export interface Folder {
        childCount: number;
    }

    export interface Root {
    }

    export interface LibraryFolder {

        createdDateTime: Date;
        id: string;
        lastModifiedDateTime: Date;
        name: string;
        webUrl: string;
        size: number;
        parentReference: ParentReference;
        fileSystemInfo: FileSystemInfo;
        folder: Folder;
        root: Root;
    }

    export interface User {
        email: string;
        id: string;
        displayName: string;
    }

    export interface CreatedBy {
        user: User;
    }


    export interface LastModifiedBy {
        user: User;
    }

    export interface ParentReference {
        driveId: string;
        driveType: string;
        id: string;
        path: string;
    }

    export interface FileSystemInfo {
        createdDateTime: Date;
        lastModifiedDateTime: Date;
    }

    export interface Folder {
        childCount: number;
    }

    export interface File {
        createdDateTime: Date;
        eTag: string;
        id: string;
        lastModifiedDateTime: Date;
        name: string;
        webUrl: string;
        cTag: string;
        size: number;
        createdBy: CreatedBy;
        lastModifiedBy: LastModifiedBy;
        parentReference: ParentReference;
        fileSystemInfo: FileSystemInfo;
        folder: Folder;
        thumbnails: Thumbnail[];
        '@microsoft.graph.downloadUrl': string;
        file: File;
        image: Image;
    }

}


export const childPath = (path: string) => {

    if (!path) return ""
    return ":/" + path + ":"
}


export const getRootSite = (accessToken: string): Promise<Result<SharePointSite>> => {
    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/root`
        var result: Result<any> = await https(accessToken, "GET", url)
        if (result.hasError) {
            return resolve({ hasError: true, errorMessage: result.errorMessage })
        }
        resolve({ hasError: false, data: result.data })
    })
}

export const getSubSite = (accessToken: string, hostname: string, subsitePath: string): Promise<Result<SharePointSite>>=> {
    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/${hostname}:/${subsitePath}`
        var result: Result<any> = await https(accessToken, "GET", url)
        if (result.hasError) {
            return resolve({ hasError: true, errorMessage: result.errorMessage })
        }
        resolve({ hasError: false, data: result.data })
    })
}

export const getAllListItems = (accessToken: string, sharePointSiteId: string, listName: string): Promise<Result<any[]>> => {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items?expand=fields`
        var result = await httpsGetAll<any>(accessToken,  url)
        resolve(result)
    })
};

export const getListItem = (accessToken: string, sharePointSiteId: string, listName: string, field: string,value:string): Promise<Result<any>> => {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items?expand=fields&$filter=fields/${field} eq '${value}'`
        var result = await https<any>(accessToken, "GET", url)
        resolve(result)
    })
};
export const getSharePointPage = (accessToken: string, sharePointSiteId: string,  pageId: number): Promise<Result<any>> => {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/beta/sites/${sharePointSiteId}/pages/${pageId}`
        var result = await https<any>(accessToken, "GET", url)
        resolve(result)
    })
};

export const getAllSharePointPage = (accessToken: string, sharePointSiteId: string): Promise<Result<any[]>> => {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/beta/sites/${sharePointSiteId}/pages/microsoft.graph.sitePage`
        var result = await httpsGetAll<any>(accessToken,  url)
        resolve(result)
    })
};

// export const getSiteDrives = (accessToken: string, siteId: string): Promise<Drive[]> => {
//     return new Promise(async (resolve, reject) => {
//         var url = `https://graph.microsoft.com/v1.0/sites/${siteId}/drives`
//         var result: Result<any> = await https(accessToken, "GET", url)
//         if (result.hasError) {
//             return resolve(null)
//         }
//         resolve(result.data.value)
//     })
// }

// export const getFolder = (accessToken: string, driveId: string, path: string): Promise<Folder> => {
//     return new Promise(async (resolve, reject) => {
//         var url = `https://graph.microsoft.com/v1.0/drives/${driveId}/root${childPath(path)}`
//         var result: Result<any> = await https(accessToken, "GET", url)
//         if (result.hasError) {
//             return resolve(null)
//         }
//         var sharePointFolder: SharePoint.LibraryFolder = result.data

//         var rootFolder: Folder = {
//             name: sharePointFolder.name,
//             modifiedDate: sharePointFolder.lastModifiedDateTime,
//             sharePoint: sharePointFolder,
//             webUrl: sharePointFolder.webUrl,
//             minHeight: ""
//         }
//         resolve(rootFolder)
//     })
// }

// export const addFolder = (accessToken: string, driveId: string, path: string, folderName: string): Promise<Folder> => {
//     return new Promise(async (resolve, reject) => {
//         var newFolder = {
//             "name": folderName,
//             "folder": {},
//             "@microsoft.graph.conflictBehavior": "rename"
//         }
//         var url = `https://graph.microsoft.com/v1.0/drives/${driveId}/root${childPath(path)}/children`
//         var result: Result<any> = await https(accessToken, "POST", url, newFolder)
//         if (result.hasError) {
//             return resolve(null)
//         }
//         var sharePointFolder: SharePoint.LibraryFolder = result.data

//         var folder: Folder = {
//             name: sharePointFolder.name,
//             modifiedDate: sharePointFolder.lastModifiedDateTime,
//             sharePoint: sharePointFolder,
//             webUrl: sharePointFolder.webUrl,
//             minHeight: ""
//         }
//         resolve(folder)
//     })
// }

// export const addFile = (accessToken: string, driveId: string, path: string, fileName: string, data: string, contentType?: string): Promise<Result<any>> => {
//     return new Promise(async (resolve, reject) => {


//         var url = `https://graph.microsoft.com/v1.0/drives/${driveId}/root${childPath(path + "/" + fileName)}/content`
//         var result: Result<any> = await https(accessToken, "PUT", url, data, contentType)

//         return resolve(result)

//     })
// }


// // const interpretUrl = (url:string,filename:string) => {
// //     return new Promise((resolve, reject) => { 

// //      })
// // }

// export const getLibraryDriveId = (accessToken: string, subSiteName, libraryName): Promise<string> => {
//     return new Promise(async (resolve, reject): Promise<string> => {

//         var rootSite = await getRootSite(accessToken)
//         if (!rootSite) { reject("Root site not found"); return }

//         var subSite = await getSubSite(accessToken, rootSite.siteCollection.hostname, subSiteName)
//         if (!subSite) { reject("Intra365 site not found"); return }

//         var drives = await getSiteDrives(accessToken, subSite.id)
//         if (!drives) { reject("No drives found"); return }

//         var id = null
//         drives.forEach(drive => {

//             if (drive.webUrl.toLowerCase().endsWith(libraryName.toLowerCase())) {
//                 id = drive.id
//             }
//         });

//         if (!id) { reject("Bookmarks library not found"); return }

//         resolve(id)
//     })
// }

// export const getSite = (accessToken: string, subSiteName, libraryName): Promise<SharePointSite> => {
//     return new Promise(async (resolve, reject): Promise<string> => {

//         var rootSite = await getRootSite(accessToken)
//         if (!rootSite) { reject("Root site not found"); return }

//         var subSite = await getSubSite(accessToken, rootSite.siteCollection.hostname, subSiteName)
//         if (!subSite) { reject("Sub site not found"); return }

//         resolve(subSite)
//     })
// }

// const onSameSharePoint = (linkUrl, url): boolean => {
//     if (!linkUrl) return false
//     if (!url) return false
//     var sp1 = linkUrl.split(".sharepoint.com/")
//     var sp2 = url.split(".sharepoint.com/")
//     if (sp1.length < 2) return false
//     if (sp2.length < 2) return false
//     return (sp1[0] === sp2[0])
// }

// const refineFile = (accessToken: string, spFile: SharePoint.File, file: File,refine:boolean=true): Promise<File> => {
//     const getFileName = (name: string) => {
//         var i = name.lastIndexOf("/")
//         return name.substring(i + 1)
//     }
//     const getLocalFile = (fileDataUrl): Promise<File> => {
//         return new Promise(async (resolve, reject) => {
//             if (!refine){
//                 resolve(file)
//                 return
//             }
//             var sharePointUrl = fileDataUrl.toLowerCase().split(".sharepoint.com/sites/")
//             try {
//                 if (sharePointUrl.length > 1) {
//                     var sharePointLibraryUrl = sharePointUrl[1].split("/forms")

//                     var site = sharePointLibraryUrl[0].split("/")[0]
//                     var library = sharePointLibraryUrl[0].split("/")[1]

//                     var rem = decodeURIComponent(sharePointLibraryUrl[1])

//                     var fileParts1 = rem.split("id=")
//                     var fileParts2 = fileParts1[1].split("&parent=")
//                     var fileName = getFileName(fileParts2[0])
//                     var parent = fileParts2[1]
//                     var folderPathElements = parent.split("/")
//                     var folderPathElements2 = [...folderPathElements].splice(4)
//                     var folderPath = folderPathElements2.join("/")

//                     //                     var p1: any[] = sharePointLibraryUrl[0].split("/")
//                     // var filename = p1.pop()
//                     // var filepath: string  = p1.splice(2).join("/")
//                     // debugger
//                     //var trailingPath : any[]= sharePointLibraryUrl[0].split("/").splice(0,2).join("/")




//                     var driveId: string = await getLibraryDriveId(accessToken, "sites/" + site, library)

//                     if (driveId) {
//                         var linkedFiles = await getFiles(accessToken, driveId, folderPath)
//                         if (linkedFiles) {
//                             var f: File = linkedFiles.find((file) => {

//                                 return file.name.toLowerCase() === fileName
//                             })
//                             if (f) {

//                                 var itemPreviewUrl = "https://graph.microsoft.com/v1.0/drives/" + f.sharePoint.parentReference.driveId + "/items/" + f.sharePoint.id + "/preview"

//                                 var result: Result<any> = await https(accessToken, "POST", itemPreviewUrl)

//                                 if (!result.hasError) {
//                                     var preview: SharePoint.Preview = result.data
//                                     f.previewUrl = preview.getUrl
//                                 }
//                                 resolve(f)
//                                 return
//                             }


//                         }



//                     }
//                     resolve(null)

//                 }
//             } catch (error) {
//                 //refinedFile.text = "Error " + error.message
//                 resolve(null)
//             }


//         })

//     }
//     const getLocalFiles = (fileDataUrl): Promise<File[]> => {
//         return new Promise(async (resolve, reject) => {

//             var sharePointUrl = fileDataUrl.toLowerCase().split(".sharepoint.com/sites/")
//             try {
//                 if (sharePointUrl.length > 1) {

//                     var sharePointLibraryUrl = sharePointUrl[1].split("/forms")

//                     var site = sharePointLibraryUrl[0].split("/")[0]
//                     var library = sharePointLibraryUrl[0].split("/")[1]

//                     var rem = decodeURIComponent(sharePointLibraryUrl[1])

//                     var fileParts1 = rem.split("id=")
//                     var fileParts2 = fileParts1[1].split("&view")
//                     var fileName = getFileName(fileParts2[0])
//                     var parent = fileParts2[1]

//                     var folderPathElements = rem.split("&view")[0].split("/")
//                     var folderPathElements2 = [...folderPathElements].splice(5, folderPathElements.length - 5)
//                     var folderPath = folderPathElements2.join("/")

//                     //                     var p1: any[] = sharePointLibraryUrl[0].split("/")
//                     // var filename = p1.pop()
//                     // var filepath: string  = p1.splice(2).join("/")
//                     // debugger
//                     //var trailingPath : any[]= sharePointLibraryUrl[0].split("/").splice(0,2).join("/")




//                     var driveId: string = await getLibraryDriveId(accessToken, "sites/" + site, library)

//                     if (driveId) {
//                         var linkedFiles = await getFiles(accessToken, driveId, folderPath)

//                         resolve(linkedFiles)

//                         return



//                     }
//                     resolve(null)

//                 }
//             } catch (error) {
//                 //refinedFile.text = "Error " + error.message
//                 resolve(null)
//             }


//         })

//     }
//     return new Promise(async (resolve, reject) => {
//         var refinedFile = { ...file }

//         var extension = spFile.name.substring(spFile.name.lastIndexOf(".") + 1).toLowerCase()




//         switch (extension) {
//             case "lnk":
//             case "exe":
//                 refinedFile.hidden = true
//                 resolve(refinedFile)
//                 break;

//             case "url":
//                 var fileData = await https<string>("", "GET", spFile["@microsoft.graph.downloadUrl"])
//                 if (fileData.hasError) { return resolve(refinedFile) }


//                 var data = fileData.data.split("URL=")
//                 var fileDataUrl: string = (data.length > 1) ? data[1]?.trim() : ""
//                 var linkedFile: File = null
//                 if (onSameSharePoint(file.downloadUrl, fileDataUrl)) {
//                     linkedFile = await getLocalFile(fileDataUrl)
//                     if (linkedFile) {

//                         refinedFile.thumbNailUrl = linkedFile.thumbNailUrl
//                         refinedFile.webUrl = linkedFile.webUrl
//                         refinedFile.modifiedDate = linkedFile.modifiedDate
//                         refinedFile.editorEmail = linkedFile.editorEmail
//                         refinedFile.editorName = linkedFile.editorName
//                         refinedFile.sharePoint = linkedFile.sharePoint
//                         refinedFile.previewUrl = linkedFile.previewUrl
//                     }


//                 }



//                 if (fileDataUrl && !linkedFile) {


//                     refinedFile.webUrl = fileDataUrl //window.location.href+"/https/" + fileDataUrl.replace("https://","")
//                     refinedFile.previewUrl = fileDataUrl

//                     var powerAppsUrl = fileDataUrl.split("https://apps.powerapps.com/play/")
//                     if (powerAppsUrl.length > 1) {
//                         refinedFile.liveTile = true
//                     }


//                     var info = await https<Intra365.WebInfo>(null, "POST", "/api/discover/web", { url: fileDataUrl })
//                     if (info) {
//                         var webInfo: Intra365.WebInfo = info.data

//                         refinedFile.thumbNailUrl = webInfo.image
//                         refinedFile.description = webInfo.description
//                         refinedFile.heading = webInfo.heading
//                         refinedFile.text = fileDataUrl // webInfo.text.trim()

//                     }


//                     var miroUrl = fileDataUrl.split("https://miro.com/app/board/")

//                     try {
//                         if (miroUrl.length > 1) {

//                             var boardId = miroUrl[1].split("/")[0]

//                             refinedFile.previewUrl = "https://miro.com/app/live-embed/" + boardId
//                             refinedFile.text = "Miro board"
//                             refinedFile.thumbNailUrl = "https://static-website.miro.com/static/images/share/miro.png"

//                         }
//                     } catch (error) {
//                         refinedFile.text = "Error " + error.message
//                     }
//                     var sharePointUrl = fileDataUrl.toLowerCase().split(".sharepoint.com/sites/")
//                     try {
//                         if (sharePointUrl.length > 1) {
//                             // var sharePointLibraryUrl = sharePointUrl[1].split("/forms")

//                             // var site = sharePointLibraryUrl[0].split("/")[0]
//                             // var library = sharePointLibraryUrl[0].split("/")[1]
//                             // var driveId: string = await getLibraryDriveId(accessToken, "sites/" + site, library)

//                             // if (driveId) {
//                             //     var linkedFolder : Folder = await getFolder(accessToken, driveId, "")
//                             //     refinedFile.linkedFolder = linkedFolder
//                             //     refinedFile.text = "Library with x  " + linkedFolder.sharePoint?.folder.childCount + " items"
//                             //     console.log(JSON.stringify(linkedFolder))
//                             // }
//                             refinedFile.linkedFiles = await getLocalFiles(fileDataUrl)
//                             if (refinedFile?.linkedFiles) {
//                                 refinedFile.text = "Library with x  " + refinedFile?.linkedFiles?.length + " items"
//                             } else {
//                                 refinedFile.liveTile = true
//                             }

//                         }
//                     } catch (error) {
//                         refinedFile.text = "Error" + error.message
//                     }


//                     //debugger


//                 }




//                 resolve(refinedFile)
//                 break;

//             default:
//                 var itemPreviewUrl = "https://graph.microsoft.com/v1.0/drives/" + spFile.parentReference.driveId + "/items/" + spFile.id + "/preview"

//                 var result: Result<any> = await https(accessToken, "POST", itemPreviewUrl)
//                 if (!result.hasError) {
//                     var preview: SharePoint.Preview = result.data
//                     refinedFile.previewUrl = preview.getUrl
//                 }
//                 resolve(refinedFile)
//                 break;
//         }



//     })
// }

// export const getFiles = (accessToken: string, driveId: string, path: string,refine:boolean=true): Promise<File[]> => {
//     var pending = 0
//     return new Promise(async (resolve, reject) => {




//         var url = `https://graph.microsoft.com/v1.0/drives/${driveId}/root${childPath(path)}/children?$expand=thumbnails`
//         var result: Result<any> = await https(accessToken, "GET", url)
//         if (result.hasError) {
//             console.log("Get Files",path,result.errorMessage)
//             return resolve(null)
//         }
//         var sharePointFiles: SharePoint.File[] = result.data.value
//         var files: File[] = []
//         sharePointFiles.forEach(async (spFile) => {
//             if (spFile.folder) return
//             var file: File = {
//                 name: spFile.name,
//                 displayName: getDisplayName(spFile.name),
//                 webUrl: spFile.webUrl,
//                 thumbNailUrl: spFile.thumbnails && spFile.thumbnails.length > 0 ? spFile.thumbnails[0].large.url : "",
//                 downloadUrl: spFile["@microsoft.graph.downloadUrl"],
//                 editorEmail: spFile.lastModifiedBy.user.email,
//                 editorName: spFile.lastModifiedBy.user.displayName,
//                 modifiedDate: spFile.lastModifiedDateTime,
//                 sharePoint: spFile,
//                 minHeight: randomHeight(),
//                 backColor: randomColor()

//             }
            
//             pending++
//             var refinedFile = await refineFile(accessToken, spFile, file,refine)
//             if (!refinedFile.hidden) {
//                 files.push(refinedFile)
//             }
//             pending--
//             if (pending === 0) resolve(files)
//         })

//         if (pending === 0) resolve(files)
//     })
// }

// export const getFolders = (accessToken: string, driveId: string, path: string): Promise<Folder[]> => {
//     return new Promise(async (resolve, reject) => {

//         var url = `https://graph.microsoft.com/v1.0/drives/${driveId}/root${childPath(path)}/children`
//         var result: Result<any> = await https(accessToken, "GET", url)
//         if (result.hasError) {
//             return resolve([])
//         }
//         var sharePointFiles: SharePoint.File[] = result.data.value
//         var folders: Folder[] = []
//         sharePointFiles.forEach(spFile => {
//             if (!spFile.folder) return
//             var folder: Folder = {
//                 name: spFile.name,
//                 webUrl: spFile.webUrl,
//                 modifiedDate: spFile.lastModifiedDateTime,
//                 minHeight: "100px"
//             }
//             folders.push(folder)
//         })


//         resolve(folders)
//     })
// }

// export const getPermissions = (accessToken: string, file: File): Promise<any[]> => {
//     return new Promise(async (resolve, reject) => {

//         var url = `https://graph.microsoft.com/v1.0/drives/${file.sharePoint.parentReference.driveId}/items/${file.sharePoint.id}/permissions`
//         var result: Result<any> = await https(accessToken, "GET", url)

//         if (result.hasError) {
//             return resolve(null)
//         }


//         resolve(result.data.value)
//     })
// }

 interface Fields {
     fields: any
 }
// /**
//  * 
//  * @param app 
//  * @param listName 
//  * @param filter  e.g "fields/Processed ne 1 AND fields/Processing ne 1"
//  * @returns 
//  */

// export const getItemByFilter = (accessToken: string, sharePointSiteId: string, listName: string, filter: string): Promise<Result<any>> => {

//     return new Promise(async (resolve, reject) => {
//         var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items?expand=fields&$filter=${filter}`

//         var result = await https<any>(accessToken, "GET", url)
//         resolve(result)
//     })
// };

// export const getItems = (accessToken: string, sharePointSiteId: string, listName: string): Promise<Result<any>> => {

//     return new Promise(async (resolve, reject) => {
//         var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items?expand=fields`
//         var result = await https<any>(accessToken, "GET", url)
//         resolve(result)
//     })
// };

// export const getItemById = (accessToken: string, sharePointSiteId: string, listName: string, id: string): Promise<Result<any>> => {

//     return new Promise(async (resolve, reject) => {
//         var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items/${id}`
//         var result = await https<any>(accessToken, "GET", url)
//         resolve(result)
//     })
// };

// export const getItemAttachments = (accessToken: string, sharePointSiteId: string, listName: string, id: string): Promise<Result<any>> => {

//     return new Promise(async (resolve, reject) => {
//         var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items/${id}/attachments`
//         var result = await https<any>(accessToken, "GET", url)
//         resolve(result)
//     })
// };

// export const resolvePath = (directory, filename) => {
//     var filePath = path.resolve(path.join(__dirname, "../../.intra365/", directory, filename))
//     return filePath
// }


// export const  downloadFile = (downloadUrl,outputLocationPath) : Promise<any> => {
//     return new Promise(async (resolve, reject) => { 
        
//         const writer = fs.createWriteStream(outputLocationPath);
//         var fileResponse = await axios({
//             method: 'get',
//             url: downloadUrl,
//             responseType: 'stream',
//           })
//           writer.on('finish', resolve)
//           writer.on('error', reject)
//           fileResponse.data.pipe(writer)
//      })
// }
// export const downloadLibrary = (accessToken: string, subsiteName: string, libraryName: string, destinationPath: string): Promise<Result<any>> => {

//     return new Promise(async (resolve, reject) => {

//         var result: Result<any> = {
//             hasError: false
//         }
//         var driveID = await getLibraryDriveId(accessToken, subsiteName, libraryName)
//         var pending = 0
        
//         fs.mkdirSync(destinationPath, { recursive: true })
        
//         async function readFolder(pathName) {
            
//             pending++
//             console.log("Downloading folder",pending,pathName)
//             if (pathName){
//                 var fp = path.join(destinationPath,pathName)
//                 fs.mkdirSync(fp, { recursive: true })    
               
//             }
//             await sleep(100)
//             var files = await getFiles(accessToken, driveID, pathName,false)


//             files.forEach(async file => {
//                 var outputLocationPath = path.join(destinationPath,pathName,file.name)
//                 pending++
//                 console.log("Downloading file",pending,outputLocationPath)    
//                 await sleep(100)
//                 await downloadFile(file.downloadUrl,outputLocationPath).catch(e=>console.log("Error downloading",outputLocationPath,e));
//                 pending--
//                 console.log("Done Downloading file",pending,outputLocationPath)    
//                 if (pending < 1) {
//                     resolve(result)
//                 }
    
//             });

//             var folders = await getFolders(accessToken, driveID, pathName)
//             folders.forEach(folder => {
//                 readFolder(pathName ?  pathName + "/"+ folder.name : folder.name)
//             });
//             pending--
//             console.log("Done downloading folder",pending,pathName)
//             if (pending < 1) {
//                 resolve(result)
//             }

//         }
//         try {
//             readFolder("")    
//         } catch (error) {
//             console.log("Downloading PowerShell libraries got error, ignoring and continuing boot",error)
//             resolve({hasError:true,errorMessage:error})
//         }
        


//     })
// };



export const updateItem = (accessToken: string,  sitename: string, listName: string, id: string, body: Fields): Promise<Result<any>> => {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/${process.env.SPAUTH_TENANTNAME}.sharepoint.com:/sites/${sitename}:/lists/${listName}/items/${id}`
        console.log(url,body)
        var result = await https<any>(accessToken, "PATCH", url, body)
        resolve(result)
    })
};

export const addItem = function (accessToken: string, sharePointSiteId: string, listName: string, body: Fields): Promise<Result<any>> {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items`
        var result = await https<any>(accessToken, "POST", url, body)
        resolve(result)
    })
};

export const deleteItem = function (accessToken: string, sharePointSiteId: string, listName: string, id: string): Promise<Result<any>> {

    return new Promise(async (resolve, reject) => {
        var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items/${id}`
        var result = await https<any>(accessToken, "DELETE", url)
        resolve(result)
    })
};



//     export interface ResultType<T> {
//       "@odata.context": string;
//       "@odata.nextLink": string;
//       value: T[];
//     }
  
//   export function readAllSharePointItems<T>(token:string,
//     sharePointSiteId:string,
//     listName:string,
//                               readAll:boolean=true): Promise<T[]> {
//     return new Promise(async (resolve, reject) => {
//       var result: T[] = [];
  
  
//       const updateStatus = () => {
//         var number = result.length.toString();
//         var text = " ".repeat(10 - number.length) + number + " downloaded";
//         consoleShowProgress(text);
//       };
  
//       const readNext = async (url) => {
        
//         var azureAdResult = await https<ResultType<any>>(
//           token,
//           "GET",
//           url
//         );
//         if (azureAdResult.hasError) {
//           reject(azureAdResult.errorMessage);
//           return;
//         }
//         var items: any[] = azureAdResult.data.value.map((row) => {
//           return row;
//         });
//         result.push(...items);
//         updateStatus()
//         if (!readAll){
//           consoleClearProgress()
//           resolve(result);
//           return
//         }
//         if (!azureAdResult.data["@odata.nextLink"]) {
//           consoleClearProgress()
//           resolve(result);
//           return;
//         } else {
//           readNext(azureAdResult.data["@odata.nextLink"]);
//         }
//       };
  
//       var url = `https://graph.microsoft.com/v1.0/sites/${sharePointSiteId}/lists/${listName}/items?expand=fields`
//       readNext(url);
    
//     });
//   }
  