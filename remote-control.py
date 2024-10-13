from typing import Generator

import evdev
from camilladsp import CamillaClient, CamillaError
from evdev import KeyEvent, InputEvent


# find available input devices via: ls /dev/input/by-id/
input_device = '/dev/input/by-id/usb-flirc.tv_flirc_350C55EE50543539302E3120FF172729-event-kbd'
cdsp_ip = "127.0.0.1"
cdsp_port = 1234
actions = [
    ('KEY_VOLUMEUP', lambda cdsp : adjust_volume(cdsp, 2)),
    ('KEY_VOLUMEDOWN', lambda cdsp : adjust_volume(cdsp, -2)),
    ('KEY_UP', lambda cdsp : set_config(cdsp, "Heimkino Setup.yml")),
    ('KEY_DOWN', lambda cdsp : set_config(cdsp, "Heimkino Setup leise.yml")),
    (['KEY_MIN_INTERESTING', 'KEY_MUTE'], lambda cdsp : mute(cdsp))
]


def main():
    cdsp = CamillaClient(cdsp_ip, cdsp_port)
    print("Listening for input events")
    for event in listen_for_key_events():
        try:
            connect_to_cdsp_if_necessary(cdsp)
            execute_action_for_event(cdsp, event)
        except CamillaError:
            print("Could not connect to CamillaDSP")
        except Exception as e:
            print(e)


def listen_for_key_events() -> Generator[InputEvent, None, None]:
    remote_control = evdev.InputDevice(input_device)
    remote_control.grab()
    return remote_control.read_loop()


def connect_to_cdsp_if_necessary(cdsp: CamillaClient):
    if not cdsp.is_connected():
        cdsp.connect()


def execute_action_for_event(cdsp: CamillaClient, event: InputEvent):
    key_event = key_press_event_of(event)
    if key_event:
        print("=== New event ===")
        print("Keycode = " + repr(key_event.keycode))
        for (keycode, action) in actions:
            if keycode == key_event.keycode:
                action(cdsp)


def key_press_event_of(event: InputEvent) -> KeyEvent | None:
    if event.type == evdev.ecodes.EV_KEY:
        key_event = evdev.categorize(event)
        if key_event.keystate == evdev.KeyEvent.key_down:
            return key_event
    return None


def adjust_volume(cdsp: CamillaClient, step: int):
    print("Adjust volume by " + str(step))
    volume = cdsp.volume.main()
    new_volume = min(volume + step, 0)
    cdsp.volume.set_main(new_volume)


def mute(cdsp: CamillaClient):
    shall_mute = not cdsp.mute.main()
    print("Mute: " + str(shall_mute))
    cdsp.mute.set_main(shall_mute)


def set_config(cdsp: CamillaClient, config_name: str):
    new_config = "/mnt/mmcblk0p2/tce/camilladsp/configs/" + config_name
    print("Setting config: " + new_config)
    cdsp.config.set_file_path(new_config)
    cdsp.general.reload()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
