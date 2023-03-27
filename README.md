# lam-karaoke
musings and prototypes in Godot for new karaoke engine

# Installation

Development is currently done using Godot 4 Stable.

1. Clone/download this repository to your machine.
2. Download Godot 4 Stable from the [official site](https://godotengine.org/).
3. Extract the downloaded file to a location of your choice. Godot is self-contained and does not require installation.
4. Run the Godot 4 executable and press the `Import` button, select the folder containing this repository on your machine.
6. Once the project opens, navigate to the `Project` menu, and select `Export`.
7. In the `Export` window, select `Windows Desktop (Runnable)` from the list of available platforms.
8. Specify an `Export Path` where the game executable should be written.
9. Press the `Export Project...` button.
10. [Optional] Tick/untick `Export With Debug`.
11. Press `Save`.
12. You should now have `LamKaraoke.exe` in the folder you've selected previously.

# Testing Multiplayer (on Windows)

Assuming you've already generated the game executable create a couple of shortcuts to
launch multiple instances of the game. The email/password can be almost anything, the account
will get automatically created if it doesn't exist.

1. Create a shortcut named `Player 1` for the game executable, set the `Target` to
   ```
   <path\to\LamKaraoke.exe> -- --email="player1@whatever.com" --password="player1pass"
   ```
2. Create another shortcut named `Player 2` for the game executable, set the `Target` to
   ```
   <path\to\LamKaraoke.exe> -- --email="player2@whatever.com" --password="player2pass"
   ```
3. Copy some songs to `%APPDATA%\Godot\app_userdata\Lam-dj\songs`.
4. Launch `Player 1` game and `Player 2` game.
5. As Player 1 select an instrument in the game window and press the `Get that` button.
6. Press `Matches` button.
7. Press `Create New Match` button.
8. Double-click on a song on the right-hand side.
9. As Player 2 select the same instrument, press `Matches` button, then double-click to join the match created by `Player 1`.

# License Agreement

TODO We are working on this

# CLA Agreement

Any pull requests to these repo require a CLA https://cla-assistant.io/ProjectLam/learn_music_game
