import ./make-test-python.nix ({ pkgs, ...} :

{
  name = "plasma5";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ ttuegel ];
  };

  machine = { ... }:

  {
    imports = [ ./common/user-account.nix ];
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
    services.xserver.desktopManager.default = "plasma5";
    services.xserver.displayManager.sddm.autoLogin = {
      enable = true;
      user = "alice";
    };
    hardware.pulseaudio.enable = true; # needed for the factl test, /dev/snd/* exists without them but udev doesn't care then
    virtualisation.memorySize = 1024;
  };

  testScript = { nodes, ... }: let
    user = nodes.machine.config.users.users.alice;
    xdo = "${pkgs.xdotool}/bin/xdotool";
  in ''
    startAll;
    # wait for log in
    $machine->waitForFile("/home/alice/.Xauthority");
    $machine->succeed("xauth merge ~alice/.Xauthority");

    $machine->waitUntilSucceeds("pgrep plasmashell");
    $machine->waitForWindow("^Desktop ");

    # Check that logging in has given the user ownership of devices.
    $machine->succeed("getfacl -p /dev/snd/timer | grep -q alice");

    $machine->execute("su - alice -c 'DISPLAY=:0.0 dolphin &'");
    $machine->waitForWindow(" Dolphin");

    $machine->execute("su - alice -c 'DISPLAY=:0.0 konsole &'");
    $machine->waitForWindow("Konsole");

    $machine->execute("su - alice -c 'DISPLAY=:0.0 systemsettings5 &'");
    $machine->waitForWindow("Settings");

    $machine->execute("${xdo} key Alt+F1 sleep 10");
    $machine->screenshot("screen");
  '';
})
