# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

from os import PathLike
import gi

gi.require_versions(
    {
        "GObject": "2.0",
        "Gtk": "4.0",
        "Gio": "2.0",
        "Adw": "1",
        "Nautilus": "4.1",
    }
)

import hashlib
from gi.repository import Adw, Gio, Nautilus, GObject
from contextlib import contextmanager
from mmap import mmap, ACCESS_READ
from urllib.parse import unquote
from typing import List, Self
import os
from enum import Flag, StrEnum, auto

# TODO:
# * Given a list of files, create a hashsum file.
# * The hashsum file is a plain-text file consisting of a list of files alongside their hash (in hexadecimal digest).
# * The hashfile format is basically just <HASH><WHITESPACE><FILENAME>.
# * Should also contain a verification function for the hashsum file for plain-text files that ends in `.hashsum.txt`.


@contextmanager
def mmap_read(file):
    with open(file) as f, mmap(f.fileno(), 0, access=ACCESS_READ) as f:
        yield f


class HashsumInputMode(StrEnum):
    BINARY = "*"
    TEXT = " "


class SupportedHashsumAlgos(Flag):
    MD5 = auto()
    SHA256 = auto()
    BLAKE2B = auto()
    BLAKE2S = auto()

    @staticmethod
    def infer_algo_type(fp: str) -> Self | None:
        match os.path.splitext(fp.removesuffix(".txt"))[1]:
            case ".md5":
                return SupportedHashsumAlgos.MD5
            case ".sha256":
                return SupportedHashsumAlgos.SHA256
            case ".blake2b":
                return SupportedHashsumAlgos.BLAKE2B
            case ".blake2s":
                return SupportedHashsumAlgos.BLAKE2S

        return None


class Hashsum:
    def __init__(self) -> None:
        self.checksum: str
        self.input_mode: HashsumInputMode
        self.filepath: str


class HashsumFile:
    def __init__(self) -> None:
        self.hash_algo: SupportedHashsumAlgos
        self.hashsums: List[Hashsum]

    def parse(self, b: str):
        for line in b.splitlines():
            hashsum = Hashsum()
            checksum, metadata = line.split(sep=" ", maxsplit=1)

            if not (metadata[0] == " " or metadata[0] == "*"):
                continue

            hashsum.checksum = checksum
            hashsum.input_mode = metadata[0]
            hashsum.filepath = metadata[1:]

            self.hashsums.append(hashsum)

    def verify(self):
        result = HashsumFile()
        for hashsum in self.hashsums:
            with mmap_read(hashsum.filepath) as f:
                h: hashlib._Hash | hashlib.blake2b | hashlib.blake2s
                match self.hash_algo:
                    case SupportedHashsumAlgos.MD5:
                        h = hashlib.md5(f)
                    case SupportedHashsumAlgos.BLAKE2B:
                        h = hashlib.blake2b(f)
                    case SupportedHashsumAlgos.SHA256:
                        h = hashlib.sha256(f)
                    case SupportedHashsumAlgos.BLAKE2S:
                        h = hashlib.blake2s(f)

                if h.hexdigest() == hashsum.checksum:
                    result.hashsums.append(hashsum)

        return result


class HashsumsSubmenu(GObject.GObject, Nautilus.MenuProvider):
    def create_checksum_file(self, menu, files: List[Nautilus.FileInfo]):
        pass

    def verify_checksum_file(self, menu, checksum_file: Nautilus.FileInfo):
        fn = unquote(checksum_file.get_uri()[7:]).encode("utf-8")
        checksum = HashsumFile().parse(fn.encode())

    def get_file_items(
        self,
        files: List[Nautilus.FileInfo],
    ) -> List[Nautilus.MenuItem]:
        hashmenu_item = Nautilus.MenuItem(
            name="HashsumsSubmenu::Hashsums",
            label="Hashsums",
        )
        submenu = Nautilus.Menu()
        hashmenu_item.set_submenu(submenu)

        submenu.append_item(
            Nautilus.MenuItem(
                name="HashsumsSubmenu::Hashsums::Create",
                label="Create checksum file",
            ).connect("activate", self.create_checksum_file, files)
        )

        file = files[0]
        if file.get_uri_scheme() != "file":
            return []

        if file.is_directory():
            return []

        if file.get_mime_type() == "text/plain":
            submenu.append_item(
                Nautilus.MenuItem(
                    name="HashsumsSubmenu::Hashsums::Verify",
                    label="Verify checksum file",
                ).connect("activate", self.verify_checksum_file, file)
            )

        return [hashmenu_item]

    # Even though we're not using background items, Nautilus will generate
    # a warning if the method isn't present
    def get_background_items(
        self,
        current_folder: Nautilus.FileInfo,
    ) -> List[Nautilus.MenuItem]:
        return []


class HashsumsPropertiesModel(GObject.GObject, Nautilus.PropertiesModelProvider):
    def get_models(
        self,
        files: List[Nautilus.FileInfo],
    ) -> List[Nautilus.PropertiesModel]:
        if len(files) != 1:
            return []

        file = files[0]
        if file.get_uri_scheme() != "file":
            return []

        if file.is_directory():
            return []

        filename = unquote(file.get_uri()[7:]).encode("utf-8")

        supported_hashes = {}

        with mmap_read(filename) as f:
            supported_hashes["MD5"] = hashlib.md5(f)
            supported_hashes["SHA256"] = hashlib.sha256(f)
            supported_hashes["SHA512"] = hashlib.sha512(f)
            supported_hashes["BLAKE2b"] = hashlib.blake2b(f)
            supported_hashes["BLAKE2s"] = hashlib.blake2s(f)

        section_model = Gio.ListStore.new(item_type=Nautilus.PropertiesItem)

        for formal_name, hashsum in supported_hashes.items():
            section_model.append(
                Nautilus.PropertiesItem(
                    name=formal_name,
                    value=hashsum.hexdigest(),
                )
            )

        return [
            Nautilus.PropertiesModel(
                title="Hashsums",
                model=section_model,
            ),
        ]


class UpdateFileInfoAsync(GObject.GObject, Nautilus.InfoProvider):
    def __init__(self):
        super().__init__()
        self.timers = []
        pass

    def update_file_info_full(self, provider, handle, closure, file):
        print("update_file_info_full")
        self.timers.append(
            GObject.timeout_add_seconds(3, self.update_cb, provider, handle, closure)
        )
        return Nautilus.OperationResult.IN_PROGRESS

    def update_cb(self, provider, handle, closure):
        print("update_cb")
        Nautilus.info_provider_update_complete_invoke(
            closure,
            provider,
            handle,
            Nautilus.OperationResult.FAILED,
        )

    def cancel_update(self, provider, handle):
        print("cancel_update")
        for t in self.timers:
            GObject.source_remove(t)
        self.timers = []
