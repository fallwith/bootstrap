#!/usr/bin/env python3
import sys
import gzip
import struct
from pathlib import Path

def get_hardcore_alive_status(world_path_str):
    world_path = Path(world_path_str)
    level_dat = world_path / "level.dat"
    
    # Rule 1: Return -1 if level.dat doesn't exist or is invalid
    if not level_dat.is_file():
        return -1

    try:
        with gzip.open(level_dat, "rb") as f:
            level_data = f.read()
    except Exception:
        return -1

    # Verify world is actually hardcore: Byte Tag (\x01), Name Length 8 (\x00\x08), Name "hardcore" -> value \x01
    if b"\x01\x00\x08hardcore\x01" not in level_data:
        return -1

    # Locate player profile sub-directory based on your structure
    players_data_dir = world_path / "players" / "data"
    if not players_data_dir.is_dir():
        # Fallback to checking the root level.dat just in case data mirrors there
        player_files = [level_dat]
    else:
        player_files = list(players_data_dir.glob("*.dat"))

    # If the folder exists but is empty, assume alive template baseline
    if not player_files:
        return 1

    # Byte signature for DeathTime tag: Short (\x02), Name Length 9 (\x00\t), Name "DeathTime"
    deathtime_tag = b"\x02\x00\tDeathTime"

    for p_file in player_files:
        try:
            with gzip.open(p_file, "rb") as pf:
                p_data = pf.read()
            
            if deathtime_tag in p_data:
                idx = p_data.index(deathtime_tag)
                # Advance 12 bytes past the type-ID and name string to read the 2-byte short payload
                val_start = idx + 12
                
                # Unpack 2 big-endian bytes as a signed short integer (>h)
                # struct.unpack returns a tuple like (64,)
                death_time = struct.unpack_from(">h", p_data, val_start)[0]
                
                # Rule 2: If DeathTime is greater than 0, player is dead
                if death_time > 0:
                    return 0
        except Exception:
            continue # If an individual player file is locked or corrupted, keep checking others

    # Rule 3: If hardcore is True and no player has a DeathTime > 0, they are alive
    return 1


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(-1)
        sys.exit(0)
        
    # Correctly parse index 1 for the CLI string path argument from zsh
    print(get_hardcore_alive_status(sys.argv[1]))

