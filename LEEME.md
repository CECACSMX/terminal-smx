# Terminal SMX

Personaliza la terminal de PowerShell con **Oh My Posh**, una fuente con iconos y un **banner con tu nombre**.
No hace falta ser administrador: todo se instala solo para tu usuario.

## Qué hace

| Paso | Qué ocurre |
|---|---|
| 1 | Te pregunta el nombre del banner, el tema y el color, y te enseña una vista previa. |
| 2 | Instala Oh My Posh con `winget`, el gestor de paquetes de Windows. |
| 3 | Copia el tema oficial elegido a `%USERPROFILE%\.terminal-smx` y guarda el banner. |
| 4 | Instala la fuente **MesloLGM Nerd Font** con `oh-my-posh font install`. |
| 5 | Descarga **Terminal-Icons** (versión fija y comprobada con SHA-256): colores e iconos al listar con `ls` o `dir`, y la ruta de la carpeta en el color del banner. |
| 6 | Pone esa fuente por defecto en Windows Terminal (guarda antes `settings.json.bak-smx`). |
| 7 | Cambia la política de ejecución a `RemoteSigned` para tu usuario, si hace falta. |
| 8 | Añade un bloque a tu perfil de PowerShell 5.1 y 7 (guarda antes una copia `.bak-fecha`). |

## Cómo instalarlo

### Opción A: carpeta (recomendada)

1. Copia la carpeta `Terminal-SMX` entera a tu equipo, o descárgala de GitHub
   (*Code → Download ZIP*) y **descomprímela** antes de seguir.
2. Doble clic en **`INSTALAR.bat`**.
3. Si Windows avisa con «Windows protegió su PC», pulsa *Más información → Ejecutar de todas formas*.
4. Responde a las preguntas y, al terminar, abre **Windows Terminal**.

### Opción B: una sola línea desde internet

Abre PowerShell y pega:

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/CECACSMX/terminal-smx/main/Instalar-Terminal.ps1')))
```

Antes de ejecutar algo descargado de internet, **léelo**: esa línea ejecuta lo que haya en esa dirección en ese momento.

## Opciones sin preguntas

```powershell
.\Instalar-Terminal.ps1 -Nombre "Marta" -Tema dracula -Color Magenta
```

- `-Nombre`: letras, números, espacios, guion, punto y guion bajo. Las tildes se quitan; la eñe se respeta.
- `-Tema`: cualquier tema oficial de Oh My Posh. Catálogo con capturas: <https://ohmyposh.dev/docs/themes>
- `-Color`: `Cyan`, `Green`, `Magenta`, `Yellow`, `Blue`, `Red` o `White`.
- `-Prueba`: no instala nada; escribe todo en `%TEMP%\terminal-smx-prueba` para revisarlo.

Con la opción B, los parámetros van al final: `& ([scriptblock]::Create((irm '...'))) -Nombre "Marta"`.

## Cambiar el nombre, el tema o el color

Vuelve a ejecutar `INSTALAR.bat`. Sustituye el bloque anterior; no lo duplica.

## Desinstalar

Doble clic en **`DESINSTALAR.bat`**. Quita el bloque de los perfiles y la carpeta `.terminal-smx`.
Oh My Posh y la fuente siguen instalados; para quitarlos:

```powershell
winget uninstall JanDeDobbeleer.OhMyPosh
```

## Qué archivos toca

| Archivo | Cambio |
|---|---|
| `%USERPROFILE%\.terminal-smx\` | Carpeta nueva: `tema.omp.json`, `banner.txt`, `config.json` y `modulos\Terminal-Icons` |
| `%APPDATA%\powershell\Community\Terminal-Icons\` | Preferencias que crea Terminal-Icons la primera vez que se carga |
| `Documentos\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` | Bloque entre `# >>> TERMINAL SMX >>>` y `# <<< TERMINAL SMX <<<` |
| `Documentos\PowerShell\Microsoft.PowerShell_profile.ps1` | El mismo bloque, para PowerShell 7 |
| `settings.json` de Windows Terminal | `profiles.defaults.font.face` |

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| Los iconos salen como cuadrados | La pestaña tiene otra fuente. En Windows Terminal: *Configuración → perfil → Apariencia → Tipo de fuente → MesloLGM Nerd Font*. |
| `ls` sale sin colores | Terminal-Icons no se pudo descargar (sin internet o bloqueado por el centro). Vuelve a ejecutar el instalador. |
| «No encuentro winget» | Actualiza «Instalador de aplicación» desde Microsoft Store. |
| No se ve el banner al abrir la terminal | La política de ejecución está bloqueada por el centro. Comprueba con `Get-ExecutionPolicy -List`. |
| El banner se parte en trozos | La ventana es estrecha: ensánchala o usa un nombre más corto. |

## Para investigar

1. Abre tu perfil con `notepad $PROFILE`. ¿Qué hace cada línea del bloque TERMINAL SMX?
2. ¿Por qué el script configura dos perfiles distintos?
3. ¿Qué diferencia hay entre las políticas `Restricted`, `RemoteSigned` y `Bypass`? ¿Protegen de verdad contra un script malicioso?
4. Busca en `Instalar-Terminal.ps1` la tabla `$Letras` y añade un carácter nuevo, por ejemplo `!`.
5. ¿Por qué es arriesgado pegar en la terminal un `irm ... | iex` que no has leído?
6. El script comprueba la huella SHA-256 de Terminal-Icons antes de instalarlo. ¿Qué es una huella (hash)? Calcula la de un archivo con `Get-FileHash`, cambia una letra y vuelve a calcularla.
