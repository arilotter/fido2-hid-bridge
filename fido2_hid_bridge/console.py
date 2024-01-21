import click

import asyncio
import logging

from .ctap_hid_device import CTAPHIDDevice

from . import __version__


@click.command()
@click.version_option(version=__version__)
def main():
    """
    This application acts as virtual USB-HID FIDO2 device.

    This device will receive FIDO2 CTAP2.1 commands, and forward them
    to an attached PC/SC authenticator.

    This allows using authenticators over PC/SC from applications
    that only support USB-HID, such as Firefox; with this program running
    you can use NFC authenticators or Smartcards.

    Note that this is a very early-stage application, but it does work with
    Chrome and Firefox.
"""
    logging.basicConfig(level=logging.DEBUG)
    loop = asyncio.get_event_loop()
    loop.run_until_complete(run_device())
    loop.run_forever()


async def run_device() -> None:
    await CTAPHIDDevice().start()