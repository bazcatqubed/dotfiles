# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

from os import PathLike
import gi
import re

gi.require_versions(
    {
        "GObject": "2.0",
        "Gtk": "4.0",
        "Gio": "2.0",
        "Adw": "1",
        "Nautilus": "4.1",
        "Xdp": "1.0",
        "XdpGtk4": "1.0",
    }
)

import hashlib
from gettext import gettext as _, textdomain
from gi.repository import Adw, Gtk, Gio, Nautilus, GObject, Xdp, XdpGtk4
from contextlib import contextmanager
from mmap import mmap, ACCESS_READ
from urllib.parse import unquote
from typing import List, Self
import os
from enum import Flag, StrEnum, auto

textdomain("one.foodogsquared.NautilusPythonExtensions")

# TODO:
# * Given a list of files, create a hashsum file.
# * The hashsum file is a plain-text file consisting of a list of files alongside their hash (in hexadecimal digest).
# * The hashfile format is basically just <HASH><WHITESPACE><FILENAME>.
# * Should also contain a verification function for the hashsum file for plain-text files that ends in `.hashsum.txt`.


@contextmanager
def mmap_read(file):
    with open(file) as f, mmap(f.fileno(), 0, access=ACCESS_READ) as f:
        yield f


class SupportedHashsumAlgos(Flag):
    MD5 = auto()
    SHA256 = auto()
    BLAKE2B = auto()
    BLAKE2S = auto()

    @staticmethod
    def infer_algo_type(fp: str) -> Self | None:
        match os.path.splitext(fp.removesuffix(".txt"))[1]:
            case "MD5":
                return SupportedHashsumAlgos.MD5
            case "SHA256":
                return SupportedHashsumAlgos.SHA256
            case "BLAKE2b":
                return SupportedHashsumAlgos.BLAKE2B
            case "BLAKE2s":
                return SupportedHashsumAlgos.BLAKE2S

        return None


class Hashsum:
    def __init__(self) -> None:
        self.checksum: str
        self.filepath: str
        self.algo: SupportedHashsumAlgos

    @staticmethod
    def verify(hashsums: List[Self]):
        for hashsum in hashsums:
            with mmap_read(hashsum.filepath) as f:
                h: hashlib._Hash | hashlib.blake2b | hashlib.blake2s | None
                match hashsum.algo:
                    case SupportedHashsumAlgos.MD5:
                        h = hashlib.md5(f)
                    case SupportedHashsumAlgos.BLAKE2B:
                        h = hashlib.blake2b(f)
                    case SupportedHashsumAlgos.SHA256:
                        h = hashlib.sha256(f)
                    case SupportedHashsumAlgos.BLAKE2S:
                        h = hashlib.blake2s(f)

                if h is None:
                    continue

                if h.hexdigest() == hashsum.checksum:
                    hashsums.append(hashsum)

    @staticmethod
    def parse(b: str) -> List[Self]:
        hashsums = []
        for line in b.splitlines():
            hashsum = Hashsum()
            match = re.fullmatch(r'(\w+)\s+\((\w+)\) = (\w+)', line)

            if match is None:
                continue

            algorithm = SupportedHashsumAlgos.infer_algo_type(match.group(1))
            if algorithm is None:
                continue

            hashsum.algo = algorithm
            hashsum.filepath = match.group(2)
            hashsum.checksum = match.group(3)

            hashsums.append(hashsum)

        return hashsums


class HashsumsSubmenu(GObject.GObject, Nautilus.MenuProvider, Nautilus.PropertiesModelProvider):
    def _on_checksum_file_save(self, files: List[Nautilus.FileInfo]):
        def F(file_dialog, result):
            result = file_dialog.save_finish(result)

            # TODO:
            # * Per given file, exclude if is a directory.
            # * Get the hash ofthe file.
            # * Create the checksum file
            for f in files:
                if f.is_directory():
                    continue

                f = f.get_location()
                continue

        return F

    def create_checksum_file(self, menu, files: List[Nautilus.FileInfo]):
        # TODO: Create a `checksum` file per given list of files.
        app = Gtk.Application.get_default()
        active_window = app.get_active_window() if app else None

        parent_folder = files[0].get_location().get_parent()
        file_dialog = Gtk.FileDialog(
            title=_(u"Save checksums file"),
            initial_name="checksum.txt",
            initial_folder=parent_folder,
            modal=True,
        )
        file_dialog.save(parent=active_window, cancellable=None, callback=self._on_checksum_file_save(files))

    def verify_checksum_file(self, menu, checksum_file: Nautilus.FileInfo):
        fn = unquote(checksum_file.get_uri()[7:]).encode("utf-8")
        pass

    def show_checkums(self, menu, files: List[Nautilus.FileInfo]):
        pass

    def get_file_items(
        self,
        files: List[Nautilus.FileInfo],
    ) -> List[Nautilus.MenuItem]:
        hashmenu_item = Nautilus.MenuItem(
            name="HashsumsSubmenu::Hashsums",
            label=_(u"Hashsums"),
        )
        submenu = Nautilus.Menu()
        hashmenu_item.set_submenu(submenu)

        if len(files) <= 0:
            return []

        file = files[0]
        if file.is_directory():
            return []

        create_submenu = Nautilus.MenuItem(
            name="HashsumsSubmenu::Hashsums::Create",
            label=_(u"Create checksum file"),
        )
        create_submenu.connect("activate", self.create_checksum_file, files)
        submenu.append_item(create_submenu)

        show_submenu = Nautilus.MenuItem(
            name="HashsumsSubmenu::Hashsums::Show",
            label=_(u"Show checksums"),
        )
        show_submenu.connect("activate", self.show_checkums, files)
        submenu.append_item(show_submenu)

        if file.get_mime_type() == "text/plain":
            verify_submenu = Nautilus.MenuItem(
                name="HashsumsSubmenu::Hashsums::Verify",
                label=_(u"Verify checksum file"),
            )
            verify_submenu.connect("activate", self.verify_checksum_file, file)
            submenu.append_item(verify_submenu)

        return [hashmenu_item]

    # Even though we're not using background items, Nautilus will generate
    # a warning if the method isn't present
    def get_background_items(
        self,
        current_folder: Nautilus.FileInfo,
    ) -> List[Nautilus.MenuItem]:
        return []

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
                title=_(u"Hashsums"),
                model=section_model,
            ),
        ]
