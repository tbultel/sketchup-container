FROM ubuntu:18.04


RUN apt-get update
RUN apt install -y software-properties-common
RUN apt install -y wget
RUN apt install -y file
RUN apt install -y p7zip
RUN apt install -y libuid-wrapper
RUN apt install -y file
RUN apt install -y winbind
RUN apt install -y xterm

RUN dpkg --add-architecture i386
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key
RUN apt-key add winehq.key
RUN apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main'
RUN apt-get update


RUN apt install -y --install-recommends winehq-stable
RUN apt install -y winetricks

RUN apt install zip

ARG gid=1000
RUN groupadd -g $gid user
ARG uid=1000
RUN useradd -u $uid -g user user
RUN mkdir /data && chown user /data
RUN mkdir -p /home/user && chown -R user:user /home/user

USER user
ENV WINEARCH=win64
ENV DISPLAY=:0
RUN winetricks -q vcrun2013 vcrun2015 
RUN winetricks -q corefonts
RUN winetricks -q dotnet452

# re-set win7 now
RUN winetricks -q win7

RUN ls
WORKDIR /home/user

ENV WINEPREFIX=/home/user/.wine

ARG sketchup_exe=sketchupmake-2017-2-2555-90782-en-x64-exe


RUN cd /home/user && wget https://github.com/tbultel/sketchup-stl/archive/master.zip
RUN unzip /home/user/master.zip

RUN cd sketchup-stl-master/src && zip -r /home/user/.wine/drive_c/users/user/Desktop/sketchup-stl.rbz sketchup-stl sketchup-stl.rb
RUN rm -rf /home/user/master.zip sketchup-stl-master

# Download Sketchup

RUN cd /home/user && wget https://www.sketchup.com/sketchup/2017/en/$sketchup_exe
# We extract the installer, because autoextracting .exe spawns uncontrolable processes

RUN rm -rf Make
RUN mkdir -p Make
RUN cd Make && 7zr x ../$sketchup_exe
RUN cd Make/SketchUpPrerequisites && wine64 start /wait /unix InstallPrerequisites.exe
RUN cd Make && wine64 start /wait /unix vcredist_x64/vcredist_x64.exe
RUN cd Make && wine64 start /wait /unix SketchUp2017-x64.msi

RUN rm -rf Make $sketchup_exe

ARG CACHEBUST=1

COPY wine-tmp-list wine-data-list /
RUN mkdir .tmp-template
RUN while read i ; do mkdir -p "$( dirname .tmp-template/"$i" )" && ( test -e .wine/"$i" || mkdir -p .wine/"$i" ) && mv .wine/"$i" .tmp-template/"$i" && ln -sv /tmp/wine/"$i" .wine/"$i" ; done < /wine-tmp-list
RUN while read i ; do mkdir -p "$( dirname .wine-template/"$i" )" && ( test -e .wine/"$i" || mkdir -p .wine/"$i" ) && mv .wine/"$i" .wine-template/"$i" && ln -sv /data/.sketchup-run/wine/"$i" .wine/"$i" ; done < /wine-data-list

COPY run-sketchup /usr/local/bin/
COPY run-xterm /usr/local/bin/

RUN rm -f /home/user/.wine/drive_c/users/user/"My Documents" && ln -sv /data /home/user/.wine/drive_c/users/user/"My Documents"

ENTRYPOINT [ "/usr/local/bin/run-sketchup" ]
#ENTRYPOINT [ "/usr/local/bin/run-xterm" ]

LABEL RUN 'docker run --read-only --network=host --tmpfs /tmp -v /tmp/.wine-$(id -u) -e DISPLAY=$DISPLAY --security-opt=label:type:spc_t --user=$(id -u):$(id -g) -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 -v $HOME:/data --rm sketchup'
