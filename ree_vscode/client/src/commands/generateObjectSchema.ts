import * as vscode from 'vscode'
import { DiagnosticSeverity } from 'vscode-languageclient'
import { PackageFacade } from '../utils/packageFacade'
import { getPackageNameFromPath } from '../utils/packageUtils'
import { loadPackagesSchema } from '../utils/packagesUtils'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { 
  isReeInstalled,
  isBundleGemsInstalled,
  isBundleGemsInstalledInDocker,
  ExecCommand,
  genObjectSchemaJsonCommandArgsArray
} from '../utils/reeUtils'
import { PACKAGES_SCHEMA_FILE } from '../core/constants'

const path = require('path')
const diagnosticCollection = vscode.languages.createDiagnosticCollection('ruby')

export function clearDocumentProblems(document: vscode.TextDocument) {
  diagnosticCollection.delete(document.uri)
}

export function genObjectSchemaCmd() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showInformationMessage("Error. Open workspace folder to use extension")
    return
  }

  let currentFilePath = null
  const activeEditor = vscode.window.activeTextEditor

  if (!activeEditor) {
    currentFilePath = vscode.workspace.workspaceFolders[0].uri.path
  } else {
    currentFilePath = activeEditor.document.uri.path
  }

  const projectPath = getCurrentProjectDir()
  if (!projectPath) {
    vscode.window.showErrorMessage(`Unable to find ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const packagesSchema = loadPackagesSchema(projectPath)

  if (!packagesSchema) {
    vscode.window.showErrorMessage(`Unable to read ${PACKAGES_SCHEMA_FILE}`)
    return
  }

  const currentPackageName = getPackageNameFromPath(currentFilePath)

  generateObjectSchema(activeEditor.document, false, currentPackageName)
}

export function generateObjectSchema(document: vscode.TextDocument, silent: boolean, packageName?: string) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const fileName = document.uri.path
  const rootProjectDir = getCurrentProjectDir()
  if (!rootProjectDir) { return }

  // check if ree is installed
  const checkReeIsInstalled = isReeInstalled(rootProjectDir)
  
  if (checkReeIsInstalled?.code === 1) {
    vscode.window.showWarningMessage('Gem ree is not installed')
    return
  }

  const checkIsBundleGemsInstalled = isBundleGemsInstalled(rootProjectDir)
  if (checkIsBundleGemsInstalled?.code !== 0) {
    vscode.window.showWarningMessage(checkIsBundleGemsInstalled.message)
    return
  }

  const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker()
  if (checkIsBundleGemsInstalledInDocker && checkIsBundleGemsInstalledInDocker.code !== 0) {
    vscode.window.showWarningMessage(checkIsBundleGemsInstalledInDocker.message)
    return
  }

  let execPackageName = null

  if (packageName || packageName !== undefined) {
    execPackageName = packageName
  } else {
    const currentPackageName = getCurrentPackage(fileName)
    if (!currentPackageName) { return }

    execPackageName = currentPackageName
  }

  let result = execGenerateObjectSchema(rootProjectDir, execPackageName, fileName)

  if (!result) {
    vscode.window.showErrorMessage(`Can't generate Package.schema.json for ${execPackageName}`)
    return
  }

  diagnosticCollection.delete(document.uri)

  if (result.code === 1) {
    const rPath = path.relative(
      rootProjectDir, document.uri.path
    )

    const line = result.message.split("\n").find(s => s.includes(rPath + ":"))
    let lineNumber = 0

    if (line) {
      try {
        lineNumber = parseInt(line.split(rPath)[1].split(":")[1])
      } catch {}
    }

    if (lineNumber > 0) {
      lineNumber -= 1
    }

    if (document.getText().length < lineNumber ) {
      lineNumber = 0
    }

    const character = document.getText().split("\n")[lineNumber].length - 1
    let diagnostics: vscode.Diagnostic[] = []

    let diagnostic: vscode.Diagnostic = {
      severity: DiagnosticSeverity.Error,
      range: new vscode.Range(
        new vscode.Position(lineNumber, 0),
        new vscode.Position(lineNumber, character)
      ),
      message: result.message,
      source: 'ree'
    }

    diagnostics.push(diagnostic)
    diagnosticCollection.set(document.uri, diagnostics)

    return
  }
  
  if (!silent) {
    vscode.window.showInformationMessage(result.message)
  }
}

export function execGenerateObjectSchema(rootProjectDir: string, name: string, objectPath: string): ExecCommand | undefined {
  try {
    let spawnSync = require('child_process').spawnSync
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string
    const projectDir = appDirectory ? appDirectory : rootProjectDir
    const fullArgsArr = buildReeCommandFullArgsArray(projectDir, genObjectSchemaJsonCommandArgsArray(projectDir, name, objectPath))
    const child = spawnSync(...fullArgsArr)

    return {
      message: child.status === 0 ? child?.stdout?.toString() : child?.stderr?.toString(),
      code: child.status
    }
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

function getCurrentPackage(fileName?: string): string | null {
  // check if active file/editor is accessible

  let currentFileName = fileName || vscode.window.activeTextEditor.document.fileName

  if (!currentFileName) {
    vscode.window.showErrorMessage("Open any package file")
    return
  }

  // finding package
  let currentPackage = getPackageNameFromPath(currentFileName)

  if (!currentPackage) { return }

  return currentPackage
}

export function buildReeCommandFullArgsArray(rootProjectDir: string, argsArray: string[]): Array<any> {
  let projectDir = rootProjectDir
  const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
  const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
  const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

  if (dockerPresented) {
    projectDir = appDirectory
    return [
      'docker', [
        'exec',
        '-i',
        '-e',
        'REE_SKIP_ENV_VARS_CHECK=true',
        '-w',
        projectDir,
        containerName,
        'bundle',
        'exec',
        'ree',
        ...argsArray
      ]
    ]
  } else {
    return [
      'env', [
        'REE_SKIP_ENV_VARS_CHECK=true',
        'ree',
        ...argsArray,
      ],
      {
        cwd: projectDir
      }
    ]
  }
}

export function buildBundlerCommandFullArgsArray(rootProjectDir: string, argsArray: string[]): Array<any> {
  let projectDir = rootProjectDir
  const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
  const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
  const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

  if (dockerPresented) {
    projectDir = appDirectory
    return [
      'docker', [
        'exec',
        '-i',
        '-w',
        projectDir,
        containerName,
        'bundle',
        ...argsArray
      ]
    ]
  } else {
    return [
      'bundle', [
        ...argsArray,
      ],
      {
        cwd: projectDir
      }
    ]
  }
}

