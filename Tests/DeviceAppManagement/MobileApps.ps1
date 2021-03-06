# POST some apps
$numApps = 5
Write-Host "Creating $numApps web apps..."
$newApps = (1..$numApps | ForEach-Object {
    New-DeviceAppManagement_MobileApps -webApp -displayName 'My new app' -publisher 'Test web app' -appUrl 'https://www.bing.com'
})

# SEARCH all web apps and make sure these all exist
Write-Host "Searching for all web apps and validating that the ones we created exist..."
$searchedApps = Get-DeviceAppManagement_MobileApps -Filter "isof('microsoft.graph.webApp')"
$ids = $newApps.id
$filteredApps = $searchedApps | Where-Object { $ids -Contains $_.id }
if ($filteredApps.Count -ne $newApps.Count)
{
    throw "Failed to create some web apps"
}

# PATCH all apps
$newAppName = 'Bing'
Write-Host "Updating the name of the created web apps to '$newAppName'..."
$newApps | Update-DeviceAppManagement_MobileApps -displayName $newAppName

# Batch GET apps (with PowerShell pipeline)
Write-Host "Retrieving the updated apps with the PowerShell pipeline..."
$updatedApps = $newApps | Get-DeviceAppManagement_MobileApps -Select id, displayName
$updatedApps | ForEach-Object {
    if ($_.displayName -ne $newAppName) {
        throw "Failed to update some web apps"
    }
}

# Batch DELETE apps (with PowerShell pipeline)
Write-Host "Deleting the updated apps with the PowerShell pipeline..."
$updatedApps | Remove-DeviceAppManagement_MobileApps

# SEARCH all app categories
Write-Host "Getting all app categories..."
Get-DeviceAppManagement_MobileAppCategories | Out-Null

# Create a custom category
Write-Host "Creating a new app category..."
$appCategory = New-DeviceAppManagement_MobileAppCategories -displayName 'Test Category'

# SEARCH all apps
Write-Host "Getting all apps..."
$allApps = Get-DeviceAppManagement_MobileApps

# Create a reference between an app and the custom category
Write-Host "Creating a reference between an app and the new category..."
$app = $allApps[0]
$appCategory | New-DeviceAppManagement_MobileApps_CategoriesReferences -mobileAppId $app.id

# Get the referenced categories on this app
Write-Host "Getting the app with categories and assignments expanded..."
$app = $app | Get-DeviceAppManagement_MobileApps -Expand assignments, categories

# DELETE the reference
Write-Host "Removing the reference between the app and the category"
$appCategory | Remove-DeviceAppManagement_MobileApps_CategoriesReferences -mobileAppId $app.id

# DELETE the category
Write-Host "Deleting the category"
$appCategory | Remove-DeviceAppManagement_MobileAppCategories

# Run some paging commands
Write-Host "Testing paging..."
$firstPage = Get-DeviceAppManagement_MobileApps -Top ($allApps.Count / 3)
$firstPage | Get-MSGraphNextPage | Out-Null
$allPagedApps = $firstPage | Get-MSGraphAllPages
if ($allPagedApps.Count -eq 0) {
    throw "Paging returned no apps"
}
Write-Host "Found $($allPagedApps.Count) apps"

Write-Host "Testing the pipeline..." -NoNewline
$success = $false
try {
    Get-DeviceAppManagement_MobileApps | Select-Object -First 1 | Out-Null

    # The script won't reach this line if the pipeline is not ended gracefully
    $success = $true
} finally {
    if ($success) {
        Write-Host "Done"
    } else {
        Write-Host "Failed" -ForegroundColor Red
        throw "Pipeline did not end gracefully"
    }
}
