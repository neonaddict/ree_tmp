import * as vscode from 'vscode'

import { getCurrentProjectDir } from '../utils/fileUtils'
import { isReeInstalled, isBundleGemsInstalled, isBundleGemsInstalledInDocker, ExecCommand, spawnCommand } from '../utils/reeUtils'
import { loadPackagesSchema } from '../utils/packagesUtils'
import { PACKAGE_SCHEMA_FILE } from '../core/constants'
import { openDocument } from '../utils/documentUtils'

const fs = require('fs')
const path = require('path')

export function generatePackage() {
  if (!vscode.workspace.workspaceFolders) {
    vscode.window.showWarningMessage("Error. Open workspace folder to use extension")
    return
  }

  const rootProjectDir = getCurrentProjectDir()
  if (!rootProjectDir) { return }

  const checkReeIsInstalled = isReeInstalled(rootProjectDir).then((res) => {
    if (res.code === 1) {
      vscode.window.showWarningMessage('Gem ree is not installed')
      return null
    }
  })

  if (!checkReeIsInstalled) { return }

  const checkIsBundleGemsInstalled = isBundleGemsInstalled(rootProjectDir).then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return null
    }
  })
  if (!checkIsBundleGemsInstalled) { return }

  const checkIsBundleGemsInstalledInDocker = isBundleGemsInstalledInDocker().then((res) => {
    if (res.code !== 0) {
      vscode.window.showWarningMessage(res.message)
      return null
    }
  })

  if (!checkIsBundleGemsInstalledInDocker) { return }

  const options: vscode.OpenDialogOptions = {
    defaultUri: vscode.Uri.parse(rootProjectDir),
    canSelectFolders: true,
    canSelectFiles: false,
    canSelectMany: false,
    openLabel: 'Select parent package folder',
  }

  vscode.window.showInputBox({placeHolder: 'Type package name...'}).then((name: string | undefined) => {
    if (!name) { return }

    if (!/^[a-z_0-9]+$/.test(name)) {
      vscode.window.showErrorMessage("Invalid package name. Name should contain a-z, 0-9 & _/")
      return
    }

    vscode.window.showOpenDialog(options).then(fileUri => {
      if (!fileUri || !fileUri[0]) { return }

      let rPath = path.relative(rootProjectDir, fileUri[0].path)
      rPath = path.join(rPath, name)

      const result = execGeneratePackage(rootProjectDir, rPath, name)

      if (!result) {
        vscode.window.showErrorMessage("Can't generate package")
        return
      }

      result.then((commandResult) => {      
        if (commandResult.code === 1) {
          vscode.window.showErrorMessage(commandResult.message)
          return
        }
  
        vscode.window.showInformationMessage(`Package ${name} was generated`)
  
        const packagesSchema = loadPackagesSchema(rootProjectDir)
        if (!packagesSchema) { return }
  
        const packageSchema = packagesSchema.packages.find(p => p.name == name)
        if (!packageSchema) { return }
  
        const packageSchemaPath = path.join(rootProjectDir, packageSchema.schema)
        const entryPath = packageSchemaPath.split(PACKAGE_SCHEMA_FILE)[0] + `package/${packageSchema.name}.rb`
  
        if (!fs.existsSync(entryPath)) { return }
        openDocument(entryPath)
      })
    })
  })
}

async function execGeneratePackage(rootProjectDir: string, relativePath: string, name: string): Promise<ExecCommand> | undefined {
  try {
    return spawnCommand(
      [
        'ree',
        ['gen.package', name.toString(), '--path', relativePath, '--project_path', rootProjectDir],
        { cwd: rootProjectDir }
      ]
    )
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
}

