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
                in
                {
                        packages.${system}.default = pkgs.stdenv.mkDerivation rec {
                                pname = "freedownloadmanager";
                                version = "6.30";

                                src = pkgs.fetchurl {
                                        url = "https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb";
                                        hash = "sha256-xllWakJxXElXJ10vmywXtrc/G+OO7JAL++MSQzY7egk=";
                                };

                                nativeBuildInputs = with pkgs; [
                                        dpkg
                                        wrapGAppsHook3
                                        kdePackages.wrapQtAppsHook
                                        autoPatchelfHook
                                        makeWrapper
                                ];

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
                                        libxcb-cursor
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
                                        ln -s $out/freedownloadmanager/fdm $out/bin/${pname}

                                        substituteInPlace $out/share/applications/freedownloadmanager.desktop \
                                                --replace 'Exec=/opt/freedownloadmanager/fdm' 'Exec=${pname}' \
                                                --replace "Icon=/opt/freedownloadmanager/icon.png" "Icon=$out/freedownloadmanager/icon.png"

                                        wrapProgram $out/freedownloadmanager/fdm \
                                                --prefix QT_PLUGIN_PATH : "${kdePackages.qtbase}/${kdePackages.qtbase.qtPluginPrefix}" \
                                                --prefix LD_LIBRARY_PATH : "${kdePackages.qtbase}/lib:${kdePackages.qtsvg}/lib" \
                                                --set QT_QPA_PLATFORM "xcb"
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

                        apps.${system}.default = {
                                type = "app";
                                program = "${self.packages.${system}.default}/bin/freedownloadmanager";
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
