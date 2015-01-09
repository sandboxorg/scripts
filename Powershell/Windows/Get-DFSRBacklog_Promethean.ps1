<#

.SYNOPSIS

Retrieves DFSR backlog information for all Replication Groups and Connections from the perspective of the targeted server.

.DESCRIPTION

The Get-DFSRBacklog script uses Windows Management Instrumentation (WMI) to retrieve Replication Groups, Replication Folders, and Connections from the targeted computer.  
 
The script then uses this information along with MicrosoftDFS WMI methods to calculate the version vector and in turn backlog for each pairing. 
 
All of this information is returned in an array custom objects, that can be later processed as needed. 
 
The computername defaults to "localhost", or may be passed to the –computerName parameter. 
 
The parameters -RGName and -RFName may also be used to filter either or both results, but currently each parameter only accepts one single value. 
 
Checking multiple replication groups/folders will require either running the script again, or using the default to return all pairings. 

#>

$DebugPreference = "SilentlyContinue"

Function Get-DFSRGroup
{
  ### Query DFSR groups from root\MicrosoftDFS namespace ###
  $WMIQuery = "SELECT * FROM DfsrReplicationGroupConfig"
  $WMIObject = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query $WMIQuery
  Write-Output $WMIObject
}

Function Get-DFSRConnections
{
  ### Query DFSR connections from root\MicrosoftDFS namespace ###
  $WMIQuery = "SELECT * FROM DfsrConnectionConfig"
  $WMIObject = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query $WMIQuery
  Write-Output $WMIObject
}

Function Get-DFSRFolder
{
  ### Query DFSR folders from root\MicrosoftDFS namespace ###
  $WMIQuery = "SELECT * FROM DfsrReplicatedFolderConfig"
  $WMIObject = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query $WMIQuery
  Write-Output $WMIObject
}

Function Get-DFSRBacklogInfo ($RGroups, $RConnections, $RFolders)
{
  $results = @()
  
  Foreach ($group in $RGroups)
  {
    $ReplicationGroupName = $group.ReplicationGroupName
    $ReplicationGroupGUID = $group.ReplicationGroupGUID

    Foreach ($folder in $RFolders)
    {
      If ($folder.ReplicationGroupGUID -eq $ReplicationGroupGUID)
      {
        $ReplicatedFolderName = $folder.ReplicatedFolderName
        $FolderEnabled = $folder.Enabled

        Foreach ($connection in $RConnections)
        {
          If ($connection.ReplicationGroupGUID -eq $ReplicationGroupGUID)
          {
            $BacklogCount = $null
            $connectionEnabled = $connection.Enabled

            If ($FolderEnabled)
            {
              If ($connectionEnabled)
              {
                If ($connection.Inbound)
                {
                  $Sendmem = $connection.PartnerName.Trim()
                  $Recvmem = "localhost"

                  ### Get version vector of inbound partner ###
                  $WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'"
                  $InboundWMI = Get-WmiObject -ComputerName $Recvmem -Namespace "root\MicrosoftDFS" -Query $WMIQuery

                  $VVector = $InboundWMI.GetVersionVector().VersionVector

                  ### Get backlog count from outbound partner ###
                  $WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $ReplicatedFolderName + "'"
                  $OutboundWMI = Get-WmiObject -ComputerName $Sendmem -Namespace "root\MicrosoftDFS" -Query $WMIQuery
                  $BacklogCount = $OutboundWMI.GetOutboundBacklogFileCount($VVector).BacklogFileCount

                  If ($BacklogCount -eq 0)
                  {
                    Write-Output $results
                  } 
                  Else 
                  {
                    $Output = "Host: $Sendmem has $BacklogCount Back logged files for DFS Folder $ReplicationGroupName"
                    $results += $Output
                    Write-Output $results
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

$RGroups = Get-DFSRGroup
$RConnections = Get-DFSRConnections
$RFolders = Get-DFSRFolder

$Info = Get-DFSRBacklogInfo $RGroups $RConnections $RFolders

If ($Info -eq $null)
{
  Write-Output "No back logged files"
  exit 0
}
Else
{
  Write-Output $info
  exit 2
}