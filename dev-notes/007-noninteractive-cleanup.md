# 007 Noninteractive Cleanup

## Summary

Removed yes/no interruptions from the full cleanup / scrubber flow.

Cleanup now applies its intended Windows Search indexing and Microsoft Store auto-update changes without prompting. The no-sleep power plan was removed from the starting menu and added to the buildup stage of the scrubber flow.

## Files Changed

- `modules/cleanout.ps1`
- `modules/optional.ps1`
- `modules/full-cleanup.ps1`
- `modules/main-menu.ps1`
- `README.md`
- `dev-notes/007-noninteractive-cleanup.md`

## Validation Performed

- Confirmed cleanup-path prompts in `modules/cleanout.ps1` were removed.
- Confirmed `Set-NoSleepPowerPlan` no longer asks for confirmation.
- Confirmed `Invoke-FullCleanup` calls `Set-NoSleepPowerPlan` during buildup.
- Confirmed the starting menu no longer lists the no-sleep power plan as a standalone option.
- Confirmed the legacy optional menu no longer lists the no-sleep power plan as a standalone option.
- Confirmed PowerShell parse checks pass for changed scripts.
- Confirmed the starting menu renders without the removed no-sleep option.

## Risks/Notes

- Full cleanup now always applies no-sleep power settings when run.
- Windows Search index rebuild is skipped to keep cleanup non-interactive and avoid a long blocking service restart.
- Remote Desktop and automatic local sign-in remain interactive utility menu items.

## Next Suggested Step

Run the full cleanup flow from an elevated session and confirm it completes without yes/no prompts:

```powershell
irm https://git.yenkuri.com | iex
```
