"""Normalize entrance/exit character art to the player's cell and feet baseline."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def build_pose(name: str) -> None:
    source = Image.open(ROOT / f'images/{name}_source.png').convert('RGBA')
    # Discard generated low-alpha residue and clear invisible RGB for clean previews.
    alpha = source.getchannel('A').point(lambda value: 255 if value >= 128 else 0)
    source.putalpha(alpha)
    source.paste((0, 0, 0, 0), mask=alpha.point(lambda value: 255 - value))
    pose = source.crop(alpha.getbbox())
    height = 196
    pose = pose.resize((round(pose.width * height / pose.height), height), Image.Resampling.NEAREST)
    cell = Image.new('RGBA', (256, 256))
    cell.paste(pose, ((256 - pose.width) // 2, 232 - height))
    for directory in ('images/normalized', 'gd-bungee-gum/assets/characters'):
        cell.save(ROOT / directory / f'{name}.png')


if __name__ == '__main__':
    for name in ('teto_front_entrance', 'teto_back_exit'):
        build_pose(name)
