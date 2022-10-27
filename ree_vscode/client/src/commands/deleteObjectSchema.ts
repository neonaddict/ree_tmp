import * as vscode from 'vscode'
import { getCurrentProjectDir } from '../utils/fileUtils'
import {
  buildReeCommandFullArgsArray,
  deleteObjectSchemaJsonCommandArgsArray,
  ExecCommand,
  spawnCommand
} from '../utils/reeUtils'

const path = require('path')

export function onDeletePackageFile(filePath: string) {
  deleteObjectSchema(filePath, true)
}

export function deleteObjectSchema(filePath: string, silent: boolean) {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const rootProjectDir = getCurrentProjectDir()
  if (!rootProjectDir) { return }

  const relativeFilePath = path.relative(rootProjectDir, filePath)

  const result = execDeleteObjectSchema(rootProjectDir, relativeFilePath)

  if (!result) {
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
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}