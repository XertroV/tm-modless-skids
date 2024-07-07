import os
import shutil
from pathlib import Path

files = [
    "Blue_Thick.dds",
    "Green_Thick.dds",
    "Orange_Thick.dds",
    "Pink_Thick.dds",
    "Purple_Thick.dds",
    "Red_Thick.dds",
    "That_Ski_Freak_V1.dds",
    "That_Ski_Freak_V2.dds",
    "That_Ski_Freak_V3.dds",
    "ChromaGreen.dds",
    "EvoBorder.dds"
]

def skip_dds(ty: str, name: str):
    return ty == "Dirt" and name == "EvoBorder.dds"

skid_types = ["Asphalt", "Dirt", "Grass"]

def main():
    base_dir = Path("~/Trackmania/Skins/Stadium/Skids/").expanduser()
    for ty in skid_types:
        for name in files:
            if skip_dds(ty, name):
                continue
            src = base_dir / ty / name
            if not src.exists():
                print(f"Missing: {src}")
                continue
            print(f".\\texconv.exe -f DXT5 -o {ty} -y .\{ty}\{name}")

if __name__ == "__main__":
    main()
