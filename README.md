<p align="center"><br>
<a href="https://github.com/Lolo280374/flashThemAll"><img src="https://hackatime-badge.hackclub.com/U09CBF0DS4F/flashThemAll"></a>
<a href="https://makeapullrequest.com"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg"></a>
<a><img src="https://img.shields.io/badge/os-linux-brightgreen"></a>
<a><img src="https://img.shields.io/badge/not_for-macOS-red"></a>
<br><p>

<h3 align="center">
download, and flash any OS and any image to any device, ENTIRELY on CLI! 
<br>no need to run google for ISO images anymore!
</h3>

<h1 align="center">
showcase (screenshots)
</h1>

<img width="1920" height="1080" alt="main flashThemAll banner" src="https://github.com/user-attachments/assets/02b6db2f-64a9-4185-a3e8-366ebacfbc3a" />

showcase video of the flashing feature, also working for non iso-hybrid images! (e.g: windows isos)

[![showcase_flash_nonisohybrid](https://github.com/user-attachments/assets/0d3c87d7-fa5d-43ee-8042-40b890d87558)](https://github.com/user-attachments/assets/08a9a4b3-302e-4f80-a970-77bf38428e8c)

showcase video of the auto image downloader for the OS you choose from the repo, and the auto flash feature! (see features tab of this readme)

[![showcase_downloadfromrepo_and_flash](https://github.com/user-attachments/assets/a56b1ac8-0462-4ded-806e-9738c3611858)](https://github.com/user-attachments/assets/e51fea92-d5d2-4eef-94b1-a6d7bc74231f)

> [!IMPORTANT]
> this script is only avalaible (and tested) for Linux!
> you should run this script as sudo, otherwise you might be prompted for elevation when flashing images, making the process less smooth!

> [!CAUTION]
> this software touches with storage devices. please, make sure you KNOW what you're doing, and you're selecting the right device to flash to (for example, sdb and not sda...). if you're unsure, please, CHECK YOUR PARTITION MAP.
> i am not responsible for any dead, broken devices, or lost data.

## table of contents

- [about](#about)
- [features](#features)
- [dependencies](#dependencies)
- [installation](#installation)
- [how it works (explanations)](#how-it-works)
- [contributing](#contributing)
- [reporting issues](#reporting-issues)
- [credits](#credits)
- [license](#license)

## about
for this week of siege, the theme was framework. i wasn't gonna make a whole framework. so i did something for the upcoming framework laptop! heh! (i really want it.)

and also, that's an issue i already encountered by the past. i had to first google the ISO, download it, then get Etcher, flash it, a lot of pain. this script now fixes everything! all you gotta do is just select the OS you want, select the USB, and it does it all on its own!

so yeah. maybe this week I didn't do a framework. but this can be hella helpful! even out of the framework laptop context. even tho it would obviously work on it, it's just another x86_64 machine.

## features
since i wanted this project to be actually usable in a real life scenario and not just a tech demo, i decided to put features i (and other actual human beings) would actually enjoy and find useful!

here's a small list of them:

* **drive listing**: lists you the partitions and drives avalaible on your system.
* **ventoy installer**: install ventoy to any drive you want, fully from CLI, and super easily!
* **ISO flashing (isohybrid/non iso-hybrid)**: allows you to flash both isohybrid isos, and also annoying non isohybrid images such as the windows ISOs! meaning you can finally flash windows iso's easily thru CLI on linux!
* **SystemRescue installer**: allows you to turn your drive into a rescue bootdrive, packed of recovery features and tools to rescue your linux install!
* **distro repository**: allows you, in short, to find, download, and flash, the latest, and ALWAYS the latest ISO of repositories you would want to have flashed on your drive! the installer automatically finds the most up-to-date ISO, downloads it, and flashes it for you! all you have to do is to select which drive to install it to.¹

¹compatible for the following distros: Ubuntu, Debian, PopOS, Arch Linux, Alpine Linux, Fedora, CentOS, Linux Mint, Bazzite, and Manjaro.

## dependencies
most of the dependencies used by this project are already baked in your Linux distribution, for sure. just in case you're missing one, or you wanna make sure what is this project is using, refer to the table below:

### might not be installed by default
this project requires 'rsync' and 'curl'. these are often the less preinstalled packages. make sure you got these two!

### often always pre installed
this project also requires the following packages: 'coreutils', 'util-linux', 'grep', 'sed', 'tar', 'sudo', 'bash'.

they are often very preinstalled tho, so don't worry too much i guess.

## installation
this script is only compatible on Linux. the good thing however is it requires little to no dependencies, and almost all of them are already baked in your distribution, for sure.

to install this script, simply curl the script and run it:
```sh
curl -L -o flash.sh flash.lolodotzip.tech
sudo chmod +x flash.sh
./flash.sh
```

note that you will most likely have to chmod +x it, considering it's coming from the Internet.

## how it works
this script is pretty simple by the fact it requires little to no deps! the way it works is quite similar to how you would do the same thing, just manually.

### flashing isohybrid images
considering these can just be flashed with the 'dd' command, it's what's mostly used. the script automatically fetches the distribution you request, or just finds the one you feed it, and detects if it's an actual ISO file or not. if it is, flashing starts using the 'dd' command, and you're done!

### flashing non-isohybrid images (e.g: windows ISOs)
that's a bit more complicated. the issue is windows ISOs are not isohybrid, meaning you cant just flash them using 'dd', because they won't be bootable. doing such on linux is quite annoying, and often requires specific packages, but putting it on the project would be a hassle because not everyone running this uses the same distro or package manager.

to solve this issue, I decided to simply use Ventoy, once again. if you're trying to flash an image that's not isohybrid, ventoy will be used. ventoy will simply be installed to your drive, and then the ISO you feed it will be simply copied to the root of that new drive. that way, it'll work!

> [!NOTE]  
> even if you use the non-isohybrid flash, the process is mostly automated! so don't worry, just because you're trying to flash windows dosen't mean you'll get 5000 extra steps!

## contributing
to contribute, you can simply git clone this repository, and start editing the script file!

```sh
git clone https://github.com/Lolo280374/flashThemAll.git
cd flashThemAll
nano flash.sh
```

you may then request your modifications via a PR.

## reporting issues
this is a community project, and your help is very much appreciated! if you notice anything wrong during your usage of this software, please report it to the [GitHub issues tracker](https://github.com/Lolo280374/flashThemAll/issues/)!

## credits
many thanks to these who without them, the project may have never seen the light of day (or just wouldn't have been the same):

- [Ventoy](https://www.ventoy.net/) - super useful tool for having multiple ISOs on the same device, and for supporting Windows's flashing scheme in our case

- [SystemRescue](https://www.system-rescue.org/) - cool tool to repair your broken Linux installs from a single device, with a ton of tools baked in!

- [the Linux distros in the download picker](#features) - great repos i thought of adding because they are quite good and popular, and well without them the downloader would be quite empty...

- [rsync, GNU coreutils and others](#dependencies) - thanks to these base linux tools for being here! they are the main essence of this script, allowing for flashing, copying, and downloading!

and probably some others I forgotten.. sorry in advance, but thanks for being here!

## license
this project is licensed under the MIT License which you may check [here](https://github.com/Lolo280374/flashThemAll/blob/main/LICENSE).
<br>if you have any questions about this project or inquieries, please reach me [at lolodotzip@hackclub.app](mailto:lolodotzip@hackclub.app).