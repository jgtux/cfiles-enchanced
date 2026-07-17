<h1 align="center">cfiles</h1>

<p align="center">
<a href="https://github.com/mananapr/cfiles/releases/latest"><img src="https://img.shields.io/github/release/mananapr/cfiles/all.svg" alt="Latest release" /></a>
<a href="https://aur.archlinux.org/packages/cfiles/"><img src="https://img.shields.io/aur/version/cfiles.svg" alt="Arch Linux" /></a>
<a href="https://github.com/mananapr/homebrew-cfiles"><img src="https://img.shields.io/badge/homebrew-v1.8-blue.svg" alt="Homebrew" /></a>
</p>

<p align="center">
<a href="https://github.com/mananapr/cfiles/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow.svg" alt="License" /></a>
</p>

> The badges above (release, AUR, Homebrew) reflect **upstream** (mananapr/cfiles), not this fork specifically — this fork isn't published to those channels under its own name.

`cfiles` is a terminal file manager with vim like keybindings, written in C using the ncurses
library. It aims to provide an interface like [ranger](https://github.com/ranger/ranger) while being lightweight, fast and
minimal.

![screenshot](cf.png)

## Changes in this fork

Upstream (mananapr/cfiles) has been inactive since 2021. On top of it, this fork fixes:

**Memory-safety fixes**
- `compare()` sized a heap buffer with `snprintf(NULL, 0, ...)` (exact length) but then wrote into it with `snprintf(buf, PATH_MAX, ...)` — a heap buffer overflow whenever the real path was shorter than `PATH_MAX`.
- `checkClipboard`/`removeClipboard` did `buf[strlen(buf)-1] = '\0'`, which underflows to `SIZE_MAX` on an empty line, causing an out-of-bounds write. Same underflow pattern existed in `displayBookmarks`/`openBookmarkDir`'s `strncpy(temp_dir, buf+2, strlen(buf)-2)` on short/malformed bookmark lines, which also lacked NUL-termination.
- `addBookmark()` called `realloc()` on a pointer that stayed referenced elsewhere globally — a potential dangling-pointer/use-after-free if the block moved.
- All of the above are now routed through two bounds-checked helpers, `textDup()` and `pathJoin()`, which size from `strlen()`, bound-check against `PATH_MAX`, and use `strcspn(buf, "\n")` instead of arithmetic that can underflow.

**Signal handling simplified**
- Removed the `SIGUSR1`/`SIGCHLD`-based `cb_sig` handler used to unify "key pressed" and "child process exited" detection around a blocking `getch()` call, in favor of a plain `getch()` + `waitpid(pid, &status, WNOHANG)` loop. Note: curses isn't in `nodelay` mode, so `getch()` still blocks — the `waitpid` check now only runs between keypresses rather than being woken immediately on child exit, which is a behavior change worth knowing about if you rely on fast previews-ready detection.

**Build**
- Replaced empty-paren K&R-style function signatures (`void foo()`) with `static void foo(void)`, fixing genuinely unspecified-argument prototypes under `-Wstrict-prototypes`.
- Reduced compiler warnings from 176 to 63 under stricter flags (see the `debug` target).
- Fixed GNU/BSD `make` portability the right way: both GNU Make (4.0+) and BSD make natively support the `!=` shell-assignment operator, so `NCURSES_CFLAGS`/`NCURSES_LIBS` no longer need a `.ifdef .MAKE` conditional block at all — a single `!=` line works on both. (An earlier version of this fix used `.ifdef`, which is BSD-make-only syntax and broke GNU make outright; verified fixed by building clean with GNU Make 4.4.1.)

## Dependencies
- `ncursesw`
- `cp`and `mv` for copying and moving
- `fzf` for searching
- `w3mimgdisplay` or `Überzug` for image previews
- `mediainfo` for viewing media info and file sizes
- `atool` for archive previews
- `poppler`(specifically `pdftoppm`) for pdf previews

## Compiling and Installation
#### Arch Linux
Arch Linux users can use the [AUR](https://aur.archlinux.org/packages/cfiles) package.

#### macOS
macOS users can use [brew](https://github.com/mananapr/homebrew-cfiles) or [macports](https://github.com/macports/macports-ports/tree/master/sysutils/cfiles)


#### Others
To compile, run

    make

and then run,

    sudo make install

to install.

## Keybindings
| Key | Function |
|:---:| --- |
| <kbd>h j k l</kbd> | Navigation keys |
| <kbd>G</kbd> | Go to end |
| <kbd>g</kbd> | Go to top |
| <kbd>H</kbd> | Go to top of current view |
| <kbd>M</kbd> | Go to middle of current view |
| <kbd>L</kbd> | Go to bottom of current view |
| <kbd>pgup</kbd> | Scroll Up One Page |
| <kbd>pgdn</kbd> | Scroll Down One Page |
| <kbd>f</kbd> | Search using fzf |
| <kbd>F</kbd> | Search using fzf in the present directory |
| <kbd>S</kbd> | Open Shell in present directory |
| <kbd>space</kbd> | Add/Remove to/from selection list |
| <kbd>tab</kbd> | View selection list |
| <kbd>e</kbd> | Edit selection list |
| <kbd>u</kbd> | Empty selection list |
| <kbd>y</kbd> | Copy files from selection list |
| <kbd>v</kbd> | Move files from selection list |
| <kbd>a</kbd> | Rename Files in selection list |
| <kbd>dd</kbd> | Move files from selection list to trash |
| <kbd>dD</kbd> | Remove selected files |
| <kbd>i</kbd> | View mediainfo and general info |
| <kbd>I</kbd> | View preview |
| <kbd>.</kbd> | Toggle hidden files |
| <kbd>b</kbd> | Toggle borders |
| <kbd>'</kbd> | View/Goto bookmarks |
| <kbd>m</kbd> | Add bookmark |
| <kbd>E</kbd> | Edit bookmarks |
| <kbd>p</kbd> | Run external script |
| <kbd>r</kbd> | Reload |
| <kbd>q</kbd> | Quit |

## Directories Used
`cfiles` uses `$XDG_CONFIG_HOME/cfiles` directory to store the clipboard file. This is used so that the clipboard
can be shared between multiple instances of `cfiles`. That's why I won't be adding tabs in `cfiles` because multiple
instances can be openend and managed by any terminal multiplexer or your window manager.
Note that this also means the selection list will persist even if all instances are closed.

`cfiles` also uses `$HOME/.local/share/Trash/files` as the Trash Directory, so make sure this directory exists before you try to delete a file.

For storing bookmarks, `cfiles` uses `$XDG_CONFIG_HOME/cfiles/bookmarks` file. Bookmarks are stored in the form `<key>:<path>`. You can either edit this file directly
or press `m` in `cfiles` to add new bookmarks.

`cfiles` looks for external scripts in the `$XDG_CONFIG_HOME/cfiles/scripts` directory. Make sure the scripts are executable before moving them to the scripts directory.

If `$XDG_CONFIG_HOME` is not set, then `$HOME/.config` is used.

## Opening Files
You can set `FILE_OPENER` in `config.h` to specify your file opening program. It is set to use `xdg-open` by default but you can change it to anything like `thunar`. macOS users need to set it to `open`.

## Image Previews
You can either go with `w3mimgdisplay` or `Überzug` ([link](https://github.com/seebye/ueberzug)) for image previews.
Each method has it's own pros and cons.

1. **Überzug**

To use `Überzug` for image previews, set `DISPLAYIMG` and `CLEARIMG` in `config.h` to the paths of `displayimg_uberzug` and `clearimg_uberzug` scripts respectively.
  * Pros
    1. Better previews when compared to `w3mimgdisplay`
  * Cons
    1. Can't generate previews for mp3 album arts
    2. Non functional scrolling with arrow keys

I recommend `Überzug` because the previews scale well with change in terminal size and don't disappear on changing workspaces.

2. **w3mimgdisplay**

To use `w3mimgdisplay` for image previews, set `DISPLAYIMG` and `CLEARIMG` in `config.h` to the paths of `displayimg` and `clearimg` scripts respectively.
  * Pros
    1. Faster scrolling
    2. Can generate previews of album arts for mp3 files
  * Cons
    1. Previews are very inconsistent and may disappear on resizing the terminal or changing workspaces
    2. You may have to redraw the UI while scrolling by pressing `KEY_RELOAD` (defaults to <kbd>R</kbd>)

You may have to modify the scripts a little, about which you can read [here](https://wiki.vifm.info/index.php/How_to_preview_images).

## Why C?
I wanted to improve my C and learn ncurses so I decided this would be an ideal project.

Apart from this, I have always wanted an alternative to ranger that is faster while still having
a similar UI.
