# General variables
$computer = get-content env:computername
$cw = "C:\dev\Sites\CorporationWiki"
$shoki = "C:\dev\Sites\Shoki"
$scripts = "C:\Users\Justin\Documents\WindowsPowerShell"
$sites = "C:\dev\Sites"

# directory variables

function ReadyEnvironment ([string]$userName, [string]$computerName)
{
    set-variable scripts $scripts -scope 1
    set-variable desktop "C:\Users\$userName\DESKTOP" -scope 1
    Write-Host "Setting environment for $computerName" -foregroundcolor cyan
}

ReadyEnvironment "Justin" $computer ;
 
# Add Git executables to the mix.
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";" + "\Utils\Git\bin", "Process")

# Add our scripts directory in the mix.
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";" + $scripts, "Process")
 
# Setup Home so that Git doesn't freak out.
[System.Environment]::SetEnvironmentVariable("HOME", (Join-Path $Env:HomeDrive $Env:HomePath), "Process")

function prompt {
    
    Write-Host("")
    $status_string = ""
    # check to see if this is a directory containing a symbolic reference, 
    # fails (gracefully) on non-git repos.
    $symbolicref = git symbolic-ref HEAD
    if($symbolicref -ne $NULL) {
        
        # if a symbolic reference exists, snag the last bit as our
        # branch name. eg "[master]"
        $status_string += "[" + `
            $symbolicref.substring($symbolicref.LastIndexOf("/") +1) + "] "
        
        # grab the differences in this branch    
        $differences = (git diff-index --name-status HEAD)
        
        # use a regular expression to count up the differences.
        # M`t, A`t, and D`t refer to M {tab}, etc.
        # $git_update_count = [regex]::matches($differences, “M`t”).count
        # $git_create_count = [regex]::matches($differences, “A`t”).count
        # $git_delete_count = [regex]::matches($differences, “D`t”).count
       
        # place those variables into our string.
        # $status_string += “c:” + $git_create_count + `
        #    ” u:” + $git_update_count + `
        #    ” d:” + $git_delete_count + ” | “
        
                
        $git_change_count = [regex]::matches($differences, "M`t").count
        $git_change_count += [regex]::matches($differences, "A`t").count
        $git_change_count += [regex]::matches($differences, "D`t").count
    }
    else {
        # Not in a Git environment, must be PowerShell!
        # $status_string = "PS "
    }
    
    # write out the status_string with the approprate color. 
    # prompt is done!
    if ($status_string.StartsWith("[")) {
        Write-Host $(get-location) "" -nonewline -foregroundcolor yellow
  
        # see if we're on a clean branch
        if ($git_change_count -eq 0) {
          Write-Host $status_string -nonewline -foregroundcolor darkgreen
        } 
        else {
          Write-Host $status_string -nonewline -foregroundcolor red
        }
        
        Write-Host "$" -nonewline -foregroundcolor yellow
    }
    else {
        Write-Host ($status_string + $(get-location) + " $") `
            -nonewline -foregroundcolor yellow
    }
    return " "
 }
 
# set common aliases
# find-to-set-alias 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE' devenv.exe vs
# find-to-set-alias 'c:\windows\system32\WindowsPowerShell\v1.0\' PowerShell_ISE.exe psise
# find-to-set-alias 'c:\Utils\Notepad2' Notepad2.exe np
# find-to-set-alias 'C:\Utils\Emacs\bin' runemacs.exe emacs
 
set-alias ai assembly-info
 
# creating a function since set-alias can't pass piped parameters
function aia {
    get-childitem | ?{ $_.extension -eq ".dll" } | %{ ai $_ }
}
 
function dc {
    git diff | out-colordiff
}
 
remove-item alias:ls
set-alias ls Get-ChildItemColor
 
function Get-ChildItemColor {
    $fore = $Host.UI.RawUI.ForegroundColor
 
    Invoke-Expression ("Get-ChildItem $args") |
    %{
      if ($_.GetType().Name -eq 'DirectoryInfo') {
        $Host.UI.RawUI.ForegroundColor = 'Gray'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(zip|tar|gz|rar)$') {
        $Host.UI.RawUI.ForegroundColor = 'Blue'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$') {
        $Host.UI.RawUI.ForegroundColor = 'Green'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(txt|cfg|conf|ini|csv|sql|xml|config)$') {
        $Host.UI.RawUI.ForegroundColor = 'Cyan'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
      } elseif ($_.Name -match '\.(cs|asax|aspx.cs)$') {
        $Host.UI.RawUI.ForegroundColor = 'Yellow'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
       } elseif ($_.Name -match '\.(aspx|spark|master)$') {
        $Host.UI.RawUI.ForegroundColor = 'DarkYellow'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
       } elseif ($_.Name -match '\.(sln|csproj)$') {
        $Host.UI.RawUI.ForegroundColor = 'Magenta'
        echo $_
        $Host.UI.RawUI.ForegroundColor = $fore
       }
        else {
        $Host.UI.RawUI.ForegroundColor = $fore
        echo $_
      }
    }
}
 
# Use VS to either open the passed solution or the first (only) solution in the
# current directory.

function vsh {
    param ($param)
    
    if ($param -eq $NULL) {
        "A solution was not specified, opening the first one found."
        $solutions = get-childitem | ?{ $_.extension -eq ".sln" }
    }
    else {
        "Opening {0} ..." -f $param
        vs $param
        break
    }
    if ($solutions.count -gt 1) {
        "Opening {0} ..." -f $solutions[0].Name
        vs $solutions[0].Name
    }
    else {
        "Opening {0} ..." -f $solutions.Name
        vs $solutions.Name
    }
}

# GIT commands
function gs { git status }
function ga { git add . }

function gco {
  git checkout $args
} 

function gca {
  git commit -am $args
}

function gb {
  git branch $args
}

function deploy {
  git checkout -b release
  git push origin release
  git checkout dev
  git branch -d release
}

function TabExpansion($line, $lastWord) {
  $LineBlocks = [regex]::Split($line, '[|;]')
  $lastBlock = $LineBlocks[-1] 
 
  switch -regex ($lastBlock) {
    '(gb|gco|gm|git push|git pull) (.*)' { gitTabExpansion($lastBlock) }
  }
}

function gitTabExpansion($lastBlock) {
     switch -regex ($lastBlock) {
 
        #Handles git branch -x -y -z <branch name>
        'gb -(d|D) (\S*)$' {
          gitLocalBranches($matches[2])
        }
 
        #handles git checkout <branch name>
        #handles git merge <brancj name>
        '(gco|gm) (\S*)$' {
          gitLocalBranches($matches[2])
        }
 
        #handles git <cmd>
        #handles git help <cmd>
        'git (help )?(\S*)$' {      
          gitCommands($matches[2])
        }
 
        #handles git push remote <branch>
        #handles git pull remote <branch>
        'git (push|pull) (\S+) (\S*)$' {
          gitLocalBranches($matches[3])
        }
 
        #handles git pull <remote>
        #handles git push <remote>
        'git (push|pull) (\S*)$' {
          gitRemotes($matches[2])
        }
    }	
}

function gitCommands($filter) {
  $cmdList = @()
  $output = git help
  foreach($line in $output) {
    if($line -match '^   (\S+) (.*)') {
      $cmd = $matches[1]
      if($filter -and $cmd.StartsWith($filter)) {
        $cmdList += $cmd.Trim()
      }
      elseif(-not $filter) {
        $cmdList += $cmd.Trim()
      }
    }
  }
 
  $cmdList | sort
 }
 
function gitRemotes($filter) {
  if($filter) {
    git remote | where { $_.StartsWith($filter) }
  }
  else {
    git remote
  }
}
 
function gitLocalBranches($filter) {
   git branch | foreach { 
      if($_ -match "^\*?\s*(.*)") { 
        if($filter -and $matches[1].StartsWith($filter)) {
          $matches[1]
        }
        elseif(-not $filter) {
          $matches[1]
        }
      } 
   }
}

function touch { 
    New-Item  -ItemType file  -Name $args[0]  
}

# program aliases

function view {
  C:\Windows\explorer.exe $args
}

function emacs {
  C:\Utils\Emacs\bin\runemacs.exe $args
}

function np {
  c:\Utils\Notepad2\Notepad2.exe $args
}