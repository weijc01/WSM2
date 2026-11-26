class Wsm2Error(Exception):
    def __init__(self, message, key=None, args=()):
        super().__init__(message)
        self.key = key
        self.args = tuple(args)
