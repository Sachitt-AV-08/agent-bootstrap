# Keyboard Shortcuts Reference

## Default Keybindings (tui.json)

### Global
| Key | Action |
|-----|--------|
| `Ctrl+C` | Quit / Interrupt |
| `F1` | Help |
| `Ctrl+P` | Command Palette |
| `Ctrl+B` | Toggle Sidebar |
| `Ctrl+L` | Toggle Logs |
| `Ctrl+N` | New Session |
| `Ctrl+Tab` | Next Session |
| `Ctrl+Shift+Tab` | Previous Session |

### Editor
| Key | Action |
|-----|--------|
| `Ctrl+S` | Save |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |
| `Ctrl+F` | Find |
| `Ctrl+H` | Replace |
| `Ctrl+G` | Go to Line |
| `Shift+Alt+F` | Format |

### Chat
| Key | Action |
|-----|--------|
| `Enter` | Send Message |
| `Shift+Enter` | New Line |
| `PageUp` | Scroll Up |
| `PageDown` | Scroll Down |
| `Ctrl+Shift+C` | Copy Code Block |
| `Ctrl+R` | Regenerate Response |
| `Ctrl+C` | Interrupt Generation |

### Sidebar
| Key | Action |
|-----|--------|
| `→` / `Right` | Expand |
| `←` / `Left` | Collapse |
| `Enter` | Select |
| `F2` | Rename |
| `Delete` | Delete |
| `F5` | Refresh |

## Customizing Keybindings

Edit `~/.config/opencode/tui.json`:

```json
{
  "keybindings": {
    "leader": "ctrl+space",
    "global": {
      "quit": "ctrl+q",
      "commandPalette": "ctrl+k"
    },
    "chat": {
      "send": "ctrl+enter",
      "newLine": "enter"
    }
  }
}
```

### Key Format

- Single key: `"a"`, `"f1"`, `"enter"`
- With modifiers: `"ctrl+a"`, `"ctrl+shift+a"`, `"alt+enter"`
- Special: `"pageup"`, `"pagedown"`, `"home"`, `"end"`

### Available Actions

#### Global
`quit`, `help`, `commandPalette`, `toggleSidebar`, `toggleLogs`, `newSession`, `nextSession`, `prevSession`

#### Editor
`save`, `undo`, `redo`, `find`, `replace`, `goToLine`, `format`

#### Chat
`send`, `newLine`, `scrollUp`, `scrollDown`, `copyCode`, `regenerate`, `interrupt`

#### Sidebar
`expand`, `collapse`, `select`, `rename`, `delete`, `refresh`

## Vim-Style Bindings (Example)

```json
{
  "keybindings": {
    "global": {
      "quit": "ctrl+c",
      "commandPalette": "ctrl+p",
      "toggleSidebar": "ctrl+b",
      "toggleLogs": "ctrl+l"
    },
    "chat": {
      "send": "ctrl+j",
      "newLine": "enter",
      "scrollUp": "ctrl+u",
      "scrollDown": "ctrl+d"
    },
    "sidebar": {
      "expand": "l",
      "collapse": "h",
      "select": "enter",
      "delete": "x"
    }
  }
}
```

## Emacs-Style Bindings (Example)

```json
{
  "keybindings": {
    "global": {
      "quit": "ctrl+x ctrl+c",
      "commandPalette": "ctrl+x ctrl+f",
      "toggleSidebar": "ctrl+x 1"
    },
    "chat": {
      "send": "ctrl+return",
      "newLine": "ctrl+o",
      "scrollUp": "ctrl+v",
      "scrollDown": "alt+v"
    }
  }
}
```

## Leader Key

The leader key prefixes multi-key commands:

```json
{
  "keybindings": {
    "leader": "ctrl+space",
    "global": {
      "quit": "ctrl+c"
    }
  }
}
```

Then `Ctrl+Space` followed by `q` = quit.

## Tips

1. **Avoid conflicts** — Don't override system shortcuts
2. **Use leader** — For less common actions
3. **Test incrementally** — Change a few at a time
4. **Document** — Comment your custom bindings
5. **Sync** — Store in dotfiles repo