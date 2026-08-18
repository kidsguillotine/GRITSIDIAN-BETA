# GRITSIDIAN-BETA
Obsidian and claudian/claude code integration framework





ALL INFORMATION SHOULD BE INCLUDED IN THE README FILE ON FOLDER ROOT. LEAVE ISSUE REQUEST IF NOT OR IF ANYTHING IS CONFUSING

install your version of obsidian based on your system

https://obsidian.md/

if on ubuntu its easier to run thru flatpak

{{{flatpak install flathub md.obsidian.Obsidian}}}
and if on ubuntu it is much easier to work with if you install git for backups {{sudo apt install git}} this will ensure any changes are committed off your machine incase of catastrophe!!

then go create an empty vault wherever you want 


then download and unzip the files. it is easier to create a new empty folder to extract the contents into, it extracts into a single folder with all sub directories under that.

easiest is to read SETUP.md and go that way.

make sure when picking the vault location it is in the folder one level up from where you extracted the vault files or it wont be recognized


from here go into the gritsidian-starter folder and run the setup.sh as a script/bash file (SETUP.md explains all of this)


There is the availability to use whichever model you would like. easiest integration is a commercial grade cloud model (claude, codex, grok ect) but with certain plugins, routing and servers, we can call on anything

--if you want to integrate a local model I personally use Vault operator(obsidian community plugin) with hugging face (https://huggingface.co/) models on ollama (https://ollama.com/) served through docker (https://www.docker.com/) but it all depends on your system capabilities. 8gb of vram are good for low level vault tasks
