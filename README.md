# FiveM Territories System

A territory control system for FiveM servers. Gangs can capture and hold territories for rewards and ranking points.

## Features

-   **Multiple territory types**: Selling markets, buying markets, or basic stash territories
-   **Real-time sync**: Territory captures and status updates are synced across all players
-   **Optimized performance**: Minimal resource usage when not near territories
-   **Ranking system**: +3 points for capturing, -2 for losing territories. Weekly and monthly leaderboards
-   **Gang rewards**: All active gang members get rewards after capturing a territory
-   **In-game management**: Create and delete territories without restarting the server
-   **Territory overview**: Use `/territories` command to see all territories and their status
-   **Configurable**: Easy to customize gangs, jobs, and blip colors
-   **Built-in stash**: Every territory has a stash using ox_inventory

## Preview

-   [Video Preview](https://streamable.com/ephnae)
-   [Resource Monitor](https://imgur.com/89Rre8n)

## Installation

Drop it in your resources folder and configure the gangs/jobs in the config file.

## Notes

-   This is a really old, but still very functional and performant.
-   Heavily relying on `ox_lib` and `ox_inventory` for UI and inventory management.
-   Uses ESX for admin permissions and job management, but can easily be adapted to any other framework.
-   Version 4.0 is very much planned, and it will be a complete rewrite, utilizing modern Lua, `ox_lib` classes and test cases.
-   Open an `Issue` for bugs or suggestions
