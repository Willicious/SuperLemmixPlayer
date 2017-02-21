{-$define develop}
{$WARN SYMBOL_PLATFORM OFF} // Disable "___ is specific to a platform" warnings, since NeoLemmix is only for Windows anyway

{$define nf-ver}

{$ifdef req-bc-ver}
  {$ifndef bc-ver}
    ERROR: Please switch NeoLemmix to backwards-compatible branch.
  {$endif}
{$endif}

{$ifdef req-nf-ver}
  {$ifndef nf-ver}
    ERROR: Please switch NeoLemmix to new-formats branch.
  {$endif}
{$endif}