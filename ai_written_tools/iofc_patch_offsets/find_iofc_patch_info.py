#!/usr/bin/env python3
"""Compute the IOFC_PATCH_INFO tuple for a decrypted+decompressed iOS kernel.

Background
----------
iphone-dataprotection's kernel_patcher.py replaces
IOFlashControllerUserClient::externalMethod with a small stub that lets the
ramdisk drive the flash controller directly (to dump NAND / use the AES engine).
For each supported build it needs a 5-value tuple, IOFC_PATCH_INFO[build]:

    [ SecureRoot_file_offset,
      externalMethod_file_offset,
      externalMethod_size,
      IOMemoryDescriptor_withAddress_file_offset,
      withAddress_delta ]

See README.md in this directory for what each value means.

This script rederives all five for a target kernel. The externalMethod function
lives in a prelinked kext whose C++ symbols are stripped from the symbol table,
so we locate it by matching against the byte-identical function from a
*reference* kernel (another device on the same iOS build) whose externalMethod
offset/size are already known-good.

Example (rederiving the iPod touch 5 values using the known-good iPod touch 4
entry [0x7988a1, 0x78F964, 0xa8, 0x25e244, 0xFFA8E8D5] as the reference):

    ./find_iofc_patch_info.py \
        --target-kernel ipod5_kernel.raw \
        --reference-kernel ipod4_kernel.raw \
        --reference-externalmethod-offset 0x78F964 \
        --reference-externalmethod-size 0xa8
"""
import argparse
import struct

# --- Mach-O constants (32-bit / MH_MAGIC) -----------------------------------
MACHO_32BIT_MAGIC = 0xFEEDFACE
MACHO_HEADER_SIZE = 28              # 32-bit mach_header, then load commands
LC_SEGMENT = 0x1
LC_SYMTAB = 0x2
NLIST_ENTRY_SIZE = 12              # struct nlist (32-bit)

# --- Patch/ABI constants ----------------------------------------------------
# The replacement stub + its trailing 4-byte delta is 168 bytes; the original
# externalMethod on every supported build happens to be exactly this size, and
# kernel_patcher.py asserts externalMethod_size >= len(stub) + 4.
IOFC_STUB_TOTAL_SIZE = 168

# externalMethod_size default: the function is byte-identical across builds, so
# the reference size is reused unless overridden.

# The stub loads the delta into r11 via `ldr r11, ...; add r11, pc` and the
# original table encodes the delta as:
#     (withAddress_vaddr + THUMB_BIT) - (externalMethod_vaddr + DELTA_ANCHOR)
# THUMB_BIT marks withAddress as a Thumb target; DELTA_ANCHOR is the "here"
# reference point documented in externalMethod.S ("externalMethod + 0xC").
THUMB_BIT = 1
DELTA_ANCHOR_FROM_EXTERNALMETHOD = 0xC
UINT32_MASK = 0xFFFFFFFF

# The exact IOMemoryDescriptor::withAddress overload the stub calls: the one
# taking (unsigned, unsigned long, IODirection, task*). Its C++ mangled name:
WITHADDRESS_MANGLED_SYMBOL = "__ZN18IOMemoryDescriptor11withAddressEjm11IODirectionP4task"

SECUREROOT_STRING = b"SecureRoot"


class MachOKernel:
    """Minimal parser for a decompressed 32-bit kernelcache Mach-O."""

    def __init__(self, data):
        self.data = data
        magic, = struct.unpack("<I", data[:4])
        if magic != MACHO_32BIT_MAGIC:
            raise ValueError("Not a 32-bit Mach-O (magic=0x%08x)" % magic)
        self.segments = []          # list of dicts: name, vmaddr, fileoff, filesize
        self.symbols = {}           # name -> vmaddr
        self._parse_load_commands()

    def _parse_load_commands(self):
        num_commands, = struct.unpack("<I", self.data[16:20])
        cursor = MACHO_HEADER_SIZE
        for _ in range(num_commands):
            command, command_size = struct.unpack("<II", self.data[cursor:cursor + 8])
            if command == LC_SEGMENT:
                name = self.data[cursor + 8:cursor + 24].rstrip(b"\0").decode()
                vmaddr, _vmsize, fileoff, filesize = struct.unpack(
                    "<IIII", self.data[cursor + 24:cursor + 40])
                self.segments.append({
                    "name": name, "vmaddr": vmaddr,
                    "fileoff": fileoff, "filesize": filesize,
                })
            elif command == LC_SYMTAB:
                self._parse_symtab(cursor)
            cursor += command_size

    def _parse_symtab(self, command_offset):
        symbol_table_offset, num_symbols, string_table_offset, _string_table_size = (
            struct.unpack("<IIII", self.data[command_offset + 8:command_offset + 24]))
        for index in range(num_symbols):
            entry = symbol_table_offset + index * NLIST_ENTRY_SIZE
            string_index, _type, _section, _desc, value = struct.unpack(
                "<IBBHI", self.data[entry:entry + NLIST_ENTRY_SIZE])
            name_start = string_table_offset + string_index
            name_end = self.data.index(b"\0", name_start)
            name = self.data[name_start:name_end].decode("latin1")
            if name:
                self.symbols[name] = value

    def segment_containing_fileoffset(self, file_offset):
        for segment in self.segments:
            start = segment["fileoff"]
            if start <= file_offset < start + segment["filesize"]:
                return segment
        raise ValueError("File offset 0x%x is not inside any segment" % file_offset)

    def segment_containing_vmaddr(self, virtual_address):
        for segment in self.segments:
            start = segment["vmaddr"]
            if start <= virtual_address < start + segment["filesize"]:
                return segment
        raise ValueError("Vaddr 0x%x is not inside any segment" % virtual_address)

    def fileoffset_to_vmaddr(self, file_offset):
        segment = self.segment_containing_fileoffset(file_offset)
        return file_offset - segment["fileoff"] + segment["vmaddr"]

    def vmaddr_to_fileoffset(self, virtual_address):
        segment = self.segment_containing_vmaddr(virtual_address)
        return virtual_address - segment["vmaddr"] + segment["fileoff"]

    def find_all(self, needle):
        offsets = []
        search_from = 0
        while True:
            found = self.data.find(needle, search_from)
            if found < 0:
                return offsets
            offsets.append(found)
            search_from = found + 1


def find_externalmethod_offset(target, reference_function_bytes):
    """Find externalMethod in the target's prelinked-kext text.

    The IOFlashStorage kext is compiled identically across devices on the same
    iOS build, so the function is byte-for-byte identical. We slide the
    reference bytes over the target's __PRELINK_TEXT and return the single
    exact match (falling back to a best-effort report if none is exact).
    """
    prelink = next(s for s in target.segments if s["name"] == "__PRELINK_TEXT")
    region_start = prelink["fileoff"]
    region = target.data[region_start:region_start + prelink["filesize"]]

    length = len(reference_function_bytes)
    exact_matches = []
    best_score = -1
    best_offset = None
    for index in range(len(region) - length + 1):
        window = region[index:index + length]
        if window == reference_function_bytes:
            exact_matches.append(region_start + index)
            continue
        # Cheap score only used to report the closest near-miss on failure.
        if best_offset is None or index % 4 == 0:
            score = sum(a == b for a, b in zip(window, reference_function_bytes))
            if score > best_score:
                best_score, best_offset = score, region_start + index

    if len(exact_matches) == 1:
        return exact_matches[0]
    if len(exact_matches) > 1:
        raise ValueError("Ambiguous: %d exact matches for externalMethod: %s"
                         % (len(exact_matches), [hex(x) for x in exact_matches]))
    raise ValueError(
        "No exact match for externalMethod. Closest was 0x%x (%d/%d bytes). "
        "The reference kernel may be a different iOS build."
        % (best_offset, best_score, length))


def compute_withaddress_delta(externalmethod_vmaddr, withaddress_vmaddr):
    anchor = externalmethod_vmaddr + DELTA_ANCHOR_FROM_EXTERNALMETHOD
    return (withaddress_vmaddr + THUMB_BIT - anchor) & UINT32_MASK


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target-kernel", required=True,
                        help="Decrypted+decompressed raw kernel to analyse")
    parser.add_argument("--reference-kernel", required=True,
                        help="Known-good raw kernel from the same iOS build (other device)")
    parser.add_argument("--reference-externalmethod-offset", required=True,
                        type=lambda x: int(x, 0),
                        help="externalMethod file offset in the reference kernel")
    parser.add_argument("--reference-externalmethod-size", required=True,
                        type=lambda x: int(x, 0),
                        help="externalMethod size (bytes) in the reference kernel")
    parser.add_argument("--reference-secureroot-offset", default=None,
                        type=lambda x: int(x, 0),
                        help="SecureRoot file offset in the reference kernel. Used only "
                             "to pick the matching occurrence in the target (the field is "
                             "a guard string; any occurrence is functionally valid).")
    args = parser.parse_args()

    target = MachOKernel(open(args.target_kernel, "rb").read())
    reference = MachOKernel(open(args.reference_kernel, "rb").read())

    # Value 1: SecureRoot self-consistency guard. kernel_patcher.py only asserts
    # kernel[offset:offset+10] == "SecureRoot", so any occurrence works. To
    # reproduce the shipped entries exactly we pick the occurrence at the same
    # ordinal as the reference kernel's known SecureRoot offset (default: first).
    secureroot_offsets = target.find_all(SECUREROOT_STRING)
    if not secureroot_offsets:
        raise ValueError("No 'SecureRoot' string found; wrong/undecrypted kernel?")
    secureroot_ordinal = 0
    if args.reference_secureroot_offset is not None:
        reference_secureroot_offsets = reference.find_all(SECUREROOT_STRING)
        secureroot_ordinal = reference_secureroot_offsets.index(
            args.reference_secureroot_offset)
    secureroot_offset = secureroot_offsets[secureroot_ordinal]

    # Value 2: externalMethod, located by byte-identical match to the reference.
    reference_function_bytes = reference.data[
        args.reference_externalmethod_offset:
        args.reference_externalmethod_offset + args.reference_externalmethod_size]
    externalmethod_offset = find_externalmethod_offset(target, reference_function_bytes)

    # Value 3: size. Function is identical, so reuse the reference size; it only
    # has to be >= the stub size.
    externalmethod_size = args.reference_externalmethod_size
    assert externalmethod_size >= IOFC_STUB_TOTAL_SIZE

    # Value 4: withAddress, resolved from the core-kernel symbol table.
    withaddress_vmaddr = target.symbols[WITHADDRESS_MANGLED_SYMBOL]
    withaddress_offset = target.vmaddr_to_fileoffset(withaddress_vmaddr)

    # Value 5: delta, computed in virtual-address space (externalMethod lives in
    # __PRELINK_TEXT, withAddress in __TEXT: different segment slides).
    externalmethod_vmaddr = target.fileoffset_to_vmaddr(externalmethod_offset)
    withaddress_delta = compute_withaddress_delta(externalmethod_vmaddr, withaddress_vmaddr)

    print("SecureRoot occurrences: %s (using ordinal %d)"
          % ([hex(x) for x in secureroot_offsets], secureroot_ordinal))
    print()
    print("  SecureRoot_file_offset            = 0x%X" % secureroot_offset)
    print("  externalMethod_file_offset        = 0x%X" % externalmethod_offset)
    print("  externalMethod_size               = 0x%X" % externalmethod_size)
    print("  withAddress_file_offset           = 0x%X" % withaddress_offset)
    print("  withAddress_delta                 = 0x%X" % withaddress_delta)
    print()
    print("IOFC_PATCH_INFO entry:")
    print("  [0x%X, 0x%X, 0x%X, 0x%X, 0x%X]" % (
        secureroot_offset, externalmethod_offset, externalmethod_size,
        withaddress_offset, withaddress_delta))


if __name__ == "__main__":
    main()
