param($rootMS,$groupName,$numberOfHoursInMaintenanceMode,$comment)

Add-PSSnapin "Microsoft.EnterpriseManagement.OperationsManager.Client" -ErrorVariable errSnapin;
Set-Location "OperationsManagerMonitoring::" -ErrorVariable errSnapin;
new-managementGroupConnection -ConnectionString:$rootMS -ErrorVariable errSnapin;
set-location $rootMS -ErrorVariable errSnapin;

$groupObject = get-monitoringobject | where {$_.DisplayName -eq $groupName};  
$groupagents = $groupObject.getrelatedmonitoringobjects()

foreach ($agent in $groupAgents)

{

$computerPrincipalName = $agent.displayname

$computerClass = get-monitoringclass -name:Microsoft.Windows.Computer
$healthServiceClass = get-monitoringclass -name:Microsoft.SystemCenter.HealthService
$healthServiceWatcherClass = get-monitoringclass -name:Microsoft.SystemCenter.HealthServiceWatcher

$computerCriteria = "PrincipalName='" + $computerPrincipalName + "'"
$computer = get-monitoringobject -monitoringclass:$computerClass -criteria:$computerCriteria
$healthServices = $computer.GetRelatedMonitoringObjects($healthServiceClass)
$healthService = $healthServices[0]

$healthServiceCriteria = "HealthServiceName='" + $computerPrincipalName + "'"
$healthServiceWatcher = get-monitoringobject -monitoringclass:$healthServiceWatcherClass -criteria:$healthServiceCriteria
$startTime = [System.DateTime]::Now
$endTime = $startTime.AddHours($numberOfHoursInMaintenanceMode)
 


"Putting " + $computerPrincipalName + " into maintenance mode"
New-MaintenanceWindow -startTime:$startTime -endTime:$endTime -monitoringObject:$computer -comment:$comment


"Putting the associated health service into maintenance mode"
New-MaintenanceWindow -startTime:$startTime -endTime:$endTime -monitoringObject:$healthService -comment:$comment


"Putting the associated health service watcher into maintenance mode"
New-MaintenanceWindow -startTime:$startTime -endTime:$endTime -monitoringObject:$healthServiceWatcher -comment:$comment

}

