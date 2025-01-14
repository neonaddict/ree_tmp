import * as vscode from 'vscode'
import { client } from '../extension'
import { getCurrentProjectDir } from '../utils/fileUtils'
import { getPackageEntryPath } from '../utils/packageUtils'
import {
  buildReeCommandFullArgsArray,
  deleteObjectSchemaJsonCommandArgsArray,
  ExecCommand,
  spawnCommand
} from '../utils/reeUtils'
import { logErrorMessage } from '../utils/stringUtils'

const path = require('path')

export function onDeletePackageFile(filePath: string) {
  deleteObjectSchema(filePath, true)
}

export function deleteObjectSchema(filePath: string, silent: boolean) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const packageEntry = getPackageEntryPath(filePath)
  if (!filePath.split("/").pop().match(/\.rb/)) {
    return 
  } else {
    if (!packageEntry) { return }
  }

  const packageName = packageEntry.split('/').slice(-1)[0].split('.rb')[0]

  const rootProjectDir = getCurrentProjectDir()
  if (!rootProjectDir) { return }

  const relativeFilePath = path.relative(rootProjectDir, filePath)

  const result = execDeleteObjectSchema(rootProjectDir, relativeFilePath)

  if (!result) {
    logErrorMessage(`Can't delete object schema ${relativeFilePath}`)
    vscode.window.showErrorMessage(`Can't delete object schema ${relativeFilePath}`)
    return
  }

  vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification
  }, async (progress) => {
    progress.report({
      message: `Deleting object schema...`
    })

    return result.then((commandResult) => {  
      if (!silent) {
        vscode.window.showInformationMessage(commandResult.message)
      }

      if (commandResult && commandResult.code !== 0) {
        logErrorMessage(`DeleteObjectSchemaError: ${commandResult.message}`)
        vscode.window.showErrorMessage(`DeleteObjectSchemaError: ${commandResult.message}`)
      }
    }).then(() => {
      client.sendNotification("reeLanguageServer/reindexPackage", { root: rootProjectDir, packageName: packageName })
    })
  })
}


export async function execDeleteObjectSchema(rootProjectDir: string, objectPath: string): Promise<ExecCommand> {
  try {
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string
    const projectDir = appDirectory ? appDirectory : rootProjectDir
    const fullArgsArr = buildReeCommandFullArgsArray(projectDir, deleteObjectSchemaJsonCommandArgsArray(projectDir, objectPath))

    return spawnCommand(fullArgsArr)
  } catch(e) {
    logErrorMessage(`Error. ${e.toString()}`)
    vscode.window.showErrorMessage(`Error. ${e.toString()}`)
    return undefined
  }
}