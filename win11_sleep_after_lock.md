For some reason Windows 11 (potentially may even been since Win10 too) started putting my screen to sleep after I would lock (WinKey-L) my screen. Could never quite figure out why as I could not find a corresponding power management setting.  Started to wonder if I was loosing track of time and actually hitting the 
default 10m sleep setting!

Turns out that Windows will hide some power configuration settings from you, and this happens to be one of them.

In ```Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238c9fa8-0aad-41ed-83f4-97be242c8f20\7bc4a2f9-d8fc-4469-b07b-33eb785aaca0``` if you set ```Attributes``` to ```(REG_DWORD)0x02``` it will "unhide" this particular power control setting.

It can be verified via ```powercfg /q 381b4222-f694-41f0-9685-ff5bb260df2e 238c9fa8-0aad-41ed-83f4-97be242c8f20```

```
[..snip]

    Power Setting GUID: 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0  (System unattended sleep timeout)
      GUID Alias: UNATTENDSLEEP
      Minimum Possible Setting: 0x00000000
      Maximum Possible Setting: 0xffffffff
      Possible Settings increment: 0x00000001
      Possible Settings units: Seconds
    Current AC Power Setting Index: 0x00000078
    Current DC Power Setting Index: 0x00000078

[snip..]

```

Which by default is set to 120 seconds.. super annoying if you're used to working in environments where it is customary to lock your screen even if moving away for a few moments.

For the Balanced power scheme ```381b4222-f694-41f0-9685-ff5bb260df2e  (Balanced)``` the remedy to disable is:

```
powercfg /setacvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0
powercfg /setdcvalueindex 381b4222-f694-41f0-9685-ff5bb260df2e 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0
```
