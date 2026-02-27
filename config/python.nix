{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      pip
      pytest
      virtualenv
    ]))
  ];
}
