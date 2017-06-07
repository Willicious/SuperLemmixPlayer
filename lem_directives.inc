{$WARN SYMBOL_PLATFORM OFF} // Disable "___ is specific to a platform" warnings, since NeoLemmix is only for Windows anyway

{$M+}

{$define nf_ver}

{$ifdef req_bc_ver}
  {$ifndef bc_ver}
    ERROR: Please switch NeoLemmix to backwards-compatible branch.
  {$endif}
{$endif}

{$ifdef req_nf_ver}
  {$ifndef nf_ver}
    ERROR: Please switch NeoLemmix to new-formats branch.
  {$endif}
{$endif}