import os
import xml.etree.ElementTree as ET

rom_dir = "/Volumes/DISK_IMG/Roms/GBA/"
games = [f for f in os.listdir(rom_dir) if f.endswith(('.z64', '.n64'))]

root = ET.Element("gameList")
for game in games:
    game_elem = ET.SubElement(root, "game")
    ET.SubElement(game_elem, "path").text = f"./{game}"
    ET.SubElement(game_elem, "name").text = os.path.splitext(game)[0]

tree = ET.ElementTree(root)
tree.write(f"{rom_dir}/miyoogamelist.xml", encoding="utf-8", xml_declaration=True)

