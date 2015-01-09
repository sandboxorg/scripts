function Get-BasicInfoChange
{

$files = Get-ChildItem *.log


$processingBlock = $False 
$usnBlock = $False


foreach ($file in $files) 
{ 
    $content = Get-Content $file 
    foreach ($line in $content) 
    { 
        if (!($line.ToString().Contains("+"))) 
        { 
            $outLine = $line 
            $processingBlock = $True 
        } 
        if ($processingBlock) 
        { 
            if ($line.ToString().Contains("+	USN_RECORD:")) 
            { 
                $usnBlock = $True 
            } 
        } 
        if ($usnBlock) 
        { 
            if ($line.ToString().Contains("+	Reason:              Basic Info Change Close")) 
            { 
                $outLine.ToString() 
                $processingBlock = $False 
                $usnBlock = $False 
            } 
        } 
    } 
}

}