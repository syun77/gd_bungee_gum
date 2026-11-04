"""Slice the approved exit source into nearest-filtered, feet-aligned cells."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'images/tilesets/restaurant_stage_exit_animation_source.png'
OUTPUTS = [ROOT / 'images/tilesets/restaurant_stage_exit.png',
           ROOT / 'gd-bungee-gum/assets/stage/restaurant_stage_exit.png']


def build():
    source = Image.open(SOURCE).convert('RGBA')
    sheet = Image.new('RGBA', (288, 256))
    header = None
    for index in range(6):
        left = 32 + 444 * (index % 3)
        top = 10 if index < 3 else 602
        frame = source.crop((left, top, left + 384, top + 524))
        frame = frame.resize((96, 128), Image.Resampling.NEAREST)
        if header is None:
            header = frame.crop((0, 0, 96, 51))
        frame.paste(header, (0, 0))
        sheet.paste(frame, (96 * (index % 3), 128 * (index // 3)))
    for output in OUTPUTS:
        output.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(output)


if __name__ == '__main__':
    build()
