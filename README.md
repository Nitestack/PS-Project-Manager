# Project-Manager

Project manager is a PowerShell module that helps you manage your projects by fuzzy finding your project files.
It's using fzf as the fuzzy finder.

## 🛠️ Installation

### Windows (Powershell)

#### Clone the repository

```pwsh
git clone --depth 1 https://github.com/Nitestack/Project-Manager $env:USERPROFILE\Documents\PowerShell\Modules\Project-Manager
```

#### Include it in your PowerShell config:

```pwsh
Import-Module Project-Manager
```

## 📖 Documentation

### Commands

- `pm`: fuzzy find your projects under the projects base path and specified sub directories
  - the fuzzy finder will look one level deep into the sub directories to find your projects
- `pm-edit`: edit the projects base path (relative to your user home directory)
- `pm-new`: create a new project
- `pm-delete`: delete a project
- `pm-add`: add a sub directory (relative to your projects base path)
- `pm-remove`: remove a sub directory (relative to your projects base path)
