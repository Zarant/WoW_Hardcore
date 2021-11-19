# Hardcore
World of Warcraft addon for the Hardcore community

## What does this addon do?
- (Death Reports) Shows in-game and in guild chat when someone dies
- (HC Verification) Logs play time and tracks deaths for [Hardcore Community Leaderboards and Hall of Legends](https://classichc.net/)
- (Accountability) Shows an overview of everyone in guild running Hardcore addon
- (Grief Protection) Warns you as you target a friendly/enemy that is Pvp flagged
- (Hardcore Rules) Prevents Mailbox and Auction House Access
- (Bubble Hearth) Warns the player while Bubble hearthing. Also reports to guild

## WARNING - MULTIPLE PCs SUPPORT - WARNING!!!!!
This addon DOES NOT support one character across multiple PCs! The consequence of this is potentially losing a VERIFIED run!

Below are steps for a work-around.

### Syncing the Saved Variable file
Not recommended if below steps are confusing

If you want to play on multiple PCs, you CAN sync the following file to Google Drive / Dropbox before and after play sessions. 
```
{WOW_INSTALL_DIRECTORY}\_classic_era\WTF\Account\{ACCOUNT_ID or ACCOUNT_NAME}\{SERVER_NAME}\{CHARACTER_NAME}\SavedVariables\Hardcore.lua
```

#### After Playing on PC #1
1. Logout and exit game properly
2. Copy above file on PC #1 to Cloud / storage

#### Before Playing on PC #2
1. If above folder path doesn't exist yet on PC #2, log in on the character and logout immediately. WoW will create the folder for you
2. Your game MUST be OFF for the below steps
3. Copy file from Cloud / storage to above location on PC #2
4. Overwrite file on PC #2
5. Start Playing