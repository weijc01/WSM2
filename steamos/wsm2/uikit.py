import json
import os
from pathlib import Path

from .errors import Wsm2Error


def clear():
    os.system("cls" if os.name == "nt" else "clear")


def pause(message=""):
    input("\n" + message + " [Enter] ")


def prompt(label, default=""):
    text = str(default) if default is not None else ""
    suffix = " [" + text + "]" if text else ""
    value = input(label + suffix + ": ").strip()
    return value if value else text


def ask_int(label, default, low=None, high=None):
    while True:
        raw = prompt(label, default)
        try:
            value = int(raw)
        except (TypeError, ValueError):
            print("Numerieke waarde vereist.")
            continue
        if low is not None and value < low:
            print("Minimum: " + str(low))
            continue
        if high is not None and value > high:
            print("Maximum: " + str(high))
            continue
        return value


def ask_bool(label, default=True):
    raw = prompt(label, "y" if default else "n").casefold()
    return raw.startswith("y") or raw.startswith("j")


def ask_choice(label, options, default=None):
    if not options:
        return default
    values = [item[0] for item in options]
    if default not in values:
        default = values[0]
    for index, item in enumerate(options, 1):
        marker = " *" if item[0] == default else ""
        print("  {0}) {1}{2}".format(index, item[1], marker))
    while True:
        raw = prompt(label, str(values.index(default) + 1))
        try:
            number = int(raw)
        except ValueError:
            continue
        if 1 <= number <= len(options):
            return options[number - 1][0]


def edit_json(label, value):
    initial = json.dumps(value, ensure_ascii=False)
    while True:
        raw = prompt(label, initial)
        try:
            return json.loads(raw)
        except ValueError as exc:
            print("Ongeldige JSON: " + str(exc))


def show_error(app, problem):
    if isinstance(problem, (Wsm2Error, Exception)):
        message = app.error_text(problem)
    else:
        message = str(problem)
    print("\n[" + app.t("WSM2 - Fout") + "] " + message)
    pause()


def show_info(message, do_pause=True):
    print("\n" + str(message))
    if do_pause:
        pause()


def edit_fields(app, title, obj, fields):
    print("\n" + title)
    for field in fields:
        key, label, kind = field[0], field[1], field[2]
        extra = field[3:]
        current = obj.get(key, extra[0] if extra else "")
        if kind == "int":
            low, high = (extra + [None, None])[:2]
            obj[key] = ask_int(label, current, low, high)
        elif kind == "bool":
            obj[key] = ask_bool(label, bool(current))
        elif kind == "json":
            obj[key] = edit_json(label, current)
        elif kind == "choice":
            obj[key] = ask_choice(label, extra[0], current)
        else:
            obj[key] = prompt(label, current)


def numbered_menu(title, items):
    print("\n" + title)
    for index, item in enumerate(items, 1):
        print("  {0}) {1}".format(index, item[0]))
    print("  0) Terug")
    while True:
        raw = prompt("Keuze", "0")
        try:
            number = int(raw)
        except ValueError:
            continue
        if number == 0:
            return None
        if 1 <= number <= len(items):
            return items[number - 1][1]


def print_indexed(title, values, selected=0, formatter=None):
    print("\n" + title)
    if not values:
        print("  (geen)")
        return
    for index, value in enumerate(values, 1):
        text = formatter(value) if formatter else str(value)
        marker = " *" if index - 1 == selected else ""
        print("  {0}) {1}{2}".format(index, text, marker))


def move_item(items, index, direction):
    target = index + direction
    if target < 0 or target >= len(items):
        return index
    items[index], items[target] = items[target], items[index]
    return target
