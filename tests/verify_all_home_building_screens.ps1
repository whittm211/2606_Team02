$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mainVillage = Get-Content -Raw -Path (Join-Path $root "scripts\main_village.gd")
$buildingsPanel = Get-Content -Raw -Path (Join-Path $root "scripts\buildings_panel.gd")

$requiredFiles = @(
    "ui\AncientTreePanel.tscn",
    "ui\ArcaneForgePanel.tscn",
    "ui\MarketStallPanel.tscn",
    "scripts\simple_building_panel.gd"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path $path)) {
        throw "Missing required file: $file"
    }
}

$requiredMainVillageText = @(
    "AncientTreePanelScene",
    "ArcaneForgePanelScene",
    "MarketStallPanelScene",
    "_open_ancient_tree",
    "_open_arcane_forge",
    "_open_market_stall",
    "_show_panel(AncientTreePanelScene.instantiate())",
    "_show_panel(ArcaneForgePanelScene.instantiate())",
    "_show_panel(MarketStallPanelScene.instantiate())"
)

foreach ($text in $requiredMainVillageText) {
    if (-not $mainVillage.Contains($text)) {
        throw "main_village.gd is missing: $text"
    }
}

if (-not ($mainVillage.Contains("_add_placeholder_area_button(`"Ancient Tree`"") -or $mainVillage.Contains("_add_landmark_hit_button(`"Ancient Tree`""))) {
    throw "main_village.gd is missing an Ancient Tree hit button"
}

if (-not ($mainVillage.Contains("_add_placeholder_area_button(`"Market Stall`"") -or $mainVillage.Contains("_add_area_button(`"Market Stall`""))) {
    throw "main_village.gd is missing a Market Stall hit button"
}

$requiredBuildingsText = @(
    "`"Ancient Tree`"",
    "`"Market Stall`"",
    "`"Arcane Forge`"",
    "Restore the grove heart and claim restoration rewards.",
    "Trade resources for Coins and reputation.",
    "Forge permanent upgrades for production, potions, and pond restoration."
)

foreach ($text in $requiredBuildingsText) {
    if (-not $buildingsPanel.Contains($text)) {
        throw "buildings_panel.gd is missing: $text"
    }
}

Write-Host "All visible home buildings have clickable screens wired."
