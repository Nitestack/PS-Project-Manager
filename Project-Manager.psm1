# Project Manager
$project_base_path_env = "PROJECT_MANAGER_BASE_PATH"
$sub_dirs_env = "PROJECT_MANAGER_SUB_DIRS"

# TODOS
# - when adding sub directories, check whether the sub directory exists already 
# - add path resolver (like replacing slashes, etc.)
#
# - reduce code duplication

Set-Alias pm Open-Project
Set-Alias pm-edit Edit-BaseProjectPath
Set-Alias pm-create Import-Project
Set-Alias pm-delete Remove-Project
Set-Alias pm-add Add-SubDir
Set-Alias pm-remove Remove-SubDir

function Confirm-PathExists([string]$path)
{
  # Check if path doesn't exist 
  if (!(Test-Path $path))
  {
    mkdir $path
  }
}

function Get-BaseProjectPath()
{
  $project_base_path = [System.Environment]::GetEnvironmentVariable($project_base_path_env, [System.EnvironmentVariableTarget]::User)

  # If it doesn't exist, create it
  if ($null -eq $project_base_path)
  {
    $initial_value = Read-Host -Prompt "Enter the base project path (relative to '$env:USERPROFILE')"
    # If the string is empty, close prompt
    if ([string]::IsNullOrEmpty($initial_value)) 
    {
      Write-Host "Cancelled!"
      break
    }

    $resolved_value = Join-Path $env:USERPROFILE $initial_value

    [System.Environment]::SetEnvironmentVariable($project_base_path_env, $resolved_value, [System.EnvironmentVariableTarget]::User)

    Write-Host "Created non-existing user environment variable '$project_base_path_env' ..."

    return $resolved_value
  } else
  {
    return $project_base_path
  }
}

function Get-SubDirs()
{
  $envValue = [System.Environment]::GetEnvironmentVariable($sub_dirs_env, [System.EnvironmentVariableTarget]::User)

  $project_base_path = Get-BaseProjectPath
  
  $unresolved_array = @()
  
  # If it doesn't exist, create it
  if ($null -eq $envValue)
  {
    $one_sub_dir = Read-Host -Prompt "Enter a sub directory (relative to '$project_base_path')"
    # If the string is empty, close prompt
    if ([string]::IsNullOrEmpty($one_sub_dir)) 
    {
      Write-Host "Cancelled!"
      break
    }

    Confirm-PathExists $(Join-Path $project_base_path $one_sub_dir)

    $initial_value = @($one_sub_dir)

    [System.Environment]::SetEnvironmentVariable($sub_dirs_env, $initial_value -join ",", [System.EnvironmentVariableTarget]::User)

    $unresolved_array = $initial_value

    Write-Host "Created non-existing user environment variable "$sub_dirs_env" ..."
  } else
  {
    $unresolved_array = $envValue -split ","
  }

  # Resolve to an array
  if ($unresolved_array.GetType().Name -eq "String")
  {
    return @($unresolved_array)
  } else
  {
    return $unresolved_array
  }
}

function Select-Project()
{
  $resolved_paths = $(Get-SubDirs) | ForEach-Object { Join-Path $(Get-BaseProjectPath) $_ }

  $projects = @()
  foreach ($path in $resolved_paths)
  {
    # Use Get-ChildItem to get directories in each path
    $directories = Get-ChildItem -Path $path -Directory
    
    # Extract and store the directory names in the array
    foreach ($directory in $directories)
    {
      # Check if the project path is not in $resolved_paths
      if ($resolved_paths -notcontains $directory.FullName)
      {
        $projects += $directory.FullName
      }
    }
  }

  $selected_project = $projects | fzf --prompt=" Select project  " --height=~50% --layout=reverse --border --exit-0

  if ([string]::IsNullOrEmpty($selected_project))
  {
    Write-Host "Cancelled!"
    break
  }

  return $selected_project
}

function Open-Project()
{
  Set-Location $(Select-Project)
  nvim.exe
}

function Import-Project()
{
  $resolved_paths = $(Get-SubDirs) | ForEach-Object { Join-Path $(Get-BaseProjectPath) $_ }

  $project_dir_name = Read-Host -Prompt "Enter the project directory name"
  # If the string is empty, close prompt
  if ([string]::IsNullOrEmpty($project_dir_name))
  {
    Write-Host "Cancelled!"
    break
  }

  $select_sub_dir = $resolved_paths | fzf --prompt=" Select sub directory  " --height=~50% --layout=reverse --border --exit-0
  # If the string is empty, close prompt
  if ([string]::IsNullOrEmpty($select_sub_dir))
  {
    Write-Host "Cancelled!"
    break
  }

  $project_path = Join-Path $select_sub_dir $project_dir_name

  mkdir $project_path

  Set-Location $project_path
  Write-Host "Going to '$project_path' ..."
}

function Remove-Project()
{
  $selected_project = Select-Project

  Remove-Item -r -Force $selected_project

  Write-Host "Successfully removed '$selected_project'!"
}

function Add-SubDirEnv([string]$sub_dir)
{
  $arrayValue = @(Get-SubDirs)
  $arrayValue += $sub_dir

  [System.Environment]::SetEnvironmentVariable($sub_dirs_env, $arrayValue -join ",", [System.EnvironmentVariableTarget]::User)

  Write-Host "Added '$sub_dir' to user environment variable ..."
}

function Add-SubDir() 
{
  $project_base_path = Get-BaseProjectPath

  $new_sub_dir = Read-Host -Prompt "Enter a new sub directory (relative to '$project_base_path')"
  # If the string is empty, close prompt
  if ([string]::IsNullOrEmpty($new_sub_dir))
  {
    Write-Host "Cancelled!"
    break
  }

  Confirm-PathExists $(Join-Path $project_base_path $new_sub_dir)

  Add-SubDirEnv $new_sub_dir

  Write-Host "Successfully added '$new_sub_dir' as a sub directory!"
}

function Remove-SubDirEnv([string]$sub_dir) 
{

  $arrayValue = @(Get-SubDirs)
  $arrayValue += $sub_dir

  $arrayValue = $arrayValue | Where-Object { $_ -ne $sub_dir }

  [System.Environment]::SetEnvironmentVariable($sub_dirs_env, $arrayValue -join ",", [System.EnvironmentVariableTarget]::User)

  Write-Host "Removed '$sub_dir' from user environment variable ..."
}

function Remove-SubDir()
{
  $resolved_paths = $(Get-SubDirs) | ForEach-Object { Join-Path $(Get-BaseProjectPath) $_ }

  $sub_dir = $resolved_paths | fzf --prompt=" Select sub directory  " --height=~50% --layout=reverse --border --exit-0
  # If the string is empty, close prompt
  if ([string]::IsNullOrEmpty($sub_dir))
  {
    Write-Host "Cancelled!"
    break
  }

  # Get relative path from base project path and remove beginning backslash
  $sub_dir = Split-Path -Path $sub_dir -Leaf -Resolve

  Remove-SubDirEnv $sub_dir

  Write-Host "Successfully removed '$sub_dir' as a sub directory (directory was not deleted)!"
}

function Edit-BaseProjectPathEnv([string]$new_base_project_path)
{
  [System.Environment]::SetEnvironmentVariable($project_base_path_env, $new_base_project_path, [System.EnvironmentVariableTarget]::User)

  Write-Host "Changed user environment variable to '$new_base_project_path' ..."
}

function Edit-BaseProjectPath()
{
  $new_base_project_dir = Read-Host -Prompt "Enter a new base project path (relative to '$env:USERPROFILE')"
  # If the string is empty, close prompt
  if ([string]::IsNullOrEmpty($new_base_project_dir))
  {
    Write-Host "Cancelled!"
    break
  }

  $new_base_project_path = Join-Path $env:USERPROFILE $new_base_project_dir

  Confirm-PathExists $new_base_project_path

  Edit-BaseProjectPathEnv $new_base_project_path

  Write-Host "Successfully changed the base project path to '$new_base_project_path'!"
}

Export-ModuleMember -Alias * -Function Open-Project, Import-Project, Remove-Project, Add-SubDir, Remove-SubDir, Edit-BaseProjectPath






