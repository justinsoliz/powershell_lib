# Add Git executables to the mix.
[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";" + "\Utils\Git\bin", "Process")

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
        
                
        $git_change_count = [regex]::matches($differences, "M`t").count
        $git_change_count += [regex]::matches($differences, "A`t").count
        $git_change_count += [regex]::matches($differences, "D`t").count
    }
    else {
        # Not in a Git environment, must be PowerShell!
        $status_string = "PS "
    }
    
    # write out the status_string with the approprate color. 
    # prompt is done!
    if ($status_string.StartsWith("[")) {
        Write-Host $(get-location) "" -nonewline -foregroundcolor white
  
        # see if we're on a clean branch
        if ($git_change_count -eq 0) {
          Write-Host $status_string -nonewline -foregroundcolor darkgreen
        } 
        else {
          Write-Host $status_string -nonewline -foregroundcolor red
        }
        
        Write-Host "$" -nonewline -foregroundcolor white
    }
    else {
        Write-Host ($status_string + $(get-location) + " $") `
            -nonewline -foregroundcolor white
    }
    return " "
 }