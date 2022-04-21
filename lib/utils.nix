{
  runCommandLocal,
  gnused,
}: {
  sanitizeFile = filename: src:
    runCommandLocal filename {
      inherit src;
      buildInputs = [
        gnused
      ];
    }
    ''
      sed 's/[[:cntrl:]]//g' $src > $out
    '';
}
