# Hardcore
World of Warcraft addon for the Hardcore community

## What does this addon do?
- (Death Reports) Shows in-game and in guild chat when someone dies
- (HC Verification) Logs play time and tracks deaths for [Hardcore Community Leaderboards and Hall of Legends](https://classichc.net/)
- (Accountability) Shows an overview of everyone in guild running Hardcore addon
- (Grief Protection) Warns you as you target a friendly/enemy that is Pvp flagged
- (Hardcore Rules) Prevents Mailbox and Auction House Access
- (Bubble Hearth) Warns the player while Bubble hearthing. Also reports to guild
- (Common communication channel) The GreenWall add-on has been embedded. It allows multiple guilds within a single realm, or connected realms to share guild chat as if they were one guild. When a member in one guild types something in guild chat, members of the other connected guilds (co-guilds) will see what was said and can respond. Guild members can use GreenWall with zero configuration. All of the necessary configuration work is done by the guild officers. There is no significant impact to the game performance. All members must have at least one spare custom chat channel available (two for officers if officer chat is also being bridged).

## FAQ
### Addon says active time is much lower than played time

The addon tracks a certain percentage of your addon uptime compared to total /played. If it is about seconds or minutes - no problem. If it is about hours - consider rerolling before level 20. After level 20, record the run as instructed by the error message.

this can happen due to: 
- Disconnect or Game crash. This happens due to WoW's WTF folder not updating due to the unexpected end of the game process.
- the Game is killed with alt+f4 or otherwise WITHOUT logging out first (exit game IS NOT THE SAME as logout) 
- the character has been played on two or more computers. Refer to the Multi-pc workaround below

### The addon is missing recorded levels after a DC / Crash

This happens due to WoW's WTF folder not updating due to the unexpected end of the game process. If you happen to have crashes every now and then consider typing /reload every 15min or so when safely out of combat's harm. It will save the process for the addon.

### I checked the accountability tab and there are people A LOT of in red, what do I do?

Close the addon tab and open it again after a minute or so. They should be green now. It takes time to sync at times.

### How can I see how much has been recorded on my character?

```
/dump Hardcore_Character.time_tracked..', '..Hardcore_Character.time_played..', '..Hardcore_Character.tracked_played_percentage
```
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