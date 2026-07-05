#!/usr/bin/env python3
"""Download only the kernelcache out of a (huge) remote IPSW.

An IPSW is just a zip file, and Apple's download server supports HTTP range
requests. Rather than downloading the whole ~900 MB image we:

  1. read the zip's End-Of-Central-Directory record from the tail,
  2. read the central directory and locate the kernelcache entry,
  3. download only that entry's compressed bytes and inflate them.

The output is the *encrypted* IMG3 kernelcache exactly as stored in the IPSW.
Decrypt + decompress it afterwards with xpwntool (see the repo's acquire.sh):

    xpwntool kernelcache.enc kernelcache.dec -iv <IV> -k <KEY> -decrypt
    xpwntool kernelcache.dec kernelcache.raw

The IV/KEY come from builds/<BUILD>/index.html (the redsn0w-style keyfile).
"""
import argparse
import struct
import sys
import urllib.request
import zlib

# Zip format constants (offsets/sizes within each record, in bytes).
END_OF_CENTRAL_DIR_SIGNATURE = b"PK\x05\x06"
CENTRAL_DIR_ENTRY_SIGNATURE = b"PK\x01\x02"
LOCAL_FILE_HEADER_FIXED_SIZE = 30
# The EOCD record is at most 22 bytes + a trailing comment (<= 65535 bytes),
# so reading the final 64 KiB is always enough to find it.
MAX_EOCD_SEARCH_BYTES = 65536

STORED_NO_COMPRESSION = 0
DEFLATE_COMPRESSION = 8


def http_range(url, first_byte, last_byte):
    """Return bytes [first_byte, last_byte] inclusive from a remote URL."""
    request = urllib.request.Request(
        url, headers={"Range": f"bytes={first_byte}-{last_byte}"})
    return urllib.request.urlopen(request).read()


def http_content_length(url):
    request = urllib.request.Request(url, method="HEAD")
    return int(urllib.request.urlopen(request).headers["Content-Length"])


def find_kernelcache_entry(url, ipsw_size):
    """Locate the kernelcache central-directory entry in the remote zip."""
    tail = http_range(url, ipsw_size - MAX_EOCD_SEARCH_BYTES, ipsw_size - 1)
    eocd_offset = tail.rfind(END_OF_CENTRAL_DIR_SIGNATURE)
    if eocd_offset < 0:
        sys.exit("Could not find zip End-Of-Central-Directory record")
    central_dir_size, central_dir_offset = struct.unpack(
        "<II", tail[eocd_offset + 12:eocd_offset + 20])

    central_dir = http_range(
        url, central_dir_offset, central_dir_offset + central_dir_size - 1)

    cursor = 0
    while cursor < len(central_dir):
        if central_dir[cursor:cursor + 4] != CENTRAL_DIR_ENTRY_SIGNATURE:
            break
        compression_method, = struct.unpack(
            "<H", central_dir[cursor + 10:cursor + 12])
        compressed_size, uncompressed_size = struct.unpack(
            "<II", central_dir[cursor + 20:cursor + 28])
        name_length, extra_length, comment_length = struct.unpack(
            "<HHH", central_dir[cursor + 28:cursor + 34])
        local_header_offset, = struct.unpack(
            "<I", central_dir[cursor + 42:cursor + 46])
        name = central_dir[cursor + 46:cursor + 46 + name_length].decode("latin1")

        if "kernelcache" in name:
            return {
                "name": name,
                "compression_method": compression_method,
                "compressed_size": compressed_size,
                "uncompressed_size": uncompressed_size,
                "local_header_offset": local_header_offset,
            }
        cursor += 46 + name_length + extra_length + comment_length
    sys.exit("No kernelcache entry found in IPSW central directory")


def download_entry_bytes(url, entry):
    """Download and inflate a single central-directory entry's file data."""
    # The local file header repeats the name/extra lengths; the actual file
    # data starts right after it.
    local_header = http_range(
        url,
        entry["local_header_offset"],
        entry["local_header_offset"] + LOCAL_FILE_HEADER_FIXED_SIZE - 1)
    name_length, extra_length = struct.unpack("<HH", local_header[26:30])
    data_offset = (entry["local_header_offset"]
                   + LOCAL_FILE_HEADER_FIXED_SIZE + name_length + extra_length)

    compressed = http_range(
        url, data_offset, data_offset + entry["compressed_size"] - 1)

    if entry["compression_method"] == STORED_NO_COMPRESSION:
        raw = compressed
    elif entry["compression_method"] == DEFLATE_COMPRESSION:
        raw = zlib.decompress(compressed, -zlib.MAX_WBITS)  # raw deflate
    else:
        sys.exit("Unexpected zip compression method %d" % entry["compression_method"])

    if len(raw) != entry["uncompressed_size"]:
        sys.exit("Size mismatch: got %d, expected %d"
                 % (len(raw), entry["uncompressed_size"]))
    return raw


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("ipsw_url", help="URL of the remote IPSW")
    parser.add_argument("output_path", help="Where to write the encrypted kernelcache")
    args = parser.parse_args()

    ipsw_size = http_content_length(args.ipsw_url)
    entry = find_kernelcache_entry(args.ipsw_url, ipsw_size)
    print("Found %s (%d bytes uncompressed)" % (entry["name"], entry["uncompressed_size"]))

    raw = download_entry_bytes(args.ipsw_url, entry)
    with open(args.output_path, "wb") as output_file:
        output_file.write(raw)
    print("Wrote encrypted kernelcache to %s (%d bytes)" % (args.output_path, len(raw)))


if __name__ == "__main__":
    main()
