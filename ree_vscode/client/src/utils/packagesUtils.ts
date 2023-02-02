
import * as vscode from 'vscode'
import { getCurrentProjectDir } from './fileUtils'
import { getPackagesSchemaPath, getProjectRootDir } from './packageUtils'
import { execGetReeFileIndex, execGetReeProjectIndex, execGetReePackageIndex, spawnCommand } from './reeUtils'
import { logDebugClientMessage } from './stringUtils'

const path = require('path')
const fs = require('fs')
const MAX_GET_INDEX_RETRY_COUNT = 5

let cachedIndex: ICachedIndex
let getNewIndexRetryCount: number = 0

let packagesSchemaCtime: number | null = null
export function getPackagesSchemaCtime(): number | null {
  return packagesSchemaCtime
}
export function setPackagesSchemaCtime(value) {
  packagesSchemaCtime = value
}
export function isPackagesSchemaCtimeChanged(): boolean {
  const root = getCurrentProjectDir()
  const oldCtime = getPackagesSchemaCtime()
  const newCtime = fs.statSync(getPackagesSchemaPath(root)).ctimeMs
  return oldCtime !== newCtime
}

let packageSchemasCtimes = {}
export function getPackageSchemaCtime(packageName: string) {
  return packageSchemasCtimes[packageName]
}
export function setPackageSchemaCtime(packageName: string, ctime: number) {
  packageSchemasCtimes[packageName] = ctime
}
export function isPackageSchemaCtimeChanged(pckg: IPackageSchema): boolean {
  const root = getCurrentProjectDir()
  const oldCtime = getPackageSchemaCtime(pckg.name)
  const pckgSchemaPath = pckg.schema_rpath
  if (!fs.existsSync(pckgSchemaPath)) { return true }

  const newCtime = fs.statSync(path.join(root, pckgSchemaPath)).ctimeMs
  return oldCtime !== newCtime
}


export function getCachedIndex(): ICachedIndex {
  if (!cachedIndex || (isCachedIndexIsEmpty())) {
    getNewProjectIndex()
  }

  if (cachedIndex) {
    let root = getCurrentProjectDir()
    if (isPackagesSchemaCtimeChanged()) {
      logDebugClientMessage('Packages.schema.json is changed')
      getNewProjectIndex()
      calculatePackagesSchemaCtime(root)
      return cachedIndex
    }

    if (cachedIndex.packages_schema && cachedIndex.packages_schema.packages) {
      let changedPackages = cachedIndex.packages_schema.packages.filter(p => isPackageSchemaCtimeChanged(p))
      if (changedPackages.length > 0) {
        logDebugClientMessage('Some packages schemas is changed')
        changedPackages.forEach(p => logDebugClientMessage(`Package ${p.name} schema is changed`))
      }
      changedPackages.forEach(pckg => {
        cachePackageIndex(root, pckg.name).then(r => {
          try {
            if (r) {
              if (r.code === 0) {
                let newPackageIndex = JSON.parse(r.message) as IPackageSchema
                logDebugClientMessage(`Got Package index for ${pckg.name}`)
                calculatePackageSchemaCtime(root, pckg.name)
                let refreshedPackages = cachedIndex.packages_schema.packages.filter(p => p.name !== pckg.name)
                refreshedPackages.push(newPackageIndex)
                cachedIndex.packages_schema.packages = refreshedPackages
              } else {
                vscode.window.showErrorMessage(`GetPackageIndexError: ${r.message}`)
              }
            }
          } catch(e: any) {
            vscode.window.showErrorMessage(e.toString())
          }
        })
      })
    }
  }

  return cachedIndex
}

export function setCachedIndex(value: ICachedIndex) {
  cachedIndex = value
}

export function isCachedIndexIsEmpty(): boolean {
  if (!cachedIndex) { return true }
  if (cachedIndex && cachedIndex.packages_schema && Object.keys(cachedIndex).length > 0) { return false }

  return true
}

export function getNewProjectIndex(manual = false, showNotification = false) {
  if (getNewIndexRetryCount > MAX_GET_INDEX_RETRY_COUNT && !manual) { 
    logDebugClientMessage('getNewProjectIndex reached max limit')
    return
  }

  const root = getCurrentProjectDir()
  if (!root) { return }

  cacheProjectIndex(root).then(r => {
    try {
      if (r) {
        if (r.code === 0) {
          cachedIndex = JSON.parse(r.message)
          calculatePackagesSchemaCtime(root)
          cachedIndex.packages_schema.packages.forEach(pckg => {
            calculatePackageSchemaCtime(root, pckg.name)
          })
          logDebugClientMessage('Got new Project Index')
          getNewIndexRetryCount = 0
        } else {
          logDebugClientMessage('Got error code when getting new Project index')
          if (isCachedIndexIsEmpty()) {
            logDebugClientMessage('Index is empty, set as empty object')
            cachedIndex = <ICachedIndex>{}
          }
          getNewIndexRetryCount += 1
          vscode.window.showErrorMessage(`GetProjectIndexError: ${r.message}`)
        }
      }
    } catch(e: any) {
      logDebugClientMessage('Catched some error when tried to get new Project index')
      if (isCachedIndexIsEmpty()) {
        logDebugClientMessage('Index is empty, set as empty object')
        cachedIndex = <ICachedIndex>{}
      }
      getNewIndexRetryCount += 1
      vscode.window.showErrorMessage(e.toString())
    }
  }).then(() => {
    cacheGemPaths(root.toString()).then((r) => {
      if (r) {
        if (r.code === 0) {
          logDebugClientMessage('Got Gem Paths')
          const gemPathsArr = r?.message.split("\n")
          if (isCachedIndexIsEmpty()) {
            logDebugClientMessage('Index is empty, set as empty object')
            cachedIndex ??= <ICachedIndex>{}
          }
          cachedIndex.gem_paths ??= {}

          gemPathsArr?.map((path) => {
            let splitedPath = path.split("/")
            let name = splitedPath[splitedPath.length - 1].replace(/\-(\d+\.?)+/, '')
    
            cachedIndex.gem_paths[name] = path
          })
          logDebugClientMessage('Gem Paths setted')
        } else {
          vscode.window.showErrorMessage(`GetGemPathsError: ${r.message.toString()}`)
        }
      }
    })
  }).then(() => {
    if (showNotification) {
      vscode.window.showInformationMessage("CLIENT: Reindex is completed!")
    }
  }) 
}

/* eslint-disable @typescript-eslint/naming-convention */
interface ExecCommand {
  message: string
  code: number
}

export interface ICachedIndex {
  classes: {
    [key: string]: IIndexedElement[]
  },
  objects: {
    [key: string]: IIndexedElement[]
  },
  packages_schema: IPackagesSchema,
  gem_paths: GemPath
}

interface GemPath {
  [key: string]: string | undefined
}

export interface IIndexedElement {
  path: string,
  package: string,
  methods: [
    {
      name: string,
      parameters?: { name: number, required: string }[]
      location: number
    }
  ]
}

export interface IPackagesSchema {
  packages: IPackageSchema[]
  gem_packages: IGemPackageSchema[]
}

export interface IPackageSchema {
  name: string
  schema_rpath: string
  entry_rpath: string
  tags: string[]
  objects: IObject[]
}

export interface IGemPackageSchema {
  gem: string
  name: string
  schema_rpath: string
  entry_rpath: string
  objects: IObject[]
}

export interface IObject {
  name: string
  schema_rpath: string
  file_rpath: string
  mount_as: string
  factory: string | null
  methods: IObjectMethod[]
  links: IObjectLink[]
}

export interface IMethodArg {
  arg: string
  type: string
}

export interface IObjectMethod {
  doc: string
  throws: string[]
  return: String | null
  args: IMethodArg[]
}

export interface IObjectLink {
  target: string,
  package_name: string,
  as: string,
  imports: string[]
}

/* eslint-enable @typescript-eslint/naming-convention */


export function cacheGemPaths(rootDir: string): Promise<ExecCommand | undefined> {
  return execBundlerGetGemPaths(rootDir)
}

export function cacheProjectIndex(rootDir: string): Promise<ExecCommand | undefined> {
  return execGetReeProjectIndex(rootDir)
}

export function cachePackageIndex(rootDir: string, packageName: string): Promise<ExecCommand | undefined> {
  return execGetReePackageIndex(rootDir, packageName)
}

export function cacheFileIndex(rootDir: string, filePath: string): Promise<ExecCommand | undefined> {
  return execGetReeFileIndex(rootDir, filePath)
}

export function calculatePackagesSchemaCtime(root: string) {
  logDebugClientMessage('Trying to recalculate Packages.schema.json ctime')
  const packagesSchemaPath = getPackagesSchemaPath(root)
  if (packagesSchemaPath) { 
    logDebugClientMessage('Packages.schema.json ctime recalculated')
    setPackagesSchemaCtime(fs.statSync(packagesSchemaPath).ctimeMs)
  }
}

export function calculatePackageSchemaCtime(root: string, packageName: string) {
  logDebugClientMessage(`Trying to recalculate Package.schema.json for ${packageName}`)
  if (!cachedIndex.packages_schema?.packages) { return }

  const pckg = cachedIndex.packages_schema.packages.find(p => p.name === packageName)
  if (!pckg) { return }

  let schemaAbsPath = path.join(root, pckg.schema_rpath)
  let time = fs.statSync(schemaAbsPath).ctimeMs
  logDebugClientMessage(`Package.schema.json for ${packageName} recalculated`)
  setPackageSchemaCtime(pckg.name, time)
}

export function getGemPackageSchemaPath(gemPackageName: string): string | undefined {
  const gemPath = getGemDir(gemPackageName)
  if (!gemPath) { return }

  const gemPackage = getCachedGemPackage(gemPackageName)
  if (!gemPackage) { return }

  return path.join(gemPath, gemPackage.schema_rpath)
}

export function getCachedGemPackage(gemPackageName: string): IGemPackageSchema | undefined {
  if (!cachedIndex) { return }

  const gemPackage = cachedIndex?.packages_schema.gem_packages.find(p => p.name === gemPackageName)
  if (!gemPackage) { return }

  return gemPackage
}

export function getGemDir(gemPackageName: string): string | undefined {
  if (!cachedIndex) { return }

  const gemPackage = cachedIndex?.packages_schema.gem_packages.find(p => p.name === gemPackageName)
  if (!gemPackage) { return }

  const gemDir = cachedIndex.gem_paths[gemPackage.gem]
  if (!gemDir) { return }

  return path.join(gemDir.trim(), 'lib', gemPackage.gem)
}

async function execBundlerGetGemPaths(rootDir: string): Promise<ExecCommand | undefined> {
  try {
    const argsArr = ['show', '--paths']

    return spawnCommand([
      'bundle',
      argsArr,
      { cwd: rootDir }
    ])
  } catch(e) {
    console.error(e)
    return new Promise(() => undefined)
  }
}

function groupBy(data: Array<any>, key: string) {
  return data.reduce((storage, item) => {
      let group = item[key]
      storage[group] = storage[group] || []
      storage[group].push(item)
      return storage
  }, {})
}
