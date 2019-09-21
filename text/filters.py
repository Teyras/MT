#!/usr/bin/python
from panflute import *


def is_include_line(elem):
    return (
        len(elem.content) >= 3 and 
        all(isinstance(x, (Str, Space)) for x in elem.content) and 
        elem.content[0].text == "!include" and 
        isinstance(elem.content[1], Space)
    )


def action(elem, doc):
    if isinstance(elem, Para):
        if is_include_line(elem):
            name = stringify(elem, newlines=False).split(maxsplit=1)[1]
            with open(name, "r") as text:
                return convert_text(text.read())
    if isinstance(elem, Image):
        if elem.url.endswith(".tex"):
            with open(elem.url, "r") as source:
                return RawInline("\n".join([
                    '\\begin{figure}',
                    '\centering',
                    source.read(),
                    f'\caption{{{stringify(elem)}}}'
                    '\end{figure}'
                ]), format="latex")


def main(doc=None):
    return run_filter(action, doc=doc)


if __name__ == "__main__":
    main()
