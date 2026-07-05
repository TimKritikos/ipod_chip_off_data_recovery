# IOFC_PATCH_INFO offsets — meaning and how to derive them

This directory documents the five per-build values that
[iphone-dataprotection](https://github.com/nabla-c0d3/iphone-dataprotection)'s
`python_scripts/kernel_patcher.py` needs in its `IOFC_PATCH_INFO` table, and
ships the scripts used to rederive them for a new device.

We add entries to that table from this repo via
`patches/iphone-dataprotection-add-ipod4-settings.patch` and
`patches/iphone-dataprotection-add-ipod5-settings.patch`.

## What the patch does

To dump the NAND / use the hardware AES engine from the recovery ramdisk, the
kernel's `IOFlashControllerUserClient::externalMethod` is replaced **in place**
with a small hand-written Thumb stub (`ramdisk_tools/ioflash/externalMethod.S`,
also inlined as the `IOFC_patch` byte string in `kernel_patcher.py`). The stub
lets userland issue raw flash commands.

The stub needs to call one core-kernel function,
`IOMemoryDescriptor::withAddress(...)`, which lives at a fixed address in the
kernel. Because the stub is position-dependent Thumb code, that call is done
with a PC-relative delta that must be computed per build. That is what most of
the table is about.

## The five values

`IOFC_PATCH_INFO[build]` is a list of five integers. All offsets are **file
offsets into the decrypted + LZSS-decompressed kernelcache Mach-O** (the same
file `kernel_patcher.py` reads):

```
[ SecureRoot_file_offset,          # 1
  externalMethod_file_offset,      # 2
  externalMethod_size,             # 3
  withAddress_file_offset,         # 4
  withAddress_delta ]              # 5
```

### 1. `SecureRoot_file_offset`
File offset of the ASCII string `"SecureRoot"` in the kernel. Used **only** as a
sanity guard:

```python
assert kernel[sr:sr+10] == "SecureRoot"
```

so the patcher refuses to run on the wrong / still-encrypted file. The string
occurs many times in the kernel; **any** occurrence satisfies the guard. The
shipped entries happen to use the 7th occurrence (0-based ordinal 6); the finder
script reproduces that by matching the reference kernel's ordinal.

### 2. `externalMethod_file_offset`
File offset of the original `IOFlashControllerUserClient::externalMethod`
function. This is where the stub is written:

```python
kernel[:externalMethod] + IOFC_patch + struct.pack("<L", delta) + kernel[externalMethod+len:...]
```

This function lives in a **prelinked kext** (segment `__PRELINK_TEXT`), whose C++
symbols are stripped from the Mach-O symbol table, so it can't be looked up by
name. It *is* byte-for-byte identical across devices on the same iOS build
(same compiled IOFlashStorage kext), so we locate it by matching the known-good
function bytes from a reference device.

### 3. `externalMethod_size`
Size in bytes of that original function. Used only for a bounds check:

```python
assert fsz >= (len(IOFC_patch) + 4)   # stub + 4-byte delta = 168 bytes
```

The original function is 168 bytes (`0xa8`) on every supported build, which is
exactly the stub size, so the stub fits precisely.

### 4. `withAddress_file_offset`
File offset of `IOMemoryDescriptor::withAddress(unsigned, unsigned long,
IODirection, task*)` — mangled symbol
`__ZN18IOMemoryDescriptor11withAddressEjm11IODirectionP4task`. This is a
**core-kernel** function (segment `__TEXT`) and *is* present in the symbol table,
so it's a direct name lookup. This value is not consumed directly by the
patcher (it's assigned to `_`); it exists to compute value 5.

### 5. `withAddress_delta`
The PC-relative delta the stub loads to reach `withAddress`, appended after the
stub as a little-endian `uint32`. Computed from **virtual addresses**:

```
withAddress_delta = (withAddress_vaddr + 1) - (externalMethod_vaddr + 0xC)   (mod 2^32)
```

* `+ 1` marks `withAddress` as a Thumb branch target.
* `+ 0xC` is the "here" anchor inside the stub documented in
  `externalMethod.S` (the location of the `add r11, pc` that consumes the delta).
* The two functions are in **different segments with different vm/file slides**
  (`__PRELINK_TEXT` vs `__TEXT`), so the delta must be computed in
  virtual-address space, not from the raw file offsets. Convert each file offset
  to a vaddr using its containing segment's `vmaddr - fileoff` slide.

## Results

Known-good reference (iPod touch 4, 6.1.6 / 10B500, `kernelcache.release.n81`):

```
"ipod4": [0x7988a1, 0x78F964, 0xa8, 0x25e244, 0xFFA8E8D5]
```

Derived here (iPod touch 5, 6.1.3 / 10B329, `kernelcache.release.n78`):

```
"ipod5": [0x6278A1, 0x61E964, 0xa8, 0x25C9C4, 0xFFBFE055]
```

Only value 1 (`0x6278A1`) was previously known for the iPod touch 5; values
2–5 were derived with the scripts below. Note the two functions moved
independently between the builds, which is exactly why the delta changed.

## Scripts

### `extract_kernelcache_from_ipsw.py`
Downloads *only* the kernelcache out of a remote IPSW (an IPSW is a zip, and
Apple's server supports HTTP range requests) instead of the whole ~900 MB image.
Outputs the encrypted IMG3 kernelcache. Decrypt + decompress it with the repo's
`xpwntool` (IV/KEY come from `builds/<BUILD>/index.html`):

```sh
URL=$(cat builds/10B329/url)
python3 tools/iofc_patch_offsets/extract_kernelcache_from_ipsw.py "$URL" /tmp/kc.enc

IV=$(jq -r '.keys[]|select(.image=="Kernelcache").iv'  builds/10B329/index.html)
KEY=$(jq -r '.keys[]|select(.image=="Kernelcache").key' builds/10B329/index.html)
other_repos/xpwn/build/ipsw-patch/xpwntool /tmp/kc.enc /tmp/kc.dec -iv "$IV" -k "$KEY" -decrypt
other_repos/xpwn/build/ipsw-patch/xpwntool /tmp/kc.dec /tmp/kc.raw   # LZSS-decompress
```

### `find_iofc_patch_info.py`
Given the target's decompressed raw kernel and a known-good reference kernel from
another device on the same iOS build, prints the full `IOFC_PATCH_INFO` tuple.

```sh
python3 tools/iofc_patch_offsets/find_iofc_patch_info.py \
    --target-kernel /tmp/kc.raw \
    --reference-kernel generated_bins/hacked_components/KernelCache.raw \
    --reference-externalmethod-offset 0x78F964 \
    --reference-externalmethod-size 0xa8 \
    --reference-secureroot-offset 0x7988a1
```

The reference `externalMethod` offset/size and `SecureRoot` offset are the
known-good iPod touch 4 values (the first three fields of that device's
`IOFC_PATCH_INFO` entry). `generated_bins/hacked_components/KernelCache.raw` is
the decompressed iPod touch 4 kernel produced by `acquire.sh --dev ipod4`.

Running the finder with the iPod touch 4 kernel as *both* target and reference
reproduces the known-good `ipod4` tuple exactly — a self-test that the method is
correct.
