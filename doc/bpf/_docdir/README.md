OCaml embedded [eBPF](https://qmonnet.github.io/whirl-offload/2016/09/01/dive-into-bpf/) assembler.

[eBPF.mli](src/eBPF.mli)

Assuming `R1` points to packet data - check if it is an ARP packet :

```
let arp =
[
  ldx H R2 (R1,12);
  movi R0 1;
  jmpi `Exit R2 `EQ 0x806;
  movi R0 0;
label `Exit;
  ret
]
```

See [src/test.ml](src/test.ml) for more examples.
