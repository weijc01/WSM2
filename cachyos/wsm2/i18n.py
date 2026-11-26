import json
from pathlib import Path

LANG_DIR = Path(__file__).resolve().parent.parent / "lang"
LANG_CODES = ["en", "nl", "fr", "de"]
LANG_NAMES = {"en": "English", "nl": "Nederlands", "fr": "Français", "de": "Deutsch"}


class I18n:
    def __init__(self, code="en"):
        self.translations = {}
        for item in LANG_CODES:
            path = LANG_DIR / (item + ".json")
            try:
                with path.open("r", encoding="utf-8") as handle:
                    self.translations[item] = json.load(handle)
            except (OSError, ValueError):
                self.translations[item] = {}
        self.language = "en"
        self.set_language(code)

    def set_language(self, code):
        self.language = code if code in self.translations else "en"
        return self.language

    def t(self, key, *args):
        text = self.translations.get(self.language, {}).get(key, key)
        if not args:
            return text
        try:
            return text.format(*args)
        except (IndexError, KeyError, ValueError):
            return text
