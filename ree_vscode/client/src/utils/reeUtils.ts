const childProcess = require('child_process')
const vscode = require('vscode')

export interface ExecCommand {
  message: string
  code: number
}

export function isReeInstalled(projectDir: string): Promise<ExecCommand> | undefined {
  try {
    let rootProjectDir = projectDir
    const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
    const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

    if (dockerPresented) { 
      return spawnCommand([
        'docker', [
          'exec',
          '-i',
          '-e',
          'REE_SKIP_ENV_VARS_CHECK=true',
          '-w',
          appDirectory,
          containerName,
          'bundle',
          'show',
          'ree'
        ]
      ])
    } else {
      return spawnCommand(['which', ['ree'], { cwd: rootProjectDir }])
    }
  } catch(e) {
    vscode.window.errorInformationMessage(`Error. ${e}`)
    return
  }
}

export function isBundleGemsInstalled(projectDir: string): Promise<ExecCommand> | undefined {
  try {
    return spawnCommand(['bundle', ['show', 'ree'], { cwd: projectDir }])
  } catch(e) {
    vscode.window.errorInformationMessage(`Error. ${e}`)
    return
  }
}

export function isBundleGemsInstalledInDocker(): Promise<ExecCommand> | undefined {
  try {
    const dockerPresented = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('presented') as boolean
    const containerName = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('containerName') as string
    const appDirectory = vscode.workspace.getConfiguration('reeLanguageServer.docker').get('appDirectory') as string

    if (dockerPresented) {
      const rootProjectDir = appDirectory
      return spawnCommand([
        'docker', [
          'exec',
          '-i',
          '-e',
          'REE_SKIP_ENV_VARS_CHECK=true',
          '-w',
          rootProjectDir,
          containerName,
          'bundle',
          'show',
          'ree'
        ]
      ])
    }
  } catch(e) {
    vscode.window.errorInformationMessage(`Error. ${e}`)
    return
  }
}

export async function spawnCommand(args): Promise<ExecCommand | undefined> {
  try {
    let spawn = require('child_process').spawn
    const child = spawn(...args)
    let message = ''

    for await (const chunk of child.stdout) {
      message += chunk
    }

    for await (const chunk of child.stderr) {
      message += chunk
    }

    const code: number  = await new Promise( (resolve, reject) => {
      child.on('close', resolve);
    })

    return {
      message: message,
      code: code
    }
  } catch(e) {
    vscode.window.showErrorMessage(`Error. ${e}`)
    return undefined
  }
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

export function genPackageSchemaJsonCommandArgsArray(projectDir: string, name?: string) {
  if (name) { return ['gen.package_json', name.toString(), '--project_path', projectDir, '--trace'] }
  
  return  ['gen.package_json', '--project_path', projectDir, '--trace']
}

export function genObjectSchemaJsonCommandArgsArray(projectDir: string, packageName: string, objectPath: string) {
  return  ['gen.schema_json', packageName, objectPath, '--project_path', projectDir, '--trace']
}