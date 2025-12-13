{
        description = "Free Download Manager";

        inputs = {
                nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        };

        outputs = { self, nixpkgs, ... }:
                let
                        system = "x86_64-linux";
                        pkgs = nixpkgs.legacyPackages.${system};
                        kdePackages = pkgs.kdePackages;

                        fdm-unwrapped = pkgs.stdenv.mkDerivation rec {
                                pname = "freedownloadmanager-unwrapped";
                                version = "6.30";

                                src = pkgs.fetchurl {
                                        url = "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
                                        hash = "sha256-xllWakJxXElXJ10vmywXtrc/G+OO7JAL++MSQzY7egk=";
                                };

                                nativeBuildInputs = with pkgs; [
                                        dpkg
                                        autoPatchelfHook
                                ];

                                dontWrapQtApps = true;

                                buildInputs = with pkgs; [
                                        libdrm
                                        libpqxx
                                        unixODBC
                                        stdenv.cc.cc
                                        mysql80
                                        firebird
                                        udev
                                        libpulseaudio
                                        wayland
                                        libxkbcommon
                                        mesa
                                        openssl
                                        gtk3
                                        pango
                                        cairo
                                        gdk-pixbuf
                                        atk
                                ] ++ (with gst_all_1; [
                                        gstreamer
                                        gst-libav
                                        gst-plugins-base
                                        gst-plugins-good
                                        gst-plugins-bad
                                        gst-plugins-ugly
                                ]) ++ (with xorg; [
                                        xcbutilwm
                                        xcbutilimage
                                        xcbutilkeysyms
                                        xcbutilrenderutil
                                        xcbutilcursor
                                        libxcb-cursor
                                        libXcursor
                                        libX11
                                        libXext
                                        libXfixes
                                        libXi
                                        libXrender
                                        libXrandr
                                        libXcomposite
                                        libXdamage
                                        xcbutil
                                ]) ++ (with kdePackages; [
                                        qtwayland
                                        qtsvg
                                        qtimageformats
                                        qtdeclarative
                                        qt5compat
                                        qtbase
                                        qtmultimedia
                                ]) ++ (with pkgs; [
                                        pipewire
                                ]);

                                runtimeDependencies = with pkgs; [
                                        (lib.getLib udev)
                                        wayland
                                        libxkbcommon
                                        mesa
                                        xorg.libX11
                                        xorg.libxcb
                                        libGL
                                ];

                                autoPatchelfIgnoreMissingDeps = [
                                        "libmimerapi.so"
                                        "libclntsh.so.23.1"
                                        "libtiff.so.5"
                                ];

                                preFixup = ''
                                        rm -f $out/freedownloadmanager/lib/libcrypto.so*
                                        rm -f $out/freedownloadmanager/lib/libssl.so*
                                        rm -f $out/freedownloadmanager/lib/libQt6*
                                '';

                                unpackPhase = "dpkg-deb -x $src .";

                                installPhase = ''
                                        mkdir -p $out/bin
                                        cp -r opt/freedownloadmanager $out
                                        cp -r usr/share $out

                                        substituteInPlace $out/share/applications/freedownloadmanager.desktop \
                                                --replace 'Exec=/opt/freedownloadmanager/fdm' 'Exec=freedownloadmanager' \
                                                --replace "Icon=/opt/freedownloadmanager/icon.png" "Icon=$out/freedownloadmanager/icon.png"
                                '';

                                meta = with pkgs.lib; {
                                        description = "A smart and fast internet download manager";
                                        homepage = "https://www.freedownloadmanager.org";
                                        license = licenses.unfree;
                                        platforms = [ "x86_64-linux" ];
                                        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
                                        maintainers = with maintainers; [ ];
                                };
                        };

                        fdm-fhs = pkgs.buildFHSEnv {
                                name = "freedownloadmanager";

                                targetPkgs = pkgs: with pkgs; [
                                        fdm-unwrapped
                                        libdrm
                                        libpqxx
                                        unixODBC
                                        stdenv.cc.cc
                                        mysql80
                                        firebird
                                        udev
                                        libpulseaudio
                                        wayland
                                        libxkbcommon
                                        mesa
                                        openssl
                                        sqlite
                                        dbus
                                        fontconfig
                                        freetype
                                        libGL
                                        libGLU
                                        glib
                                        gtk3
                                        pango
                                        cairo
                                        gdk-pixbuf
                                        atk
                                        zlib
                                        libpng
                                        libjpeg
                                ] ++ (with gst_all_1; [
                                        gstreamer
                                        gst-libav
                                        gst-plugins-base
                                        gst-plugins-good
                                        gst-plugins-bad
                                        gst-plugins-ugly
                                ]) ++ (with xorg; [
                                        xcbutilwm
                                        xcbutilimage
                                        xcbutilkeysyms
                                        xcbutilrenderutil
                                        xcbutilcursor
                                        libxcb-cursor
                                        libXcursor
                                        libX11
                                        libXext
                                        libXfixes
                                        libXi
                                        libXrender
                                        libXrandr
                                        libXcomposite
                                        libXdamage
                                        libXtst
                                        libXScrnSaver
                                        xcbutil
                                ]) ++ (with kdePackages; [
                                        qtwayland
                                        qtsvg
                                        qtimageformats
                                        qtdeclarative
                                        qt5compat
                                        qtbase
                                        qtmultimedia
                                ]) ++ (with pkgs; [
                                        pipewire
                                        alsa-lib
                                        libsndfile
                                        libvorbis
                                        flac
                                        curl
                                        nspr
                                        nss
                                        expat
                                ]);

                                multiPkgs = pkgs: with pkgs; [
                                        libGL
                                        libGLU
                                ];

                                runScript = pkgs.writeShellScript "fdm-wrapper" ''
                                        export QT_QPA_PLATFORM=xcb
                                        export QT_PLUGIN_PATH="${kdePackages.qtbase}/${kdePackages.qtbase.qtPluginPrefix}"
                                        export LD_LIBRARY_PATH="${kdePackages.qtbase}/lib:${kdePackages.qtsvg}/lib:$LD_LIBRARY_PATH"
                                        exec ${fdm-unwrapped}/freedownloadmanager/fdm "$@"
                                '';

                                extraInstallCommands = ''
                                        mkdir -p $out/share/applications
                                        cp ${fdm-unwrapped}/share/applications/freedownloadmanager.desktop $out/share/applications/
                                        mkdir -p $out/share/icons
                                        cp ${fdm-unwrapped}/freedownloadmanager/icon.png $out/share/icons/freedownloadmanager.png
                                '';

                                meta = with pkgs.lib; {
                                        description = "A smart and fast internet download manager (FHS wrapper for cross-distro compatibility)";
                                        homepage = "https://www.freedownloadmanager.org";
                                        license = licenses.unfree;
                                        platforms = [ "x86_64-linux" ];
                                        maintainers = with maintainers; [ ];
                                };
                        };
                in
                {
                        packages.${system} = {
                                default = fdm-fhs;
                                unwrapped = fdm-unwrapped;
                                fhs = fdm-fhs;
                        };

                        apps.${system}.default = {
                                type = "app";
                                program = "${fdm-fhs}/bin/freedownloadmanager";
                        };

                        devShells.${system}.default = pkgs.mkShell {
                                buildInputs = with pkgs; [
                                        kdePackages.qtbase
                                        kdePackages.qtsvg
                                        kdePackages.qtdeclarative
                                ];
                        };
                };
}
