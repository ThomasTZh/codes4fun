# codes4fun

Small MATLAB programs written for fun. Each file is self-contained, needs only
base MATLAB, and opens a figure.

## Contents

| File | What it does |
|---|---|
| `catGo9.m` | Cat Go on a 9x9 Go board |
| `catGo19.m` | Cat Go on a 19x19 Go board |
| `Rose.m` | 3-D rose-like surface with a local light and Gouraud shading |

## Cat Go

`catGo9` and `catGo19` open a playable Go board drawn as a MATLAB figure.
Stones of the same colour that touch merge into one shape, stones carry cat
ears and faces, and groups that lose their last liberty are captured.
`catGo19` adds the nine star points, emoji reactions and the larger board.

Controls for both games:

- Left click: place a stone of the current colour.
- `b`: undo the last move.

Neither game keeps score. They are plain functions with no inputs, no outputs
and no dependencies beyond base MATLAB.

```matlab
catGo9
catGo19
```

## Rose

`Rose.m` is a script that draws a rose-like surface with red faces, one local
light and Gouraud shading. It takes no inputs and opens a new figure with a
white background.

```matlab
Rose
```

## Notes

- These are recreational programs, not part of a toolbox. There are no tests.
- No licence file is included. Ask before reusing the code in your own work.

The image, volume and signal processing library lives separately in
[matlabTools](https://github.com/ThomasZhangTY/matlabTools).
